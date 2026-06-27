package com.highsteak.api.db.migration;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.sql.Connection;
import java.sql.Statement;

/**
 * Places (and legacy post venue fields) were created without explicit utf8mb4 columns.
 * Arabic and other non-Latin addresses from Google Places fail with
 * "Incorrect string value" on prod MySQL defaults (latin1 / utf8 3-byte).
 */
public class V23__PlacesUtf8mb4Text extends BaseJavaMigration {

    @Override
    public void migrate(Context context) throws Exception {
        Connection conn = context.getConnection();
        if (!conn.getMetaData().getDatabaseProductName().toLowerCase().contains("mysql")) {
            return;
        }

        try (Statement stmt = conn.createStatement()) {
            stmt.execute("""
                    ALTER TABLE places
                    MODIFY name VARCHAR(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL
                    """);
            stmt.execute("""
                    ALTER TABLE places
                    MODIFY formatted_address VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL
                    """);
            stmt.execute("""
                    ALTER TABLE places
                    MODIFY locality VARCHAR(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL
                    """);
            stmt.execute("""
                    ALTER TABLE places
                    MODIFY admin_area VARCHAR(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL
                    """);
            stmt.execute("""
                    ALTER TABLE steak_posts
                    MODIFY restaurant_name VARCHAR(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL
                    """);
            stmt.execute("""
                    ALTER TABLE steak_posts
                    MODIFY restaurant_location VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL
                    """);
        }
    }
}
