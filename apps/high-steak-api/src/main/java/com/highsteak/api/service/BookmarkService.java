package com.highsteak.api.service;

import com.highsteak.api.domain.PostBookmark;
import com.highsteak.api.domain.PostBookmarkId;
import com.highsteak.api.domain.SteakPost;
import com.highsteak.api.dto.PageDtos;
import com.highsteak.api.dto.PostDtos;
import com.highsteak.api.repository.PostBookmarkRepository;
import com.highsteak.api.repository.SteakPostRepository;
import com.highsteak.api.security.UserPrincipal;
import com.highsteak.api.util.PaginationHelper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

import static org.springframework.http.HttpStatus.CONFLICT;
import static org.springframework.http.HttpStatus.NOT_FOUND;

@Service
@RequiredArgsConstructor
public class BookmarkService {

    private final PostBookmarkRepository bookmarkRepository;
    private final SteakPostRepository steakPostRepository;
    private final SteakPostService steakPostService;

    @Transactional(readOnly = true)
    public PageDtos.PageResponse<PostDtos.PostResponse> listBookmarkedPosts(
            UserPrincipal principal, int page, int size) {
        Pageable pageable = PaginationHelper.pageable(page, size);
        Page<PostBookmark> bookmarkPage =
                bookmarkRepository.findByIdUserIdOrderByCreatedAtDesc(principal.getId(), pageable);

        List<UUID> postIds = bookmarkPage.getContent().stream()
                .map(bookmark -> bookmark.getId().getPostId())
                .toList();

        if (postIds.isEmpty()) {
            return new PageDtos.PageResponse<>(
                    List.of(),
                    bookmarkPage.getNumber(),
                    bookmarkPage.getSize(),
                    bookmarkPage.getTotalElements(),
                    bookmarkPage.getTotalPages());
        }

        Map<UUID, SteakPost> postsById = steakPostRepository.findWithDetailsByIdIn(postIds).stream()
                .collect(Collectors.toMap(SteakPost::getId, Function.identity()));

        List<PostDtos.PostResponse> content = new ArrayList<>();
        for (UUID postId : postIds) {
            SteakPost post = postsById.get(postId);
            if (post == null || !steakPostService.canViewPost(principal, post)) {
                continue;
            }
            content.add(steakPostService.toResponse(post, principal, true));
        }

        return new PageDtos.PageResponse<>(
                content,
                bookmarkPage.getNumber(),
                bookmarkPage.getSize(),
                bookmarkPage.getTotalElements(),
                bookmarkPage.getTotalPages());
    }

    @Transactional
    public void bookmarkPost(UserPrincipal principal, UUID postId) {
        SteakPost post = steakPostRepository.findWithDetailsById(postId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Post not found"));
        if (!steakPostService.canViewPost(principal, post)) {
            throw new ResponseStatusException(NOT_FOUND, "Post not found");
        }

        PostBookmarkId id = new PostBookmarkId(principal.getId(), postId);
        if (bookmarkRepository.existsById(id)) {
            throw new ResponseStatusException(CONFLICT, "Post is already bookmarked");
        }

        bookmarkRepository.save(PostBookmark.builder().id(id).build());
    }

    @Transactional
    public void unbookmarkPost(UserPrincipal principal, UUID postId) {
        PostBookmarkId id = new PostBookmarkId(principal.getId(), postId);
        if (!bookmarkRepository.existsById(id)) {
            throw new ResponseStatusException(NOT_FOUND, "Bookmark not found");
        }
        bookmarkRepository.deleteById(id);
    }
}
