package com.t3ratech.bantora.entity;

import com.t3ratech.bantora.enums.BantoraPollScope;
import com.t3ratech.bantora.enums.BantoraPollStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.Transient;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Table("bantora_poll")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BantoraPoll {
    
    @Id
    private UUID id;
    
    @Column("title")
    private String title;
    
    @Column("description")
    private String description;
    
    @Column("creator_phone")
    private String creatorPhone;

    @Column("category_id")
    private UUID categoryId;
    
    @Column("scope")
    private BantoraPollScope scope;
    
    @Column("region")
    private String region;
    
    @Column("country_code")
    private String countryCode;
    
    @Column("status")
    @Builder.Default
    private BantoraPollStatus status = BantoraPollStatus.PENDING;
    
    @Column("start_time")
    private LocalDateTime startTime;
    
    @Column("end_time")
    private LocalDateTime endTime;
    
    @Column("allow_anonymous")
    @Builder.Default
    private Boolean allowAnonymous = true;
    
    @Column("allow_multiple_votes")
    @Builder.Default
    private Boolean allowMultipleVotes = false;
    
    @Column("total_votes")
    @Builder.Default
    private Long totalVotes = 0L;
    
    @Column("created_at")
    private LocalDateTime createdAt;
    
    @Column("updated_at")
    private LocalDateTime updatedAt;
    
    @Transient
    @Builder.Default
    private List<BantoraPollOption> options = new ArrayList<>();
}
