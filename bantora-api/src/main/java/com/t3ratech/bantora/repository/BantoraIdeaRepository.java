package com.t3ratech.bantora.repository;

import com.t3ratech.bantora.entity.BantoraIdea;
import com.t3ratech.bantora.enums.BantoraIdeaStatus;
import org.springframework.data.r2dbc.repository.Query;
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

    Flux<BantoraIdea> findByStatusAndCategoryIdOrderByCreatedAtDesc(BantoraIdeaStatus status, UUID categoryId);

    @Query("""
            SELECT DISTINCT i.*
            FROM bantora_idea i
            JOIN bantora_idea_hashtag ih ON ih.idea_id = i.id
            JOIN bantora_hashtag h ON h.id = ih.hashtag_id
            WHERE i.status = :status
              AND lower(h.tag) = lower(:tag)
            ORDER BY i.created_at DESC
            """)
    Flux<BantoraIdea> findByStatusAndHashtagOrderByCreatedAtDesc(String status, String tag);

    @Query("""
            SELECT DISTINCT i.*
            FROM bantora_idea i
            JOIN bantora_idea_hashtag ih ON ih.idea_id = i.id
            JOIN bantora_hashtag h ON h.id = ih.hashtag_id
            WHERE i.status = :status
              AND i.category_id = :categoryId
              AND lower(h.tag) = lower(:tag)
            ORDER BY i.created_at DESC
            """)
    Flux<BantoraIdea> findByStatusAndCategoryIdAndHashtagOrderByCreatedAtDesc(String status, UUID categoryId, String tag);
}
