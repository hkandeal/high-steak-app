package com.highsteak.api.controller;

import com.highsteak.api.dto.PageDtos;
import com.highsteak.api.dto.PostDtos;
import com.highsteak.api.security.UserPrincipal;
import com.highsteak.api.service.BookmarkService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequiredArgsConstructor
public class BookmarkController {

    private final BookmarkService bookmarkService;

    @GetMapping("/bookmarks")
    @PreAuthorize("hasAuthority('bookmarks:read')")
    public PageDtos.PageResponse<PostDtos.PostResponse> listBookmarks(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return bookmarkService.listBookmarkedPosts(principal, page, size);
    }

    @PostMapping("/posts/{postId}/bookmark")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasAuthority('bookmarks:write')")
    public void bookmarkPost(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID postId) {
        bookmarkService.bookmarkPost(principal, postId);
    }

    @DeleteMapping("/posts/{postId}/bookmark")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasAuthority('bookmarks:write')")
    public void unbookmarkPost(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID postId) {
        bookmarkService.unbookmarkPost(principal, postId);
    }
}
