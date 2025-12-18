package com.t3ratech.bantora.controller;

import com.t3ratech.bantora.dto.common.ApiResponse;
import com.t3ratech.bantora.dto.response.BantoraCountryResponse;
import com.t3ratech.bantora.entity.BantoraCountry;
import com.t3ratech.bantora.repository.BantoraCountryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Locale;

@RestController
@RequestMapping("/api/v1/countries")
@RequiredArgsConstructor
public class BantoraCountryController {

    private final BantoraCountryRepository countryRepository;

    @GetMapping
    public Mono<ResponseEntity<ApiResponse<List<BantoraCountryResponse>>>> getCountries(
            @RequestParam(name = "q", required = false) String q
    ) {
        if (q == null || q.isBlank()) {
            return countryRepository.findByRegistrationEnabledTrueOrderByNameAsc()
                    .map(this::toResponse)
                    .collectList()
                    .map(list -> ResponseEntity.ok(ApiResponse.success(list, "Countries retrieved")))
                    .onErrorResume(e -> Mono.just(ResponseEntity.internalServerError()
                            .body(ApiResponse.error("Countries fetch failed", List.of(errorMessage(e))))));
        }

        return countryRepository.searchEnabledByQuery(q.trim())
                .map(this::toResponse)
                .collectList()
                .map(list -> ResponseEntity.ok(ApiResponse.success(list, "Countries retrieved")))
                .onErrorResume(e -> Mono.just(ResponseEntity.internalServerError()
                        .body(ApiResponse.error("Countries fetch failed", List.of(errorMessage(e))))));
    }

    private BantoraCountryResponse toResponse(BantoraCountry country) {
        final String languageCode = country.getDefaultLanguage();
        final Locale locale = Locale.forLanguageTag(languageCode);
        String languageName = locale.getDisplayLanguage(locale);
        if (languageName == null || languageName.isBlank()) {
            languageName = languageCode;
        }

        return BantoraCountryResponse.builder()
                .code(country.getCode())
                .name(country.getName())
                .callingCode(country.getCallingCode())
                .currency(country.getCurrency())
                .defaultLanguage(country.getDefaultLanguage())
                .defaultLanguageName(languageName)
                .build();
    }

    private String errorMessage(Throwable e) {
        String msg = e.getMessage();
        return (msg == null || msg.isBlank()) ? e.getClass().getName() : msg;
    }
}
