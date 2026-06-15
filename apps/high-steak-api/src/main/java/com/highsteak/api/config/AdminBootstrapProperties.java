package com.highsteak.api.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Getter
@Setter
@ConfigurationProperties(prefix = "app.bootstrap.admin")
public class AdminBootstrapProperties {

    private boolean enabled = true;
    private String username = "admin";
    private String password = "AdminPass123!";
    private String email = "admin@high-steak.local";
    private String displayName = "System Admin";
}
