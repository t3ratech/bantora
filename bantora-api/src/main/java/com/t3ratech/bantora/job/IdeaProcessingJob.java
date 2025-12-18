/**
 * Created by Cascade AI
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025-11-30
 * Email        : tkaviya@t3ratech.co.zw
 */

package com.t3ratech.bantora.job;

import com.t3ratech.bantora.service.AiService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class IdeaProcessingJob {

    private final AiService aiService;

    @Scheduled(cron = "0 0 * * * *")
    public void processIdeasHourly() {
        log.info("Starting hourly AI idea processing job...");
        aiService.processTopHashtags()
                .doOnError(e -> log.error("Hourly AI processing failed", e))
                .subscribe();
    }

    // Run on application startup
    @EventListener(ApplicationReadyEvent.class)
    public void onStartup() {
        log.info("Application started. Running initial AI idea processing...");
        aiService.processTopHashtags()
                .doOnError(e -> log.error("Startup AI processing failed", e))
                .subscribe();
    }
}
