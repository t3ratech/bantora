package com.t3ratech.bantora.dto.response;

import com.t3ratech.bantora.enums.BantoraPollScope;
import com.t3ratech.bantora.enums.BantoraPollStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BantoraPollResponse {
    private UUID id;
    private String title;
    private String description;
    private String creatorPhone;
    private UUID categoryId;
    private BantoraPollScope scope;
    private BantoraPollStatus status;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private Long totalVotes;
    private List<BantoraPollOptionResponse> options;
    private LocalDateTime createdAt;
}
