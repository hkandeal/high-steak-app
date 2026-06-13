package com.highsteak.api.service;

import com.highsteak.api.domain.ReviewTag;
import com.highsteak.api.domain.TagSentiment;
import com.highsteak.api.dto.PostDtos;
import com.highsteak.api.repository.ReviewTagRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ReviewTagService {

    private final ReviewTagRepository reviewTagRepository;

    @Transactional(readOnly = true)
    public PostDtos.ReviewTagCatalog getCatalog() {
        List<PostDtos.ReviewTagSummary> positive = new ArrayList<>();
        List<PostDtos.ReviewTagSummary> negative = new ArrayList<>();

        for (ReviewTag tag : reviewTagRepository.findByActiveTrueOrderBySortOrderAsc()) {
            PostDtos.ReviewTagSummary summary = toSummary(tag);
            if (tag.getSentiment() == TagSentiment.POSITIVE) {
                positive.add(summary);
            } else {
                negative.add(summary);
            }
        }

        return new PostDtos.ReviewTagCatalog(positive, negative);
    }

    public PostDtos.ReviewTagSummary toSummary(ReviewTag tag) {
        return new PostDtos.ReviewTagSummary(
                tag.getId(),
                tag.getLabel(),
                tag.getSentiment().name());
    }
}
