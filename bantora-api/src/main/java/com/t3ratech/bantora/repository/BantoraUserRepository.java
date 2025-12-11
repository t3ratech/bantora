package com.t3ratech.bantora.repository;

import com.t3ratech.bantora.entity.BantoraUser;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface BantoraUserRepository extends JpaRepository<BantoraUser, String> {
    Optional<BantoraUser> findByPhoneNumber(String phoneNumber);

    Optional<BantoraUser> findByEmail(String email);

    boolean existsByPhoneNumber(String phoneNumber);

    boolean existsByEmail(String email);
}
