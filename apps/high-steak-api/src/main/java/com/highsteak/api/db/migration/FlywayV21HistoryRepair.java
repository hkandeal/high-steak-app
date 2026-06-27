package com.highsteak.api.db.migration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

/**
 * Reconciles databases that applied the retired {@code V21__geo_places.sql} migration
 * with the Java migration registered in {@link com.highsteak.api.config.FlywayConfig}.
 * Schema is left untouched; only {@code flyway_schema_history} is updated.
 */
public final class FlywayV21HistoryRepair {

    private static final Logger log = LoggerFactory.getLogger(FlywayV21HistoryRepair.class);

    static final String JDBC_SCRIPT = "com.highsteak.api.db.migration.V21__GeoPlaces";
    static final String JDBC_DESCRIPTION = "GeoPlaces";

    private FlywayV21HistoryRepair() {}

    public static void repairIfNeeded(DataSource dataSource) {
        try (Connection conn = dataSource.getConnection()) {
            if (!tableExists(conn, "flyway_schema_history")
                    || !isAppliedSqlV21(conn)
                    || !geoSchemaComplete(conn)) {
                return;
            }

            try (PreparedStatement ps = conn.prepareStatement("""
                    UPDATE flyway_schema_history
                    SET type = 'JDBC',
                        script = ?,
                        checksum = NULL,
                        description = ?
                    WHERE version = '21'
                      AND type = 'SQL'
                      AND success = 1
                    """)) {
                ps.setString(1, JDBC_SCRIPT);
                ps.setString(2, JDBC_DESCRIPTION);
                int updated = ps.executeUpdate();
                if (updated > 0) {
                    log.info(
                            "Repaired Flyway V21 history: SQL migration replaced by Java migration record (schema unchanged)");
                }
            }
        } catch (Exception e) {
            throw new IllegalStateException("Failed to repair Flyway V21 history for Java migration", e);
        }
    }

    private static boolean isAppliedSqlV21(Connection conn) throws Exception {
        try (PreparedStatement ps = conn.prepareStatement("""
                SELECT 1 FROM flyway_schema_history
                WHERE version = '21' AND type = 'SQL' AND success = 1
                LIMIT 1
                """)) {
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private static boolean geoSchemaComplete(Connection conn) throws Exception {
        return tableExists(conn, "places") && columnExists(conn, "steak_posts", "place_id");
    }

    private static boolean tableExists(Connection conn, String table) throws Exception {
        try (PreparedStatement ps = conn.prepareStatement("""
                SELECT 1
                FROM information_schema.tables
                WHERE table_schema = DATABASE()
                  AND table_name = ?
                LIMIT 1
                """)) {
            ps.setString(1, table);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private static boolean columnExists(Connection conn, String table, String column) throws Exception {
        try (PreparedStatement ps = conn.prepareStatement("""
                SELECT 1
                FROM information_schema.columns
                WHERE table_schema = DATABASE()
                  AND table_name = ?
                  AND column_name = ?
                LIMIT 1
                """)) {
            ps.setString(1, table);
            ps.setString(2, column);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }
}
