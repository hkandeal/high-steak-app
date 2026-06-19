package com.highsteak.api.db.migration;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.sql.Connection;
import java.sql.Statement;

public class V16__Utf8mb4TextColumns extends BaseJavaMigration {

    @Override
    public void migrate(Context context) throws Exception {
        Connection conn = context.getConnection();
        if (!conn.getMetaData().getDatabaseProductName().toLowerCase().contains("mysql")) {
            return;
        }

        try (Statement stmt = conn.createStatement()) {
            stmt.execute("""
                    ALTER TABLE post_comments
                    MODIFY body TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL
                    """);
            stmt.execute("""
                    ALTER TABLE steak_posts
                    MODIFY comment TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL
                    """);
            stmt.execute("""
                    ALTER TABLE steak_posts
                    MODIFY title VARCHAR(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL
                    """);
            stmt.execute("""
                    ALTER TABLE users
                    MODIFY display_name VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL
                    """);
        }
    }
}
