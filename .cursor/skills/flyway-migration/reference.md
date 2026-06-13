# Migration History

| Version | Type | Description |
|---------|------|-------------|
| V1 | SQL | users, steak_posts tables |
| V2 | SQL | users.role column, posts.hidden |
| V3 | SQL | roles, permissions, role_permissions + seeds |
| V4 | Java | User ID BIGINT → UUID (`V4__UserUuid.java`) |
| V5 | SQL | user_subscriptions + discover/subscription permissions |
| V6 | SQL | post_images, post_comments, restaurant fields |
| V7 | Java | Post and comment IDs BIGINT → UUID (`V7__PostUuid.java`) |

**New tables:** primary keys must be `CHAR(36)` UUID — see `.cursor/rules/api-ids.mdc` and ADR `docs/decisions/007-uuid-primary-keys.md`.

## Java migration registration (required pattern)

```java
// FlywayConfig.java
configuration.javaMigrations(
    new V4__UserUuid(),
    new V7__PostUuid());
```

## PK migration MySQL lesson

```sql
-- BAD
ALTER TABLE users DROP PRIMARY KEY;
ALTER TABLE users DROP COLUMN id;

-- GOOD (single statement)
ALTER TABLE users DROP PRIMARY KEY, DROP COLUMN id;
```

## H2 test profile

`src/test/resources/application-test.yml` — Flyway enabled, H2 in-memory with MySQL mode.

## Verify migration applied

```bash
cd apps/high-steak-api && mvn test 2>&1 | grep -i flyway
```

Look for "Successfully applied" or "Schema is up to date".
