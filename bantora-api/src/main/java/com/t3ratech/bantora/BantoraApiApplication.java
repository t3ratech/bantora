/**
 * Created by Cascade AI
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025-11-28
 * Email        : tkaviya@t3ratech.co.zw
 */

package com.t3ratech.bantora;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.data.r2dbc.repository.config.EnableR2dbcRepositories;

@SpringBootApplication
@EnableScheduling
@EnableR2dbcRepositories(basePackages = "com.t3ratech.bantora.persistence.repository")
@EnableJpaRepositories(basePackages = "com.t3ratech.bantora.repository")
public class BantoraApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(BantoraApiApplication.class, args);
    }
}
