package com.t3ratech.bantora.job;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.t3ratech.bantora.persistence.entity.BantoraIdea;
import com.t3ratech.bantora.persistence.repository.IdeaRepository;
import com.t3ratech.bantora.service.AiService;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@ExtendWith(MockitoExtension.class)
class IdeaProcessingJobTest {

    @Mock
    private IdeaRepository ideaRepository;

    @Mock
    private AiService aiService;

    @InjectMocks
    private IdeaProcessingJob ideaProcessingJob;

    @Test
    void processPendingIdeas_ShouldProcessAllPendingIdeas() {
        BantoraIdea idea1 = BantoraIdea.builder().id(java.util.UUID.randomUUID()).status(BantoraIdea.IdeaStatus.PENDING).build();
        BantoraIdea idea2 = BantoraIdea.builder().id(java.util.UUID.randomUUID()).status(BantoraIdea.IdeaStatus.PENDING).build();

        when(ideaRepository.findByStatus(BantoraIdea.IdeaStatus.PENDING)).thenReturn(Flux.just(idea1, idea2));
        when(aiService.processIdea(idea1)).thenReturn(Mono.empty());
        when(aiService.processIdea(idea2)).thenReturn(Mono.empty());

        // We need to access the private method or trigger it via scheduled/event
        // Since we can't easily call private methods, we might need to change
        // visibility or test via public entry points
        // But the public entry points are void.
        // Let's assume we can call the public methods.

        ideaProcessingJob.onStartup();

        verify(ideaRepository).findByStatus(BantoraIdea.IdeaStatus.PENDING);
        verify(aiService).processIdea(idea1);
        verify(aiService).processIdea(idea2);
    }
}
