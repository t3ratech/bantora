package com.t3ratech.bantora.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BantoraPollOptionResponse {
    private UUID id;
    private String optionText;
    private Integer optionOrder;
    private Long votesCount;
}
