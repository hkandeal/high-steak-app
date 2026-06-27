package com.highsteak.api.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "app.geo")
@Getter
@Setter
public class GeoProperties {

    private int defaultRadiusM = 50_000;
    private int maxRadiusM = 50_000;
    private String placeProvider = "google";

    private Google google = new Google();

    @Getter
    @Setter
    public static class Google {
        private String apiKey = "";
        private boolean enabled = false;
    }
}
