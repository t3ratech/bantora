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

import java.time.Instant;

@Entity
@Table(name = "bantora_verification_code")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BantoraVerificationCode {
    
    @Id
    @Column(name = "phone_number", length = 20, nullable = false)
    private String phoneNumber;
    
    @Column(name = "code", nullable = false, length = 10)
    private String code;
    
    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;
    
    @Column(name = "attempts", nullable = false)
    @Builder.Default
    private Integer attempts = 0;
    
    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private Instant createdAt = Instant.now();
    
    @Column(name = "verified", nullable = false)
    @Builder.Default
    private Boolean verified = false;
}
