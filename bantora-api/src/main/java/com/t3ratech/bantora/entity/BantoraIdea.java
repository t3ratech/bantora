package com.t3ratech.bantora.entity;

import com.t3ratech.bantora.enums.BantoraIdeaStatus;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "bantora_ideas")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BantoraIdea {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_phone", nullable = false, length = 20)
    private String userPhone;

    @Column(name = "content", nullable = false, columnDefinition = "TEXT")
    private String content;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private BantoraIdeaStatus status;

    @Column(name = "ai_summary", columnDefinition = "TEXT")
    private String aiSummary;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "processed_at")
    private LocalDateTime processedAt;

    @Column(name = "upvotes", nullable = false)
    @Builder.Default
    private Long upvotes = 0L;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_phone", referencedColumnName = "phone_number", insertable = false, updatable = false)
    private BantoraUser user;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (status == null) {
            status = BantoraIdeaStatus.PENDING;
        }
    }
}
