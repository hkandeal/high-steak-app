package com.highsteak.api.repository;

import com.highsteak.api.domain.ReviewTag;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

public interface ReviewTagRepository extends JpaRepository<ReviewTag, UUID> {

    List<ReviewTag> findByActiveTrueOrderBySortOrderAsc();

    List<ReviewTag> findByIdInAndActiveTrue(Collection<UUID> ids);
}
