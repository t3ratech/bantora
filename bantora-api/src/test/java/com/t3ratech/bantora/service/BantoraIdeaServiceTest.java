package com.t3ratech.bantora.service;

import com.t3ratech.bantora.dto.request.BantoraCreateIdeaRequest;
import com.t3ratech.bantora.dto.response.BantoraIdeaResponse;
import com.t3ratech.bantora.entity.BantoraCategory;
import com.t3ratech.bantora.entity.BantoraHashtag;
import com.t3ratech.bantora.entity.BantoraIdea;
import com.t3ratech.bantora.enums.BantoraIdeaStatus;
import com.t3ratech.bantora.repository.BantoraCategoryRepository;
import com.t3ratech.bantora.repository.BantoraHashtagRepository;
import com.t3ratech.bantora.repository.BantoraIdeaRepository;
import com.t3ratech.bantora.repository.BantoraIdeaHashtagLinkRepository;
import com.t3ratech.bantora.repository.BantoraIdeaHashtagReadRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.ArgumentMatchers;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.r2dbc.core.R2dbcEntityTemplate;
import org.springframework.transaction.reactive.TransactionalOperator;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.assertj.core.api.Assertions.assertThat;

@ExtendWith(MockitoExtension.class)
class BantoraIdeaServiceTest {

    @Mock
    private BantoraIdeaRepository ideaRepository;

    @Mock
    private BantoraCategoryRepository categoryRepository;

    @Mock
    private BantoraHashtagRepository hashtagRepository;

    @Mock
    private BantoraIdeaHashtagLinkRepository ideaHashtagLinkRepository;

    @Mock
    private BantoraIdeaHashtagReadRepository ideaHashtagReadRepository;

    @Mock
    private R2dbcEntityTemplate entityTemplate;

    @Mock
    private TransactionalOperator transactionalOperator;

    @InjectMocks
    private BantoraIdeaService ideaService;

    private BantoraIdea testIdea;
    private UUID testCategoryId;

    @BeforeEach
    void setUp() {
        testCategoryId = UUID.randomUUID();
        testIdea = BantoraIdea.builder()
                .id(UUID.randomUUID())
                .userPhone("+263785107830")
                .content("Test idea content for irrigation systems")
                .categoryId(testCategoryId)
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
        when(ideaHashtagReadRepository.findTagsByIdeaId(any(UUID.class)))
                .thenReturn(Flux.just("water", "agriculture"));

        Flux<BantoraIdeaResponse> result = ideaService.getPendingIdeas();

        StepVerifier.create(result)
                .assertNext(response -> {
                    assertThat(response.getContent()).contains("irrigation");
                    assertThat(response.getStatus()).isEqualTo(BantoraIdeaStatus.PENDING);
                    assertThat(response.getUpvotes()).isEqualTo(5L);
                    assertThat(response.getCategoryId()).isEqualTo(testCategoryId);
                    assertThat(response.getHashtags()).contains("water", "agriculture");
                })
                .verifyComplete();
    }

    @Test
    void getProcessedIdeas_shouldReturnProcessedIdeas() {
        BantoraIdea processedIdea = BantoraIdea.builder()
                .id(UUID.randomUUID())
                .userPhone("+263785107830")
                .content("Processed idea")
                .categoryId(testCategoryId)
                .status(BantoraIdeaStatus.PROCESSED)
                .aiSummary("AI generated summary")
                .createdAt(LocalDateTime.now())
                .upvotes(10L)
                .build();

        when(ideaRepository.findByStatusOrderByCreatedAtDesc(BantoraIdeaStatus.PROCESSED))
                .thenReturn(Flux.just(processedIdea));
        when(ideaHashtagReadRepository.findTagsByIdeaId(any(UUID.class)))
                .thenReturn(Flux.just("energy"));

        Flux<BantoraIdeaResponse> result = ideaService.getProcessedIdeas();

        StepVerifier.create(result)
                .assertNext(response -> {
                    assertThat(response.getStatus()).isEqualTo(BantoraIdeaStatus.PROCESSED);
                    assertThat(response.getAiSummary()).isEqualTo("AI generated summary");
                    assertThat(response.getHashtags()).contains("energy");
                })
                .verifyComplete();
    }

    @Test
    void createIdea_shouldSaveAndReturnIdea() {
        String userPhone = "+263785107830";
        String content = "New irrigation idea";
        BantoraCreateIdeaRequest req = BantoraCreateIdeaRequest.builder()
                .content(content)
                .categoryId(testCategoryId)
                .hashtags(List.of("Water"))
                .build();

        when(transactionalOperator.transactional(ArgumentMatchers.<Mono<BantoraIdeaResponse>>any()))
                .thenAnswer(invocation -> invocation.getArgument(0));

        when(categoryRepository.findById(testCategoryId))
                .thenReturn(Mono.just(BantoraCategory.builder().id(testCategoryId).name("Economy").build()));
        when(entityTemplate.insert(ArgumentMatchers.<BantoraIdea>any()))
                .thenReturn(Mono.just(testIdea));
        when(hashtagRepository.findByTag("water"))
                .thenReturn(Mono.empty());
        when(hashtagRepository.save(ArgumentMatchers.<BantoraHashtag>any()))
                .thenReturn(Mono.just(BantoraHashtag.builder().id(UUID.randomUUID()).tag("water").build()));
        when(ideaHashtagLinkRepository.linkIdeaToHashtag(ArgumentMatchers.<UUID>any(), ArgumentMatchers.<UUID>any()))
                .thenReturn(Mono.empty());
        when(ideaHashtagReadRepository.findTagsByIdeaId(ArgumentMatchers.<UUID>any()))
                .thenReturn(Flux.just("water"));

        Mono<BantoraIdeaResponse> result = ideaService.createIdea(userPhone, req);

        StepVerifier.create(result)
                .assertNext(response -> {
                    assertThat(response.getUserPhone()).isEqualTo(userPhone);
                    assertThat(response.getStatus()).isEqualTo(BantoraIdeaStatus.PENDING);
                    assertThat(response.getUpvotes()).isEqualTo(5L);
                    assertThat(response.getCategoryId()).isEqualTo(testCategoryId);
                    assertThat(response.getHashtags()).contains("water");
                })
                .verifyComplete();
    }
}
