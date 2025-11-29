/**
 * Created by Cascade AI
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025-11-28
 * Email        : tkaviya@t3ratech.co.zw
 */

package com.t3ratech.bantora.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.time.Instant;
import java.util.Base64;
import java.util.Date;
import java.util.Set;

@Component
public class JwtUtil {
    
    private final SecretKey secretKey;
    private final long accessTokenExpiration;
    private final long refreshTokenExpiration;
    private final String issuer;
    private final String audience;
    
    public JwtUtil(
            @Value("${bantora.security.jwt.secret}") String secret,
            @Value("${bantora.security.jwt.access-token.expiration-ms}") long accessTokenExpiration,
            @Value("${bantora.security.jwt.refresh-token.expiration-ms}") long refreshTokenExpiration,
            @Value("${bantora.security.jwt.issuer}") String issuer,
            @Value("${bantora.security.jwt.audience}") String audience
    ) {
        this.secretKey = Keys.hmacShaKeyFor(Base64.getDecoder().decode(secret));
        this.accessTokenExpiration = accessTokenExpiration;
        this.refreshTokenExpiration = refreshTokenExpiration;
        this.issuer = issuer;
        this.audience = audience;
    }
    
    public String generateAccessToken(String phoneNumber, Set<String> roles) {
        Instant now = Instant.now();
        Instant expiration = now.plusMillis(accessTokenExpiration);
        
        return Jwts.builder()
                .subject(phoneNumber)
                .claim("roles", String.join(",", roles))
                .claim("type", "access")
                .issuer(issuer)
                .audience().add(audience).and()
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiration))
                .signWith(secretKey)
                .compact();
    }
    
    public String generateRefreshToken(String phoneNumber) {
        Instant now = Instant.now();
        Instant expiration = now.plusMillis(refreshTokenExpiration);
        
        return Jwts.builder()
                .subject(phoneNumber)
                .claim("type", "refresh")
                .issuer(issuer)
                .audience().add(audience).and()
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiration))
                .signWith(secretKey)
                .compact();
    }
    
    public boolean validateToken(String token) {
        try {
            Jwts.parser()
                    .verifyWith(secretKey)
                    .requireIssuer(issuer)
                    .requireAudience(audience)
                    .build()
                    .parseSignedClaims(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }
    
    public String getPhoneNumberFromToken(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(secretKey)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
            return claims.getSubject();
        } catch (Exception e) {
            return null;
        }
    }
    
    public Set<String> getRolesFromToken(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(secretKey)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
            String rolesString = claims.get("roles", String.class);
            return rolesString != null ? Set.of(rolesString.split(",")) : Set.of();
        } catch (Exception e) {
            return Set.of();
        }
    }
    
    public Instant getExpirationFromToken(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(secretKey)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
            return claims.getExpiration().toInstant();
        } catch (Exception e) {
            return null;
        }
    }
}
