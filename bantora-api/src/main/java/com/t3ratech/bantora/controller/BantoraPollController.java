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
import lombok.RequiredArgsConstructor;
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
    public Mono<Map<String, Object>> createIdea(@RequestBody Map<String, String> request) {
        String content = request.get("content");
        String userPhone = request.getOrDefault("userPhone", "+263785107830");

        return ideaService.createIdea(userPhone, content)
                .map(idea -> Map.of(
                        "success", true,
                        "data", idea,
                        "timestamp", Instant.now().toString()));
    }
}
