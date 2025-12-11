package com.t3ratech.bantora.repository;

import com.t3ratech.bantora.entity.BantoraUser;
import org.springframework.data.r2dbc.repository.R2dbcRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;

@Repository
public interface BantoraUserRepository extends R2dbcRepository<BantoraUser, String> {
    Mono<BantoraUser> findByPhoneNumber(String phoneNumber);
    Mono<BantoraUser> findByEmail(String email);
    Mono<Boolean> existsByPhoneNumber(String phoneNumber);
    Mono<Boolean> existsByEmail(String email);
}
