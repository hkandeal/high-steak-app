package com.highsteak.api.controller;

import com.highsteak.api.dto.PostDtos;
import com.highsteak.api.security.UserPrincipal;
import com.highsteak.api.service.SteakPostService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/posts")
@RequiredArgsConstructor
public class SteakPostController {

    private final SteakPostService steakPostService;

    @GetMapping
    public List<PostDtos.PostResponse> getFeed() {
        return steakPostService.getFeed();
    }

    @GetMapping("/mine")
    public List<PostDtos.PostResponse> getMyPosts(@AuthenticationPrincipal UserPrincipal principal) {
        return steakPostService.getMyPosts(principal);
    }

    @PostMapping(consumes = "multipart/form-data")
    @ResponseStatus(HttpStatus.CREATED)
    public PostDtos.PostResponse createPost(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam String title,
            @RequestParam(required = false) String comment,
            @RequestParam int rating,
            @RequestParam("image") MultipartFile image) {
        return steakPostService.createPost(principal, title, comment, rating, image);
    }
}
