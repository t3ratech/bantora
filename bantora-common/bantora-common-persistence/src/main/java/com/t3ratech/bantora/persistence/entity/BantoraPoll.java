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
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@jakarta.persistence.Table(name = "bantora_poll")
@org.springframework.data.relational.core.mapping.Table("bantora_poll")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BantoraPoll {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false)
    private UUID id;

    @Column(name = "title", nullable = false, length = 255)
    private String title;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "creator_phone", nullable = false, length = 20)
    private String creatorPhone;


    @Enumerated(EnumType.STRING)
    @Column(name = "scope", nullable = false, length = 20)
    private BantoraPollScope scope;

    @Column(name = "region", length = 50)
    private String region;

    @Column(name = "country_code", length = 2)
    private String countryCode;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private BantoraPollStatus status = BantoraPollStatus.PENDING;

    @Column(name = "start_time", nullable = false)
    private Instant startTime;

    @Column(name = "end_time", nullable = false)
    private Instant endTime;

    @Column(name = "total_votes", nullable = false)
    @Builder.Default
    private Long totalVotes = 0L;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    @Builder.Default
    private Instant updatedAt = Instant.now();

    @OneToMany(mappedBy = "poll", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @org.springframework.data.annotation.Transient
    @Builder.Default
    private List<BantoraPollOption> options = new ArrayList<>();

    @PreUpdate
    public void preUpdate() {
        updatedAt = Instant.now();
    }
}
