package com.t3ratech.bantora.security;

import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.ReactiveAuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

public class JwtReactiveAuthenticationManager implements ReactiveAuthenticationManager {

    private final JwtUtil jwtUtil;

    public JwtReactiveAuthenticationManager(JwtUtil jwtUtil) {
        this.jwtUtil = jwtUtil;
    }

    @Override
    public Mono<Authentication> authenticate(Authentication authentication) {
        if (authentication == null || authentication.getCredentials() == null) {
            return Mono.empty();
        }

        String token = authentication.getCredentials().toString();
        if (token.isBlank()) {
            return Mono.empty();
        }

        if (!jwtUtil.validateToken(token)) {
            return Mono.error(new BadCredentialsException("Invalid token"));
        }

        String type = jwtUtil.getTokenType(token);
        if (type == null || !"access".equalsIgnoreCase(type)) {
            return Mono.error(new BadCredentialsException("Invalid token type"));
        }

        String phoneNumber = jwtUtil.getPhoneNumberFromToken(token);
        if (phoneNumber == null || phoneNumber.isBlank()) {
            return Mono.error(new BadCredentialsException("Invalid token subject"));
        }

        Set<String> roles = jwtUtil.getRolesFromToken(token);
        List<GrantedAuthority> authorities = roles.stream()
                .filter(r -> r != null && !r.isBlank())
                .map(SimpleGrantedAuthority::new)
                .collect(Collectors.toList());

        return Mono.just(new UsernamePasswordAuthenticationToken(phoneNumber, token, authorities));
    }
}
