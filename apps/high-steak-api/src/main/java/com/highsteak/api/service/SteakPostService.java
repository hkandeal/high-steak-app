package com.highsteak.api.service;

import com.highsteak.api.domain.PostImage;
import com.highsteak.api.domain.PostReviewTag;
import com.highsteak.api.domain.ReviewTag;
import com.highsteak.api.domain.SteakPost;
import com.highsteak.api.domain.User;
import com.highsteak.api.dto.PostDtos;
import com.highsteak.api.repository.ReviewTagRepository;
import com.highsteak.api.repository.SteakPostRepository;
import com.highsteak.api.repository.UserRepository;
import com.highsteak.api.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
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
    private final ReviewTagRepository reviewTagRepository;
    private final ReviewTagService reviewTagService;
    private final AuthService authService;
    private final SubscriptionService subscriptionService;

    @Value("${app.uploads.dir}")
    private String uploadsDir;

    @Transactional(readOnly = true)
    public List<PostDtos.PostResponse> getFeed() {
        return steakPostRepository.findAllByHiddenFalseOrderByCreatedAtDesc().stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public PostDtos.PostResponse getPost(UUID postId) {
        SteakPost post = steakPostRepository.findWithDetailsById(postId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Post not found"));
        if (post.isHidden()) {
            throw new ResponseStatusException(NOT_FOUND, "Post not found");
        }
        return toResponse(post);
    }

    @Transactional(readOnly = true)
    public List<PostDtos.PostResponse> getMyPosts(UserPrincipal principal) {
        return steakPostRepository.findByUserIdOrderByCreatedAtDesc(principal.getId()).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<PostDtos.PostResponse> getHiddenPosts() {
        return steakPostRepository.findByHiddenTrueOrderByCreatedAtDesc().stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<PostDtos.PostResponse> getFollowingFeed(UserPrincipal principal) {
        Set<UUID> followedUserIds = subscriptionService.getSubscribedUserIds(principal.getId());
        if (followedUserIds.isEmpty()) {
            return List.of();
        }
        return steakPostRepository.findByUserIdInAndHiddenFalseOrderByCreatedAtDesc(followedUserIds).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public PostDtos.PostResponse createPost(
            UserPrincipal principal,
            String title,
            String comment,
            int rating,
            String restaurantName,
            String restaurantLocation,
            MultipartFile[] images,
            List<UUID> tagIds) {
        if (rating < 1 || rating > 5) {
            throw new ResponseStatusException(BAD_REQUEST, "Rating must be between 1 and 5");
        }
        if (images == null || images.length == 0) {
            throw new ResponseStatusException(BAD_REQUEST, "At least one image is required");
        }

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
                .title(title)
                .comment(comment)
                .rating((byte) rating)
                .restaurantName(blankToNull(restaurantName))
                .restaurantLocation(blankToNull(restaurantLocation))
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
            List<String> keepImageUrls,
            MultipartFile[] newImages,
            List<UUID> tagIds) {
        if (rating < 1 || rating > 5) {
            throw new ResponseStatusException(BAD_REQUEST, "Rating must be between 1 and 5");
        }

        SteakPost post = steakPostRepository.findWithDetailsById(postId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Post not found"));
        if (!post.getUser().getId().equals(principal.getId())) {
            throw new ResponseStatusException(FORBIDDEN, "Not allowed to edit this post");
        }

        post.setTitle(title);
        post.setComment(comment);
        post.setRating((byte) rating);
        post.setRestaurantName(blankToNull(restaurantName));
        post.setRestaurantLocation(blankToNull(restaurantLocation));

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
        if (uniqueTagIds.size() > 12) {
            throw new ResponseStatusException(BAD_REQUEST, "You can select up to 12 tags");
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
        if (desired.size() > 12) {
            throw new ResponseStatusException(BAD_REQUEST, "You can select up to 12 tags");
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
    public PostDtos.PostResponse hidePost(UUID postId) {
        SteakPost post = steakPostRepository.findWithDetailsById(postId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Post not found"));
        post.setHidden(true);
        post = steakPostRepository.save(post);
        return toResponse(post);
    }

    public PostDtos.PostResponse toResponse(SteakPost post) {
        List<String> imageUrls = uniqueImageUrls(post.getImages());
        List<PostDtos.ReviewTagSummary> tags = post.getReviewTags().stream()
                .map(link -> reviewTagService.toSummary(link.getTag()))
                .toList();
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
}
