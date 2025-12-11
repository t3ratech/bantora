package com.t3ratech.bantora.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Entity
@Table(name = "bantora_poll_options")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BantoraPollOption {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "poll_id", nullable = false)
    private UUID pollId;

    @Column(name = "option_text", nullable = false, length = 500)
    private String optionText;

    @Column(name = "option_order", nullable = false)
    private Integer optionOrder;

    @Column(name = "votes_count", nullable = false)
    @Builder.Default
    private Long votesCount = 0L;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "poll_id", referencedColumnName = "id", insertable = false, updatable = false)
    private BantoraPoll poll;
}
