package com.t3ratech.bantora.repository;

import com.t3ratech.bantora.entity.BantoraCategory;
import org.springframework.data.r2dbc.repository.R2dbcRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;

import java.util.UUID;

@Repository
public interface BantoraCategoryRepository extends R2dbcRepository<BantoraCategory, UUID> {
    Flux<BantoraCategory> findAllByOrderByNameAsc();
}
