package com.t3ratech.bantora.service;

import com.t3ratech.bantora.dto.response.BantoraIdeaResponse;
import com.t3ratech.bantora.entity.BantoraIdea;
import com.t3ratech.bantora.enums.BantoraIdeaStatus;
import com.t3ratech.bantora.repository.BantoraIdeaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class BantoraIdeaService {

    private final BantoraIdeaRepository ideaRepository;

    @Transactional(readOnly = true)
    public List<BantoraIdeaResponse> getPendingIdeas() {
        List<BantoraIdea> ideas = ideaRepository.findByStatusOrderByCreatedAtDesc(BantoraIdeaStatus.PENDING);
        return ideas.stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<BantoraIdeaResponse> getProcessedIdeas() {
        List<BantoraIdea> ideas = ideaRepository.findByStatusOrderByCreatedAtDesc(BantoraIdeaStatus.PROCESSED);
        return ideas.stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public BantoraIdeaResponse createIdea(String userPhone, String content) {
        BantoraIdea idea = BantoraIdea.builder()
                .userPhone(userPhone)
                .content(content)
                .status(BantoraIdeaStatus.PENDING)
                .createdAt(LocalDateTime.now())
                .upvotes(0L)
                .build();

        BantoraIdea saved = ideaRepository.save(idea);
        return toResponse(saved);
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
