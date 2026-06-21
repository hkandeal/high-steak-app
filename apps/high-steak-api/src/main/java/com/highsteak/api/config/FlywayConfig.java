package com.highsteak.api.config;

import com.highsteak.api.db.migration.V19__AccountDeletion;
import com.highsteak.api.db.migration.V4__UserUuid;
import com.highsteak.api.db.migration.V7__PostUuid;
import com.highsteak.api.db.migration.V16__Utf8mb4TextColumns;
import org.springframework.boot.autoconfigure.flyway.FlywayConfigurationCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class FlywayConfig {

    @Bean
    FlywayConfigurationCustomizer registerJavaMigrations() {
        return configuration -> configuration.javaMigrations(
                new V4__UserUuid(),
                new V7__PostUuid(),
                new V16__Utf8mb4TextColumns(),
                new V19__AccountDeletion());
    }
}
