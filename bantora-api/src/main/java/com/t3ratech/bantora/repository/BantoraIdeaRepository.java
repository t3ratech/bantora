package com.t3ratech.bantora.repository;

import com.t3ratech.bantora.entity.BantoraIdea;
import com.t3ratech.bantora.enums.BantoraIdeaStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface BantoraIdeaRepository extends JpaRepository<BantoraIdea, UUID> {
    List<BantoraIdea> findByStatus(BantoraIdeaStatus status);

    List<BantoraIdea> findByUserPhone(String userPhone);

    List<BantoraIdea> findByStatusOrderByCreatedAtDesc(BantoraIdeaStatus status);

    List<BantoraIdea> findAllByOrderByUpvotesDesc();
}
