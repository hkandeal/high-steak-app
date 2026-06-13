CREATE TABLE user_subscriptions (
    subscriber_id  CHAR(36) NOT NULL,
    target_user_id CHAR(36) NOT NULL,
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (subscriber_id, target_user_id),
    CONSTRAINT fk_sub_subscriber FOREIGN KEY (subscriber_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_sub_target     FOREIGN KEY (target_user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT chk_sub_not_self  CHECK (subscriber_id <> target_user_id)
);

CREATE INDEX idx_sub_subscriber ON user_subscriptions (subscriber_id);
CREATE INDEX idx_sub_target     ON user_subscriptions (target_user_id);

INSERT INTO permissions (resource, action, qualifier, scope) VALUES
    ('users', 'discover', NULL,  'users:discover'),
    ('subscriptions', 'read',  NULL, 'subscriptions:read'),
    ('subscriptions', 'write', NULL, 'subscriptions:write');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name IN ('USER', 'MODERATOR', 'ADMIN')
  AND p.scope IN ('users:discover', 'subscriptions:read', 'subscriptions:write');
