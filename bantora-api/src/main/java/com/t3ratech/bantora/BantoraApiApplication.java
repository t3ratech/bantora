package com.t3ratech.bantora;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.data.jpa.JpaRepositoriesAutoConfiguration;
import org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration;
import org.springframework.data.r2dbc.repository.config.EnableR2dbcRepositories;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication(exclude = { JpaRepositoriesAutoConfiguration.class, HibernateJpaAutoConfiguration.class })
@EnableScheduling
@EnableR2dbcRepositories(basePackages = { "com.t3ratech.bantora.repository" })
public class BantoraApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(BantoraApiApplication.class, args);
    }
}
