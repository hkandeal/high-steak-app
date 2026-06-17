package com.highsteak.api.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@ConfigurationProperties(prefix = "app.logging")
public class ApiLoggingProperties {

    private boolean httpAccessEnabled = true;

    private List<String> skipPaths = new ArrayList<>(List.of(
            "/health",
            "/config",
            "/swagger-ui",
            "/v3/api-docs",
            "/uploads"
    ));
}
