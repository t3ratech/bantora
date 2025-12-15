package com.t3ratech.bantora.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;

import java.time.LocalDateTime;
import java.util.UUID;

@Table("bantora_vote")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BantoraVote {
    
    @Id
    private UUID id;
    
    @Column("poll_id")
    private UUID pollId;
    
    @Column("option_id")
    private UUID optionId;
    
    @Column("user_phone")
    private String userPhone;
    
    @Column("anonymous")
    @Builder.Default
    private Boolean anonymous = false;
    
    @Column("voted_at")
    private LocalDateTime votedAt;
    
    @Column("ip_address")
    private String ipAddress;
    
    @Column("user_agent")
    private String userAgent;
}
