package com.t3ratech.bantora.entity;

import com.t3ratech.bantora.enums.BantoraPollScope;
import com.t3ratech.bantora.enums.BantoraPollStatus;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "bantora_polls")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BantoraPoll {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "creator_phone", nullable = false, length = 20)
    private String creatorPhone;

    @Column(name = "category", length = 50)
    private String category;

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
    private LocalDateTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalDateTime endTime;

    @Column(name = "allow_anonymous", nullable = false)
    @Builder.Default
    private Boolean allowAnonymous = true;

    @Column(name = "allow_multiple_votes", nullable = false)
    @Builder.Default
    private Boolean allowMultipleVotes = false;

    @Column(name = "total_votes", nullable = false)
    @Builder.Default
    private Long totalVotes = 0L;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "poll", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<BantoraPollOption> options = new ArrayList<>();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "creator_phone", referencedColumnName = "phone_number", insertable = false, updatable = false)
    private BantoraUser creator;

    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        if (createdAt == null) {
            createdAt = now;
        }
        if (updatedAt == null) {
            updatedAt = now;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
