package com.highsteak.api.service;

import com.highsteak.api.domain.SteakPost;
import com.highsteak.api.domain.User;
import com.highsteak.api.dto.AuthDtos;
import com.highsteak.api.dto.PostDtos;
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
import java.util.List;
import java.util.UUID;

import static org.springframework.http.HttpStatus.BAD_REQUEST;
import static org.springframework.http.HttpStatus.NOT_FOUND;

@Service
@RequiredArgsConstructor
public class SteakPostService {

    private final SteakPostRepository steakPostRepository;
    private final UserRepository userRepository;

    @Value("${app.uploads.dir}")
    private String uploadsDir;

    @Transactional(readOnly = true)
    public List<PostDtos.PostResponse> getFeed() {
        return steakPostRepository.findAllByOrderByCreatedAtDesc().stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<PostDtos.PostResponse> getMyPosts(UserPrincipal principal) {
        return steakPostRepository.findByUserIdOrderByCreatedAtDesc(principal.getId()).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public PostDtos.PostResponse createPost(
            UserPrincipal principal,
            String title,
            String comment,
            int rating,
            MultipartFile image) {
        if (rating < 1 || rating > 5) {
            throw new ResponseStatusException(BAD_REQUEST, "Rating must be between 1 and 5");
        }
        if (image == null || image.isEmpty()) {
            throw new ResponseStatusException(BAD_REQUEST, "Image is required");
        }

        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "User not found"));

        String imageUrl = storeImage(image);

        SteakPost post = SteakPost.builder()
                .user(user)
                .title(title)
                .comment(comment)
                .rating((byte) rating)
                .imageUrl(imageUrl)
                .build();

        post = steakPostRepository.save(post);
        return toResponse(post);
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

    private PostDtos.PostResponse toResponse(SteakPost post) {
        return new PostDtos.PostResponse(
                post.getId(),
                post.getTitle(),
                post.getComment(),
                post.getRating(),
                post.getImageUrl(),
                post.getCreatedAt(),
                AuthService.toSummary(post.getUser()));
    }
}
