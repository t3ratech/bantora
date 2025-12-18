package com.t3ratech.bantora.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BantoraCreateIdeaRequest {
    private String content;
    private UUID categoryId;
    private List<String> hashtags;
}
