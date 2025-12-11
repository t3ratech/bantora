package com.t3ratech.bantora.repository;

import com.t3ratech.bantora.entity.BantoraVote;
import org.springframework.data.r2dbc.repository.R2dbcRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.UUID;

@Repository
public interface BantoraVoteRepository extends R2dbcRepository<BantoraVote, UUID> {
    Mono<BantoraVote> findByPollIdAndUserPhone(UUID pollId, String userPhone);
    Flux<BantoraVote> findByPollId(UUID pollId);
    Flux<BantoraVote> findByUserPhone(String userPhone);
    Mono<Boolean> existsByPollIdAndUserPhone(UUID pollId, String userPhone);
}
