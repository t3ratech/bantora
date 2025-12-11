package com.t3ratech.bantora.service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.t3ratech.bantora.dto.response.BantoraPollOptionResponse;
import com.t3ratech.bantora.dto.response.BantoraPollResponse;
import com.t3ratech.bantora.entity.BantoraPoll;
import com.t3ratech.bantora.entity.BantoraPollOption;
import com.t3ratech.bantora.repository.BantoraPollOptionRepository;
import com.t3ratech.bantora.repository.BantoraPollRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class BantoraPollService {

    private final BantoraPollRepository pollRepository;
    private final BantoraPollOptionRepository optionRepository;

    @Transactional(readOnly = true)
    public List<BantoraPollResponse> getAllActivePolls() {
        List<BantoraPoll> polls = pollRepository.findActiveOrderByCreatedDesc(LocalDateTime.now());
        return polls.stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<BantoraPollResponse> getPopularPolls() {
        List<BantoraPoll> polls = pollRepository.findActiveOrderByVotesDesc(LocalDateTime.now());
        return polls.stream()
                .limit(10)
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public BantoraPollResponse getPollById(UUID id) {
        return pollRepository.findById(id)
                .map(this::toResponse)
                .orElse(null);
    }

    private BantoraPollResponse toResponse(BantoraPoll poll) {
        List<BantoraPollOption> options = optionRepository.findByPollIdOrderByOptionOrder(poll.getId());

        return BantoraPollResponse.builder()
                .id(poll.getId())
                .title(poll.getTitle())
                .description(poll.getDescription())
                .creatorPhone(poll.getCreatorPhone())
                .category(poll.getCategory())
                .scope(poll.getScope())
                .status(poll.getStatus())
                .startTime(poll.getStartTime())
                .endTime(poll.getEndTime())
                .totalVotes(poll.getTotalVotes())
                .options(options.stream()
                        .map(opt -> BantoraPollOptionResponse.builder()
                                .id(opt.getId())
                                .optionText(opt.getOptionText())
                                .optionOrder(opt.getOptionOrder())
                                .votesCount(opt.getVotesCount())
                                .build())
                        .collect(Collectors.toList()))
                .createdAt(poll.getCreatedAt())
                .build();
    }
}
