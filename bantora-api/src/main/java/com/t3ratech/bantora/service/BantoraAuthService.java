package com.t3ratech.bantora.service;

import com.t3ratech.bantora.dto.auth.AuthResponse;
import com.t3ratech.bantora.dto.auth.LoginRequest;
import com.t3ratech.bantora.dto.auth.RegisterRequest;
import com.t3ratech.bantora.entity.BantoraRefreshToken;
import com.t3ratech.bantora.entity.BantoraUser;
import com.t3ratech.bantora.repository.BantoraCountryRepository;
import com.t3ratech.bantora.repository.BantoraRefreshTokenRepository;
import com.t3ratech.bantora.repository.BantoraUserRepository;
import com.t3ratech.bantora.security.Argon2PasswordEncoder;
import com.t3ratech.bantora.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.r2dbc.core.R2dbcEntityTemplate;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class BantoraAuthService {

    private static final Set<String> DEFAULT_ROLES = Set.of("ROLE_USER");

    private final BantoraUserRepository userRepository;
    private final BantoraCountryRepository countryRepository;
    private final BantoraRefreshTokenRepository refreshTokenRepository;
    private final Argon2PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final R2dbcEntityTemplate entityTemplate;

    @Value("${bantora.i18n.default-locale}")
    private String defaultLocale;

    public Mono<AuthResponse> register(RegisterRequest request) {
        Objects.requireNonNull(request, "request");

        String phone = Objects.requireNonNull(request.getPhoneNumber(), "phoneNumber").trim();
        String password = Objects.requireNonNull(request.getPassword(), "password");
        String countryCode = Objects.requireNonNull(request.getCountryCode(), "countryCode").trim().toUpperCase();
        String preferredCurrency = Objects.requireNonNull(request.getPreferredCurrency(), "preferredCurrency").trim().toUpperCase();

        return countryRepository.findByCodeAndRegistrationEnabledTrue(countryCode)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("Country code not allowed")))
                .then(userRepository.existsByPhoneNumber(phone)
                        .flatMap(exists -> {
                            if (Boolean.TRUE.equals(exists)) {
                                return Mono.error(new IllegalArgumentException("Phone number already registered"));
                            }
                            if (request.getEmail() != null && !request.getEmail().isBlank()) {
                                return userRepository.existsByEmail(request.getEmail().trim())
                                        .flatMap(emailExists -> {
                                            if (Boolean.TRUE.equals(emailExists)) {
                                                return Mono.error(new IllegalArgumentException("Email already registered"));
                                            }
                                            return createUserAndIssueTokens(request, phone, password, countryCode, preferredCurrency);
                                        });
                            }
                            return createUserAndIssueTokens(request, phone, password, countryCode, preferredCurrency);
                        }))
                .doOnError(e -> log.error("Auth register failed for {}: {}", phone, e.toString()));
    }

    public Mono<AuthResponse> login(LoginRequest request) {
        Objects.requireNonNull(request, "request");

        String phone = Objects.requireNonNull(request.getPhoneNumber(), "phoneNumber").trim();
        String password = Objects.requireNonNull(request.getPassword(), "password");

        return userRepository.findByPhoneNumber(phone)
                .switchIfEmpty(Mono.error(new BadCredentialsException("Invalid credentials")))
                .flatMap(user -> {
                    if (Boolean.FALSE.equals(user.getEnabled())) {
                        return Mono.error(new IllegalStateException("Account disabled"));
                    }
                    if (Boolean.FALSE.equals(user.getVerified())) {
                        return Mono.error(new IllegalStateException("Account not verified"));
                    }
                    return Mono.fromCallable(() -> passwordEncoder.matches(password, user.getPasswordHash()))
                            .subscribeOn(Schedulers.boundedElastic())
                            .flatMap(matches -> {
                                if (!Boolean.TRUE.equals(matches)) {
                                    return Mono.error(new BadCredentialsException("Invalid credentials"));
                                }

                                user.setLastLoginAt(LocalDateTime.now(ZoneOffset.UTC));
                                user.setUpdatedAt(LocalDateTime.now(ZoneOffset.UTC));

                                return userRepository.save(user)
                                        .then(issueTokensForUser(user));
                            });
                })
                .doOnError(e -> log.error("Auth login failed for {}: {}", phone, e.toString()));
    }

    public Mono<AuthResponse> refresh(String refreshToken) {
        String token = Objects.requireNonNull(refreshToken, "refreshToken").trim();
        if (token.toLowerCase().startsWith("bearer ")) {
            token = token.substring(7).trim();
        }

        if (token.isBlank()) {
            return Mono.error(new BadCredentialsException("Missing refresh token"));
        }

        if (!jwtUtil.validateToken(token)) {
            return Mono.error(new BadCredentialsException("Invalid refresh token"));
        }

        String type = jwtUtil.getTokenType(token);
        if (type == null || !"refresh".equalsIgnoreCase(type)) {
            return Mono.error(new BadCredentialsException("Invalid refresh token type"));
        }

        Instant exp = jwtUtil.getExpirationFromToken(token);
        if (exp == null || exp.isBefore(Instant.now())) {
            return Mono.error(new BadCredentialsException("Refresh token expired"));
        }

        String phone = jwtUtil.getPhoneNumberFromToken(token);
        if (phone == null || phone.isBlank()) {
            return Mono.error(new BadCredentialsException("Invalid refresh token subject"));
        }

        return refreshTokenRepository.findByToken(token)
                .switchIfEmpty(Mono.error(new BadCredentialsException("Refresh token not recognized")))
                .flatMap(stored -> {
                    if (Boolean.TRUE.equals(stored.getRevoked())) {
                        return Mono.error(new BadCredentialsException("Refresh token revoked"));
                    }
                    stored.setRevoked(true);
                    return refreshTokenRepository.save(stored)
                            .then(userRepository.findByPhoneNumber(phone))
                            .switchIfEmpty(Mono.error(new BadCredentialsException("User not found")))
                            .flatMap(this::issueTokensForUser);
                });
    }

    public Mono<Void> logout(String refreshToken) {
        String token = Objects.requireNonNull(refreshToken, "refreshToken").trim();
        if (token.toLowerCase().startsWith("bearer ")) {
            token = token.substring(7).trim();
        }

        if (token.isBlank()) {
            return Mono.error(new IllegalArgumentException("Missing token"));
        }

        return refreshTokenRepository.findByToken(token)
                .switchIfEmpty(Mono.empty())
                .flatMap(stored -> {
                    stored.setRevoked(true);
                    return refreshTokenRepository.save(stored).then();
                });
    }

    private Mono<AuthResponse> createUserAndIssueTokens(RegisterRequest request, String phone, String password, String countryCode, String preferredCurrency) {
        LocalDateTime now = LocalDateTime.now(ZoneOffset.UTC);

        String requestedPreferredLanguage = request.getPreferredLanguage();
        final String resolvedPreferredLanguage;
        if (requestedPreferredLanguage == null || requestedPreferredLanguage.isBlank()) {
            String configuredDefaultLocale = Objects.requireNonNull(defaultLocale, "bantora.i18n.default-locale").trim();
            if (configuredDefaultLocale.isBlank()) {
                return Mono.error(new IllegalStateException("bantora.i18n.default-locale must not be blank"));
            }
            resolvedPreferredLanguage = configuredDefaultLocale;
        } else {
            resolvedPreferredLanguage = requestedPreferredLanguage.trim();
        }

        return Mono.fromCallable(() -> passwordEncoder.encode(password))
                .subscribeOn(Schedulers.boundedElastic())
                .flatMap(passwordHash -> {
                    BantoraUser user = BantoraUser.builder()
                            .phoneNumber(phone)
                            .passwordHash(passwordHash)
                            .fullName(request.getFullName())
                            .email(request.getEmail())
                            .countryCode(countryCode)
                            .verified(true)
                            .enabled(true)
                            .preferredLanguage(resolvedPreferredLanguage)
                            .preferredCurrency(preferredCurrency)
                            .createdAt(now)
                            .updatedAt(now)
                            .lastLoginAt(now)
                            .build();

                    // Explicit INSERT (R2dbcRepository.save may attempt UPDATE when @Id is non-null)
                    return entityTemplate.insert(Objects.requireNonNull(user, "user"))
                            .flatMap(saved -> issueTokensForUser(Objects.requireNonNull(saved, "savedUser")));
                });
    }

    private Mono<AuthResponse> issueTokensForUser(BantoraUser user) {
        String phone = Objects.requireNonNull(user.getPhoneNumber(), "user.phoneNumber");

        String accessToken = jwtUtil.generateAccessToken(phone, DEFAULT_ROLES);
        Instant accessExpiresAt = jwtUtil.getExpirationFromToken(accessToken);
        if (accessExpiresAt == null) {
            return Mono.error(new IllegalStateException("Access token expiration missing"));
        }

        String refreshToken = jwtUtil.generateRefreshToken(phone);
        Instant refreshExpiresAt = jwtUtil.getExpirationFromToken(refreshToken);
        if (refreshExpiresAt == null) {
            return Mono.error(new IllegalStateException("Refresh token expiration missing"));
        }

        BantoraRefreshToken refreshEntity = BantoraRefreshToken.builder()
                .id(UUID.randomUUID())
                .token(refreshToken)
                .userPhone(phone)
                .expiresAt(LocalDateTime.ofInstant(refreshExpiresAt, ZoneOffset.UTC))
                .revoked(false)
                .createdAt(LocalDateTime.now(ZoneOffset.UTC))
                .build();

        // Explicit INSERT (R2dbcRepository.save may attempt UPDATE when @Id is non-null)
        return entityTemplate.insert(Objects.requireNonNull(refreshEntity, "refreshEntity"))
                .thenReturn(AuthResponse.builder()
                        .accessToken(accessToken)
                        .refreshToken(refreshToken)
                        .expiresAt(accessExpiresAt)
                        .user(AuthResponse.UserInfo.builder()
                                .phoneNumber(phone)
                                .fullName(user.getFullName())
                                .countryCode(user.getCountryCode())
                                .roles(DEFAULT_ROLES)
                                .preferredLanguage(user.getPreferredLanguage())
                                .preferredCurrency(user.getPreferredCurrency())
                                .build())
                        .build());
    }
}
