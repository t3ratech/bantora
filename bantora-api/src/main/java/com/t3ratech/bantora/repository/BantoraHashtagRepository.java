package com.t3ratech.bantora.repository;

import com.t3ratech.bantora.entity.BantoraHashtag;
import org.springframework.data.r2dbc.repository.R2dbcRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.UUID;

@Repository
public interface BantoraHashtagRepository extends R2dbcRepository<BantoraHashtag, UUID> {
    Mono<BantoraHashtag> findByTag(String tag);

    Flux<BantoraHashtag> findAllByOrderByTagAsc();
}
