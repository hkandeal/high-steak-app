package com.highsteak.api.repository;

import com.highsteak.api.domain.SteakPost;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface SteakPostRepository extends JpaRepository<SteakPost, UUID> {

    @EntityGraph(attributePaths = {"user", "images", "reviewTags", "reviewTags.tag"})
    List<SteakPost> findAllByHiddenFalseOrderByCreatedAtDesc();

    @EntityGraph(attributePaths = {"user", "images", "reviewTags", "reviewTags.tag"})
    List<SteakPost> findByHiddenTrueOrderByCreatedAtDesc();

    @EntityGraph(attributePaths = {"user", "images", "reviewTags", "reviewTags.tag"})
    List<SteakPost> findByUserIdOrderByCreatedAtDesc(UUID userId);

    @EntityGraph(attributePaths = {"user", "images", "reviewTags", "reviewTags.tag"})
    List<SteakPost> findByUserIdAndHiddenFalseOrderByCreatedAtDesc(UUID userId);

    @EntityGraph(attributePaths = {"user", "images", "reviewTags", "reviewTags.tag"})
    List<SteakPost> findByUserIdInAndHiddenFalseOrderByCreatedAtDesc(Collection<UUID> userIds);

    @EntityGraph(attributePaths = {"user", "images", "reviewTags", "reviewTags.tag"})
    Optional<SteakPost> findWithDetailsById(UUID id);

    long countByUserIdAndHiddenFalse(UUID userId);
}
