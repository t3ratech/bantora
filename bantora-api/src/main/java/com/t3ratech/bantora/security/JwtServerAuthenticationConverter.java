package com.t3ratech.bantora.security;

import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.web.server.authentication.ServerAuthenticationConverter;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

public class JwtServerAuthenticationConverter implements ServerAuthenticationConverter {

    @Override
    public Mono<Authentication> convert(ServerWebExchange exchange) {
        String header = exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
        if (header == null || header.isBlank()) {
            return Mono.empty();
        }

        String token = header;
        if (header.toLowerCase().startsWith("bearer ")) {
            token = header.substring(7).trim();
        }

        if (token.isBlank()) {
            return Mono.empty();
        }

        return Mono.just(new UsernamePasswordAuthenticationToken(token, token));
    }
}
