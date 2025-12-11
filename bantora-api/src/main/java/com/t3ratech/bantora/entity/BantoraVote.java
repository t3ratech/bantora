package com.t3ratech.bantora.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "bantora_votes", uniqueConstraints = {
        @UniqueConstraint(columnNames = { "poll_id", "user_phone" })
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BantoraVote {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "poll_id", nullable = false)
    private UUID pollId;

    @Column(name = "option_id", nullable = false)
    private UUID optionId;

    @Column(name = "user_phone", length = 20)
    private String userPhone;

    @Column(name = "anonymous", nullable = false)
    @Builder.Default
    private Boolean anonymous = false;

    @Column(name = "voted_at", nullable = false)
    private LocalDateTime votedAt;

    @Column(name = "ip_address", length = 45)
    private String ipAddress;

    @Column(name = "user_agent", length = 500)
    private String userAgent;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "poll_id", referencedColumnName = "id", insertable = false, updatable = false)
    private BantoraPoll poll;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "option_id", referencedColumnName = "id", insertable = false, updatable = false)
    private BantoraPollOption option;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_phone", referencedColumnName = "phone_number", insertable = false, updatable = false)
    private BantoraUser user;

    @PrePersist
    protected void onCreate() {
        if (votedAt == null) {
            votedAt = LocalDateTime.now();
        }
    }
}
