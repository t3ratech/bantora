/**
 * Created by Cascade AI
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025-12-11
 * Email        : tkaviya@t3ratech.co.zw
 */

package com.t3ratech.bantora.controller;

import com.t3ratech.bantora.dto.response.BantoraIdeaResponse;
import com.t3ratech.bantora.dto.response.BantoraPollResponse;
import com.t3ratech.bantora.service.BantoraIdeaService;
import com.t3ratech.bantora.service.BantoraPollService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
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
    public Map<String, Object> getPolls() {
        List<BantoraPollResponse> polls = pollService.getAllActivePolls();

        return Map.of(
                "success", true,
                "data", polls,
                "timestamp", Instant.now().toString());
    }

    @GetMapping("/polls/{id}")
    public Map<String, Object> getPoll(@PathVariable UUID id) {
        BantoraPollResponse poll = pollService.getPollById(id);

        if (poll == null) {
            return Map.of(
                    "success", false,
                    "error", "Poll not found",
                    "timestamp", Instant.now().toString());
        }

        return Map.of(
                "success", true,
                "data", poll,
                "timestamp", Instant.now().toString());
    }

    @GetMapping("/polls/popular")
    public Map<String, Object> getPopularPolls() {
        List<BantoraPollResponse> polls = pollService.getPopularPolls();

        return Map.of(
                "success", true,
                "data", polls,
                "timestamp", Instant.now().toString());
    }

    @GetMapping("/ideas")
    public Map<String, Object> getIdeas(@RequestParam(defaultValue = "PENDING") String status) {
        List<BantoraIdeaResponse> ideas;

        if ("PROCESSED".equalsIgnoreCase(status)) {
            ideas = ideaService.getProcessedIdeas();
        } else {
            ideas = ideaService.getPendingIdeas();
        }

        return Map.of(
                "success", true,
                "data", ideas,
                "timestamp", Instant.now().toString());
    }

    @PostMapping("/ideas")
    public Map<String, Object> createIdea(@RequestBody Map<String, String> request) {
        String content = request.get("content");
        String userPhone = request.getOrDefault("userPhone", "+263785107830"); // Default for now

        BantoraIdeaResponse idea = ideaService.createIdea(userPhone, content);

        return Map.of(
                "success", true,
                "data", idea,
                "timestamp", Instant.now().toString());
    }
}
