package com.highsteak.api.service;

import com.highsteak.api.domain.PostComment;
import com.highsteak.api.domain.SteakPost;
import com.highsteak.api.domain.User;
import com.highsteak.api.dto.PostDtos;
import com.highsteak.api.dto.PageDtos;
import com.highsteak.api.util.PaginationHelper;
import com.highsteak.api.notification.NotificationEvent;
import com.highsteak.api.repository.PostCommentRepository;
import com.highsteak.api.repository.SteakPostRepository;
import com.highsteak.api.repository.UserRepository;
import com.highsteak.api.security.UserPrincipal;
import com.highsteak.api.validation.CommentValidation;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.UUID;

import static org.springframework.http.HttpStatus.FORBIDDEN;
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
    private final ApplicationEventPublisher eventPublisher;

    @Transactional(readOnly = true)
    public PageDtos.PageResponse<PostDtos.CommentResponse> listComments(
            UserPrincipal viewer, UUID postId, int page, int size) {
        SteakPost post = steakPostRepository.findWithDetailsById(postId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Post not found"));
        if (!steakPostService.canViewPost(viewer, post)) {
            throw new ResponseStatusException(NOT_FOUND, "Post not found");
        }
        Pageable pageable = PaginationHelper.pageable(page, size);
        Page<PostComment> comments = commentRepository.findByPost_IdOrderByCreatedAtDesc(postId, pageable);
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
        eventPublisher.publishEvent(new NotificationEvent.NewComment(
                post.getId(),
                comment.getId(),
                post.getUser().getId(),
                user.getId()));
        return toResponse(comment);
    }

    @Transactional
    public PostDtos.CommentResponse updateComment(
            UserPrincipal principal, UUID postId, UUID commentId, String body) {
        String normalized = commentValidation.normalizeAndValidate(body);
        PostComment comment = loadCommentOnViewablePost(principal, postId, commentId);
        if (!comment.getUser().getId().equals(principal.getId())) {
            throw new ResponseStatusException(FORBIDDEN, "Not allowed to edit this comment");
        }
        comment.setBody(normalized);
        return toResponse(commentRepository.save(comment));
    }

    @Transactional
    public void deleteComment(UserPrincipal principal, UUID postId, UUID commentId) {
        PostComment comment = loadCommentOnViewablePost(principal, postId, commentId);
        boolean isCommentAuthor = comment.getUser().getId().equals(principal.getId());
        boolean isPostAuthor = comment.getPost().getUser().getId().equals(principal.getId());
        if (!isCommentAuthor && !isPostAuthor) {
            throw new ResponseStatusException(FORBIDDEN, "Not allowed to delete this comment");
        }
        commentRepository.delete(comment);
    }

    private PostComment loadCommentOnViewablePost(UserPrincipal viewer, UUID postId, UUID commentId) {
        PostComment comment = commentRepository.findByIdAndPost_Id(commentId, postId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Comment not found"));
        if (!steakPostService.canViewPost(viewer, comment.getPost())) {
            throw new ResponseStatusException(NOT_FOUND, "Comment not found");
        }
        return comment;
    }

    private PostDtos.CommentResponse toResponse(PostComment comment) {
        return new PostDtos.CommentResponse(
                comment.getId(),
                comment.getBody(),
                comment.getCreatedAt(),
                authService.toFeedAuthorSummary(comment.getUser(), null));
    }
}
