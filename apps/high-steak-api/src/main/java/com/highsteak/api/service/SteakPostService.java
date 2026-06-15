package com.highsteak.api.service;

import com.highsteak.api.domain.PostImage;
import com.highsteak.api.domain.PostReviewTag;
import com.highsteak.api.domain.PostVisibility;
import com.highsteak.api.domain.ReviewTag;
import com.highsteak.api.domain.SteakPost;
import com.highsteak.api.domain.User;
import com.highsteak.api.dto.PostDtos;
import com.highsteak.api.dto.PageDtos;
import com.highsteak.api.repository.ReviewTagRepository;
import com.highsteak.api.repository.SteakPostRepository;
import com.highsteak.api.repository.UserRepository;
import com.highsteak.api.repository.UserSubscriptionRepository;
import com.highsteak.api.security.UserPrincipal;
import com.highsteak.api.validation.ApiConstraints;
import com.highsteak.api.validation.TextValidation;
import com.highsteak.api.validation.UploadValidation;
import com.highsteak.api.util.PaginationHelper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashSet;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

import static org.springframework.http.HttpStatus.BAD_REQUEST;
import static org.springframework.http.HttpStatus.FORBIDDEN;
import static org.springframework.http.HttpStatus.NOT_FOUND;

@Service
@RequiredArgsConstructor
public class SteakPostService {

    private final SteakPostRepository steakPostRepository;
    private final UserRepository userRepository;
    private final UserSubscriptionRepository subscriptionRepository;
    private final ReviewTagRepository reviewTagRepository;
    private final ReviewTagService reviewTagService;
    private final AuthService authService;
    private final SubscriptionService subscriptionService;

    @Value("${app.uploads.dir}")
    private String uploadsDir;

    @Transactional(readOnly = true)
    public PageDtos.PageResponse<PostDtos.PostResponse> getFeed(int page, int size) {
        Pageable pageable = PaginationHelper.pageable(page, size);
        Page<SteakPost> posts = steakPostRepository.findByHiddenFalseAndVisibilityOrderByCreatedAtDesc(
                PostVisibility.PUBLIC, pageable);
        return PaginationHelper.toPageResponse(posts, this::toResponse);
    }

