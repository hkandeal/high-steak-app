package com.highsteak.api.validation;

import com.highsteak.api.config.UploadProperties;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;

class UploadValidationTest {

    @Test
    void rejectsImageLargerThanConfiguredLimit() {
        UploadProperties properties = new UploadProperties();
        properties.setMaxImageSizeMb(3);
        UploadValidation validation = new UploadValidation(properties);

        byte[] tooLarge = new byte[(int) properties.maxImageBytes() + 1];
        MockMultipartFile file = new MockMultipartFile("image", "steak.jpg", "image/jpeg", tooLarge);

        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> validation.validateImage(file));
    }

    @Test
    void acceptsImageWithinConfiguredLimit() {
        UploadProperties properties = new UploadProperties();
        properties.setMaxImageSizeMb(3);
        UploadValidation validation = new UploadValidation(properties);

        MockMultipartFile file = new MockMultipartFile("image", "steak.jpg", "image/jpeg", new byte[1024]);

        assertDoesNotThrow(() -> validation.validateImage(file));
    }
}
