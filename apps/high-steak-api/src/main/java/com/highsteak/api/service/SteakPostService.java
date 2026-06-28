package com.highsteak.api.service;

import com.highsteak.api.config.GeoProperties;
import com.highsteak.api.domain.CoverImageSource;
import com.highsteak.api.domain.Place;
import com.highsteak.api.domain.PostBookmarkId;
import com.highsteak.api.domain.PostImage;
import com.highsteak.api.domain.PostReviewTag;
import com.highsteak.api.domain.PostVisibility;
import com.highsteak.api.domain.ReviewTag;
import com.highsteak.api.domain.SteakPost;
import com.highsteak.api.domain.User;
import com.highsteak.api.dto.PostDtos;
import com.highsteak.api.dto.PlaceDtos;
import com.highsteak.api.dto.PageDtos;
import com.highsteak.api.notification.NotificationEvent;
import com.highsteak.api.repository.PlaceRepository;
import com.highsteak.api.repository.PostBookmarkRepository;
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
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
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

    static final String NEW_IMAGE_SLOT_PREFIX = "__new__:";

    private final SteakPostRepository steakPostRepository;
    private final PlaceRepository placeRepository;
    private final PostBookmarkRepository postBookmarkRepository;
    private final UserRepository userRepository;
    private final UserSubscriptionRepository subscriptionRepository;
    private final ReviewTagRepository reviewTagRepository;
    private final ReviewTagService reviewTagService;
    private final AuthService authService;
    private final SubscriptionService subscriptionService;
    private final UploadValidation uploadValidation;
    private final ApplicationEventPublisher eventPublisher;
    private final GeoProperties geoProperties;

    @Value("${app.uploads.dir}")
    private String uploadsDir;

    @Transactional(readOnly = true)
    public PageDtos.PageResponse<PostDtos.PostResponse> getFeed(UserPrincipal viewer, int page, int size) {
        Pageable pageable = PaginationHelper.pageable(page, size);
        Page<SteakPost> posts = steakPostRepository.findByHiddenFalseAndVisibilityAndUserIdNotOrderByCreatedAtDesc(
                PostVisibility.PUBLIC, viewer.getId(), pageable);
        return toEveryoneFeedPageResponse(posts, viewer);
    }

    @Transactional(readOnly = true)
    public PageDtos.PageResponse<PostDtos.PostResponse> getNearbyFeed(
            UserPrincipal viewer,
            double latitude,
            double longitude,
            Integer radiusM,
            int page,
            int size) {
        int effectiveRadius = normalizeRadius(radiusM);
        BoundingBox box = BoundingBox.around(latitude, longitude, effectiveRadius);
        Pageable pageable = PaginationHelper.pageable(page, size);

        List<String> postIdStrings = steakPostRepository.findNearbyPostIds(
                viewer.getId().toString(),
                latitude,
                longitude,
                box.minLat(),
                box.maxLat(),
                box.minLng(),
                box.maxLng(),
                effectiveRadius,
                pageable.getPageSize(),
                (int) pageable.getOffset());

        long total = steakPostRepository.countNearbyPosts(
                viewer.getId().toString(),
                latitude,
                longitude,
                box.minLat(),
                box.maxLat(),
                box.minLng(),
                box.maxLng(),
                effectiveRadius);

        List<SteakPost> ordered = loadPostsInOrder(postIdStrings);
        Page<SteakPost> posts = new PageImpl<>(ordered, pageable, total);
        return toEveryoneFeedPageResponse(posts, viewer);
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
        return toPageResponse(posts, principal);
    }

    @Transactional(readOnly = true)
    public List<PostDtos.PostResponse> getMyModerationNotices(UserPrincipal principal) {
        List<SteakPost> posts = steakPostRepository.findModerationNoticesByUserId(principal.getId());
        Set<UUID> bookmarkedIds = resolveBookmarkedIds(principal, posts);
        return posts.stream()
                .map(post -> toResponse(post, principal, bookmarkedIds.contains(post.getId())))
                .toList();
    }

    @Transactional(readOnly = true)
    public PageDtos.PageResponse<PostDtos.PostResponse> getHiddenPosts(int page, int size) {
        Pageable pageable = PaginationHelper.pageable(page, size);
        Page<SteakPost> posts = steakPostRepository.findByHiddenTrueOrderByCreatedAtDesc(pageable);
        return PaginationHelper.toPageResponse(posts, post -> toResponse(post, null, false));
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
        return toFeedPageResponse(posts, principal);
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
        return toPageResponse(posts, viewer);
    }

    private PageDtos.PageResponse<PostDtos.PostResponse> toPageResponse(
            Page<SteakPost> posts, UserPrincipal viewer) {
        Set<UUID> bookmarkedIds = resolveBookmarkedIds(viewer, posts.getContent());
        return PaginationHelper.toPageResponse(
                posts, post -> toResponse(post, viewer, bookmarkedIds.contains(post.getId())));
    }

    private PageDtos.PageResponse<PostDtos.PostResponse> toFeedPageResponse(
            Page<SteakPost> posts, UserPrincipal viewer) {
        Set<UUID> bookmarkedIds = resolveBookmarkedIds(viewer, posts.getContent());
        return PaginationHelper.toPageResponse(
                posts, post -> toFeedResponse(post, viewer, bookmarkedIds.contains(post.getId())));
    }

    private PageDtos.PageResponse<PostDtos.PostResponse> toEveryoneFeedPageResponse(
            Page<SteakPost> posts, UserPrincipal viewer) {
        Set<UUID> bookmarkedIds = resolveBookmarkedIds(viewer, posts.getContent());
        Set<UUID> subscribedIds = subscriptionService.getSubscribedUserIds(viewer.getId());
        return PaginationHelper.toPageResponse(
                posts,
                post -> toEveryoneFeedResponse(
                        post,
                        viewer,
                        bookmarkedIds.contains(post.getId()),
                        subscribedIds.contains(post.getUser().getId())));
    }

    private Set<UUID> resolveBookmarkedIds(UserPrincipal viewer, List<SteakPost> posts) {
        if (viewer == null || posts.isEmpty()) {
            return Set.of();
        }
        List<UUID> postIds = posts.stream().map(SteakPost::getId).toList();
        return postBookmarkRepository.findPostIdsByUserIdAndPostIdIn(viewer.getId(), postIds);
    }

    private PageDtos.PageResponse<PostDtos.PostResponse> emptyPage(int page, int size) {
        Pageable pageable = PaginationHelper.pageable(page, size);
        return new PageDtos.PageResponse<>(List.of(), pageable.getPageNumber(), pageable.getPageSize(), 0, 0);
    }

    private int normalizeRadius(Integer radiusM) {
        int value = radiusM != null ? radiusM : geoProperties.getDefaultRadiusM();
        if (value <= 0) {
            throw new ResponseStatusException(BAD_REQUEST, "radiusM must be positive");
        }
        if (value > geoProperties.getMaxRadiusM()) {
            throw new ResponseStatusException(BAD_REQUEST, "radiusM exceeds maximum allowed");
        }
        return value;
    }

    private List<SteakPost> loadPostsInOrder(List<String> postIdStrings) {
        if (postIdStrings.isEmpty()) {
            return List.of();
        }
        List<UUID> ids = postIdStrings.stream().map(UUID::fromString).toList();
        Map<UUID, SteakPost> byId = steakPostRepository.findWithDetailsByIdIn(ids).stream()
                .collect(Collectors.toMap(SteakPost::getId, Function.identity()));
        return ids.stream().map(byId::get).filter(Objects::nonNull).toList();
    }

    private record BoundingBox(double minLat, double maxLat, double minLng, double maxLng) {
        static BoundingBox around(double lat, double lng, int radiusM) {
            double deltaLat = radiusM / 111_320.0;
            double deltaLng = radiusM / (111_320.0 * Math.cos(Math.toRadians(lat)));
            return new BoundingBox(lat - deltaLat, lat + deltaLat, lng - deltaLng, lng + deltaLng);
        }
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
            UUID placeId,
            String visibility,
            MultipartFile[] images,
            List<UUID> tagIds) {
        ValidatedPostFields fields = validatePostFields(title, comment, rating, restaurantName, restaurantLocation);
        if (images == null || images.length == 0) {
            throw new ResponseStatusException(BAD_REQUEST, "At least one image is required");
        }
        uploadValidation.validateImages(images);

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

        applyPlaceIfPresent(post, placeId);

        for (PostImage image : postImages) {
            image.setPost(post);
        }
        post = steakPostRepository.saveAndFlush(post);
        attachReviewTags(post, tagIds);
        return loadPostResponse(post.getId(), principal);
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
            UUID placeId,
            String visibility,
            List<String> keepImageUrls,
            List<String> imageOrder,
            MultipartFile[] newImages,
            List<UUID> tagIds) {
        ValidatedPostFields fields = validatePostFields(title, comment, rating, restaurantName, restaurantLocation);
        uploadValidation.validateImages(newImages);

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
        applyPlaceIfPresent(post, placeId);

        if (imageOrder != null && !imageOrder.isEmpty()) {
            syncImagesOrdered(post, imageOrder, newImages);
        } else {
            syncImages(post, keepImageUrls, newImages);
        }
        replaceReviewTags(post, tagIds);
        steakPostRepository.saveAndFlush(post);
        return loadPostResponse(post.getId(), principal);
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

    private void syncImagesOrdered(SteakPost post, List<String> imageOrder, MultipartFile[] newImages) {
        MultipartFile[] uploads = newImages != null ? newImages : new MultipartFile[0];
        Map<String, PostImage> existingByUrl = post.getImages().stream()
                .collect(Collectors.toMap(PostImage::getImageUrl, Function.identity(), (left, right) -> left));

        Set<String> keepUrls = new LinkedHashSet<>();
        Set<Integer> referencedNewIndexes = new HashSet<>();
        for (String slot : imageOrder) {
            if (slot == null || slot.isBlank()) {
                throw new ResponseStatusException(BAD_REQUEST, "Image order entries cannot be blank");
            }
            if (slot.startsWith(NEW_IMAGE_SLOT_PREFIX)) {
                int index = parseNewImageSlotIndex(slot);
                if (index < 0 || index >= uploads.length) {
                    throw new ResponseStatusException(BAD_REQUEST, "Invalid new image slot in image order");
                }
                if (!referencedNewIndexes.add(index)) {
                    throw new ResponseStatusException(BAD_REQUEST, "Each new image must appear once in image order");
                }
                continue;
            }
            if (!existingByUrl.containsKey(slot)) {
                throw new ResponseStatusException(BAD_REQUEST, "Image order references an unknown existing image");
            }
            keepUrls.add(slot);
        }

        for (int index = 0; index < uploads.length; index++) {
            MultipartFile upload = uploads[index];
            if (upload == null || upload.isEmpty()) {
                continue;
            }
            if (!referencedNewIndexes.contains(index)) {
                throw new ResponseStatusException(BAD_REQUEST, "Each uploaded image must appear once in image order");
            }
        }

        post.getImages().removeIf(image -> !keepUrls.contains(image.getImageUrl()));

        int sortOrder = 0;
        for (String slot : imageOrder) {
            if (slot.startsWith(NEW_IMAGE_SLOT_PREFIX)) {
                int index = parseNewImageSlotIndex(slot);
                MultipartFile upload = uploads[index];
                if (upload == null || upload.isEmpty()) {
                    throw new ResponseStatusException(BAD_REQUEST, "Invalid new image slot in image order");
                }
                post.getImages().add(PostImage.builder()
                        .imageUrl(storeImage(upload))
                        .sortOrder(sortOrder++)
                        .post(post)
                        .build());
                continue;
            }

            PostImage existing = existingByUrl.get(slot);
            if (existing != null) {
                existing.setSortOrder(sortOrder++);
            }
        }

        if (post.getImages().isEmpty()) {
            throw new ResponseStatusException(BAD_REQUEST, "At least one image is required");
        }
    }

    private static int parseNewImageSlotIndex(String slot) {
        try {
            return Integer.parseInt(slot.substring(NEW_IMAGE_SLOT_PREFIX.length()));
        } catch (NumberFormatException ex) {
            throw new ResponseStatusException(BAD_REQUEST, "Invalid new image slot in image order");
        }
    }

    private PostDtos.PostResponse loadPostResponse(UUID postId, UserPrincipal principal) {
        SteakPost post = steakPostRepository.findWithDetailsById(postId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Post not found"));
        boolean bookmarked = principal != null
                && postBookmarkRepository.existsById(new PostBookmarkId(principal.getId(), postId));
        return toResponse(post, principal, bookmarked);
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
        eventPublisher.publishEvent(new NotificationEvent.PostHidden(post.getId(), post.getUser().getId()));
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
        eventPublisher.publishEvent(new NotificationEvent.PostRestored(post.getId(), post.getUser().getId()));
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
        boolean bookmarked = viewer != null
                && postBookmarkRepository.existsById(new PostBookmarkId(viewer.getId(), post.getId()));
        return toResponse(post, viewer, bookmarked);
    }

    public PostDtos.PostResponse toResponse(SteakPost post, UserPrincipal viewer, boolean bookmarked) {
        return buildResponse(post, viewer, bookmarked, false, null);
    }

    public PostDtos.PostResponse toFeedResponse(SteakPost post, UserPrincipal viewer, boolean bookmarked) {
        return buildResponse(post, viewer, bookmarked, true, null);
    }

    public PostDtos.PostResponse toEveryoneFeedResponse(
            SteakPost post, UserPrincipal viewer, boolean bookmarked, boolean authorSubscribed) {
        return buildResponse(post, viewer, bookmarked, true, authorSubscribed);
    }

    private PostDtos.PostResponse buildResponse(
            SteakPost post,
            UserPrincipal viewer,
            boolean bookmarked,
            boolean feedAuthorAvatar,
            Boolean authorSubscribed) {
        List<String> imageUrls = uniqueImageUrls(post.getImages());
        List<PostDtos.ReviewTagSummary> tags = post.getReviewTags().stream()
                .map(link -> reviewTagService.toSummary(link.getTag()))
                .toList();
        boolean includeAuthorModerationFields = viewer != null
                && viewer.getId().equals(post.getUser().getId());
        PostDtos.AuthorSummary author = feedAuthorAvatar
                ? authService.toFeedAuthorSummary(post.getUser(), authorSubscribed)
                : authService.toAuthorSummary(post.getUser());
        return new PostDtos.PostResponse(
                post.getId(),
                post.getTitle(),
                post.getComment(),
                post.getRating(),
                imageUrls,
                post.getRestaurantName(),
                post.getRestaurantLocation(),
                toPlaceSummary(post.getPlace()),
                post.getCreatedAt(),
                post.isHidden(),
                post.isHidden() ? post.getModerationReason() : null,
                includeAuthorModerationFields ? post.getModerationRestoredAt() : null,
                post.getVisibility(),
                author,
                tags,
                bookmarked);
    }

    private List<String> uniqueImageUrls(List<PostImage> images) {
        LinkedHashSet<String> urls = new LinkedHashSet<>();
        images.stream()
                .sorted(Comparator.comparingInt(PostImage::getSortOrder))
                .forEach(image -> urls.add(image.getImageUrl()));
        return new ArrayList<>(urls);
    }

    private String storeImage(MultipartFile image) {
        uploadValidation.validateImage(image);
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

    private void applyPlaceIfPresent(SteakPost post, UUID placeId) {
        if (placeId == null) {
            return;
        }
        Place place = placeRepository.findById(placeId)
                .orElseThrow(() -> new ResponseStatusException(BAD_REQUEST, "Place not found"));
        post.setPlace(place);
        post.setRestaurantName(place.getName());
        post.setRestaurantLocation(place.getFormattedAddress() != null
                ? place.getFormattedAddress()
                : place.getLatitude() + ", " + place.getLongitude());
    }

    private PlaceDtos.PlaceSummary toPlaceSummary(Place place) {
        if (place == null) {
            return null;
        }
        String previewPhotoUrl = null;
        CoverImageSource previewPhotoSource = null;
        if (place.getProviderPhotoName() != null && !place.getProviderPhotoName().isBlank()) {
            previewPhotoUrl = "/places/" + place.getId() + "/provider-photo";
            previewPhotoSource = CoverImageSource.GOOGLE;
        }
        return new PlaceDtos.PlaceSummary(
                place.getId(),
                place.getProvider(),
                place.getName(),
                place.getFormattedAddress(),
                place.getLatitude(),
                place.getLongitude(),
                place.getLocationPrecision(),
                previewPhotoUrl,
                previewPhotoSource);
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
