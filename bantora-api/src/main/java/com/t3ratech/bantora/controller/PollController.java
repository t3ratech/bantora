/**
 * Created by Cascade AI
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025-11-28
 * Email        : tkaviya@t3ratech.co.zw
 */

package com.t3ratech.bantora.controller;

import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Mono;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class PollController {
    
    @GetMapping("/polls")
    public Mono<Map<String, Object>> getPolls() {
        // Return mock data for now
        List<Map<String, Object>> polls = new ArrayList<>();
        
        // Mock poll 1
        Map<String, Object> poll1 = Map.of(
            "id", UUID.randomUUID().toString(),
            "title", "Best African Music Artist 2025",
            "description", "Vote for your favorite African music artist of the year",
            "creatorPhone", "+263771234567",
            "scope", "CONTINENTAL",
            "status", "ACTIVE",
            "createdAt", Instant.now().toString(),
            "options", List.of(
                Map.of("id", UUID.randomUUID().toString(), "pollId", "1", "optionText", "Burna Boy", "optionOrder", 1, "votesCount", 45),
                Map.of("id", UUID.randomUUID().toString(), "pollId", "1", "optionText", "Wizkid", "optionOrder", 2, "votesCount", 38),
                Map.of("id", UUID.randomUUID().toString(), "pollId", "1", "optionText", "Diamond Platnumz", "optionOrder", 3, "votesCount", 29)
            )
        );
        
        polls.add(poll1);
        
        return Mono.just(Map.of(
            "success", true,
            "data", polls,
            "timestamp", Instant.now().toString()
        ));
    }
    
    @GetMapping("/polls/{id}")
    public Mono<Map<String, Object>> getPoll(@PathVariable String id) {
        // Return mock poll
        Map<String, Object> poll = Map.of(
            "id", id,
            "title", "Best African Music Artist 2025",
            "description", "Vote for your favorite African music artist of the year. This poll determines the most popular artist across the African continent.",
            "creatorPhone", "+263771234567",
            "scope", "CONTINENTAL",
            "status", "ACTIVE",
            "createdAt", Instant.now().minusSeconds(3600).toString(),
            "options", List.of(
                Map.of("id", UUID.randomUUID().toString(), "pollId", id, "optionText", "Burna Boy", "optionOrder", 1, "votesCount", 45),
                Map.of("id", UUID.randomUUID().toString(), "pollId", id, "optionText", "Wizkid", "optionOrder", 2, "votesCount", 38),
                Map.of("id", UUID.randomUUID().toString(), "pollId", id, "optionText", "Diamond Platnumz", "optionOrder", 3, "votesCount", 29)
            )
        );
        
        return Mono.just(Map.of(
            "success", true,
            "data", poll,
            "timestamp", Instant.now().toString()
        ));
    }
    
    @PostMapping("/polls")
    public Mono<Map<String, Object>> createPoll(@RequestBody Map<String, Object> request) {
        // Return mock created poll
        String pollId = UUID.randomUUID().toString();
        List<Map<String, Object>> options = new ArrayList<>();
        
        @SuppressWarnings("unchecked")
        List<String> requestOptions = (List<String>) request.get("options");
        for (int i = 0; i < requestOptions.size(); i++) {
            options.add(Map.of(
                "id", UUID.randomUUID().toString(),
                "pollId", pollId,
                "optionText", requestOptions.get(i),
                "optionOrder", i + 1,
                "votesCount", 0
            ));
        }
        
        Map<String, Object> poll = Map.of(
            "id", pollId,
            "title", request.get("title").toString(),
            "description", request.get("description").toString(),
            "creatorPhone", "+263771234567",
            "scope", request.get("scope").toString(),
            "status", "PENDING",
            "createdAt", Instant.now().toString(),
            "options", options
        );
        
        return Mono.just(Map.of(
            "success", true,
            "data", poll,
            "message", "Poll created successfully",
            "timestamp", Instant.now().toString()
        ));
    }
    
    @PostMapping("/votes")
    public Mono<Map<String, Object>> vote(@RequestBody Map<String, Object> request) {
        return Mono.just(Map.of(
            "success", true,
            "message", "Vote recorded successfully",
            "data", Map.of(
                "voteId", UUID.randomUUID().toString(),
                "pollId", request.get("pollId"),
                "optionId", request.get("optionId"),
                "timestamp", Instant.now().toString()
            ),
            "timestamp", Instant.now().toString()
        ));
    }
}
