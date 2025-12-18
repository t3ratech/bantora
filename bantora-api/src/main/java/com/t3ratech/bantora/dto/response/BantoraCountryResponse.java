package com.t3ratech.bantora.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BantoraCountryResponse {
    private String code;
    private String name;
    private String callingCode;
    private String currency;
    private String defaultLanguage;
    private String defaultLanguageName;
}
