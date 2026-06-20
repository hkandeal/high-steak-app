package com.highsteak.api.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "app.mail")
@Getter
@Setter
public class MailProperties {

    private boolean enabled = false;
    private String from = "High Steaks <noreply@notify.hossam.io>";
    private String baseUrl = "https://steaks.apps.hossam.io";
}
