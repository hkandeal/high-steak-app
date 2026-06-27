package com.highsteak.api.config;

import com.highsteak.api.db.migration.FlywayV21HistoryRepair;
import com.highsteak.api.db.migration.V19__AccountDeletion;
import com.highsteak.api.db.migration.V20__PasswordReset;
import com.highsteak.api.db.migration.V21__GeoPlaces;
import com.highsteak.api.db.migration.V23__PlacesUtf8mb4Text;
import com.highsteak.api.db.migration.V4__UserUuid;
import com.highsteak.api.db.migration.V7__PostUuid;
import com.highsteak.api.db.migration.V16__Utf8mb4TextColumns;
import org.springframework.boot.autoconfigure.flyway.FlywayConfigurationCustomizer;
import org.springframework.boot.autoconfigure.flyway.FlywayMigrationStrategy;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.sql.DataSource;

@Configuration
public class FlywayConfig {

    @Bean
    FlywayConfigurationCustomizer registerJavaMigrations() {
        return configuration -> configuration.javaMigrations(
                new V4__UserUuid(),
                new V7__PostUuid(),
                new V16__Utf8mb4TextColumns(),
                new V19__AccountDeletion(),
                new V20__PasswordReset(),
                new V21__GeoPlaces(),
                new V23__PlacesUtf8mb4Text());
    }

    @Bean
    FlywayMigrationStrategy flywayMigrationStrategy(DataSource dataSource) {
        return flyway -> {
            FlywayV21HistoryRepair.repairIfNeeded(dataSource);
            flyway.migrate();
        };
    }
}
