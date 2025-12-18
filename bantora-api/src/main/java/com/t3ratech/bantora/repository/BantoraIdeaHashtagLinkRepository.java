package com.t3ratech.bantora.repository;

import lombok.RequiredArgsConstructor;
import org.springframework.r2dbc.core.DatabaseClient;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Mono;

import java.util.UUID;

@Repository
@RequiredArgsConstructor
public class BantoraIdeaHashtagLinkRepository {

    private final DatabaseClient databaseClient;

    public Mono<Void> linkIdeaToHashtag(UUID ideaId, UUID hashtagId) {
        return databaseClient.sql("INSERT INTO bantora_idea_hashtag (idea_id, hashtag_id) VALUES (:ideaId, :hashtagId)")
                .bind("ideaId", ideaId)
                .bind("hashtagId", hashtagId)
                .fetch()
                .rowsUpdated()
                .then();
    }

    public Mono<Void> unlinkAllForIdea(UUID ideaId) {
        return databaseClient.sql("DELETE FROM bantora_idea_hashtag WHERE idea_id = :ideaId")
                .bind("ideaId", ideaId)
                .fetch()
                .rowsUpdated()
                .then();
    }
}
