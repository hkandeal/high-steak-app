package com.highsteak.api.config;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableConfigurationProperties(ApiLoggingProperties.class)
public class ApiLoggingConfig {
}
