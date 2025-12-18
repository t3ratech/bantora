/**
 * Created by Cascade AI
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025-11-30
 * Email        : tkaviya@t3ratech.co.zw
 */

package com.t3ratech.bantora.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.t3ratech.bantora.entity.BantoraIdea;
import com.t3ratech.bantora.entity.BantoraPoll;
import com.t3ratech.bantora.entity.BantoraPollOption;
import com.t3ratech.bantora.enums.BantoraIdeaStatus;
import com.t3ratech.bantora.enums.BantoraPollScope;
import com.t3ratech.bantora.enums.BantoraPollStatus;
import com.t3ratech.bantora.repository.BantoraHashtagStatsReadRepository;
import com.t3ratech.bantora.repository.BantoraIdeaRepository;
import com.t3ratech.bantora.repository.BantoraIdeaReadRepository;
import com.t3ratech.bantora.repository.BantoraPollHashtagLinkRepository;
import com.t3ratech.bantora.repository.BantoraPollOptionRepository;
import com.t3ratech.bantora.repository.BantoraPollRepository;
import com.t3ratech.bantora.repository.BantoraPollSourceIdeaLinkRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.reactive.TransactionalOperator;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;
import reactor.core.publisher.Mono;
import reactor.core.publisher.Flux;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class AiService {

    private final WebClient.Builder webClientBuilder;
    private final BantoraHashtagStatsReadRepository hashtagStatsReadRepository;
    private final BantoraIdeaReadRepository ideaReadRepository;
    private final BantoraIdeaRepository ideaRepository;
    private final BantoraPollRepository pollRepository;
    private final BantoraPollOptionRepository pollOptionRepository;
    private final BantoraPollHashtagLinkRepository pollHashtagLinkRepository;
    private final BantoraPollSourceIdeaLinkRepository pollSourceIdeaLinkRepository;
    private final TransactionalOperator transactionalOperator;
    private final ObjectMapper objectMapper;

    @Value("${bantora.ai.gemini.api-key}")
    private String geminiApiKey;

    @Value("${bantora.ai.gemini.url}")
    private String geminiUrl;

    @Value("${bantora.ai.poll.duration-days}")
    private int pollDurationDays;

    @Value("${bantora.ai.poll.default-scope}")
    private String defaultScope;

    @Value("${bantora.ai.poll.max-ideas-per-hashtag}")
    private int maxIdeasPerHashtag;

    @Value("${bantora.poll.approval-required}")
    private boolean pollApprovalRequired;

    public Mono<Void> processTopHashtags() {
        return hashtagStatsReadRepository.findTopHashtagsByPendingIdeaCount(2)
                .concatMap(this::processHashtag)
                .then();
    }

    private Mono<Void> processHashtag(BantoraHashtagStatsReadRepository.HashtagPendingIdeaCount stat) {
        UUID hashtagId = Objects.requireNonNull(stat.hashtagId(), "hashtagId");
        if (stat.pendingIdeaCount() <= 0) {
            return Mono.empty();
        }

        return ideaReadRepository.findPendingIdeasByHashtagId(hashtagId, maxIdeasPerHashtag)
                .collectList()
                .flatMap(ideas -> {
                    if (ideas.isEmpty()) {
                        return Mono.empty();
                    }
                    return processIdeasForHashtag(stat, ideas);
                });
    }

    private Mono<Void> processIdeasForHashtag(
            BantoraHashtagStatsReadRepository.HashtagPendingIdeaCount stat,
            List<BantoraIdea> ideas
    ) {
        UUID hashtagId = Objects.requireNonNull(stat.hashtagId(), "hashtagId");
        String tag = Objects.requireNonNull(stat.tag(), "tag");

        Map<UUID, BantoraIdea> ideaById = new HashMap<>();
        for (BantoraIdea idea : ideas) {
            UUID ideaId = Objects.requireNonNull(idea.getId(), "idea.id");
            ideaById.put(ideaId, idea);
        }

        String prompt = buildPromptForHashtag(tag, ideas);

        return callGemini(prompt)
                .flatMap(aiResponse -> applyAiResponse(hashtagId, ideaById, aiResponse));
    }

    private String buildPromptForHashtag(String tag, List<BantoraIdea> ideas) {
        StringBuilder builder = new StringBuilder();
        builder.append("You are generating polls for the hashtag '");
        builder.append(tag);
        builder.append("'.\n\n");
        builder.append("Input ideas are JSON objects with fields: id, categoryId, userPhone, content.\n");
        builder.append("Return STRICT JSON (no markdown) with this schema:\n");
        builder.append("{\n");
        builder.append("  \"polls\": [\n");
        builder.append("    {\n");
        builder.append("      \"title\": \"...\",\n");
        builder.append("      \"description\": \"...\",\n");
        builder.append("      \"categoryId\": \"<uuid-from-input>\",\n");
        builder.append("      \"options\": [\"...\", \"...\"],\n");
        builder.append("      \"sourceIdeaIds\": [\"<uuid>\", ...]\n");
        builder.append("    }\n");
        builder.append("  ],\n");
        builder.append("  \"rejectedIdeaIds\": [\"<uuid>\", ...]\n");
        builder.append("}\n\n");
        builder.append("Rules:\n");
        builder.append("- Deduplicate similar ideas into one poll when appropriate.\n");
        builder.append("- Reject infeasible or unclear ideas by listing their IDs in rejectedIdeaIds.\n");
        builder.append("- Every poll must reference at least 1 source idea ID from the input list.\n");
        builder.append("- categoryId for each poll MUST be one of the categoryIds from its source ideas.\n\n");
        builder.append("Input ideas:\n");

        List<Map<String, Object>> ideaPayload = new ArrayList<>();
        for (BantoraIdea idea : ideas) {
            Map<String, Object> item = new HashMap<>();
            item.put("id", Objects.requireNonNull(idea.getId(), "idea.id").toString());
            item.put("categoryId", Objects.requireNonNull(idea.getCategoryId(), "idea.categoryId").toString());
            item.put("userPhone", Objects.requireNonNull(idea.getUserPhone(), "idea.userPhone"));
            item.put("content", Objects.requireNonNull(idea.getContent(), "idea.content"));
            ideaPayload.add(item);
        }

        try {
            builder.append(objectMapper.writeValueAsString(ideaPayload));
        } catch (Exception e) {
            throw new IllegalStateException("Failed to build AI prompt JSON", e);
        }

        return builder.toString();
    }

    private Mono<AiResponse> callGemini(String prompt) {
        if (prompt == null || prompt.isBlank()) {
            return Mono.error(new IllegalArgumentException("prompt is required"));
        }
        if (geminiApiKey == null || geminiApiKey.isBlank()) {
            return Mono.error(new IllegalStateException("Missing Gemini API key configuration"));
        }
        if (geminiUrl == null || geminiUrl.isBlank()) {
            return Mono.error(new IllegalStateException("Missing Gemini URL configuration"));
        }

        Map<String, Object> requestBody = Map.of(
                "contents", List.of(
                        Map.of(
                                "parts", List.of(
                                        Map.of("text", prompt)
                                )
                        )
                )
        );

        return webClientBuilder.build()
                .post()
                .uri(geminiUrl + "?key=" + geminiApiKey)
                .header("Content-Type", "application/json")
                .bodyValue(requestBody)
                .retrieve()
                .bodyToMono(String.class)
                .map(this::extractAiTextFromGeminiResponse)
                .map(this::parseAiResponse)
                .onErrorResume(WebClientResponseException.class, e -> {
                    String body = e.getResponseBodyAsString();
                    return Mono.error(new IllegalStateException("Gemini API call failed: HTTP " + e.getStatusCode() + " body=" + body));
                });
    }

    private String extractAiTextFromGeminiResponse(String response) {
        try {
            JsonNode root = objectMapper.readTree(response);
            JsonNode candidates = root.path("candidates");
            if (!candidates.isArray() || candidates.isEmpty()) {
                throw new IllegalStateException("Gemini response missing candidates");
            }
            String text = candidates.get(0)
                    .path("content")
                    .path("parts")
                    .get(0)
                    .path("text")
                    .asText();
            if (text == null || text.isBlank()) {
                throw new IllegalStateException("Gemini response missing text");
            }
            return stripMarkdownCodeFences(text.trim());
        } catch (Exception e) {
            throw new IllegalStateException("Failed to parse Gemini response", e);
        }
    }

    private String stripMarkdownCodeFences(String text) {
        String cleaned = text;
        if (cleaned.startsWith("```")) {
            int firstNewline = cleaned.indexOf('\n');
            if (firstNewline > 0) {
                cleaned = cleaned.substring(firstNewline + 1);
            }
        }
        if (cleaned.endsWith("```")) {
            cleaned = cleaned.substring(0, cleaned.length() - 3);
        }
        return cleaned.trim();
    }

    AiResponse parseAiResponse(String aiText) {
        try {
            JsonNode node = objectMapper.readTree(aiText);
            JsonNode pollsNode = node.path("polls");
            if (!pollsNode.isArray()) {
                throw new IllegalStateException("AI response missing polls array");
            }
            List<AiPoll> polls = new ArrayList<>();
            for (JsonNode pollNode : pollsNode) {
                polls.add(AiPoll.fromJson(pollNode));
            }

            JsonNode rejectedNode = node.path("rejectedIdeaIds");
            if (!rejectedNode.isArray()) {
                throw new IllegalStateException("AI response missing rejectedIdeaIds array");
            }
            Set<UUID> rejected = new HashSet<>();
            for (JsonNode idNode : rejectedNode) {
                rejected.add(UUID.fromString(idNode.asText()));
            }

            return new AiResponse(polls, rejected);
        } catch (Exception e) {
            throw new IllegalStateException("Failed to parse AI response JSON", e);
        }
    }

    private Mono<Void> applyAiResponse(
            UUID hashtagId,
            Map<UUID, BantoraIdea> ideaById,
            AiResponse aiResponse
    ) {
        Objects.requireNonNull(hashtagId, "hashtagId");
        Objects.requireNonNull(ideaById, "ideaById");
        Objects.requireNonNull(aiResponse, "aiResponse");

        return transactionalOperator.transactional(Mono.defer(() -> {
            LocalDateTime now = LocalDateTime.now();

            Set<UUID> usedIdeaIds = new HashSet<>();
            return Flux.fromIterable(aiResponse.polls())
                    .concatMap(poll -> createPollFromAi(hashtagId, ideaById, poll, now)
                            .doOnNext(created -> usedIdeaIds.addAll(poll.sourceIdeaIds())))
                    .then(updateIdeaStatuses(ideaById, usedIdeaIds, aiResponse.rejectedIdeaIds(), now));
        }));
    }

    private Mono<UUID> createPollFromAi(
            UUID hashtagId,
            Map<UUID, BantoraIdea> ideaById,
            AiPoll poll,
            LocalDateTime now
    ) {
        Objects.requireNonNull(hashtagId, "hashtagId");
        Objects.requireNonNull(ideaById, "ideaById");
        Objects.requireNonNull(poll, "poll");
        Objects.requireNonNull(now, "now");

        if (poll.title().isBlank()) {
            return Mono.error(new IllegalArgumentException("AI poll title is required"));
        }
        if (poll.categoryId() == null) {
            return Mono.error(new IllegalArgumentException("AI poll categoryId is required"));
        }
        if (poll.options().isEmpty()) {
            return Mono.error(new IllegalArgumentException("AI poll options are required"));
        }
        if (poll.sourceIdeaIds().isEmpty()) {
            return Mono.error(new IllegalArgumentException("AI poll sourceIdeaIds are required"));
        }
        if (poll.options().size() < 2) {
            return Mono.error(new IllegalArgumentException("AI poll must have at least 2 options"));
        }

        BantoraIdea firstIdea = ideaById.get(poll.sourceIdeaIds().get(0));
        if (firstIdea == null) {
            return Mono.error(new IllegalArgumentException("AI poll references unknown source idea"));
        }
        String creatorPhone = Objects.requireNonNull(firstIdea.getUserPhone(), "idea.userPhone");

        for (UUID sourceIdeaId : poll.sourceIdeaIds()) {
            BantoraIdea sourceIdea = ideaById.get(sourceIdeaId);
            if (sourceIdea == null) {
                return Mono.error(new IllegalArgumentException("AI poll references unknown sourceIdeaId: " + sourceIdeaId));
            }
            UUID sourceCategoryId = Objects.requireNonNull(sourceIdea.getCategoryId(), "idea.categoryId");
            if (!poll.categoryId().equals(sourceCategoryId)) {
                return Mono.error(new IllegalArgumentException("AI poll categoryId must match source idea categories"));
            }
        }

        BantoraPollScope scope = BantoraPollScope.valueOf(Objects.requireNonNull(defaultScope, "defaultScope").trim().toUpperCase());
        BantoraPollStatus status = pollApprovalRequired ? BantoraPollStatus.PENDING : BantoraPollStatus.ACTIVE;

        UUID pollId = UUID.randomUUID();
        BantoraPoll entity = BantoraPoll.builder()
                .id(pollId)
                .title(poll.title())
                .description(poll.description())
                .creatorPhone(creatorPhone)
                .categoryId(poll.categoryId())
                .scope(scope)
                .status(status)
                .startTime(now)
                .endTime(now.plusDays(pollDurationDays))
                .createdAt(now)
                .updatedAt(now)
                .build();

        return pollRepository.save(entity)
                .thenMany(savePollOptions(pollId, poll.options()))
                .then(pollHashtagLinkRepository.linkPollToHashtag(pollId, hashtagId))
                .thenMany(Flux.fromIterable(poll.sourceIdeaIds())
                        .concatMap(ideaId -> pollSourceIdeaLinkRepository.linkPollToIdea(pollId, ideaId)))
                .then(Mono.just(pollId));
    }

    private Flux<BantoraPollOption> savePollOptions(UUID pollId, List<String> options) {
        List<BantoraPollOption> entities = new ArrayList<>();
        int order = 0;
        for (String optionText : options) {
            if (optionText == null || optionText.isBlank()) {
                throw new IllegalArgumentException("AI poll option text must not be blank");
            }
            entities.add(BantoraPollOption.builder()
                    .id(UUID.randomUUID())
                    .pollId(pollId)
                    .optionText(optionText.trim())
                    .optionOrder(order++)
                    .votesCount(0L)
                    .build());
        }
        return pollOptionRepository.saveAll(entities);
    }

    private Mono<Void> updateIdeaStatuses(
            Map<UUID, BantoraIdea> ideaById,
            Set<UUID> usedIdeaIds,
            Set<UUID> rejectedIdeaIds,
            LocalDateTime now
    ) {
        Set<UUID> processed = new HashSet<>(usedIdeaIds);
        Set<UUID> rejected = new HashSet<>(rejectedIdeaIds);

        for (UUID rejectedId : rejected) {
            if (!ideaById.containsKey(rejectedId)) {
                return Mono.error(new IllegalArgumentException("AI rejectedIdeaIds contains unknown id: " + rejectedId));
            }
        }

        List<BantoraIdea> updates = new ArrayList<>();
        for (UUID ideaId : processed) {
            BantoraIdea idea = ideaById.get(ideaId);
            if (idea == null) {
                return Mono.error(new IllegalArgumentException("AI usedIdeaIds contains unknown id: " + ideaId));
            }
            idea.setStatus(BantoraIdeaStatus.CONVERTED_TO_POLL);
            idea.setProcessedAt(now);
            updates.add(idea);
        }
        for (UUID ideaId : rejected) {
            BantoraIdea idea = ideaById.get(ideaId);
            idea.setStatus(BantoraIdeaStatus.REJECTED);
            idea.setProcessedAt(now);
            updates.add(idea);
        }

        return Flux.fromIterable(updates)
                .concatMap(ideaRepository::save)
                .then();
    }

    record AiResponse(List<AiPoll> polls, Set<UUID> rejectedIdeaIds) {
    }

    record AiPoll(
            String title,
            String description,
            UUID categoryId,
            List<String> options,
            List<UUID> sourceIdeaIds
    ) {
        static AiPoll fromJson(JsonNode node) {
            if (node == null || !node.isObject()) {
                throw new IllegalArgumentException("AI poll must be an object");
            }
            String title = Objects.requireNonNull(node.path("title").asText(null), "title");
            String description = node.path("description").asText("");
            UUID categoryId = UUID.fromString(Objects.requireNonNull(node.path("categoryId").asText(null), "categoryId"));

            JsonNode optionsNode = node.path("options");
            if (!optionsNode.isArray()) {
                throw new IllegalArgumentException("AI poll options must be an array");
            }
            List<String> options = new ArrayList<>();
            for (JsonNode opt : optionsNode) {
                options.add(opt.asText());
            }

            JsonNode sourcesNode = node.path("sourceIdeaIds");
            if (!sourcesNode.isArray()) {
                throw new IllegalArgumentException("AI poll sourceIdeaIds must be an array");
            }
            List<UUID> sourceIdeaIds = new ArrayList<>();
            for (JsonNode id : sourcesNode) {
                sourceIdeaIds.add(UUID.fromString(id.asText()));
            }

            return new AiPoll(title, description, categoryId, options, sourceIdeaIds);
        }
    }
}
