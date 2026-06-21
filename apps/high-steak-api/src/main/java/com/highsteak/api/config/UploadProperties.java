package com.highsteak.api.config;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Getter
@Setter
@Validated
@ConfigurationProperties(prefix = "app.uploads")
public class UploadProperties {

    @Min(1)
    @Max(50)
    private int maxImageSizeMb = 5;

    @Min(1)
    @Max(20)
    private int maxImagesPerPost = 10;

    public long maxImageBytes() {
        return maxImageSizeMb * 1024L * 1024L;
    }

    /** Multipart request cap: all images plus small form/metadata overhead. */
    public long maxRequestSizeMb() {
        return (long) maxImageSizeMb * maxImagesPerPost + 3L;
    }
}
