package com.t3ratech.bantora.service;

import com.t3ratech.bantora.dto.request.BantoraCreateIdeaRequest;
import com.t3ratech.bantora.dto.response.BantoraIdeaResponse;
import com.t3ratech.bantora.entity.BantoraHashtag;
import com.t3ratech.bantora.entity.BantoraIdea;
import com.t3ratech.bantora.enums.BantoraIdeaStatus;
import com.t3ratech.bantora.repository.BantoraCategoryRepository;
import com.t3ratech.bantora.repository.BantoraHashtagRepository;
import com.t3ratech.bantora.repository.BantoraIdeaRepository;
import com.t3ratech.bantora.repository.BantoraIdeaHashtagLinkRepository;
import com.t3ratech.bantora.repository.BantoraIdeaHashtagReadRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.data.r2dbc.core.R2dbcEntityTemplate;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Service;
import org.springframework.transaction.reactive.TransactionalOperator;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class BantoraIdeaService {

    private static final int MAX_HASHTAG_LENGTH = 64;

    private final BantoraIdeaRepository ideaRepository;
    private final BantoraCategoryRepository categoryRepository;
    private final BantoraHashtagRepository hashtagRepository;
    private final BantoraIdeaHashtagLinkRepository ideaHashtagLinkRepository;
    private final BantoraIdeaHashtagReadRepository ideaHashtagReadRepository;
    private final R2dbcEntityTemplate entityTemplate;
    private final TransactionalOperator transactionalOperator;

    public Flux<BantoraIdeaResponse> getPendingIdeas() {
        return ideaRepository.findByStatusOrderByCreatedAtDesc(BantoraIdeaStatus.PENDING)
                .flatMap(idea -> ideaHashtagReadRepository.findTagsByIdeaId(idea.getId())
                        .collectList()
                        .map(tags -> toResponse(idea, tags)));
    }

    public Flux<BantoraIdeaResponse> getProcessedIdeas() {
        return ideaRepository.findByStatusOrderByCreatedAtDesc(BantoraIdeaStatus.PROCESSED)
                .flatMap(idea -> ideaHashtagReadRepository.findTagsByIdeaId(idea.getId())
                        .collectList()
                        .map(tags -> toResponse(idea, tags)));
    }

    public Flux<BantoraIdeaResponse> getIdeas(String status, UUID categoryId, String hashtag) {
        BantoraIdeaStatus resolvedStatus;
        try {
            resolvedStatus = BantoraIdeaStatus.valueOf(Objects.requireNonNull(status, "status").trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return Flux.error(new IllegalArgumentException("Invalid status"));
        }

        String normalizedTag = normalizeSingleHashtag(hashtag);

        Flux<BantoraIdea> ideas;
        if (categoryId != null && normalizedTag != null) {
            ideas = ideaRepository.findByStatusAndCategoryIdAndHashtagOrderByCreatedAtDesc(
                    resolvedStatus.name(),
                    categoryId,
                    normalizedTag
            );
        } else if (categoryId != null) {
            ideas = ideaRepository.findByStatusAndCategoryIdOrderByCreatedAtDesc(resolvedStatus, categoryId);
        } else if (normalizedTag != null) {
            ideas = ideaRepository.findByStatusAndHashtagOrderByCreatedAtDesc(resolvedStatus.name(), normalizedTag);
        } else {
            ideas = ideaRepository.findByStatusOrderByCreatedAtDesc(resolvedStatus);
        }

        return ideas.flatMap(idea -> ideaHashtagReadRepository.findTagsByIdeaId(idea.getId())
                .collectList()
                .map(tags -> toResponse(idea, tags)));
    }

    public Mono<BantoraIdeaResponse> getIdeaById(UUID ideaId) {
        return ideaRepository.findById(Objects.requireNonNull(ideaId, "ideaId"))
                .flatMap(idea -> ideaHashtagReadRepository.findTagsByIdeaId(idea.getId())
                        .collectList()
                        .map(tags -> toResponse(idea, tags)));
    }

    public Mono<BantoraIdeaResponse> createIdea(String userPhone, BantoraCreateIdeaRequest request) {
        if (request == null) {
            return Mono.error(new IllegalArgumentException("Missing request body"));
        }

        String content = request.getContent();
        UUID categoryId = request.getCategoryId();
        List<String> hashtags = normalizeHashtags(request.getHashtags());

        if (content == null || content.isBlank()) {
            return Mono.error(new IllegalArgumentException("Missing required field: content"));
        }

        if (categoryId == null) {
            return Mono.error(new IllegalArgumentException("Missing required field: categoryId"));
        }

        if (hashtags.isEmpty()) {
            return Mono.error(new IllegalArgumentException("Missing required field: hashtags"));
        }

        Mono<Void> requireValidCategory = categoryRepository.findById(categoryId)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("Invalid categoryId")))
                .then();

        UUID ideaId = UUID.randomUUID();
        BantoraIdea idea = BantoraIdea.builder()
                .id(ideaId)
                .userPhone(userPhone)
                .content(content)
                .categoryId(categoryId)
                .status(BantoraIdeaStatus.PENDING)
                .createdAt(LocalDateTime.now())
                .upvotes(0L)
                .build();

        Mono<BantoraIdeaResponse> tx = requireValidCategory
                .then(entityTemplate.insert(idea))
                .flatMap(savedIdea -> Flux.fromIterable(hashtags)
                        .flatMap(this::getOrCreateHashtag)
                        .flatMap(hashtag -> ideaHashtagLinkRepository.linkIdeaToHashtag(
                                savedIdea.getId(),
                                Objects.requireNonNull(hashtag.getId(), "hashtag.id")
                        ))
                        .then(ideaHashtagReadRepository.findTagsByIdeaId(savedIdea.getId()).collectList())
                        .map(tags -> toResponse(savedIdea, tags)));

        return transactionalOperator.transactional(tx);
    }

    public Mono<BantoraIdeaResponse> upvoteIdea(UUID ideaId) {
        return ideaRepository.findById(Objects.requireNonNull(ideaId, "ideaId"))
                .switchIfEmpty(Mono.error(new IllegalArgumentException("Idea not found")))
                .flatMap(idea -> {
                    long currentUpvotes = idea.getUpvotes() == null ? 0L : idea.getUpvotes();
                    idea.setUpvotes(currentUpvotes + 1L);
                    return ideaRepository.save(idea);
                })
                .flatMap(updated -> ideaHashtagReadRepository.findTagsByIdeaId(updated.getId())
                        .collectList()
                        .map(tags -> toResponse(updated, tags)));
    }

    private BantoraIdeaResponse toResponse(BantoraIdea idea, List<String> hashtags) {
        return BantoraIdeaResponse.builder()
                .id(Objects.requireNonNull(idea.getId(), "idea.id"))
                .userPhone(idea.getUserPhone())
                .content(idea.getContent())
                .categoryId(Objects.requireNonNull(idea.getCategoryId(), "idea.categoryId"))
                .hashtags(hashtags)
                .status(idea.getStatus())
                .aiSummary(idea.getAiSummary())
                .createdAt(idea.getCreatedAt())
                .upvotes(idea.getUpvotes())
                .build();
    }

    private List<String> normalizeHashtags(List<String> hashtags) {
        if (hashtags == null || hashtags.isEmpty()) {
            return List.of();
        }

        LinkedHashSet<String> normalized = new LinkedHashSet<>();
        for (String raw : hashtags) {
            if (raw == null) {
                continue;
            }
            String tag = raw.trim();
            if (tag.startsWith("#")) {
                tag = tag.substring(1);
            }
            tag = tag.trim().toLowerCase();
            if (tag.isBlank()) {
                continue;
            }
            if (tag.length() > MAX_HASHTAG_LENGTH) {
                throw new IllegalArgumentException("Hashtag too long (max " + MAX_HASHTAG_LENGTH + ")");
            }
            normalized.add(tag);
        }
        return new ArrayList<>(normalized);
    }

    private String normalizeSingleHashtag(String hashtag) {
        if (hashtag == null) {
            return null;
        }
        String tag = hashtag.trim();
        if (tag.isEmpty()) {
            return null;
        }
        if (tag.startsWith("#")) {
            tag = tag.substring(1);
        }
        tag = tag.trim().toLowerCase();
        if (tag.isBlank()) {
            return null;
        }
        if (tag.length() > MAX_HASHTAG_LENGTH) {
            throw new IllegalArgumentException("Hashtag too long (max " + MAX_HASHTAG_LENGTH + ")");
        }
        return tag;
    }

    @NonNull
    private Mono<BantoraHashtag> getOrCreateHashtag(@NonNull String tag) {
        final BantoraHashtag newHashtag = Objects.requireNonNull(
                BantoraHashtag.builder()
                        .tag(tag)
                        .createdAt(LocalDateTime.now())
                        .build(),
                "newHashtag"
        );

        return hashtagRepository.findByTag(tag)
                .switchIfEmpty(hashtagRepository.save(newHashtag)
                        .flatMap(saved -> {
                            if (saved != null && saved.getId() != null) {
                                return Mono.just(saved);
                            }
                            return hashtagRepository.findByTag(tag);
                        })
                        .onErrorResume(DuplicateKeyException.class, e -> hashtagRepository.findByTag(tag))
                        .onErrorResume(e -> {
                            String msg = e.getMessage();
                            if (msg != null && msg.toLowerCase().contains("duplicate")) {
                                return hashtagRepository.findByTag(tag);
                            }
                            return Mono.error(e);
                        }))
                .map(hashtag -> Objects.requireNonNull(hashtag, "hashtag"))
                .flatMap(hashtag -> {
                    if (hashtag.getId() == null) {
                        return Mono.error(new IllegalStateException("Resolved hashtag has null id: " + tag));
                    }
                    return Mono.just(hashtag);
                })
                .switchIfEmpty(Mono.error(new IllegalStateException("Failed to resolve hashtag: " + tag)));
    }
}
