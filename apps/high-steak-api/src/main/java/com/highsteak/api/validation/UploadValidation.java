package com.highsteak.api.validation;

import com.highsteak.api.config.UploadProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import static org.springframework.http.HttpStatus.BAD_REQUEST;

@Component
@RequiredArgsConstructor
public class UploadValidation {

    private final UploadProperties uploadProperties;

    public void requireImage(MultipartFile file, String label) {
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(BAD_REQUEST, label + " is required");
        }
        validateImage(file);
    }

    public void validateImage(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            return;
        }
        long maxBytes = uploadProperties.maxImageBytes();
        if (file.getSize() > maxBytes) {
            throw new ResponseStatusException(
                    BAD_REQUEST,
                    "Each image must be "
                            + uploadProperties.getMaxImageSizeMb()
                            + " MB or smaller (received "
                            + formatMegabytes(file.getSize())
                            + " MB)");
        }
        String contentType = file.getContentType();
        if (contentType != null && !contentType.startsWith("image/")) {
            throw new ResponseStatusException(BAD_REQUEST, "Upload must be an image file");
        }
    }

    public void validateImages(MultipartFile[] files) {
        if (files == null) {
            return;
        }
        for (MultipartFile file : files) {
            validateImage(file);
        }
    }

    private static String formatMegabytes(long bytes) {
        return String.format("%.2f", bytes / 1_048_576.0);
    }
}
