/**
 * Created by Cascade AI
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025-11-28
 * Email        : tkaviya@t3ratech.co.zw
 */

package com.t3ratech.bantora.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class Argon2PasswordEncoder implements PasswordEncoder {

    private final org.springframework.security.crypto.argon2.Argon2PasswordEncoder delegate;

    public Argon2PasswordEncoder(
            @Value("${bantora.security.argon2.iterations}") int iterations,
            @Value("${bantora.security.argon2.memory}") int memory,
            @Value("${bantora.security.argon2.parallelism}") int parallelism,
            @Value("${bantora.security.argon2.salt-length}") int saltLength,
            @Value("${bantora.security.argon2.hash-length}") int hashLength
    ) {
        this.delegate = new org.springframework.security.crypto.argon2.Argon2PasswordEncoder(
                saltLength,
                hashLength,
                parallelism,
                memory,
                iterations
        );
    }

    @Override
    public String encode(CharSequence rawPassword) {
        return delegate.encode(rawPassword);
    }

    @Override
    public boolean matches(CharSequence rawPassword, String encodedPassword) {
        return delegate.matches(rawPassword, encodedPassword);
    }

    @Override
    public boolean upgradeEncoding(String encodedPassword) {
        return false;
    }
}
