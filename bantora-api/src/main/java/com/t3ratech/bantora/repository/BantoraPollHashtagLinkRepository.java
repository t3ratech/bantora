package com.t3ratech.bantora.repository;

import lombok.RequiredArgsConstructor;
import org.springframework.r2dbc.core.DatabaseClient;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;

import java.util.UUID;

@Repository
@RequiredArgsConstructor
public class BantoraPollHashtagLinkRepository {

    private final DatabaseClient databaseClient;

    public Mono<Void> linkPollToHashtag(UUID pollId, UUID hashtagId) {
        if (pollId == null) {
            return Mono.error(new IllegalArgumentException("pollId is required"));
        }
        if (hashtagId == null) {
            return Mono.error(new IllegalArgumentException("hashtagId is required"));
        }

        return databaseClient.sql("""
                        INSERT INTO bantora_poll_hashtag (poll_id, hashtag_id)
                        VALUES (:pollId, :hashtagId)
                        ON CONFLICT DO NOTHING
                        """)
                .bind("pollId", pollId)
                .bind("hashtagId", hashtagId)
                .fetch()
                .rowsUpdated()
                .then();
    }
}
