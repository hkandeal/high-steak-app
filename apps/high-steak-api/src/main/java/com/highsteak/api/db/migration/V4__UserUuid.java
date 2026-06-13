package com.highsteak.api.db.migration;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

public class V4__UserUuid extends BaseJavaMigration {

    @Override
    public void migrate(Context context) throws Exception {
        Connection conn = context.getConnection();
        boolean h2 = conn.getMetaData().getDatabaseProductName().toLowerCase().contains("h2");

        try (Statement stmt = conn.createStatement()) {
            stmt.execute("ALTER TABLE users ADD COLUMN new_id CHAR(36)");
            stmt.execute("ALTER TABLE steak_posts ADD COLUMN new_user_id CHAR(36)");

            Map<Long, String> idMap = new HashMap<>();
            try (ResultSet rs = stmt.executeQuery("SELECT id FROM users")) {
                while (rs.next()) {
                    long oldId = rs.getLong("id");
                    String uuid = UUID.randomUUID().toString();
                    idMap.put(oldId, uuid);
                    try (PreparedStatement ps = conn.prepareStatement("UPDATE users SET new_id = ? WHERE id = ?")) {
                        ps.setString(1, uuid);
                        ps.setLong(2, oldId);
                        ps.executeUpdate();
                    }
                }
            }

            for (Map.Entry<Long, String> entry : idMap.entrySet()) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE steak_posts SET new_user_id = ? WHERE user_id = ?")) {
                    ps.setString(1, entry.getValue());
                    ps.setLong(2, entry.getKey());
                    ps.executeUpdate();
                }
            }

            stmt.execute("ALTER TABLE steak_posts DROP FOREIGN KEY fk_steak_posts_user");
            stmt.execute("ALTER TABLE steak_posts DROP COLUMN user_id");

            if (h2) {
                stmt.execute("ALTER TABLE steak_posts RENAME COLUMN new_user_id TO user_id");
                stmt.execute("ALTER TABLE steak_posts ALTER COLUMN user_id SET NOT NULL");
            } else {
                stmt.execute("ALTER TABLE steak_posts CHANGE new_user_id user_id CHAR(36) NOT NULL");
            }

            if (h2) {
                stmt.execute("ALTER TABLE users DROP PRIMARY KEY");
                stmt.execute("ALTER TABLE users DROP COLUMN id");
                stmt.execute("ALTER TABLE users RENAME COLUMN new_id TO id");
                stmt.execute("ALTER TABLE users ALTER COLUMN id SET NOT NULL");
                stmt.execute("ALTER TABLE users ADD PRIMARY KEY (id)");
            } else {
                stmt.execute("ALTER TABLE users DROP PRIMARY KEY, DROP COLUMN id");
                stmt.execute("ALTER TABLE users CHANGE COLUMN new_id id CHAR(36) NOT NULL PRIMARY KEY");
            }

            stmt.execute("""
                    ALTER TABLE steak_posts
                    ADD CONSTRAINT fk_steak_posts_user
                    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
                    """);
        }
    }
}
