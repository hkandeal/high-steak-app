package com.highsteak.api.controller;

import com.highsteak.api.config.UploadProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequiredArgsConstructor
public class AppConfigController {

    private final UploadProperties uploadProperties;

    @GetMapping("/config")
    public Map<String, Object> config() {
        return Map.of(
                "maxImageSizeMb", uploadProperties.getMaxImageSizeMb(),
                "maxImagesPerPost", uploadProperties.getMaxImagesPerPost(),
                "maxImageBytes", uploadProperties.maxImageBytes());
    }
}
