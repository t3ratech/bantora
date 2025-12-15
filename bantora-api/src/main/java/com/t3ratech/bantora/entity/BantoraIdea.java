package com.t3ratech.bantora.entity;

import com.t3ratech.bantora.enums.BantoraIdeaStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;

import java.time.LocalDateTime;
import java.util.UUID;

@Table("bantora_idea")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BantoraIdea {
    
    @Id
    private UUID id;
    
    @Column("user_phone")
    private String userPhone;
    
    @Column("content")
    private String content;
    
    @Column("status")
    private BantoraIdeaStatus status;
    
    @Column("ai_summary")
    private String aiSummary;
    
    @Column("created_at")
    private LocalDateTime createdAt;
    
    @Column("processed_at")
    private LocalDateTime processedAt;
    
    @Column("upvotes")
    @Builder.Default
    private Long upvotes = 0L;
}
