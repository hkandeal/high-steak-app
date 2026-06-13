package com.highsteak.api.validation;

import org.springframework.web.server.ResponseStatusException;

import java.util.regex.Pattern;

import static org.springframework.http.HttpStatus.BAD_REQUEST;

public final class EmailValidation {

    private static final Pattern EMAIL_PATTERN = Pattern.compile(
            "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");

    private EmailValidation() {}

    public static String require(String email) {
        if (email == null || email.isBlank()) {
            throw new ResponseStatusException(BAD_REQUEST, "Email is required");
        }
        String trimmed = email.trim();
        String bounded = TextValidation.bounded(trimmed, "Email", 1, ApiConstraints.EMAIL_MAX);
        String formatError = formatError(bounded);
        if (formatError != null) {
            throw new ResponseStatusException(BAD_REQUEST, formatError);
        }
        return bounded;
    }

    public static String formatError(String email) {
        if (email == null || email.isBlank()) {
            return "Email is required";
        }
        String trimmed = email.trim();
        if (trimmed.length() > ApiConstraints.EMAIL_MAX) {
            return "Email must be at most " + ApiConstraints.EMAIL_MAX + " characters";
        }
        if (!EMAIL_PATTERN.matcher(trimmed).matches()) {
            return "Enter a valid email address";
        }
        return null;
    }
}
