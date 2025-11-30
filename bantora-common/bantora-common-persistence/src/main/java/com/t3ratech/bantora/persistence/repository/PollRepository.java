/**
 * Created by Cascade AI
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025-11-30
 * Email        : tkaviya@t3ratech.co.zw
 */

package com.t3ratech.bantora.persistence.repository;

import com.t3ratech.bantora.persistence.entity.Poll;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface PollRepository extends ReactiveCrudRepository<Poll, UUID> {
}
