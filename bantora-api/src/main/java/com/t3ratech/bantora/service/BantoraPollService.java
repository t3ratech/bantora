package com.t3ratech.bantora.service;

import com.t3ratech.bantora.dto.response.BantoraPollOptionResponse;
import com.t3ratech.bantora.dto.response.BantoraPollResponse;
import com.t3ratech.bantora.entity.BantoraPoll;
import com.t3ratech.bantora.repository.BantoraPollOptionRepository;
import com.t3ratech.bantora.repository.BantoraPollRepository;
import com.t3ratech.bantora.repository.BantoraPollSourceIdeaReadRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class BantoraPollService {

        private final BantoraPollRepository pollRepository;
        private final BantoraPollOptionRepository optionRepository;
        private final BantoraPollSourceIdeaReadRepository pollSourceIdeaReadRepository;

        public Flux<BantoraPollResponse> getAllActivePolls() {
                return getActivePolls(null, null, "created", null);
        }

        public Flux<BantoraPollResponse> getPopularPolls() {
                return getActivePolls(null, null, "votes", 10);
        }

        public Flux<BantoraPollResponse> getActivePolls(
                        UUID categoryId,
                        String hashtag,
                        String sort,
                        Integer limit
        ) {
                final LocalDateTime now = LocalDateTime.now();
                final boolean sortByVotes = "votes".equalsIgnoreCase(sort);

                Flux<BantoraPoll> polls;
                if (categoryId != null && hashtag != null && !hashtag.isBlank()) {
                        polls = sortByVotes
                                        ? pollRepository.findActiveByCategoryIdAndHashtagOrderByVotesDesc(categoryId, hashtag, now)
                                        : pollRepository.findActiveByCategoryIdAndHashtagOrderByCreatedDesc(categoryId, hashtag, now);
                } else if (categoryId != null) {
                        polls = sortByVotes
                                        ? pollRepository.findActiveByCategoryIdOrderByVotesDesc(categoryId, now)
                                        : pollRepository.findActiveByCategoryIdOrderByCreatedDesc(categoryId, now);
                } else if (hashtag != null && !hashtag.isBlank()) {
                        polls = sortByVotes
                                        ? pollRepository.findActiveByHashtagOrderByVotesDesc(hashtag, now)
                                        : pollRepository.findActiveByHashtagOrderByCreatedDesc(hashtag, now);
                } else {
                        polls = sortByVotes
                                        ? pollRepository.findActiveOrderByVotesDesc(now)
                                        : pollRepository.findActiveOrderByCreatedDesc(now);
                }

                if (limit != null) {
                        polls = polls.take(Math.max(0, limit));
                }

                return polls.flatMap(this::toResponse);
        }

        public Mono<BantoraPollResponse> getPollById(UUID id) {
                return pollRepository.findById(Objects.requireNonNull(id, "id"))
                                .flatMap(this::toResponse);
        }

        public Flux<UUID> getSourceIdeaIdsForPoll(UUID pollId) {
                return pollSourceIdeaReadRepository.findIdeaIdsByPollId(Objects.requireNonNull(pollId, "pollId"));
        }

        public Flux<BantoraPollResponse> getPollsBySourceIdeaId(UUID ideaId) {
                return pollSourceIdeaReadRepository.findPollIdsByIdeaId(Objects.requireNonNull(ideaId, "ideaId"))
                        .concatMap(this::getPollById);
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
                                                .categoryId(poll.getCategoryId())
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
