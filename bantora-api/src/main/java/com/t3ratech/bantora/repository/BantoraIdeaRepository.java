package com.t3ratech.bantora.repository;

import com.t3ratech.bantora.entity.BantoraIdea;
import com.t3ratech.bantora.enums.BantoraIdeaStatus;
import org.springframework.data.r2dbc.repository.R2dbcRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;

import java.util.UUID;

@Repository
public interface BantoraIdeaRepository extends R2dbcRepository<BantoraIdea, UUID> {
    Flux<BantoraIdea> findByStatus(BantoraIdeaStatus status);
    Flux<BantoraIdea> findByUserPhone(String userPhone);
    Flux<BantoraIdea> findByStatusOrderByCreatedAtDesc(BantoraIdeaStatus status);
    Flux<BantoraIdea> findAllByOrderByUpvotesDesc();
}
