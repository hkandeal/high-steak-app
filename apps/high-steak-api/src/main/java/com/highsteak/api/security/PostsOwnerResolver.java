package com.highsteak.api.security;

import com.highsteak.api.repository.SteakPostRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class PostsOwnerResolver implements ResourceOwnerResolver {

    private final SteakPostRepository steakPostRepository;

    @Override
    public String resource() {
        return "posts";
    }

    @Override
    public Optional<UUID> findOwnerId(UUID resourceId) {
        return steakPostRepository.findById(resourceId)
                .map(post -> post.getUser().getId());
    }
}
