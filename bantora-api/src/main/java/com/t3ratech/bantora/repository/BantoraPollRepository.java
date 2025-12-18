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
    
    @Query("SELECT * FROM bantora_poll WHERE status = 'ACTIVE' AND end_time > :now ORDER BY total_votes DESC")
    Flux<BantoraPoll> findActiveOrderByVotesDesc(LocalDateTime now);
    
    @Query("SELECT * FROM bantora_poll WHERE status = 'ACTIVE' AND end_time > :now ORDER BY created_at DESC")
    Flux<BantoraPoll> findActiveOrderByCreatedDesc(LocalDateTime now);

    @Query("""
            SELECT *
            FROM bantora_poll
            WHERE status = 'ACTIVE'
              AND end_time > :now
              AND category_id = :categoryId
            ORDER BY created_at DESC
            """)
    Flux<BantoraPoll> findActiveByCategoryIdOrderByCreatedDesc(UUID categoryId, LocalDateTime now);

    @Query("""
            SELECT *
            FROM bantora_poll
            WHERE status = 'ACTIVE'
              AND end_time > :now
              AND category_id = :categoryId
            ORDER BY total_votes DESC
            """)
    Flux<BantoraPoll> findActiveByCategoryIdOrderByVotesDesc(UUID categoryId, LocalDateTime now);

    @Query("""
            SELECT p.*
            FROM bantora_poll p
            JOIN bantora_poll_hashtag ph ON ph.poll_id = p.id
            JOIN bantora_hashtag h ON h.id = ph.hashtag_id
            WHERE p.status = 'ACTIVE'
              AND p.end_time > :now
              AND lower(h.tag) = lower(:tag)
            ORDER BY p.created_at DESC
            """)
    Flux<BantoraPoll> findActiveByHashtagOrderByCreatedDesc(String tag, LocalDateTime now);

    @Query("""
            SELECT p.*
            FROM bantora_poll p
            JOIN bantora_poll_hashtag ph ON ph.poll_id = p.id
            JOIN bantora_hashtag h ON h.id = ph.hashtag_id
            WHERE p.status = 'ACTIVE'
              AND p.end_time > :now
              AND lower(h.tag) = lower(:tag)
            ORDER BY p.total_votes DESC
            """)
    Flux<BantoraPoll> findActiveByHashtagOrderByVotesDesc(String tag, LocalDateTime now);

    @Query("""
            SELECT p.*
            FROM bantora_poll p
            JOIN bantora_poll_hashtag ph ON ph.poll_id = p.id
            JOIN bantora_hashtag h ON h.id = ph.hashtag_id
            WHERE p.status = 'ACTIVE'
              AND p.end_time > :now
              AND p.category_id = :categoryId
              AND lower(h.tag) = lower(:tag)
            ORDER BY p.created_at DESC
            """)
    Flux<BantoraPoll> findActiveByCategoryIdAndHashtagOrderByCreatedDesc(UUID categoryId, String tag, LocalDateTime now);

    @Query("""
            SELECT p.*
            FROM bantora_poll p
            JOIN bantora_poll_hashtag ph ON ph.poll_id = p.id
            JOIN bantora_hashtag h ON h.id = ph.hashtag_id
            WHERE p.status = 'ACTIVE'
              AND p.end_time > :now
              AND p.category_id = :categoryId
              AND lower(h.tag) = lower(:tag)
            ORDER BY p.total_votes DESC
            """)
    Flux<BantoraPoll> findActiveByCategoryIdAndHashtagOrderByVotesDesc(UUID categoryId, String tag, LocalDateTime now);
}
