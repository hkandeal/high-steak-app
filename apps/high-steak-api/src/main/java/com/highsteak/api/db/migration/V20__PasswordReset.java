package com.highsteak.api.db.migration;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;

public class V20__PasswordReset extends BaseJavaMigration {

    @Override
    public void migrate(Context context) throws Exception {
        Connection conn = context.getConnection();
        boolean mysql = conn.getMetaData().getDatabaseProductName().toLowerCase().contains("mysql");

        String idColumn = "CHAR(36) NOT NULL";
        String userIdColumn = "CHAR(36) NOT NULL";

        if (mysql) {
            ColumnCharset usersId = usersIdColumn(conn);
            idColumn = charColumn(usersId);
            userIdColumn = charColumn(usersId);
        }

        try (Statement stmt = conn.createStatement()) {
            stmt.execute("""
                    CREATE TABLE password_reset_tokens (
                        id         %s PRIMARY KEY,
                        user_id    %s,
                        token_hash VARCHAR(64)  NOT NULL,
                        expires_at TIMESTAMP    NOT NULL,
                        used_at    TIMESTAMP    NULL,
                        created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        CONSTRAINT fk_password_reset_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
                        CONSTRAINT uk_password_reset_token_hash UNIQUE (token_hash)
                    )
                    """.formatted(idColumn, userIdColumn));
            stmt.execute("CREATE INDEX idx_password_reset_user ON password_reset_tokens (user_id)");
        }
    }

    private static String charColumn(ColumnCharset charset) {
        if (charset.collation() == null || charset.collation().isBlank()) {
            return "CHAR(36) NOT NULL";
        }
        return "CHAR(36) CHARACTER SET %s COLLATE %s NOT NULL"
                .formatted(charset.characterSet(), charset.collation());
    }

    private static ColumnCharset usersIdColumn(Connection conn) throws Exception {
        try (PreparedStatement ps = conn.prepareStatement("""
                SELECT CHARACTER_SET_NAME, COLLATION_NAME
                FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE()
                  AND TABLE_NAME = 'users'
                  AND COLUMN_NAME = 'id'
                """)) {
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
