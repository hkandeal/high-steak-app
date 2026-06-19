package com.highsteak.api.service;

import com.highsteak.api.domain.PostComment;
import com.highsteak.api.domain.SteakPost;
import com.highsteak.api.domain.User;
import com.highsteak.api.dto.PostDtos;
import com.highsteak.api.dto.PageDtos;
import com.highsteak.api.util.PaginationHelper;
import com.highsteak.api.repository.PostCommentRepository;
import com.highsteak.api.repository.SteakPostRepository;
import com.highsteak.api.repository.UserRepository;
import com.highsteak.api.security.UserPrincipal;
import com.highsteak.api.validation.CommentValidation;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.UUID;

import static org.springframework.http.HttpStatus.NOT_FOUND;

@Service
@RequiredArgsConstructor
public class PostCommentService {

    private final PostCommentRepository commentRepository;
    private final SteakPostRepository steakPostRepository;
    private final UserRepository userRepository;
    private final AuthService authService;
    private final SteakPostService steakPostService;
    private final CommentValidation commentValidation;

    @Transactional(readOnly = true)
    public PageDtos.PageResponse<PostDtos.CommentResponse> listComments(
            UserPrincipal viewer, UUID postId, int page, int size) {
        SteakPost post = steakPostRepository.findWithDetailsById(postId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Post not found"));
        if (!steakPostService.canViewPost(viewer, post)) {
            throw new ResponseStatusException(NOT_FOUND, "Post not found");
        }
        Pageable pageable = PaginationHelper.pageable(page, size);
        Page<PostComment> comments = commentRepository.findByPost_IdOrderByCreatedAtAsc(postId, pageable);
        return PaginationHelper.toPageResponse(comments, this::toResponse);
    }

    @Transactional
    public PostDtos.CommentResponse addComment(UserPrincipal principal, UUID postId, String body) {
        String normalized = commentValidation.normalizeAndValidate(body);

        SteakPost post = steakPostRepository.findWithDetailsById(postId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Post not found"));
        if (!steakPostService.canViewPost(principal, post)) {
            throw new ResponseStatusException(NOT_FOUND, "Post not found");
        }

        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "User not found"));

        PostComment comment = PostComment.builder()
                .post(post)
                .user(user)
                .body(normalized)
                .build();

        comment = commentRepository.save(comment);
        return toResponse(comment);
    }

    private PostDtos.CommentResponse toResponse(PostComment comment) {
        return new PostDtos.CommentResponse(
                comment.getId(),
                comment.getBody(),
                comment.getCreatedAt(),
                authService.toAuthorSummary(comment.getUser()));
    }
}
