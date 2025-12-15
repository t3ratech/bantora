package com.t3ratech.bantora.service;

import com.t3ratech.bantora.dto.response.BantoraIdeaResponse;
import com.t3ratech.bantora.entity.BantoraIdea;
import com.t3ratech.bantora.enums.BantoraIdeaStatus;
import com.t3ratech.bantora.repository.BantoraIdeaRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

import java.time.LocalDateTime;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.assertj.core.api.Assertions.assertThat;

@ExtendWith(MockitoExtension.class)
class BantoraIdeaServiceTest {

    @Mock
    private BantoraIdeaRepository ideaRepository;

    @InjectMocks
    private BantoraIdeaService ideaService;

    private BantoraIdea testIdea;

    @BeforeEach
    void setUp() {
        testIdea = BantoraIdea.builder()
                .id(UUID.randomUUID())
                .userPhone("+263785107830")
                .content("Test idea content for irrigation systems")
                .status(BantoraIdeaStatus.PENDING)
                .aiSummary(null)
                .createdAt(LocalDateTime.now())
                .upvotes(5L)
                .build();
    }

    @Test
    void getPendingIdeas_shouldReturnPendingIdeas() {
        when(ideaRepository.findByStatusOrderByCreatedAtDesc(BantoraIdeaStatus.PENDING))
                .thenReturn(Flux.just(testIdea));

        Flux<BantoraIdeaResponse> result = ideaService.getPendingIdeas();

        StepVerifier.create(result)
                .assertNext(response -> {
                    assertThat(response.getContent()).contains("irrigation");
                    assertThat(response.getStatus()).isEqualTo(BantoraIdeaStatus.PENDING);
                    assertThat(response.getUpvotes()).isEqualTo(5L);
                })
                .verifyComplete();
    }

    @Test
    void getProcessedIdeas_shouldReturnProcessedIdeas() {
        BantoraIdea processedIdea = BantoraIdea.builder()
                .id(UUID.randomUUID())
                .userPhone("+263785107830")
                .content("Processed idea")
                .status(BantoraIdeaStatus.PROCESSED)
                .aiSummary("AI generated summary")
                .createdAt(LocalDateTime.now())
                .upvotes(10L)
                .build();

        when(ideaRepository.findByStatusOrderByCreatedAtDesc(BantoraIdeaStatus.PROCESSED))
                .thenReturn(Flux.just(processedIdea));

        Flux<BantoraIdeaResponse> result = ideaService.getProcessedIdeas();

        StepVerifier.create(result)
                .assertNext(response -> {
                    assertThat(response.getStatus()).isEqualTo(BantoraIdeaStatus.PROCESSED);
                    assertThat(response.getAiSummary()).isEqualTo("AI generated summary");
                })
                .verifyComplete();
    }

    @Test
    void createIdea_shouldSaveAndReturnIdea() {
        String userPhone = "+263785107830";
        String content = "New irrigation idea";

        when(ideaRepository.save(any(BantoraIdea.class)))
                .thenReturn(Mono.just(testIdea));

        Mono<BantoraIdeaResponse> result = ideaService.createIdea(userPhone, content);

        StepVerifier.create(result)
                .assertNext(response -> {
                    assertThat(response.getUserPhone()).isEqualTo(userPhone);
                    assertThat(response.getStatus()).isEqualTo(BantoraIdeaStatus.PENDING);
                    assertThat(response.getUpvotes()).isEqualTo(5L);
                })
                .verifyComplete();
    }
}
