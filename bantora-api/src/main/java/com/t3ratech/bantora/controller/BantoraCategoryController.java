package com.t3ratech.bantora.controller;

import com.t3ratech.bantora.dto.common.ApiResponse;
import com.t3ratech.bantora.dto.response.BantoraCategoryResponse;
import com.t3ratech.bantora.entity.BantoraCategory;
import com.t3ratech.bantora.repository.BantoraCategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

import java.util.List;

@RestController
@RequestMapping("/api/v1/categories")
@RequiredArgsConstructor
public class BantoraCategoryController {

    private final BantoraCategoryRepository categoryRepository;

    @GetMapping
    public Mono<ResponseEntity<ApiResponse<List<BantoraCategoryResponse>>>> getCategories() {
        return categoryRepository.findAllByOrderByNameAsc()
                .map(this::toResponse)
                .collectList()
                .map(list -> ResponseEntity.ok(ApiResponse.success(list, "Categories retrieved")))
                .onErrorResume(e -> Mono.just(ResponseEntity.internalServerError()
                        .body(ApiResponse.error("Categories fetch failed", List.of(errorMessage(e))))));
    }

    private BantoraCategoryResponse toResponse(BantoraCategory category) {
        return BantoraCategoryResponse.builder()
                .id(category.getId())
                .name(category.getName())
                .build();
    }

    private String errorMessage(Throwable e) {
        String msg = e.getMessage();
        return (msg == null || msg.isBlank()) ? e.getClass().getName() : msg;
    }
}
