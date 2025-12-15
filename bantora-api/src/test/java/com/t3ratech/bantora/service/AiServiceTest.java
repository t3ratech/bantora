package com.t3ratech.bantora.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.t3ratech.bantora.persistence.entity.BantoraIdea;
import com.t3ratech.bantora.persistence.entity.BantoraPoll;
import com.t3ratech.bantora.persistence.repository.IdeaRepository;
import com.t3ratech.bantora.persistence.repository.PollRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AiServiceTest {

    @Mock
    private WebClient.Builder webClientBuilder;
    @Mock
    private WebClient webClient;
    @Mock
    private WebClient.RequestBodyUriSpec requestBodyUriSpec;
    @Mock
    private WebClient.RequestBodySpec requestBodySpec;
    @Mock
    private WebClient.RequestHeadersSpec requestHeadersSpec;
    @Mock
    private WebClient.ResponseSpec responseSpec;

    @Mock
    private IdeaRepository ideaRepository;
    @Mock
    private PollRepository pollRepository;

    @Spy
    private ObjectMapper objectMapper = new ObjectMapper();

    @InjectMocks
    private AiService aiService;

    private BantoraIdea testIdea;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(aiService, "geminiApiKey", "test-key");
        ReflectionTestUtils.setField(aiService, "geminiUrl", "http://test-url");

        testIdea = new BantoraIdea();
        testIdea.setId(UUID.randomUUID());
        testIdea.setContent("Test Idea Content");
        testIdea.setStatus(BantoraIdea.IdeaStatus.PENDING);
    }

    @Test
    void processIdea_shouldSuccessfullyCreatePoll() {
        // Mock WebClient
        when(webClientBuilder.build()).thenReturn(webClient);
        when(webClient.post()).thenReturn(requestBodyUriSpec);
        when(requestBodyUriSpec.uri(anyString())).thenReturn(requestBodySpec);
        when(requestBodySpec.header(anyString(), anyString())).thenReturn(requestBodySpec);
        when(requestBodySpec.bodyValue(anyString())).thenReturn(requestHeadersSpec);
        when(requestHeadersSpec.retrieve()).thenReturn(responseSpec);

        // Mock Gemini Response
        String geminiResponse = "{\"candidates\": [{\"content\": {\"parts\": [{\"text\": \"{\\\"title\\\": \\\"AI Generated Poll\\\", \\\"description\\\": \\\"Generated Description\\\"}\"}]}}]}";
        when(responseSpec.bodyToMono(String.class)).thenReturn(Mono.just(geminiResponse));

        // Mock Repositories
        when(ideaRepository.save(any(BantoraIdea.class))).thenAnswer(i -> Mono.just(i.getArgument(0)));
        when(pollRepository.save(any(BantoraPoll.class))).thenAnswer(i -> Mono.just(i.getArgument(0)));

        // Run Test
        StepVerifier.create(aiService.processIdea(testIdea))
                .verifyComplete();

        // Verify Interactions
        verify(ideaRepository).save(argThat(idea -> idea.getStatus() == BantoraIdea.IdeaStatus.PROCESSED &&
                idea.getProcessedAt() != null));

        verify(pollRepository).save(argThat(poll -> poll.getTitle().equals("AI Generated Poll") &&
                poll.getDescription().equals("Generated Description")));
    }
}
