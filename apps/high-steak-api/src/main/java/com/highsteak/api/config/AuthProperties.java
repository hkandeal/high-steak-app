package com.highsteak.api.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "app.auth")
@Getter
@Setter
public class AuthProperties {

    /** When true (tests), skip verification email and issue tokens on register. */
    private boolean autoVerifyOnRegister = false;

    /** Hours until a verification link expires. */
    private int verificationExpirationHours = 24;
}
