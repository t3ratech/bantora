package com.t3ratech.bantora.ui.config;

import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.r2dbc.repository.config.EnableR2dbcRepositories;

@Configuration
@EnableAutoConfiguration
@EnableR2dbcRepositories(basePackages = "com.t3ratech.bantora.persistence.repository")
@EntityScan(basePackages = "com.t3ratech.bantora.persistence.entity")
@ComponentScan(basePackages = {
        "com.t3ratech.bantora.persistence",
        "com.t3ratech.bantora.service" // If needed
})
public class PlaywrightTestConfig {
}