    @Transactional(readOnly = true)
    public PostDtos.PostResponse getPost(UUID postId, UserPrincipal viewer) {
        SteakPost post = steakPostRepository.findWithDetailsById(postId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Post not found"));
        if (!canViewPost(viewer, post)) {
            throw new ResponseStatusException(NOT_FOUND, "Post not found");
        }
        return toResponse(post, viewer);
    }

    public boolean canViewPost(UserPrincipal viewer, SteakPost post) {
        if (post.isHidden()) {
            if (viewer != null && viewer.getId().equals(post.getUser().getId())) {
                return true;
            }
            return viewer != null && viewer.hasScope("posts:moderate");
        }
        if (viewer != null && viewer.getId().equals(post.getUser().getId())) {
            return true;
        }
        if (post.getVisibility() == PostVisibility.PUBLIC) {
            return true;
        }
        if (viewer != null && viewer.hasScope("posts:moderate")) {
            return true;
        }
        if (viewer == null) {
            return false;
        }
        return subscriptionRepository.existsByIdSubscriberIdAndIdTargetUserId(
                viewer.getId(), post.getUser().getId());
    }

    @Transactional(readOnly = true)
    public PageDtos.PageResponse<PostDtos.PostResponse> getMyPosts(UserPrincipal principal, int page, int size) {
        Pageable pageable = PaginationHelper.pageable(page, size);
        Page<SteakPost> posts = steakPostRepository.findByUserIdOrderByCreatedAtDesc(principal.getId(), pageable);
        return PaginationHelper.toPageResponse(posts, post -> toResponse(post, principal));
    }

    @Transactional(readOnly = true)
    public PageDtos.PageResponse<PostDtos.PostResponse> getHiddenPosts(int page, int size) {
        Pageable pageable = PaginationHelper.pageable(page, size);
        Page<SteakPost> posts = steakPostRepository.findByHiddenTrueOrderByCreatedAtDesc(pageable);
        return PaginationHelper.toPageResponse(posts, this::toResponse);
    }

    @Transactional(readOnly = true)
    public PageDtos.PageResponse<PostDtos.PostResponse> getFollowingFeed(UserPrincipal principal, int page, int size) {
        Set<UUID> followedUserIds = subscriptionService.getSubscribedUserIds(principal.getId());
        if (followedUserIds.isEmpty()) {
            return emptyPage(page, size);
        }
        Pageable pageable = PaginationHelper.pageable(page, size);
        Page<SteakPost> posts = steakPostRepository.findByUserIdInAndHiddenFalseOrderByCreatedAtDesc(
                followedUserIds, pageable);
        return PaginationHelper.toPageResponse(posts, this::toResponse);
    }

    @Transactional(readOnly = true)
    public PageDtos.PageResponse<PostDtos.PostResponse> getVisiblePostsForProfile(
            UUID profileUserId, UserPrincipal viewer, int page, int size) {
        if (!userRepository.existsById(profileUserId)) {
            throw new ResponseStatusException(NOT_FOUND, "User not found");
        }
        UUID viewerId = viewer != null ? viewer.getId() : null;
        Pageable pageable = PaginationHelper.pageable(page, size);
        Page<SteakPost> posts;
        if (viewerId != null && viewerId.equals(profileUserId)) {
            posts = steakPostRepository.findByUserIdOrderByCreatedAtDesc(profileUserId, pageable);
        } else if (viewerId == null) {
            posts = steakPostRepository.findByUserIdAndHiddenFalseAndVisibilityOrderByCreatedAtDesc(
                    profileUserId, PostVisibility.PUBLIC, pageable);
        } else {
            posts = steakPostRepository.findVisiblePostsForProfile(profileUserId, viewerId, pageable);
        }
        return PaginationHelper.toPageResponse(posts, post -> toResponse(post, viewer));
    }

    private PageDtos.PageResponse<PostDtos.PostResponse> emptyPage(int page, int size) {
        Pageable pageable = PaginationHelper.pageable(page, size);
        return new PageDtos.PageResponse<>(List.of(), pageable.getPageNumber(), pageable.getPageSize(), 0, 0);
    }

    @Transactional(readOnly = true)
    public long countVisiblePostsForProfile(UUID profileUserId, UserPrincipal viewer) {
        if (!userRepository.existsById(profileUserId)) {
            throw new ResponseStatusException(NOT_FOUND, "User not found");
        }
        UUID viewerId = viewer != null ? viewer.getId() : null;
        if (viewerId != null && viewerId.equals(profileUserId)) {
            return steakPostRepository.countByUserId(profileUserId);
        }
        if (viewerId == null) {
            return steakPostRepository.countByUserIdAndHiddenFalseAndVisibility(
                    profileUserId, PostVisibility.PUBLIC);
        }
        return steakPostRepository.countVisiblePostsForProfile(profileUserId, viewerId);
    }

    @Transactional
    public PostDtos.PostResponse createPost(
            UserPrincipal principal,
            String title,
            String comment,
            int rating,
            String restaurantName,
            String restaurantLocation,
            String visibility,
            MultipartFile[] images,
            List<UUID> tagIds) {
        ValidatedPostFields fields = validatePostFields(title, comment, rating, restaurantName, restaurantLocation);
        if (images == null || images.length == 0) {
            throw new ResponseStatusException(BAD_REQUEST, "At least one image is required");
        }
        UploadValidation.validateImages(images);

        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "User not found"));

        List<PostImage> postImages = new ArrayList<>();
        for (int i = 0; i < images.length; i++) {
            MultipartFile image = images[i];
            if (image == null || image.isEmpty()) {
                continue;
            }
            postImages.add(PostImage.builder()
                    .imageUrl(storeImage(image))
                    .sortOrder(i)
                    .build());
        }

        if (postImages.isEmpty()) {
            throw new ResponseStatusException(BAD_REQUEST, "At least one image is required");
        }

        SteakPost post = SteakPost.builder()
                .user(user)
                .title(fields.title())
                .comment(fields.comment())
                .rating(fields.rating())
                .restaurantName(fields.restaurantName())
                .restaurantLocation(fields.restaurantLocation())
                .visibility(parseVisibility(visibility))
                .images(postImages)
                .build();

