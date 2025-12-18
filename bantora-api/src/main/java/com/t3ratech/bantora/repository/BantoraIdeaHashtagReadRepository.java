package com.t3ratech.bantora.repository;

import lombok.RequiredArgsConstructor;
import org.springframework.r2dbc.core.DatabaseClient;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;

import java.util.UUID;

@Repository
@RequiredArgsConstructor
public class BantoraIdeaHashtagReadRepository {

    private final DatabaseClient databaseClient;

    public Flux<String> findTagsByIdeaId(UUID ideaId) {
        return databaseClient.sql("""
                        SELECT h.tag
                        FROM bantora_idea_hashtag ih
                        JOIN bantora_hashtag h ON h.id = ih.hashtag_id
                        WHERE ih.idea_id = :ideaId
                        ORDER BY h.tag ASC
                        """)
                .bind("ideaId", ideaId)
                .map((row, meta) -> row.get("tag", String.class))
                .all();
    }
}
