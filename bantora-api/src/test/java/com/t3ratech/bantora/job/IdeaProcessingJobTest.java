package com.t3ratech.bantora.job;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.t3ratech.bantora.service.AiService;

import reactor.core.publisher.Mono;

@ExtendWith(MockitoExtension.class)
class IdeaProcessingJobTest {

    @Mock
    private AiService aiService;

    @InjectMocks
    private IdeaProcessingJob ideaProcessingJob;

    @Test
    void onStartup_ShouldTriggerProcessing() {
        when(aiService.processTopHashtags()).thenReturn(Mono.empty());
        ideaProcessingJob.onStartup();
        verify(aiService).processTopHashtags();
    }
}
