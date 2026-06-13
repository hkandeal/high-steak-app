# ADR 007: UUID Primary Keys for New Entities

## Status

Accepted

## Context

Early schema used `BIGINT AUTO_INCREMENT` for `steak_posts` and related tables. User and post identifiers are exposed in URLs and APIs. Sequential IDs leak volume and are easy to enumerate.

## Decision

- All **new** primary keys and public resource IDs use **UUID** (`CHAR(36)` in MySQL, `java.util.UUID` in the API).
- IDs are assigned in application code (`@PrePersist`), not by the database.
- Existing integer PKs are migrated forward via Flyway (e.g. `V4__UserUuid`, `V7__PostUuid`) rather than edited in place.
- Internal legacy tables (`roles`, `permissions`, `post_images.id`) may remain `BIGINT` until intentionally migrated; no **new** integer PKs.

## Consequences

- OpenAPI and clients use `string` + `format: uuid` for resource IDs.
- Migrations that change PK type require Java Flyway migrations when FKs and data exist.
- Agents must follow `.cursor/rules/api-ids.mdc` when adding schema or entities.

## References

- `.cursor/rules/api-ids.mdc`
- `apps/high-steak-api/src/main/java/com/highsteak/api/domain/User.java`
- `apps/high-steak-api/src/main/java/com/highsteak/api/domain/SteakPost.java`
