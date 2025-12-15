/**
 * Created by Cascade AI
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025-11-28
 * Email        : tkaviya@t3ratech.co.zw
 */

package com.t3ratech.bantora.controller;

import com.t3ratech.bantora.dto.auth.*;
import com.t3ratech.bantora.dto.common.ApiResponse;
import com.t3ratech.bantora.service.BantoraAuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import java.util.List;

@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Authentication", description = "User authentication and registration endpoints")
@RequiredArgsConstructor
public class AuthController {

    private final BantoraAuthService authService;

    private <T> ResponseEntity<ApiResponse<T>> errorResponse(String message, Throwable error) {
        HttpStatus status = HttpStatus.INTERNAL_SERVER_ERROR;
        if (error instanceof IllegalArgumentException) {
            status = HttpStatus.BAD_REQUEST;
        } else if (error instanceof BadCredentialsException) {
            status = HttpStatus.UNAUTHORIZED;
        } else if (error instanceof IllegalStateException) {
            status = HttpStatus.BAD_REQUEST;
        }

        String detail = error.getMessage();
        List<String> errors = (detail != null && !detail.isBlank())
                ? List.of(detail)
                : List.of(error.getClass().getName());

        return ResponseEntity.status(status)
                .body(ApiResponse.error(message, errors));
    }
    
    @PostMapping("/register")
    @Operation(summary = "Register a new user with phone number")
    public Mono<ResponseEntity<ApiResponse<AuthResponse>>> register(@Valid @RequestBody RegisterRequest request) {
        return authService.register(request)
                .map(auth -> ResponseEntity.ok(ApiResponse.success(auth, "Registration successful")))
                .onErrorResume(e -> Mono.just(errorResponse("Registration failed", e)));
    }
    
    @PostMapping("/verify")
    @Operation(summary = "Verify phone number with SMS code")
    public Mono<ApiResponse<String>> verify(@Valid @RequestBody VerifyRequest request) {
        // Verification is currently out of scope for UI flow; registration marks verified.
        // Fail fast to avoid implying SMS verification is implemented.
        return Mono.just(ApiResponse.error("Not implemented", null));
    }
    
    @PostMapping("/login")
    @Operation(summary = "Login with phone number and password")
    public Mono<ResponseEntity<ApiResponse<AuthResponse>>> login(@Valid @RequestBody LoginRequest request) {
        return authService.login(request)
                .map(auth -> ResponseEntity.ok(ApiResponse.success(auth, "Login successful")))
                .onErrorResume(e -> Mono.just(errorResponse("Login failed", e)));
    }
    
    @PostMapping("/refresh")
    @Operation(summary = "Refresh access token using refresh token")
    public Mono<ResponseEntity<ApiResponse<AuthResponse>>> refresh(@RequestHeader("Authorization") String refreshToken) {
        return authService.refresh(refreshToken)
                .map(auth -> ResponseEntity.ok(ApiResponse.success(auth, "Token refreshed")))
                .onErrorResume(e -> Mono.just(errorResponse("Token refresh failed", e)));
    }
    
    @PostMapping("/logout")
    @Operation(summary = "Logout and revoke refresh token")
    public Mono<ResponseEntity<ApiResponse<String>>> logout(@RequestHeader("Authorization") String token) {
        return authService.logout(token)
                .thenReturn(ResponseEntity.ok(ApiResponse.success("Logged out successfully", null)))
                .onErrorResume(e -> Mono.just(errorResponse("Logout failed", e)));
    }
}
