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

@Table("bantora_hashtag")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BantoraHashtag {

    @Id
    private UUID id;

    @Column("tag")
    private String tag;

    @Column("created_at")
    private LocalDateTime createdAt;
}
