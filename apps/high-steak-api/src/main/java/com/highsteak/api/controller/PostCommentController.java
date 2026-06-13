package com.highsteak.api.controller;

import com.highsteak.api.dto.PostDtos;
import com.highsteak.api.security.UserPrincipal;
import com.highsteak.api.service.PostCommentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/posts/{postId}/comments")
@RequiredArgsConstructor
public class PostCommentController {

    private final PostCommentService commentService;

    @GetMapping
    @PreAuthorize("hasAuthority('posts:read')")
    public List<PostDtos.CommentResponse> listComments(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID postId) {
        return commentService.listComments(principal, postId);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAuthority('comments:write')")
    public PostDtos.CommentResponse addComment(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID postId,
            @Valid @RequestBody PostDtos.CreateCommentRequest request) {
        return commentService.addComment(principal, postId, request.body());
    }
}
