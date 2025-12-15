package com.t3ratech.bantora.service;

import com.t3ratech.bantora.dto.response.BantoraPollResponse;
import com.t3ratech.bantora.entity.BantoraPoll;
import com.t3ratech.bantora.entity.BantoraPollOption;
import com.t3ratech.bantora.enums.BantoraPollScope;
import com.t3ratech.bantora.enums.BantoraPollStatus;
import com.t3ratech.bantora.repository.BantoraPollOptionRepository;
import com.t3ratech.bantora.repository.BantoraPollRepository;
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
class BantoraPollServiceTest {

    @Mock
    private BantoraPollRepository pollRepository;

    @Mock
    private BantoraPollOptionRepository optionRepository;

    @InjectMocks
    private BantoraPollService pollService;

    private BantoraPoll testPoll;
    private BantoraPollOption option1;
    private BantoraPollOption option2;

    @BeforeEach
    void setUp() {
        UUID pollId = UUID.randomUUID();

        testPoll = BantoraPoll.builder()
                .id(pollId)
                .title("Test Poll")
                .description("Test Description")
                .creatorPhone("+263785107830")
                .category("Test")
                .scope(BantoraPollScope.CONTINENTAL)
                .status(BantoraPollStatus.ACTIVE)
                .startTime(LocalDateTime.now().minusDays(1))
                .endTime(LocalDateTime.now().plusDays(1))
                .totalVotes(100L)
                .createdAt(LocalDateTime.now())
                .build();

        option1 = BantoraPollOption.builder()
                .id(UUID.randomUUID())
                .pollId(pollId)
                .optionText("Yes")
                .optionOrder(1)
                .votesCount(60L)
                .build();

        option2 = BantoraPollOption.builder()
                .id(UUID.randomUUID())
                .pollId(pollId)
                .optionText("No")
                .optionOrder(2)
                .votesCount(40L)
                .build();
    }

    @Test
    void getAllActivePolls_shouldReturnActivePolls() {
        when(pollRepository.findActiveOrderByCreatedDesc(any(LocalDateTime.class)))
                .thenReturn(Flux.just(testPoll));
        when(optionRepository.findByPollIdOrderByOptionOrder(testPoll.getId()))
                .thenReturn(Flux.just(option1, option2));

        Flux<BantoraPollResponse> result = pollService.getAllActivePolls();

        StepVerifier.create(result)
                .assertNext(response -> {
                    assertThat(response.getTitle()).isEqualTo("Test Poll");
                    assertThat(response.getOptions()).hasSize(2);
                    assertThat(response.getTotalVotes()).isEqualTo(100L);
                })
                .verifyComplete();
    }

    @Test
    void getPopularPolls_shouldReturnTopPolls() {
        when(pollRepository.findActiveOrderByVotesDesc(any(LocalDateTime.class)))
                .thenReturn(Flux.just(testPoll));
        when(optionRepository.findByPollIdOrderByOptionOrder(testPoll.getId()))
                .thenReturn(Flux.just(option1, option2));

        Flux<BantoraPollResponse> result = pollService.getPopularPolls();

        StepVerifier.create(result.take(1))
                .assertNext(response -> {
                    assertThat(response.getTotalVotes()).isEqualTo(100L);
                    assertThat(response.getScope()).isEqualTo(BantoraPollScope.CONTINENTAL);
                })
                .verifyComplete();
    }

    @Test
    void getPollById_shouldReturnPollWhenExists() {
        when(pollRepository.findById(testPoll.getId()))
                .thenReturn(Mono.just(testPoll));
        when(optionRepository.findByPollIdOrderByOptionOrder(testPoll.getId()))
                .thenReturn(Flux.just(option1, option2));

        Mono<BantoraPollResponse> result = pollService.getPollById(testPoll.getId());

        StepVerifier.create(result)
                .assertNext(response -> {
                    assertThat(response.getId()).isEqualTo(testPoll.getId());
                    assertThat(response.getOptions()).hasSize(2);
                    assertThat(response.getOptions().get(0).getOptionText()).isEqualTo("Yes");
                    assertThat(response.getOptions().get(1).getOptionText()).isEqualTo("No");
                })
                .verifyComplete();
    }

    @Test
    void getPollById_shouldReturnEmptyWhenNotExists() {
        UUID nonExistentId = UUID.randomUUID();
        when(pollRepository.findById(nonExistentId))
                .thenReturn(Mono.empty());

        Mono<BantoraPollResponse> result = pollService.getPollById(nonExistentId);

        StepVerifier.create(result)
                .verifyComplete();
    }
}
