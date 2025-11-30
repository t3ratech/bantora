/**
 * Created by Cascade AI
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025-11-28
 * Email        : tkaviya@t3ratech.co.zw
 */

package com.t3ratech.bantora.persistence.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "votes", uniqueConstraints = @UniqueConstraint(columnNames = { "poll_id", "user_phone" }), indexes = {
        @Index(name = "idx_votes_poll", columnList = "poll_id"),
        @Index(name = "idx_votes_user", columnList = "user_phone"),
        @Index(name = "idx_votes_timestamp", columnList = "voted_at")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Vote {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false)
    private UUID id;

    @Column(name = "poll_id", nullable = false)
    private UUID pollId;

    @Column(name = "option_id", nullable = false)
    private UUID optionId;

    @Column(name = "user_phone", length = 20)
    private String userPhone;

    @Column(name = "voted_at", nullable = false)
    @Builder.Default
    private Instant votedAt = Instant.now();

    @Column(name = "ip_address", length = 45)
    private String ipAddress;

    @Column(name = "user_agent", length = 500)
    private String userAgent;
}
