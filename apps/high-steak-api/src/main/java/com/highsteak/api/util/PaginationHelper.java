package com.highsteak.api.util;

import com.highsteak.api.dto.PageDtos;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.util.function.Function;

public final class PaginationHelper {

    public static final int DEFAULT_PAGE_SIZE = 20;
    public static final int MAX_PAGE_SIZE = 50;

    private PaginationHelper() {}

    public static Pageable pageable(int page, int size) {
        int pageSize = Math.min(Math.max(size, 1), MAX_PAGE_SIZE);
        int pageIndex = Math.max(page, 0);
        return PageRequest.of(pageIndex, pageSize);
    }

    public static <T, R> PageDtos.PageResponse<R> toPageResponse(Page<T> page, Function<T, R> mapper) {
        return new PageDtos.PageResponse<>(
                page.getContent().stream().map(mapper).toList(),
                page.getNumber(),
                page.getSize(),
                page.getTotalElements(),
                page.getTotalPages());
    }

    public static <T> PageDtos.PageResponse<T> toPageResponse(Page<T> page) {
        return new PageDtos.PageResponse<>(
                page.getContent(),
                page.getNumber(),
                page.getSize(),
                page.getTotalElements(),
                page.getTotalPages());
    }
}
