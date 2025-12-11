package com.t3ratech.bantora.service;

import com.t3ratech.bantora.dto.response.BantoraPollOptionResponse;
import com.t3ratech.bantora.dto.response.BantoraPollResponse;
import com.t3ratech.bantora.entity.BantoraPoll;
import com.t3ratech.bantora.repository.BantoraPollOptionRepository;
import com.t3ratech.bantora.repository.BantoraPollRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class BantoraPollService {

        private final BantoraPollRepository pollRepository;
        private final BantoraPollOptionRepository optionRepository;

        public Flux<BantoraPollResponse> getAllActivePolls() {
                return pollRepository.findActiveOrderByCreatedDesc(LocalDateTime.now())
                                .flatMap(this::toResponse);
        }

        public Flux<BantoraPollResponse> getPopularPolls() {
                return pollRepository.findActiveOrderByVotesDesc(LocalDateTime.now())
                                .take(10)
                                .flatMap(this::toResponse);
        }

        public Mono<BantoraPollResponse> getPollById(UUID id) {
                return pollRepository.findById(id)
                                .flatMap(this::toResponse);
        }

        private Mono<BantoraPollResponse> toResponse(BantoraPoll poll) {
                return optionRepository.findByPollIdOrderByOptionOrder(poll.getId())
                                .map(opt -> BantoraPollOptionResponse.builder()
                                                .id(opt.getId())
                                                .optionText(opt.getOptionText())
                                                .optionOrder(opt.getOptionOrder())
                                                .votesCount(opt.getVotesCount())
                                                .build())
                                .collectList()
                                .map(options -> BantoraPollResponse.builder()
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
                                                .options(options)
                                                .createdAt(poll.getCreatedAt())
                                                .build());
        }
}