        for (PostImage image : postImages) {
            image.setPost(post);
        }
        post = steakPostRepository.saveAndFlush(post);
        attachReviewTags(post, tagIds);
        return loadPostResponse(post.getId());
    }

    @Transactional
    public PostDtos.PostResponse updatePost(
            UserPrincipal principal,
            UUID postId,
            String title,
            String comment,
            int rating,
            String restaurantName,
            String restaurantLocation,
            String visibility,
            List<String> keepImageUrls,
            MultipartFile[] newImages,
            List<UUID> tagIds) {
        ValidatedPostFields fields = validatePostFields(title, comment, rating, restaurantName, restaurantLocation);
        UploadValidation.validateImages(newImages);

        SteakPost post = steakPostRepository.findWithDetailsById(postId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Post not found"));
        if (!post.getUser().getId().equals(principal.getId())) {
            throw new ResponseStatusException(FORBIDDEN, "Not allowed to edit this post");
        }

        post.setTitle(fields.title());
        post.setComment(fields.comment());
        post.setRating(fields.rating());
        post.setRestaurantName(fields.restaurantName());
        post.setRestaurantLocation(fields.restaurantLocation());
        if (visibility != null && !visibility.isBlank()) {
            post.setVisibility(parseVisibility(visibility));
        }

        syncImages(post, keepImageUrls, newImages);
        replaceReviewTags(post, tagIds);
        steakPostRepository.saveAndFlush(post);
        return loadPostResponse(post.getId());
    }

    private void syncImages(SteakPost post, List<String> keepImageUrls, MultipartFile[] newImages) {
        List<String> keep = keepImageUrls != null ? keepImageUrls : List.of();
        Set<String> keepSet = new LinkedHashSet<>(keep);
        Map<String, PostImage> existingByUrl = post.getImages().stream()
                .collect(Collectors.toMap(PostImage::getImageUrl, Function.identity(), (left, right) -> left));

        post.getImages().removeIf(image -> !keepSet.contains(image.getImageUrl()));

        int sortOrder = 0;
        for (String url : keep) {
            PostImage existing = existingByUrl.get(url);
            if (existing != null) {
                existing.setSortOrder(sortOrder++);
            }
        }

        if (newImages != null) {
            for (MultipartFile image : newImages) {
                if (image == null || image.isEmpty()) {
                    continue;
                }
                post.getImages().add(PostImage.builder()
                        .imageUrl(storeImage(image))
                        .sortOrder(sortOrder++)
                        .post(post)
                        .build());
            }
        }

        if (post.getImages().isEmpty()) {
            throw new ResponseStatusException(BAD_REQUEST, "At least one image is required");
        }
    }

    private PostDtos.PostResponse loadPostResponse(UUID postId) {
        return toResponse(steakPostRepository.findWithDetailsById(postId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Post not found")));
    }

    private void attachReviewTags(SteakPost post, List<UUID> tagIds) {
        if (tagIds == null || tagIds.isEmpty()) {
            return;
        }
        LinkedHashSet<UUID> uniqueTagIds = new LinkedHashSet<>(tagIds);
        if (uniqueTagIds.size() > ApiConstraints.MAX_REVIEW_TAGS) {
            throw new ResponseStatusException(BAD_REQUEST, "You can select up to " + ApiConstraints.MAX_REVIEW_TAGS + " tags");
        }
        List<ReviewTag> tags = reviewTagRepository.findByIdInAndActiveTrue(uniqueTagIds);
        if (tags.size() != uniqueTagIds.size()) {
            throw new ResponseStatusException(BAD_REQUEST, "One or more tags are invalid");
        }
        for (ReviewTag tag : tags) {
            post.getReviewTags().add(PostReviewTag.of(post, tag));
        }
    }

    private void replaceReviewTags(SteakPost post, List<UUID> tagIds) {
        LinkedHashSet<UUID> desired = tagIds != null && !tagIds.isEmpty()
                ? new LinkedHashSet<>(tagIds)
                : new LinkedHashSet<>();
        if (desired.size() > ApiConstraints.MAX_REVIEW_TAGS) {
            throw new ResponseStatusException(BAD_REQUEST, "You can select up to " + ApiConstraints.MAX_REVIEW_TAGS + " tags");
        }

        post.getReviewTags().removeIf(link -> !desired.contains(link.getTagId()));

        Set<UUID> current = post.getReviewTags().stream()
                .map(PostReviewTag::getTagId)
                .collect(Collectors.toCollection(LinkedHashSet::new));

        LinkedHashSet<UUID> toAdd = new LinkedHashSet<>(desired);
        toAdd.removeAll(current);

        if (toAdd.isEmpty()) {
            return;
        }
        List<ReviewTag> tags = reviewTagRepository.findByIdInAndActiveTrue(toAdd);
        if (tags.size() != toAdd.size()) {
            throw new ResponseStatusException(BAD_REQUEST, "One or more tags are invalid");
        }
        for (ReviewTag tag : tags) {
            post.getReviewTags().add(PostReviewTag.of(post, tag));
        }
    }

    @Transactional
    public void deletePost(UUID postId) {
        SteakPost post = steakPostRepository.findById(postId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Post not found"));
        steakPostRepository.delete(post);
    }

    @Transactional
    public PostDtos.PostResponse hidePost(UUID postId, String reason) {
        SteakPost post = steakPostRepository.findWithDetailsById(postId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Post not found"));
        post.setHidden(true);
        post.setModerationReason(normalizeModerationReason(reason));
        post.setModerationRestoredAt(null);
        post = steakPostRepository.save(post);
        return toResponse(post);
    }

    @Transactional
    public PostDtos.PostResponse unhidePost(UUID postId) {
        SteakPost post = steakPostRepository.findWithDetailsById(postId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Post not found"));
        post.setHidden(false);
        post.setModerationReason(null);
        post.setModerationRestoredAt(java.time.Instant.now());
        post = steakPostRepository.save(post);
        return toResponse(post);
    }

    private String normalizeModerationReason(String reason) {
        if (reason == null || reason.isBlank()) {
            return null;
        }
        return TextValidation.bounded(reason.trim(), "Moderation reason", 1, ApiConstraints.MODERATION_REASON_MAX);
    }

    public PostDtos.PostResponse toResponse(SteakPost post) {
        return toResponse(post, null);
    }

    public PostDtos.PostResponse toResponse(SteakPost post, UserPrincipal viewer) {
        List<String> imageUrls = uniqueImageUrls(post.getImages());
        List<PostDtos.ReviewTagSummary> tags = post.getReviewTags().stream()
                .map(link -> reviewTagService.toSummary(link.getTag()))
                .toList();
        boolean includeAuthorModerationFields = viewer != null
                && viewer.getId().equals(post.getUser().getId());
        return new PostDtos.PostResponse(
                post.getId(),
                post.getTitle(),
                post.getComment(),
                post.getRating(),
                imageUrls,
                post.getRestaurantName(),
                post.getRestaurantLocation(),
                post.getCreatedAt(),
                post.isHidden(),
                post.isHidden() ? post.getModerationReason() : null,
                includeAuthorModerationFields ? post.getModerationRestoredAt() : null,
                post.getVisibility(),
                authService.toAuthorSummary(post.getUser()),
                tags);
    }

    private List<String> uniqueImageUrls(List<PostImage> images) {
        LinkedHashSet<String> urls = new LinkedHashSet<>();
        for (PostImage image : images) {
            urls.add(image.getImageUrl());
        }
        return new ArrayList<>(urls);
    }

    private String storeImage(MultipartFile image) {
        UploadValidation.validateImage(image);
        String original = image.getOriginalFilename();
        String extension = original != null && original.contains(".")
                ? original.substring(original.lastIndexOf('.'))
                : ".jpg";
        String filename = UUID.randomUUID() + extension;

        try {
            Path dir = Path.of(uploadsDir).toAbsolutePath().normalize();
            Files.createDirectories(dir);
            Path target = dir.resolve(filename);
            image.transferTo(target);
            return "/uploads/" + filename;
        } catch (IOException ex) {
            throw new ResponseStatusException(BAD_REQUEST, "Failed to store image");
        }
    }

    private String blankToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private ValidatedPostFields validatePostFields(
            String title,
            String comment,
            int rating,
            String restaurantName,
            String restaurantLocation) {
        TextValidation.requireRating(rating);
        return new ValidatedPostFields(
                TextValidation.require(title, "Title", ApiConstraints.POST_TITLE_MIN, ApiConstraints.POST_TITLE_MAX),
                TextValidation.optional(comment, "Comment", ApiConstraints.POST_COMMENT_MAX),
                (byte) rating,
                TextValidation.optional(restaurantName, "Restaurant name", ApiConstraints.RESTAURANT_NAME_MAX),
                TextValidation.optional(restaurantLocation, "Restaurant location", ApiConstraints.RESTAURANT_LOCATION_MAX));
    }

    private PostVisibility parseVisibility(String visibility) {
        if (visibility == null || visibility.isBlank()) {
            return PostVisibility.PUBLIC;
        }
        try {
            return PostVisibility.valueOf(visibility.trim().toUpperCase());
        } catch (IllegalArgumentException ex) {
            throw new ResponseStatusException(BAD_REQUEST, "Invalid visibility");
        }
    }

    private record ValidatedPostFields(
            String title,
            String comment,
            byte rating,
            String restaurantName,
            String restaurantLocation) {}
}
