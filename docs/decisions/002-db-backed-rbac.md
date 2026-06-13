# ADR 002: Database-Backed RBAC

## Status

Accepted

## Context

The app needs roles (USER, MODERATOR, ADMIN) and fine-grained permissions (scopes like `posts:write`, `users:manage`). Hardcoding permissions in Java enums does not scale as features grow.

## Decision

- Store roles in `roles`, permissions in `permissions`, links in `role_permissions`
- Each user has one role via `users.role_id`
- `PermissionService` loads scope strings from DB at login
- JWT carries `roles` and `scopes` claims
- Controllers enforce via `@PreAuthorize("hasAuthority('scope:name')")`
- Resource-level checks use `ResourceAuthorizationService` + owner resolvers
- New permissions: Flyway seed + controller annotation — no Java enum changes

## Consequences

- Adding a feature permission requires a migration, not code enum edits
- Web uses `hasScope()` from JWT; admin UI gates on scopes like `users:read`
- Integration tests use `@WithMockUser(authorities = {"scope:name"})`

## References

- `V3__rbac_tables.sql`
- `PermissionService.java`, `SecurityConfig.java`
- `.cursor/skills/flyway-migration/`
