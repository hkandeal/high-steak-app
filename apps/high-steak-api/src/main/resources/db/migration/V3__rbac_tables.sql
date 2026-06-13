CREATE TABLE roles (
    id   BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE permissions (
    id        BIGINT AUTO_INCREMENT PRIMARY KEY,
    resource  VARCHAR(50)  NOT NULL,
    action    VARCHAR(50)  NOT NULL,
    qualifier VARCHAR(50),
    scope     VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE role_permissions (
    role_id       BIGINT NOT NULL,
    permission_id BIGINT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_role_permissions_role FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE CASCADE,
    CONSTRAINT fk_role_permissions_permission FOREIGN KEY (permission_id) REFERENCES permissions (id) ON DELETE CASCADE
);

INSERT INTO roles (name) VALUES ('USER'), ('MODERATOR'), ('ADMIN');

INSERT INTO permissions (resource, action, qualifier, scope) VALUES
    ('posts', 'read',        NULL,  'posts:read'),
    ('posts', 'write',       NULL,  'posts:write'),
    ('posts', 'read',        'own', 'posts:read:own'),
    ('posts', 'delete',      'own', 'posts:delete:own'),
    ('posts', 'delete',      'any', 'posts:delete:any'),
    ('posts', 'moderate',    NULL,  'posts:moderate'),
    ('users', 'read',        NULL,  'users:read'),
    ('users', 'manage',      NULL,  'users:manage');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'USER'
  AND p.scope IN (
      'posts:read', 'posts:write', 'posts:read:own', 'posts:delete:own'
  );

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'MODERATOR'
  AND p.scope IN (
      'posts:read', 'posts:write', 'posts:read:own', 'posts:delete:own',
      'posts:delete:any', 'posts:moderate'
  );

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'ADMIN';

ALTER TABLE users ADD COLUMN role_id BIGINT;

UPDATE users u
SET u.role_id = (SELECT r.id FROM roles r WHERE r.name = u.role);

UPDATE users SET role_id = (SELECT id FROM roles WHERE name = 'USER') WHERE role_id IS NULL;

ALTER TABLE users
    ADD CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles (id);

ALTER TABLE users MODIFY role_id BIGINT NOT NULL;

ALTER TABLE users DROP COLUMN role;
