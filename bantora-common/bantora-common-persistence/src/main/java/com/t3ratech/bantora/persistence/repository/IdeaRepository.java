/**
 * Created by Cascade AI
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025-11-30
 * Email        : tkaviya@t3ratech.co.zw
 */

package com.t3ratech.bantora.persistence.repository;

import com.t3ratech.bantora.persistence.entity.Idea;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;

import java.util.UUID;

@Repository
public interface IdeaRepository extends ReactiveCrudRepository<Idea, UUID> {
    Flux<Idea> findByStatus(Idea.IdeaStatus status);
}
