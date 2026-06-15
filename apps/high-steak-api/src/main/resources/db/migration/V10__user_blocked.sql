ALTER TABLE users
    ADD COLUMN blocked BOOLEAN NOT NULL DEFAULT FALSE;

INSERT INTO permissions (resource, action, qualifier, scope) VALUES
    ('users', 'block', NULL, 'users:block');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name IN ('MODERATOR', 'ADMIN')
  AND p.scope = 'users:block';
