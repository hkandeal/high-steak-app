ALTER TABLE steak_posts ADD COLUMN restaurant_name VARCHAR(120);
ALTER TABLE steak_posts ADD COLUMN restaurant_location VARCHAR(255);

CREATE TABLE post_images (
    id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    post_id    BIGINT       NOT NULL,
    image_url  VARCHAR(512) NOT NULL,
    sort_order INT          NOT NULL DEFAULT 0,
    CONSTRAINT fk_post_images_post FOREIGN KEY (post_id) REFERENCES steak_posts (id) ON DELETE CASCADE
);

CREATE INDEX idx_post_images_post ON post_images (post_id, sort_order);

INSERT INTO post_images (post_id, image_url, sort_order)
SELECT id, image_url, 0 FROM steak_posts;

ALTER TABLE steak_posts DROP COLUMN image_url;

CREATE TABLE post_comments (
    id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    post_id    BIGINT       NOT NULL,
    user_id    CHAR(36)     NOT NULL,
    body       TEXT         NOT NULL,
    created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_post_comments_post FOREIGN KEY (post_id) REFERENCES steak_posts (id) ON DELETE CASCADE,
    CONSTRAINT fk_post_comments_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX idx_post_comments_post ON post_comments (post_id, created_at);

INSERT INTO permissions (resource, action, qualifier, scope) VALUES
    ('comments', 'write', NULL, 'comments:write');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name IN ('USER', 'MODERATOR', 'ADMIN')
  AND p.scope = 'comments:write';
