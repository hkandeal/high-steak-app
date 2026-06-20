CREATE TABLE user_notification_preferences (
    user_id              CHAR(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL PRIMARY KEY,
    email_enabled        BOOLEAN   NOT NULL DEFAULT TRUE,
    welcome_email        BOOLEAN   NOT NULL DEFAULT TRUE,
    comment_email        BOOLEAN   NOT NULL DEFAULT TRUE,
    follower_email       BOOLEAN   NOT NULL DEFAULT TRUE,
    moderation_email     BOOLEAN   NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_notification_prefs_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO user_notification_preferences (user_id, email_enabled, welcome_email, comment_email, follower_email, moderation_email)
SELECT id, TRUE, TRUE, TRUE, TRUE, TRUE FROM users;
