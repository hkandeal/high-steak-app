package com.highsteak.api.validation;

import org.springframework.web.server.ResponseStatusException;

import java.util.regex.Pattern;

import static org.springframework.http.HttpStatus.BAD_REQUEST;

public final class UsernameValidation {

    /** Letters, digits, underscore, hyphen; must start with a letter. */
    private static final Pattern USERNAME_PATTERN = Pattern.compile("^[a-zA-Z][a-zA-Z0-9_-]*$");

    private UsernameValidation() {}

    public static String require(String username) {
        if (username == null || username.isBlank()) {
            throw new ResponseStatusException(BAD_REQUEST, "Username is required");
        }
        String trimmed = username.trim();
        String bounded = TextValidation.bounded(
                trimmed, "Username", ApiConstraints.USERNAME_MIN, ApiConstraints.USERNAME_MAX);
        String formatError = formatError(bounded);
        if (formatError != null) {
            throw new ResponseStatusException(BAD_REQUEST, formatError);
        }
        return bounded;
    }

    public static String formatError(String username) {
        if (username == null || username.isBlank()) {
            return "Username is required";
        }
        String trimmed = username.trim();
        if (trimmed.length() < ApiConstraints.USERNAME_MIN) {
            return "Username must be at least " + ApiConstraints.USERNAME_MIN + " characters";
        }
        if (trimmed.length() > ApiConstraints.USERNAME_MAX) {
            return "Username must be at most " + ApiConstraints.USERNAME_MAX + " characters";
        }
        if (Character.isDigit(trimmed.charAt(0))) {
            return "Username must not start with a number";
        }
        if (!USERNAME_PATTERN.matcher(trimmed).matches()) {
            return "Username can only contain letters, numbers, underscores, and hyphens";
        }
        return null;
    }
}
