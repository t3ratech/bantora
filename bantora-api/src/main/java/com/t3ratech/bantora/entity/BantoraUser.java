package com.t3ratech.bantora.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;

import java.time.LocalDateTime;

@Table("bantora_users")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BantoraUser {
    
    @Id
    @Column("phone_number")
    private String phoneNumber;
    
    @Column("password_hash")
    private String passwordHash;
    
    @Column("full_name")
    private String fullName;
    
    @Column("email")
    private String email;
    
    @Column("country_code")
    private String countryCode;
    
    @Column("verified")
    @Builder.Default
    private Boolean verified = false;
    
    @Column("enabled")
    @Builder.Default
    private Boolean enabled = true;
    
    @Column("preferred_language")
    @Builder.Default
    private String preferredLanguage = "en";
    
    @Column("created_at")
    private LocalDateTime createdAt;
    
    @Column("updated_at")
    private LocalDateTime updatedAt;
    
    @Column("last_login_at")
    private LocalDateTime lastLoginAt;
}
