CREATE TABLE post_bookmarks (
    user_id    CHAR(36)  NOT NULL,
    post_id    CHAR(36)  NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, post_id),
    CONSTRAINT fk_post_bookmarks_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_post_bookmarks_post FOREIGN KEY (post_id) REFERENCES steak_posts (id) ON DELETE CASCADE
);

CREATE INDEX idx_post_bookmarks_user_created ON post_bookmarks (user_id, created_at DESC);

INSERT INTO permissions (resource, action, qualifier, scope) VALUES
    ('bookmarks', 'read',  NULL, 'bookmarks:read'),
    ('bookmarks', 'write', NULL, 'bookmarks:write');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name IN ('USER', 'MODERATOR', 'ADMIN')
  AND p.scope IN ('bookmarks:read', 'bookmarks:write');
