package com.highsteak.api.db.migration;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;

public class V21__GeoPlaces extends BaseJavaMigration {

    @Override
    public void migrate(Context context) throws Exception {
        Connection conn = context.getConnection();
        boolean mysql = conn.getMetaData().getDatabaseProductName().toLowerCase().contains("mysql");

        String placeIdNotNull = "CHAR(36) NOT NULL";
        String placeIdNullable = "CHAR(36) NULL";

        if (mysql) {
            ColumnCharset steakPostsId = columnCharset(conn, "steak_posts", "id");
            placeIdNotNull = charColumnNotNull(steakPostsId);
            placeIdNullable = charColumnNullable(steakPostsId);
        }

        try (Statement stmt = conn.createStatement()) {
            stmt.execute("""
                    CREATE TABLE places (
                        id                  %s,
                        provider            VARCHAR(32)   NOT NULL,
                        provider_place_id   VARCHAR(255)  NOT NULL,
                        name                VARCHAR(120)  NOT NULL,
                        formatted_address   VARCHAR(255)  NULL,
                        locality            VARCHAR(120)  NULL,
                        admin_area          VARCHAR(120)  NULL,
                        country_code        VARCHAR(2)    NULL,
                        latitude            DECIMAL(9, 6) NOT NULL,
                        longitude           DECIMAL(9, 6) NOT NULL,
                        location_precision  VARCHAR(16)   NOT NULL DEFAULT 'EXACT',
                        created_at          TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        updated_at          TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                        PRIMARY KEY (id),
                        CONSTRAINT uk_places_provider_place UNIQUE (provider, provider_place_id),
                        CONSTRAINT chk_places_provider CHECK (provider IN ('google', 'mapbox', 'osm', 'manual')),
                        CONSTRAINT chk_places_precision CHECK (location_precision IN ('EXACT', 'APPROXIMATE'))
                    )
                    """.formatted(placeIdNotNull));
            stmt.execute("CREATE INDEX idx_places_lat_lng ON places (latitude, longitude)");
            stmt.execute("CREATE INDEX idx_places_name ON places (name)");
            stmt.execute("ALTER TABLE steak_posts ADD COLUMN place_id %s".formatted(placeIdNullable));
            stmt.execute("""
                    ALTER TABLE steak_posts
                        ADD CONSTRAINT fk_steak_posts_place
                            FOREIGN KEY (place_id) REFERENCES places (id) ON DELETE SET NULL
                    """);
            stmt.execute("CREATE INDEX idx_steak_posts_place_created ON steak_posts (place_id, created_at DESC)");
            stmt.execute("""
                    INSERT INTO permissions (resource, action, qualifier, scope) VALUES
                        ('places', 'read', NULL, 'places:read')
                    """);
            stmt.execute("""
                    INSERT INTO role_permissions (role_id, permission_id)
                    SELECT r.id, p.id
                    FROM roles r
                    CROSS JOIN permissions p
                    WHERE r.name IN ('USER', 'MODERATOR', 'ADMIN')
                      AND p.scope = 'places:read'
                    """);
        }
    }

    private static String charColumnNotNull(ColumnCharset charset) {
        if (charset.collation() == null || charset.collation().isBlank()) {
            return "CHAR(36) NOT NULL";
        }
        return "CHAR(36) CHARACTER SET %s COLLATE %s NOT NULL"
                .formatted(charset.characterSet(), charset.collation());
    }

    private static String charColumnNullable(ColumnCharset charset) {
        if (charset.collation() == null || charset.collation().isBlank()) {
            return "CHAR(36) NULL";
        }
        return "CHAR(36) CHARACTER SET %s COLLATE %s NULL"
                .formatted(charset.characterSet(), charset.collation());
    }

    private static ColumnCharset columnCharset(Connection conn, String table, String column) throws Exception {
        try (PreparedStatement ps = conn.prepareStatement("""
                SELECT CHARACTER_SET_NAME, COLLATION_NAME
                FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE()
                  AND TABLE_NAME = ?
                  AND COLUMN_NAME = ?
                """)) {
            ps.setString(1, table);
            ps.setString(2, column);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return new ColumnCharset(null, null);
                }
                return new ColumnCharset(rs.getString(1), rs.getString(2));
            }
        }
    }

    private record ColumnCharset(String characterSet, String collation) {}
}
