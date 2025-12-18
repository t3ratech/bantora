package com.t3ratech.bantora.service;

import com.fasterxml.jackson.databind.ObjectMapper;
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
    private com.t3ratech.bantora.repository.BantoraHashtagStatsReadRepository hashtagStatsReadRepository;
    @Mock
    private com.t3ratech.bantora.repository.BantoraHashtagRepository hashtagRepository;
    @Mock
    private com.t3ratech.bantora.repository.BantoraIdeaReadRepository ideaReadRepository;
    @Mock
    private com.t3ratech.bantora.repository.BantoraIdeaRepository ideaRepository;
    @Mock
    private com.t3ratech.bantora.repository.BantoraPollRepository pollRepository;
    @Mock
    private com.t3ratech.bantora.repository.BantoraPollOptionRepository pollOptionRepository;
    @Mock
    private com.t3ratech.bantora.repository.BantoraPollHashtagLinkRepository pollHashtagLinkRepository;
    @Mock
    private com.t3ratech.bantora.repository.BantoraPollSourceIdeaLinkRepository pollSourceIdeaLinkRepository;
    @Mock
    private org.springframework.transaction.reactive.TransactionalOperator transactionalOperator;

    @Spy
    private ObjectMapper objectMapper = new ObjectMapper();

    @InjectMocks
    private AiService aiService;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(aiService, "geminiApiKey", "test-key");
        ReflectionTestUtils.setField(aiService, "geminiUrl", "http://test-url");
    }

    @Test
    void parseAiResponse_shouldParsePollsAndRejectedIdeas() {
        String aiJson = "{" +
                "\"polls\":[{" +
                "\"title\":\"T\"," +
                "\"description\":\"D\"," +
                "\"categoryId\":\"00000000-0000-0000-0000-000000000001\"," +
                "\"options\":[\"Yes\",\"No\"]," +
                "\"sourceIdeaIds\":[\"00000000-0000-0000-0000-0000000000aa\"]" +
                "}]," +
                "\"rejectedIdeaIds\":[\"00000000-0000-0000-0000-0000000000bb\"]" +
                "}";

        StepVerifier.create(Mono.fromCallable(() -> aiService.parseAiResponse(aiJson)))
                .expectNextMatches(resp -> resp.polls().size() == 1 && resp.rejectedIdeaIds().size() == 1)
                .verifyComplete();
    }
}
