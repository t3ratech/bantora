package com.t3ratech.bantora.repository;

import com.t3ratech.bantora.entity.BantoraIdea;
import com.t3ratech.bantora.enums.BantoraIdeaStatus;
import lombok.RequiredArgsConstructor;
import org.springframework.r2dbc.core.DatabaseClient;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;

import java.util.UUID;

@Repository
@RequiredArgsConstructor
public class BantoraIdeaReadRepository {

    private final DatabaseClient databaseClient;

    public Flux<BantoraIdea> findPendingIdeasByHashtagId(UUID hashtagId, int limit) {
        if (hashtagId == null) {
            return Flux.error(new IllegalArgumentException("hashtagId is required"));
        }
        if (limit <= 0) {
            return Flux.empty();
        }

        return databaseClient.sql("""
                        SELECT i.*
                        FROM bantora_idea i
                        JOIN bantora_idea_hashtag ih ON ih.idea_id = i.id
                        WHERE ih.hashtag_id = :hashtagId
                          AND i.status = 'PENDING'
                        ORDER BY i.created_at DESC
                        LIMIT :limit
                        """)
                .bind("hashtagId", hashtagId)
                .bind("limit", limit)
                .map((row, meta) -> BantoraIdea.builder()
                        .id(row.get("id", UUID.class))
                        .userPhone(row.get("user_phone", String.class))
                        .content(row.get("content", String.class))
                        .categoryId(row.get("category_id", UUID.class))
                        .status(BantoraIdeaStatus.valueOf(row.get("status", String.class)))
                        .aiSummary(row.get("ai_summary", String.class))
                        .createdAt(row.get("created_at", java.time.LocalDateTime.class))
                        .processedAt(row.get("processed_at", java.time.LocalDateTime.class))
                        .upvotes(row.get("upvotes", Long.class))
                        .build())
                .all();
    }
}
