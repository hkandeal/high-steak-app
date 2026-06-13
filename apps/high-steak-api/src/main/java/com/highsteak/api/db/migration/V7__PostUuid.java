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

public class V7__PostUuid extends BaseJavaMigration {

    @Override
    public void migrate(Context context) throws Exception {
        Connection conn = context.getConnection();
        boolean h2 = conn.getMetaData().getDatabaseProductName().toLowerCase().contains("h2");

        try (Statement stmt = conn.createStatement()) {
            stmt.execute("ALTER TABLE steak_posts ADD COLUMN new_id CHAR(36)");
            stmt.execute("ALTER TABLE post_images ADD COLUMN new_post_id CHAR(36)");
            stmt.execute("ALTER TABLE post_comments ADD COLUMN new_id CHAR(36)");
            stmt.execute("ALTER TABLE post_comments ADD COLUMN new_post_id CHAR(36)");

            Map<Long, String> postIdMap = new HashMap<>();
            try (ResultSet rs = stmt.executeQuery("SELECT id FROM steak_posts")) {
                while (rs.next()) {
                    long oldId = rs.getLong("id");
                    String uuid = UUID.randomUUID().toString();
                    postIdMap.put(oldId, uuid);
                    try (PreparedStatement ps = conn.prepareStatement(
                            "UPDATE steak_posts SET new_id = ? WHERE id = ?")) {
                        ps.setString(1, uuid);
                        ps.setLong(2, oldId);
                        ps.executeUpdate();
                    }
                }
            }

            for (Map.Entry<Long, String> entry : postIdMap.entrySet()) {
                String newPostId = entry.getValue();
                long oldPostId = entry.getKey();
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE post_images SET new_post_id = ? WHERE post_id = ?")) {
                    ps.setString(1, newPostId);
                    ps.setLong(2, oldPostId);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE post_comments SET new_post_id = ? WHERE post_id = ?")) {
                    ps.setString(1, newPostId);
                    ps.setLong(2, oldPostId);
                    ps.executeUpdate();
                }
            }

            try (ResultSet rs = stmt.executeQuery("SELECT id FROM post_comments")) {
                while (rs.next()) {
                    long oldId = rs.getLong("id");
                    try (PreparedStatement ps = conn.prepareStatement(
                            "UPDATE post_comments SET new_id = ? WHERE id = ?")) {
                        ps.setString(1, UUID.randomUUID().toString());
                        ps.setLong(2, oldId);
                        ps.executeUpdate();
                    }
                }
            }

            stmt.execute("ALTER TABLE post_images DROP FOREIGN KEY fk_post_images_post");
            stmt.execute("ALTER TABLE post_comments DROP FOREIGN KEY fk_post_comments_post");

            if (h2) {
                stmt.execute("DROP INDEX idx_post_images_post");
                stmt.execute("DROP INDEX idx_post_comments_post");
            } else {
                stmt.execute("DROP INDEX idx_post_images_post ON post_images");
                stmt.execute("DROP INDEX idx_post_comments_post ON post_comments");
            }

            stmt.execute("ALTER TABLE post_images DROP COLUMN post_id");
            if (h2) {
                stmt.execute("ALTER TABLE post_images RENAME COLUMN new_post_id TO post_id");
                stmt.execute("ALTER TABLE post_images ALTER COLUMN post_id SET NOT NULL");
            } else {
                stmt.execute("ALTER TABLE post_images CHANGE new_post_id post_id CHAR(36) NOT NULL");
            }

            if (h2) {
                stmt.execute("ALTER TABLE post_comments DROP PRIMARY KEY");
                stmt.execute("ALTER TABLE post_comments DROP COLUMN id");
                stmt.execute("ALTER TABLE post_comments DROP COLUMN post_id");
                stmt.execute("ALTER TABLE post_comments RENAME COLUMN new_id TO id");
                stmt.execute("ALTER TABLE post_comments RENAME COLUMN new_post_id TO post_id");
                stmt.execute("ALTER TABLE post_comments ALTER COLUMN id SET NOT NULL");
                stmt.execute("ALTER TABLE post_comments ALTER COLUMN post_id SET NOT NULL");
                stmt.execute("ALTER TABLE post_comments ADD PRIMARY KEY (id)");
            } else {
                stmt.execute("ALTER TABLE post_comments DROP PRIMARY KEY, DROP COLUMN id, DROP COLUMN post_id");
                stmt.execute("ALTER TABLE post_comments CHANGE new_id id CHAR(36) NOT NULL PRIMARY KEY");
                stmt.execute("ALTER TABLE post_comments CHANGE new_post_id post_id CHAR(36) NOT NULL");
            }

            if (h2) {
                stmt.execute("ALTER TABLE steak_posts DROP PRIMARY KEY");
                stmt.execute("ALTER TABLE steak_posts DROP COLUMN id");
                stmt.execute("ALTER TABLE steak_posts RENAME COLUMN new_id TO id");
                stmt.execute("ALTER TABLE steak_posts ALTER COLUMN id SET NOT NULL");
                stmt.execute("ALTER TABLE steak_posts ADD PRIMARY KEY (id)");
            } else {
                stmt.execute("ALTER TABLE steak_posts DROP PRIMARY KEY, DROP COLUMN id");
                stmt.execute("ALTER TABLE steak_posts CHANGE new_id id CHAR(36) NOT NULL PRIMARY KEY");
            }

            stmt.execute("""
                    ALTER TABLE post_images
                    ADD CONSTRAINT fk_post_images_post
                    FOREIGN KEY (post_id) REFERENCES steak_posts (id) ON DELETE CASCADE
                    """);
            stmt.execute("""
                    ALTER TABLE post_comments
                    ADD CONSTRAINT fk_post_comments_post
                    FOREIGN KEY (post_id) REFERENCES steak_posts (id) ON DELETE CASCADE
                    """);
            stmt.execute("CREATE INDEX idx_post_images_post ON post_images (post_id, sort_order)");
            stmt.execute("CREATE INDEX idx_post_comments_post ON post_comments (post_id, created_at)");
        }
    }
}
