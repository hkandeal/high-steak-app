# High Steak — Agent Guide

Start here. This file is an **index**, not a wiki. For depth, follow links to `docs/` and source files.

## Monorepo map

| App | Path | Stack |
|-----|------|-------|
| API | `apps/high-steak-api` | Java 17, Spring Boot 3.5, MySQL, Flyway, JWT |
| Web | `apps/high-steak-web` | React 19, TypeScript, Vite |
| Mobile | `apps/high-steak-mobile` | Flutter / Dart |

Shared: `docker-compose.yml`, `assets/`, root `package.json` scripts.

## Commands (run from repo root)

| Command | Purpose |
|---------|---------|
| `npm run web:dev` | Web dev server (5173) |
| `npm run web:build` | Web production build |
| `npm run api:build` | Package API JAR |
| `npm run api:test` | Run API unit/integration tests |
| `npm run docker:up` | Build and start full stack |
| `npm run docker:down` | Stop stack |
| `npm run docker:restart` | Down, rebuild, start detached, health check |
| `npm run docker:health` | Curl API health endpoint |

## Non-negotiables

1. **Context path** — API servlet context is `/api`. Controller paths are relative (`/auth`, `/posts`). External URLs: `http://localhost:8080/api/...`.
2. **JWT auth** — Stateless; no server sessions. Login/register return `{ "token" }` only; profile via `GET /auth/me`.
3. **DB-backed RBAC** — Roles and permissions live in MySQL (`roles`, `permissions`, `role_permissions`). Scopes are loaded at login; do not add Java enum mappers for permissions.
4. **Flyway only** — Schema changes via versioned migrations in `src/main/resources/db/migration/`. Java migrations must be registered in `FlywayConfig.java`. JPA `ddl-auto: validate`.
5. **UUID identifiers** — All new primary keys and public resource IDs are UUID (`CHAR(36)` / Java `UUID`). No new `AUTO_INCREMENT` or `Long` entity IDs. See `.cursor/rules/api-ids.mdc`.
6. **Web API base URL** — `VITE_API_URL` must include `/api` (e.g. `http://localhost:8080/api`). Client paths are servlet-relative (`/auth/login`, not `/api/auth/login`).
7. **OpenAPI** — Update `apps/high-steak-api/openapi/openapi.yaml` when adding or changing endpoints.
8. **No secrets in repo** — Never commit `.env`, JWT secrets, or credentials.
9. **Minimal diffs** — Match existing patterns; do not refactor unrelated code (see `core.mdc` for full agent behavior guidelines).

## Where to look

| Concern | Location |
|---------|----------|
| Security filter chain | `apps/high-steak-api/.../config/SecurityConfig.java` |
| JWT issue/parse | `.../security/JwtService.java`, `JwtAuthFilter.java` |
| RBAC / scopes | `.../service/PermissionService.java`, `V3__rbac_tables.sql` |
| Resource ownership | `.../security/ResourceAuthorizationService.java` |
| Auth endpoints | `.../controller/AuthController.java` |
| Posts | `.../controller/SteakPostController.java` |
| Admin users | `.../controller/UserAdminController.java` |
| Request / error logging | `.../config/ApiRequestLoggingFilter.java`, `GlobalExceptionHandler.java`, `application.yml` → `logging.level` |
| DTOs | `.../dto/` |
| Web API client | `apps/high-steak-web/src/api/client.ts` |
| Web auth state | `apps/high-steak-web/src/context/AuthContext.tsx` |
| Role/scope UI gates | `apps/high-steak-web/src/components/RoleGate.tsx` |
| Mobile API | `apps/high-steak-mobile/lib/services/api_service.dart` |
| OpenAPI spec | `apps/high-steak-api/openapi/openapi.yaml` |
| Architecture | `docs/architecture.md` |
| Runbook | `docs/runbook.md` |
| Decisions (ADRs) | `docs/decisions/` |

## Project skills (read when task matches)

| Skill | When to use |
|-------|-------------|
| `.cursor/skills/add-api-endpoint/` | New or changed REST route |
| `.cursor/skills/flyway-migration/` | Database schema/data migration |
| `.cursor/skills/docker-dev-loop/` | Docker build/run/debug |

## Cursor rules

- `core.mdc` — always applies (High Steak standards + Karpathy-inspired agent behavior: think first, simplicity, surgical diffs, goal-driven verify)
- `api-ids.mdc` — always applies (UUID-only IDs for new entities and APIs)
- `api-security.mdc`, `api-spring.mdc`, `api-flyway.mdc`, `api-logging.mdc` — API Java files
- `web-react.mdc` — web app
- `docker.mdc` — Docker/compose

## Before finishing a task

- [ ] Run `npm run api:test` if API code changed
- [ ] Update `openapi/openapi.yaml` if endpoints or auth changed
- [ ] Update web/mobile clients if API contract or JWT claims changed
- [ ] **Restart Docker** — `npm run docker:restart` after any app code or compose/Dockerfile change; confirm health check passes
- [ ] If introducing a new architectural decision, add an ADR under `docs/decisions/` (do not edit `.cursor/plans/` unless asked)

## Decision policy

If a design choice is not documented in `docs/decisions/`, propose a short ADR before implementing non-trivial changes.
