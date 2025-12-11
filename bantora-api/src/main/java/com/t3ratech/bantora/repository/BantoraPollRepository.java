package com.t3ratech.bantora.repository;

import com.t3ratech.bantora.entity.BantoraPoll;
import com.t3ratech.bantora.enums.BantoraPollStatus;
import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.r2dbc.repository.R2dbcRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;

import java.time.LocalDateTime;
import java.util.UUID;

@Repository
public interface BantoraPollRepository extends R2dbcRepository<BantoraPoll, UUID> {
    Flux<BantoraPoll> findByStatus(BantoraPollStatus status);
    Flux<BantoraPoll> findByCreatorPhone(String creatorPhone);
    
    @Query("SELECT * FROM bantora_polls WHERE status = 'ACTIVE' AND end_time > :now ORDER BY total_votes DESC")
    Flux<BantoraPoll> findActiveOrderByVotesDesc(LocalDateTime now);
    
    @Query("SELECT * FROM bantora_polls WHERE status = 'ACTIVE' AND end_time > :now ORDER BY created_at DESC")
    Flux<BantoraPoll> findActiveOrderByCreatedDesc(LocalDateTime now);
}
