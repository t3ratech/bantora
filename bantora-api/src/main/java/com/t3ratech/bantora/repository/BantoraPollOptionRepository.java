package com.t3ratech.bantora.repository;

import com.t3ratech.bantora.entity.BantoraPollOption;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface BantoraPollOptionRepository extends JpaRepository<BantoraPollOption, UUID> {
    List<BantoraPollOption> findByPollIdOrderByOptionOrder(UUID pollId);
}
