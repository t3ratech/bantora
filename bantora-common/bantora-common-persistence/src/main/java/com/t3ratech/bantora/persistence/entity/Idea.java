/**
 * Created by Cascade AI
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025-11-30
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
@jakarta.persistence.Table(name = "ideas")
@org.springframework.data.relational.core.mapping.Table("ideas")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Idea {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false)
    private UUID id;

    @Column(name = "user_phone", nullable = false, length = 20)
    private String userPhone;

    @Column(name = "content", nullable = false, columnDefinition = "TEXT")
    private String content;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private IdeaStatus status = IdeaStatus.PENDING;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private Instant createdAt = Instant.now();

    @Column(name = "processed_at")
    private Instant processedAt;

    @Column(name = "upvotes", nullable = false)
    @Builder.Default
    private Long upvotes = 0L;

    public enum IdeaStatus {
        PENDING,
        PROCESSED,
        REJECTED,
        POPULAR
    }
}
