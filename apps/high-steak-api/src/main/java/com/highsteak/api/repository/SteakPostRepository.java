package com.highsteak.api.repository;

import com.highsteak.api.domain.SteakPost;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SteakPostRepository extends JpaRepository<SteakPost, Long> {
    List<SteakPost> findAllByOrderByCreatedAtDesc();
    List<SteakPost> findByUserIdOrderByCreatedAtDesc(Long userId);
}
