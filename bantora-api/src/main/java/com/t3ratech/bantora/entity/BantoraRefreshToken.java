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

@Table("bantora_refresh_token")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BantoraRefreshToken {

    @Id
    private UUID id;

    @Column("token")
    private String token;

    @Column("user_phone")
    private String userPhone;

    @Column("expires_at")
    private LocalDateTime expiresAt;

    @Column("revoked")
    private Boolean revoked;

    @Column("created_at")
    private LocalDateTime createdAt;
}
