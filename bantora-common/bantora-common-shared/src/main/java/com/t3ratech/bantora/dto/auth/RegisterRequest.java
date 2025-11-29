/**
 * Created by Cascade AI
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025-11-28
 * Email        : tkaviya@t3ratech.co.zw
 */

package com.t3ratech.bantora.dto.auth;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RegisterRequest {
    
    @NotBlank(message = "Phone number is required")
    @Pattern(
        regexp = "^\\+[1-9]\\d{1,14}$",
        message = "Phone number must be in E.164 format (e.g., +263771234567)"
    )
    private String phoneNumber;
    
    @NotBlank(message = "Password is required")
    @Size(min = 8, max = 100, message = "Password must be between 8 and 100 characters")
    private String password;
    
    @NotBlank(message = "Country code is required")
    @Pattern(regexp = "^[A-Z]{2}$", message = "Country code must be ISO 3166-1 alpha-2 (e.g., ZA, NG)")
    private String countryCode;
    
    private String fullName;
    
    private String email;
    
    @Pattern(regexp = "^(en|sw|yo|zu|am|ar|fr|pt|ha|ig|so|af|sn)$", message = "Unsupported language")
    @Builder.Default
    private String preferredLanguage = "en";
}
