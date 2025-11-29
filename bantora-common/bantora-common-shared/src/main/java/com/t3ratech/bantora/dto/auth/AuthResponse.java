/**
 * Created by Cascade AI
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025-11-28
 * Email        : tkaviya@t3ratech.co.zw
 */

package com.t3ratech.bantora.dto.auth;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.Set;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {
    private String accessToken;
    private String refreshToken;
    private Instant expiresAt;
    @Builder.Default
    private String tokenType = "Bearer";
    private UserInfo user;
}

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
class UserInfo {
    private String phoneNumber;
    private String fullName;
    private String countryCode;
    private Set<String> roles;
    private String preferredLanguage;
}
