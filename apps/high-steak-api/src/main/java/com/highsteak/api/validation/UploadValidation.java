package com.highsteak.api.validation;

import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import static org.springframework.http.HttpStatus.BAD_REQUEST;

public final class UploadValidation {

    private UploadValidation() {}

    public static void requireImage(MultipartFile file, String label) {
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(BAD_REQUEST, label + " is required");
        }
        validateImage(file);
    }

    public static void validateImage(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            return;
        }
        if (file.getSize() > ApiConstraints.MAX_IMAGE_BYTES) {
            throw new ResponseStatusException(
                    BAD_REQUEST,
                    "Each image must be 1 MB or smaller (received "
                            + formatMegabytes(file.getSize())
                            + " MB)");
        }
        String contentType = file.getContentType();
        if (contentType != null && !contentType.startsWith("image/")) {
            throw new ResponseStatusException(BAD_REQUEST, "Upload must be an image file");
        }
    }

    public static void validateImages(MultipartFile[] files) {
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
