package com.vnmap.common.model;

import java.util.List;

public record PagedResponse<T>(
        List<T> items,
        int page,
        int limit,
        long totalItems,
        int totalPages
) {
    public static <T> PagedResponse<T> of(List<T> items, int page, int limit, long totalItems) {
        int totalPages = limit <= 0 ? 0 : (int) Math.ceil((double) totalItems / limit);
        return new PagedResponse<>(items, page, limit, totalItems, totalPages);
    }
}
