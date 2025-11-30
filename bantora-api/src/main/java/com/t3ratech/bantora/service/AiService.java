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
import com.t3ratech.bantora.persistence.entity.Idea;
import com.t3ratech.bantora.persistence.entity.Poll;
import com.t3ratech.bantora.persistence.entity.PollScope;
import com.t3ratech.bantora.persistence.entity.PollStatus;
import com.t3ratech.bantora.persistence.repository.IdeaRepository;
import com.t3ratech.bantora.persistence.repository.PollRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.time.Instant;
import java.time.temporal.ChronoUnit;

@Service
@RequiredArgsConstructor
@Slf4j
public class AiService {

    private final WebClient.Builder webClientBuilder;
    private final IdeaRepository ideaRepository;
    private final PollRepository pollRepository;
    private final ObjectMapper objectMapper;

    @Value("${bantora.ai.gemini.api-key}")
    private String geminiApiKey;

    @Value("${bantora.ai.gemini.url}")
    private String geminiUrl;

    public Mono<Void> processIdea(Idea idea) {
        return summarizeIdea(idea.getContent())
                .flatMap(summary -> createPollFromSummary(idea, summary))
                .flatMap(poll -> {
                    idea.setStatus(Idea.IdeaStatus.PROCESSED);
                    idea.setProcessedAt(Instant.now());
                    return ideaRepository.save(idea);
                })
                .then();
    }

    private Mono<String> summarizeIdea(String content) {
        String prompt = "Summarize the following idea into a concise poll title and description. Return JSON format: {\"title\": \"...\", \"description\": \"...\"}. Idea: "
                + content;

        String requestBody = "{\"contents\": [{\"parts\": [{\"text\": \"" + prompt.replace("\"", "\\\"") + "\"}]}]}";

        return webClientBuilder.build()
                .post()
                .uri(geminiUrl + "?key=" + geminiApiKey)
                .header("Content-Type", "application/json")
                .bodyValue(requestBody)
                .retrieve()
                .bodyToMono(String.class)
                .map(this::extractSummaryFromResponse)
                .onErrorResume(e -> {
                    log.error("Error calling Gemini API", e);
                    return Mono.just(
                            "{\"title\": \"Error Processing Idea\", \"description\": \"Could not summarize idea.\"}");
                });
    }

    private String extractSummaryFromResponse(String response) {
        try {
            JsonNode root = objectMapper.readTree(response);
            String text = root.path("candidates").get(0).path("content").path("parts").get(0).path("text").asText();
            // Clean up markdown code blocks if present
            if (text.startsWith("```json")) {
                text = text.substring(7);
            }
            if (text.startsWith("```")) {
                text = text.substring(3);
            }
            if (text.endsWith("```")) {
                text = text.substring(0, text.length() - 3);
            }
            return text.trim();
        } catch (Exception e) {
            log.error("Error parsing Gemini response", e);
            return "{\"title\": \"Error Parsing\", \"description\": \"Error parsing AI response.\"}";
        }
    }

    private Mono<Poll> createPollFromSummary(Idea idea, String summaryJson) {
        try {
            JsonNode node = objectMapper.readTree(summaryJson);
            String title = node.path("title").asText("Untitled Poll");
            String description = node.path("description").asText("No description available.");

            Poll poll = Poll.builder()
                    .title(title)
                    .description(description)
                    .creatorPhone(idea.getUserPhone())
                    .ideaId(idea.getId())
                    .scope(PollScope.NATIONAL) // Default scope, AI could determine this too
                    .status(PollStatus.ACTIVE) // Auto-activate for now
                    .startTime(Instant.now())
                    .endTime(Instant.now().plus(7, ChronoUnit.DAYS))
                    .build();

            return pollRepository.save(poll);
        } catch (Exception e) {
            log.error("Error creating poll from summary", e);
            return Mono.empty();
        }
    }
}
