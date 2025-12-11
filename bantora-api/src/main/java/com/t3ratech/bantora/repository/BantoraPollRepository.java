package com.t3ratech.bantora.repository;

import com.t3ratech.bantora.entity.BantoraPoll;
import com.t3ratech.bantora.enums.BantoraPollStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface BantoraPollRepository extends JpaRepository<BantoraPoll, UUID> {
    List<BantoraPoll> findByStatus(BantoraPollStatus status);

    List<BantoraPoll> findByCreatorPhone(String creatorPhone);

    @Query("SELECT p FROM BantoraPoll p WHERE p.status = 'ACTIVE' AND p.endTime > :now ORDER BY p.totalVotes DESC")
    List<BantoraPoll> findActiveOrderByVotesDesc(LocalDateTime now);

    @Query("SELECT p FROM BantoraPoll p WHERE p.status = 'ACTIVE' AND p.endTime > :now ORDER BY p.createdAt DESC")
    List<BantoraPoll> findActiveOrderByCreatedDesc(LocalDateTime now);
}
