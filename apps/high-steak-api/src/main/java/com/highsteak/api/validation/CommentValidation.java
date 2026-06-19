package com.highsteak.api.validation;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

import java.util.regex.Pattern;

import static com.highsteak.api.validation.ApiConstraints.COMMENT_BODY_MAX;
import static org.springframework.http.HttpStatus.BAD_REQUEST;

@Component
public class CommentValidation {

    private static final Pattern HTML_TAG = Pattern.compile("<[^>]+>");
    private static final Pattern DISALLOWED_CONTROL = Pattern.compile("[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]");

    public String normalizeAndValidate(String body) {
        if (body == null) {
            throw new ResponseStatusException(BAD_REQUEST, "Comment body is required");
        }

        String normalized = body.strip();
        if (normalized.isEmpty()) {
            throw new ResponseStatusException(BAD_REQUEST, "Comment body is required");
        }
        if (normalized.length() > COMMENT_BODY_MAX) {
            throw new ResponseStatusException(
                    BAD_REQUEST, "Comment must be at most " + COMMENT_BODY_MAX + " characters");
        }
        if (HTML_TAG.matcher(normalized).find()) {
            throw new ResponseStatusException(BAD_REQUEST, "HTML is not allowed in comments");
        }
        if (DISALLOWED_CONTROL.matcher(normalized).find()) {
            throw new ResponseStatusException(BAD_REQUEST, "Comment contains invalid characters");
        }

        return normalized;
    }
}
