package com.highsteak.api.validation;

import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class CommentValidationTest {

    private final CommentValidation validation = new CommentValidation();

    @Test
    void acceptsEmojiAndNewlines() {
        String body = "Great sear 🔥\nLove the crust!";
        assertEquals(body, validation.normalizeAndValidate(body));
    }

    @Test
    void rejectsHtmlTags() {
        assertThrows(
                ResponseStatusException.class,
                () -> validation.normalizeAndValidate("Nice <b>crust</b>"));
    }

    @Test
    void rejectsEmptyBody() {
        assertThrows(ResponseStatusException.class, () -> validation.normalizeAndValidate("   "));
    }
}
