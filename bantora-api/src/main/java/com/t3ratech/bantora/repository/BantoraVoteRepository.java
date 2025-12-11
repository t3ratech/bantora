package com.t3ratech.bantora.repository;

import com.t3ratech.bantora.entity.BantoraVote;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface BantoraVoteRepository extends JpaRepository<BantoraVote, UUID> {
    Optional<BantoraVote> findByPollIdAndUserPhone(UUID pollId, String userPhone);

    List<BantoraVote> findByPollId(UUID pollId);

    List<BantoraVote> findByUserPhone(String userPhone);

    boolean existsByPollIdAndUserPhone(UUID pollId, String userPhone);
}
