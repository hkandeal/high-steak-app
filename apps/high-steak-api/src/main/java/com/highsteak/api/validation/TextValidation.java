package com.highsteak.api.validation;

import org.springframework.web.server.ResponseStatusException;

import static org.springframework.http.HttpStatus.BAD_REQUEST;

public final class TextValidation {

    private TextValidation() {}

    public static String require(String value, String field, int min, int max) {
        if (value == null || value.isBlank()) {
            throw new ResponseStatusException(BAD_REQUEST, field + " is required");
        }
        return bounded(value.trim(), field, min, max);
    }

    public static String optional(String value, String field, int max) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        if (trimmed.isEmpty()) {
            return null;
        }
        return bounded(trimmed, field, 0, max);
    }

    public static String bounded(String value, String field, int min, int max) {
        if (value.length() < min) {
            throw new ResponseStatusException(
                    BAD_REQUEST,
                    field + " must be at least " + min + " characters");
        }
        if (value.length() > max) {
            throw new ResponseStatusException(
                    BAD_REQUEST,
                    field + " must be at most " + max + " characters");
        }
        return value;
    }

    public static void requireRating(int rating) {
        if (rating < 1 || rating > 5) {
            throw new ResponseStatusException(BAD_REQUEST, "Rating must be between 1 and 5");
        }
    }

    public static String requireSearchQuery(String query) {
        if (query == null || query.isBlank()) {
            throw new ResponseStatusException(BAD_REQUEST, "Search query is required");
        }
        return bounded(query.trim(), "Search query", ApiConstraints.SEARCH_QUERY_MIN, ApiConstraints.SEARCH_QUERY_MAX);
    }
}
