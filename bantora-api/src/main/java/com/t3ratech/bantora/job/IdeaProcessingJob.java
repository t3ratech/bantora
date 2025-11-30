/**
 * Created by Cascade AI
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025-11-30
 * Email        : tkaviya@t3ratech.co.zw
 */

package com.t3ratech.bantora.job;

import com.t3ratech.bantora.persistence.entity.Idea;
import com.t3ratech.bantora.persistence.repository.IdeaRepository;
import com.t3ratech.bantora.service.AiService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;

@Component
@RequiredArgsConstructor
@Slf4j
public class IdeaProcessingJob {

    private final IdeaRepository ideaRepository;
    private final AiService aiService;

    // Run once a day at midnight
    @Scheduled(cron = "0 0 0 * * *")
    public void processIdeasDaily() {
        log.info("Starting daily idea processing job...");
        processPendingIdeas().subscribe();
    }

    // Run on application startup
    @EventListener(ApplicationReadyEvent.class)
    public void onStartup() {
        log.info("Application started. Checking for pending ideas...");
        processPendingIdeas().subscribe();
    }

    private Flux<Void> processPendingIdeas() {
        return ideaRepository.findByStatus(Idea.IdeaStatus.PENDING)
                .flatMap(idea -> {
                    log.info("Processing idea: {}", idea.getId());
                    return aiService.processIdea(idea)
                            .doOnError(e -> log.error("Failed to process idea: {}", idea.getId(), e));
                });
    }
}
