package com.t3ratech.bantora.repository;

import lombok.RequiredArgsConstructor;
import org.springframework.r2dbc.core.DatabaseClient;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;

import java.util.UUID;

@Repository
@RequiredArgsConstructor
public class BantoraPollSourceIdeaReadRepository {

    private final DatabaseClient databaseClient;

    public Flux<UUID> findIdeaIdsByPollId(UUID pollId) {
        if (pollId == null) {
            return Flux.error(new IllegalArgumentException("pollId is required"));
        }

        return databaseClient.sql("""
                        SELECT idea_id
                        FROM bantora_poll_source_idea
                        WHERE poll_id = :pollId
                        ORDER BY idea_id
                        """)
                .bind("pollId", pollId)
                .map((row, meta) -> row.get("idea_id", UUID.class))
                .all();
    }

    public Flux<UUID> findPollIdsByIdeaId(UUID ideaId) {
        if (ideaId == null) {
            return Flux.error(new IllegalArgumentException("ideaId is required"));
        }

        return databaseClient.sql("""
                        SELECT poll_id
                        FROM bantora_poll_source_idea
                        WHERE idea_id = :ideaId
                        ORDER BY poll_id
                        """)
                .bind("ideaId", ideaId)
                .map((row, meta) -> row.get("poll_id", UUID.class))
                .all();
    }
}
