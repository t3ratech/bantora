/**
 * Created by Cascade AI
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025-12-11
 * Email        : tkaviya@t3ratech.co.zw
 */

package com.t3ratech.bantora.controller;

import com.t3ratech.bantora.dto.response.BantoraIdeaResponse;
import com.t3ratech.bantora.service.BantoraIdeaService;
import com.t3ratech.bantora.service.BantoraPollService;
import com.t3ratech.bantora.service.BantoraVoteService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class BantoraPollController {

    private final BantoraPollService pollService;
    private final BantoraIdeaService ideaService;
    private final BantoraVoteService voteService;

    @GetMapping("/polls")
    public Mono<Map<String, Object>> getPolls() {
        return pollService.getAllActivePolls()
                .collectList()
                .map(polls -> Map.of(
                        "success", true,
                        "data", polls,
                        "timestamp", Instant.now().toString()));
    }

    @GetMapping("/polls/{id}")
    public Mono<Map<String, Object>> getPoll(@PathVariable UUID id) {
        return pollService.getPollById(id)
                .map(poll -> Map.of(
                        "success", true,
                        "data", poll,
                        "timestamp", Instant.now().toString()))
                .switchIfEmpty(Mono.just(Map.of(
                        "success", false,
                        "error", "Poll not found",
                        "timestamp", Instant.now().toString())));
    }

    @GetMapping("/polls/popular")
    public Mono<Map<String, Object>> getPopularPolls() {
        return pollService.getPopularPolls()
                .collectList()
                .map(polls -> Map.of(
                        "success", true,
                        "data", polls,
                        "timestamp", Instant.now().toString()));
    }

    @GetMapping("/ideas")
    public Mono<Map<String, Object>> getIdeas(@RequestParam(defaultValue = "PENDING") String status) {
        Flux<BantoraIdeaResponse> ideas;

        if ("PROCESSED".equalsIgnoreCase(status)) {
            ideas = ideaService.getProcessedIdeas();
        } else {
            ideas = ideaService.getPendingIdeas();
        }

        return ideas.collectList()
                .map(list -> Map.of(
                        "success", true,
                        "data", list,
                        "timestamp", Instant.now().toString()));
    }

    @PostMapping("/ideas")
    public Mono<Map<String, Object>> createIdea(@RequestBody Map<String, String> request, Authentication authentication) {
        String content = request.get("content");
        if (authentication == null || authentication.getName() == null || authentication.getName().isBlank()) {
            return Mono.just(Map.of(
                    "success", false,
                    "error", "Unauthorized",
                    "timestamp", Instant.now().toString()));
        }
        String userPhone = authentication.getName();

        if (content == null || content.isBlank()) {
            return Mono.just(Map.of(
                    "success", false,
                    "error", "Missing required field: content",
                    "timestamp", Instant.now().toString()));
        }

        return ideaService.createIdea(userPhone, content)
                .map(idea -> Map.of(
                        "success", true,
                        "data", idea,
                        "timestamp", Instant.now().toString()));
    }

    @PostMapping("/ideas/{id}/upvote")
    public Mono<Map<String, Object>> upvoteIdea(@PathVariable UUID id, Authentication authentication) {
        if (authentication == null || authentication.getName() == null || authentication.getName().isBlank()) {
            return Mono.just(Map.of(
                    "success", false,
                    "error", "Unauthorized",
                    "timestamp", Instant.now().toString()));
        }
        return ideaService.upvoteIdea(id)
                .map(idea -> Map.of(
                        "success", true,
                        "data", idea,
                        "timestamp", Instant.now().toString()))
                .onErrorResume(e -> Mono.just(Map.of(
                        "success", false,
                        "error", e.getMessage() == null ? "Upvote failed" : e.getMessage(),
                        "timestamp", Instant.now().toString())));
    }

    @PostMapping("/votes")
    public Mono<Map<String, Object>> submitVote(
            @RequestBody Map<String, Object> request,
            ServerHttpRequest httpRequest,
            Authentication authentication
    ) {
        if (authentication == null || authentication.getName() == null || authentication.getName().isBlank()) {
            return Mono.just(Map.of(
                    "success", false,
                    "error", "Unauthorized",
                    "timestamp", Instant.now().toString()));
        }
        Object pollIdRaw = request.get("pollId");
        Object optionIdRaw = request.get("optionId");

        if (!(pollIdRaw instanceof String) || ((String) pollIdRaw).isBlank()) {
            return Mono.just(Map.of(
                    "success", false,
                    "error", "Missing required field: pollId",
                    "timestamp", Instant.now().toString()));
        }

        if (!(optionIdRaw instanceof String) || ((String) optionIdRaw).isBlank()) {
            return Mono.just(Map.of(
                    "success", false,
                    "error", "Missing required field: optionId",
                    "timestamp", Instant.now().toString()));
        }

        String userPhone = authentication.getName();
        boolean anonymous = false;

        String xForwardedFor = httpRequest.getHeaders().getFirst("X-Forwarded-For");
        var remoteAddress = httpRequest.getRemoteAddress();
        String ipAddress = null;
        if (xForwardedFor != null && !xForwardedFor.isBlank()) {
            ipAddress = xForwardedFor.split(",")[0].trim();
        } else if (remoteAddress != null && remoteAddress.getAddress() != null) {
            ipAddress = remoteAddress.getAddress().getHostAddress();
        }

        String userAgent = httpRequest.getHeaders().getFirst("User-Agent");

        UUID pollId;
        UUID optionId;
        try {
            pollId = UUID.fromString((String) pollIdRaw);
            optionId = UUID.fromString((String) optionIdRaw);
        } catch (IllegalArgumentException e) {
            return Mono.just(Map.of(
                    "success", false,
                    "error", "Invalid pollId or optionId",
                    "timestamp", Instant.now().toString()));
        }

        return voteService.submitVote(pollId, optionId, userPhone, anonymous, ipAddress, userAgent)
                .map(updatedPoll -> Map.of(
                        "success", true,
                        "data", updatedPoll,
                        "timestamp", Instant.now().toString()))
                .onErrorResume(e -> Mono.just(Map.of(
                        "success", false,
                        "error", e.getMessage() == null ? "Vote failed" : e.getMessage(),
                        "timestamp", Instant.now().toString())));
    }
}
