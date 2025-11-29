/**
 * Created by Cascade AI
 * Author       : Tsungai Kaviya
 * Copyright    : TeraTech Solutions (Pvt) Ltd
 * Date/Time    : 2025-11-28
 * Email        : tkaviya@t3ratech.co.zw
 */

package com.t3ratech.bantora.security;

import de.mkammerer.argon2.Argon2;
import de.mkammerer.argon2.Argon2Factory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class Argon2PasswordEncoder implements PasswordEncoder {
    
    private final int iterations;
    private final int memory;
    private final int parallelism;
    private final Argon2 argon2;
    
    public Argon2PasswordEncoder(
            @Value("${bantora.security.argon2.iterations}") int iterations,
            @Value("${bantora.security.argon2.memory}") int memory,
            @Value("${bantora.security.argon2.parallelism}") int parallelism,
            @Value("${bantora.security.argon2.salt-length}") int saltLength,
            @Value("${bantora.security.argon2.hash-length}") int hashLength
    ) {
        this.iterations = iterations;
        this.memory = memory;
        this.parallelism = parallelism;
        this.argon2 = Argon2Factory.create(
            Argon2Factory.Argon2Types.ARGON2id,
            saltLength,
            hashLength
        );
    }
    
    @Override
    public String encode(CharSequence rawPassword) {
        return argon2.hash(iterations, memory, parallelism, rawPassword.toString().toCharArray());
    }
    
    @Override
    public boolean matches(CharSequence rawPassword, String encodedPassword) {
        try {
            return argon2.verify(encodedPassword, rawPassword.toString().toCharArray());
        } catch (Exception e) {
            return false;
        }
    }
    
    @Override
    public boolean upgradeEncoding(String encodedPassword) {
        return false;
    }
}
