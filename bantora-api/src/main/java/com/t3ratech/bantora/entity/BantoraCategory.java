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

@Table("bantora_category")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BantoraCategory {

    @Id
    private UUID id;

    @Column("name")
    private String name;

    @Column("created_at")
    private LocalDateTime createdAt;
}
