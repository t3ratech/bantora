package com.t3ratech.bantora.service;

import com.t3ratech.bantora.dto.response.BantoraPollResponse;
import com.t3ratech.bantora.entity.BantoraPoll;
import com.t3ratech.bantora.entity.BantoraPollOption;
import com.t3ratech.bantora.entity.BantoraVote;
import com.t3ratech.bantora.repository.BantoraPollOptionRepository;
import com.t3ratech.bantora.repository.BantoraPollRepository;
import com.t3ratech.bantora.repository.BantoraVoteRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.r2dbc.core.R2dbcEntityTemplate;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class BantoraVoteService {

    private final BantoraPollRepository pollRepository;
    private final BantoraPollOptionRepository optionRepository;
    private final BantoraVoteRepository voteRepository;
    private final BantoraPollService pollService;
    private final R2dbcEntityTemplate entityTemplate;

    public Mono<BantoraPollResponse> submitVote(
            UUID pollId,
            UUID optionId,
            String userPhone,
            boolean anonymous,
            String ipAddress,
            String userAgent
    ) {
        UUID nonNullPollId = Objects.requireNonNull(pollId, "pollId");
        UUID nonNullOptionId = Objects.requireNonNull(optionId, "optionId");

        Mono<BantoraPoll> pollMono = pollRepository.findById(nonNullPollId)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("Poll not found")));

        Mono<BantoraPollOption> optionMono = optionRepository.findById(nonNullOptionId)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("Option not found")));

        return pollMono.zipWith(optionMono)
                .flatMap(tuple -> {
                    BantoraPoll poll = tuple.getT1();
                    BantoraPollOption option = tuple.getT2();

                    if (option.getPollId() == null || !option.getPollId().equals(nonNullPollId)) {
                        return Mono.error(new IllegalArgumentException("Option does not belong to poll"));
                    }

                    Mono<Boolean> alreadyVotedMono;
                    if (userPhone != null && !userPhone.isBlank()) {
                        alreadyVotedMono = voteRepository.existsByPollIdAndUserPhone(nonNullPollId, userPhone);
                    } else {
                        alreadyVotedMono = Mono.just(false);
                    }

                    return alreadyVotedMono.flatMap(alreadyVoted -> {
                        if (alreadyVoted && Boolean.FALSE.equals(poll.getAllowMultipleVotes())) {
                            return Mono.error(new IllegalStateException("User has already voted"));
                        }

                        BantoraVote vote = BantoraVote.builder()
                                .id(UUID.randomUUID())
                                .pollId(nonNullPollId)
                                .optionId(nonNullOptionId)
                                .userPhone(userPhone)
                                .anonymous(anonymous)
                                .votedAt(LocalDateTime.now())
                                .ipAddress(ipAddress)
                                .userAgent(userAgent)
                                .build();

                        long currentOptionVotes = option.getVotesCount() == null ? 0L : option.getVotesCount();
                        option.setVotesCount(currentOptionVotes + 1L);

                        long currentTotalVotes = poll.getTotalVotes() == null ? 0L : poll.getTotalVotes();
                        poll.setTotalVotes(currentTotalVotes + 1L);

                        return entityTemplate.insert(Objects.requireNonNull(vote, "vote"))
                                .then(optionRepository.save(option))
                                .then(pollRepository.save(poll))
                                .then(pollService.getPollById(nonNullPollId));
                    });
                });
    }
}
