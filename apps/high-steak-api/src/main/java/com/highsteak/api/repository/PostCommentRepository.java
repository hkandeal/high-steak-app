package com.highsteak.api.repository;

import com.highsteak.api.domain.PostComment;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface PostCommentRepository extends JpaRepository<PostComment, UUID> {

    @EntityGraph(attributePaths = {"user"})
    List<PostComment> findByPost_IdOrderByCreatedAtAsc(UUID postId);
}
