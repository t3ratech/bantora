package com.t3ratech.bantora.service;

import com.t3ratech.bantora.dto.response.BantoraIdeaResponse;
import com.t3ratech.bantora.entity.BantoraIdea;
import com.t3ratech.bantora.enums.BantoraIdeaStatus;
import com.t3ratech.bantora.repository.BantoraIdeaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.r2dbc.core.R2dbcEntityTemplate;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class BantoraIdeaService {

    private final BantoraIdeaRepository ideaRepository;
    private final R2dbcEntityTemplate entityTemplate;

    public Flux<BantoraIdeaResponse> getPendingIdeas() {
        return ideaRepository.findByStatusOrderByCreatedAtDesc(BantoraIdeaStatus.PENDING)
                .map(this::toResponse);
    }

    public Flux<BantoraIdeaResponse> getProcessedIdeas() {
        return ideaRepository.findByStatusOrderByCreatedAtDesc(BantoraIdeaStatus.PROCESSED)
                .map(this::toResponse);
    }

    public Mono<BantoraIdeaResponse> createIdea(String userPhone, String content) {
        UUID ideaId = UUID.randomUUID();
        BantoraIdea idea = BantoraIdea.builder()
                .id(ideaId)
                .userPhone(userPhone)
                .content(content)
                .status(BantoraIdeaStatus.PENDING)
                .createdAt(LocalDateTime.now())
                .upvotes(0L)
                .build();

        // Use insert() to explicitly INSERT (not UPDATE)
        // R2DBC's insert() should work for new entities
        return entityTemplate.insert(idea)
                .map(this::toResponse)
                .onErrorResume(e -> {
                    // If insert fails with "trying to update" error, the entity might already exist
                    // Check if it exists first, then update if needed, otherwise insert
                    if (e.getMessage() != null && e.getMessage().contains("Failed to update")) {
                        log.warn("Insert attempted update, checking if entity exists: {}", e.getMessage());
                        return ideaRepository.findById(ideaId)
                                .flatMap(existing -> {
                                    // Entity exists, update it
                                    log.info("Entity exists, updating: {}", ideaId);
                                    return ideaRepository.save(idea);
                                })
                                .switchIfEmpty(
                                        // Entity doesn't exist, try save which should insert
                                        ideaRepository.save(idea)
                                )
                                .map(this::toResponse);
                    }
                    // Other errors, just propagate
                    return Mono.error(e);
                });
    }

    public Mono<BantoraIdeaResponse> upvoteIdea(UUID ideaId) {
        return ideaRepository.findById(Objects.requireNonNull(ideaId, "ideaId"))
                .switchIfEmpty(Mono.error(new IllegalArgumentException("Idea not found")))
                .flatMap(idea -> {
                    long currentUpvotes = idea.getUpvotes() == null ? 0L : idea.getUpvotes();
                    idea.setUpvotes(currentUpvotes + 1L);
                    return ideaRepository.save(idea);
                })
                .map(this::toResponse);
    }

    private BantoraIdeaResponse toResponse(BantoraIdea idea) {
        return BantoraIdeaResponse.builder()
                .id(Objects.requireNonNull(idea.getId(), "idea.id"))
                .userPhone(idea.getUserPhone())
                .content(idea.getContent())
                .status(idea.getStatus())
                .aiSummary(idea.getAiSummary())
                .createdAt(idea.getCreatedAt())
                .upvotes(idea.getUpvotes())
                .build();
    }
}
