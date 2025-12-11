package com.t3ratech.bantora.service;

import com.t3ratech.bantora.dto.response.BantoraIdeaResponse;
import com.t3ratech.bantora.entity.BantoraIdea;
import com.t3ratech.bantora.enums.BantoraIdeaStatus;
import com.t3ratech.bantora.repository.BantoraIdeaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class BantoraIdeaService {

    private final BantoraIdeaRepository ideaRepository;

    public Flux<BantoraIdeaResponse> getPendingIdeas() {
        return ideaRepository.findByStatusOrderByCreatedAtDesc(BantoraIdeaStatus.PENDING)
                .map(this::toResponse);
    }

    public Flux<BantoraIdeaResponse> getProcessedIdeas() {
        return ideaRepository.findByStatusOrderByCreatedAtDesc(BantoraIdeaStatus.PROCESSED)
                .map(this::toResponse);
    }

    public Mono<BantoraIdeaResponse> createIdea(String userPhone, String content) {
        BantoraIdea idea = BantoraIdea.builder()
                .id(UUID.randomUUID())
                .userPhone(userPhone)
                .content(content)
                .status(BantoraIdeaStatus.PENDING)
                .createdAt(LocalDateTime.now())
                .upvotes(0L)
                .build();

        return ideaRepository.save(idea)
                .map(this::toResponse);
    }

    private BantoraIdeaResponse toResponse(BantoraIdea idea) {
        return BantoraIdeaResponse.builder()
                .id(idea.getId())
                .userPhone(idea.getUserPhone())
                .content(idea.getContent())
                .status(idea.getStatus())
                .aiSummary(idea.getAiSummary())
                .createdAt(idea.getCreatedAt())
                .upvotes(idea.getUpvotes())
                .build();
    }
}
