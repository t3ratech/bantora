package com.t3ratech.bantora.repository;

import com.t3ratech.bantora.entity.BantoraCountry;
import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.r2dbc.repository.R2dbcRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Repository
public interface BantoraCountryRepository extends R2dbcRepository<BantoraCountry, String> {

    Mono<BantoraCountry> findByCodeAndRegistrationEnabledTrue(String code);

    Flux<BantoraCountry> findByRegistrationEnabledTrueOrderByNameAsc();

    @Query("SELECT * FROM bantora_country WHERE registration_enabled = TRUE AND (code ILIKE '%'||:q||'%' OR name ILIKE '%'||:q||'%') ORDER BY name ASC")
    Flux<BantoraCountry> searchEnabledByQuery(String q);
}
