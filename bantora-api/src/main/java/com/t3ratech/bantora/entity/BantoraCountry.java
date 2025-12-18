package com.t3ratech.bantora.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;

import java.time.LocalDateTime;

@Table("bantora_country")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BantoraCountry {

    @Id
    private String code;

    @Column("name")
    private String name;

    @Column("calling_code")
    private String callingCode;

    @Column("currency")
    private String currency;

    @Column("default_language")
    private String defaultLanguage;

    @Column("registration_enabled")
    private Boolean registrationEnabled;

    @Column("created_at")
    private LocalDateTime createdAt;

    @Column("updated_at")
    private LocalDateTime updatedAt;
}
