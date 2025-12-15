package com.t3ratech.bantora.repository;

import com.t3ratech.bantora.entity.BantoraRefreshToken;
import org.springframework.data.r2dbc.repository.R2dbcRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;

import java.util.UUID;

@Repository
public interface BantoraRefreshTokenRepository extends R2dbcRepository<BantoraRefreshToken, UUID> {
    Mono<BantoraRefreshToken> findByToken(String token);
}
