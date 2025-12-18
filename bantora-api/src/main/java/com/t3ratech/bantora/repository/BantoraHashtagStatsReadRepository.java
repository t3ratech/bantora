package com.t3ratech.bantora.repository;

import lombok.RequiredArgsConstructor;
import org.springframework.r2dbc.core.DatabaseClient;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;

import java.util.UUID;

@Repository
@RequiredArgsConstructor
public class BantoraHashtagStatsReadRepository {

    private final DatabaseClient databaseClient;

    public record HashtagPendingIdeaCount(UUID hashtagId, String tag, long pendingIdeaCount) {
    }

    public Flux<HashtagPendingIdeaCount> findTopHashtagsByPendingIdeaCount(int limit) {
        if (limit <= 0) {
            return Flux.empty();
        }

        return databaseClient.sql("""
                        SELECT h.id AS hashtag_id,
                               h.tag AS tag,
                               COUNT(*) AS pending_idea_count
                        FROM bantora_hashtag h
                        JOIN bantora_idea_hashtag ih ON ih.hashtag_id = h.id
                        JOIN bantora_idea i ON i.id = ih.idea_id
                        WHERE i.status = 'PENDING'
                        GROUP BY h.id, h.tag
                        ORDER BY pending_idea_count DESC
                        LIMIT :limit
                        """)
                .bind("limit", limit)
                .map((row, meta) -> new HashtagPendingIdeaCount(
                        row.get("hashtag_id", UUID.class),
                        row.get("tag", String.class),
                        row.get("pending_idea_count", Long.class) == null ? 0L : row.get("pending_idea_count", Long.class)
                ))
                .all();
    }
}
