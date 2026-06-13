---
name: flyway-migration
description: Create or modify Flyway database migrations for High Steak API. Use for schema changes, RBAC seeds, or data migrations.
---

# Flyway Migration

Read `.cursor/rules/api-flyway.mdc` before starting.

## SQL vs Java migration

| Use SQL when | Use Java when |
|--------------|---------------|
| DDL (CREATE/ALTER TABLE) | Complex multi-step data transform |
| Simple INSERT seeds | Logic hard to express in SQL (e.g. UUID backfill) |
| Index/constraint changes | Need Java APIs or conditional logic |

## Steps

### 1. Choose version number

List existing: `src/main/resources/db/migration/V*.sql` and `db/migration/V*.java`.

Next version = highest + 1. Example: `V5__add_notifications.sql`

### 2. Create migration file

**SQL** — `src/main/resources/db/migration/V5__description.sql`

**Java** — `src/main/java/com/highsteak/api/db/migration/V5__Description.java`

Implement `BaseJavaMigration`, override `migrate(Context context)`.

### 3. Register Java migrations

Add to `FlywayConfig.java`:

```java
configuration.javaMigrations(new V4__UserUuid(), new V5__Description());
```

SQL migrations are auto-discovered; Java migrations are **not** without registration.

### 4. Test locally

```bash
npm run api:test
```

H2 test profile runs all migrations on startup.

### 5. Docker / existing MySQL

If migration is **breaking** (column type change, drop table):

```bash
docker compose down -v
docker compose up --build -d
```

For additive migrations (new table/column), normal restart is usually enough.

## RBAC permission seed pattern

```sql
INSERT INTO permissions (name) VALUES ('feature:action');
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'ADMIN' AND p.name = 'feature:action';
```

Then use `@PreAuthorize("hasAuthority('feature:action')")` — no Java enum.

## MySQL pitfalls

- `DROP PRIMARY KEY` on `AUTO_INCREMENT` column fails — use combined drop
- User IDs are `CHAR(36)` UUID strings (see V4)
- Post IDs remain `BIGINT`

## Do not

- Edit already-applied migration files
- Use JPA `ddl-auto: update` — project uses `validate`
- Skip FlywayConfig registration for Java migrations

See `reference.md` for migration history.
