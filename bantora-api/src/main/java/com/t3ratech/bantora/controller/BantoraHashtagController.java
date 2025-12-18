package com.t3ratech.bantora.controller;

import com.t3ratech.bantora.dto.common.ApiResponse;
import com.t3ratech.bantora.dto.response.BantoraHashtagResponse;
import com.t3ratech.bantora.entity.BantoraHashtag;
import com.t3ratech.bantora.repository.BantoraHashtagRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

import java.util.List;

@RestController
@RequestMapping("/api/v1/hashtags")
@RequiredArgsConstructor
public class BantoraHashtagController {

    private final BantoraHashtagRepository hashtagRepository;

    @GetMapping
    public Mono<ResponseEntity<ApiResponse<List<BantoraHashtagResponse>>>> getHashtags() {
        return hashtagRepository.findAllByOrderByTagAsc()
                .map(this::toResponse)
                .collectList()
                .map(list -> ResponseEntity.ok(ApiResponse.success(list, "Hashtags retrieved")))
                .onErrorResume(e -> Mono.just(ResponseEntity.internalServerError()
                        .body(ApiResponse.error("Hashtags fetch failed", List.of(errorMessage(e))))));
    }

    private BantoraHashtagResponse toResponse(BantoraHashtag hashtag) {
        return BantoraHashtagResponse.builder()
                .id(hashtag.getId())
                .tag(hashtag.getTag())
                .build();
    }

    private String errorMessage(Throwable e) {
        String msg = e.getMessage();
        return (msg == null || msg.isBlank()) ? e.getClass().getName() : msg;
    }
}
