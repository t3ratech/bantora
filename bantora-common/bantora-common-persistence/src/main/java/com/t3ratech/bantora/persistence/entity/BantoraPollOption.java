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

import java.util.UUID;

@Entity
@Table(name = "bantora_poll_option")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BantoraPollOption {
    
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false)
    private UUID id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "poll_id", nullable = false)
    private BantoraPoll poll;
    
    @Column(name = "option_text", nullable = false, length = 500)
    private String optionText;
    
    @Column(name = "option_order", nullable = false)
    private Integer optionOrder;
    
    @Column(name = "votes_count", nullable = false)
    @Builder.Default
    private Long votesCount = 0L;
}
