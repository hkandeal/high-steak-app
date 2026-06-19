package com.highsteak.api.repository;

import com.highsteak.api.domain.PostBookmark;
import com.highsteak.api.domain.PostBookmarkId;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.Set;
import java.util.UUID;

public interface PostBookmarkRepository extends JpaRepository<PostBookmark, PostBookmarkId> {

    Page<PostBookmark> findByIdUserIdOrderByCreatedAtDesc(UUID userId, Pageable pageable);

    @Query("""
            SELECT b.id.postId FROM PostBookmark b
            WHERE b.id.userId = :userId AND b.id.postId IN :postIds
            """)
    Set<UUID> findPostIdsByUserIdAndPostIdIn(
            @Param("userId") UUID userId, @Param("postIds") Collection<UUID> postIds);
}
