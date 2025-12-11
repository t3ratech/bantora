package com.t3ratech.bantora.dto.response;

import com.t3ratech.bantora.enums.BantoraIdeaStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BantoraIdeaResponse {
    private UUID id;
    private String userPhone;
    private String content;
    private BantoraIdeaStatus status;
    private String aiSummary;
    private LocalDateTime createdAt;
    private Long upvotes;
}
