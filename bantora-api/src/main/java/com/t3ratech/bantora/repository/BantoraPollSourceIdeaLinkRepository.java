package com.t3ratech.bantora.repository;

import lombok.RequiredArgsConstructor;
import org.springframework.r2dbc.core.DatabaseClient;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;

import java.util.UUID;

@Repository
@RequiredArgsConstructor
public class BantoraPollSourceIdeaLinkRepository {

    private final DatabaseClient databaseClient;

    public Mono<Void> linkPollToIdea(UUID pollId, UUID ideaId) {
        if (pollId == null) {
            return Mono.error(new IllegalArgumentException("pollId is required"));
        }
        if (ideaId == null) {
            return Mono.error(new IllegalArgumentException("ideaId is required"));
        }

        return databaseClient.sql("""
                        INSERT INTO bantora_poll_source_idea (poll_id, idea_id)
                        VALUES (:pollId, :ideaId)
                        ON CONFLICT DO NOTHING
                        """)
                .bind("pollId", pollId)
                .bind("ideaId", ideaId)
                .fetch()
                .rowsUpdated()
                .then();
    }
}
