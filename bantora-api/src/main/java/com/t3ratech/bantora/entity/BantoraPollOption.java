package com.t3ratech.bantora.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;

import java.util.UUID;

@Table("bantora_poll_option")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BantoraPollOption {
    
    @Id
    private UUID id;
    
    @Column("poll_id")
    private UUID pollId;
    
    @Column("option_text")
    private String optionText;
    
    @Column("option_order")
    private Integer optionOrder;
    
    @Column("votes_count")
    @Builder.Default
    private Long votesCount = 0L;
}
