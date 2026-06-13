# Contributing to High Steak

Thank you for contributing. This guide applies to humans and AI agents working in the repo.

## Getting started

1. Read [`AGENTS.md`](AGENTS.md) — project map and non-negotiables
2. Read [`docs/runbook.md`](docs/runbook.md) — how to run and test locally
3. Read [`docs/architecture.md`](docs/architecture.md) — system design

## Branch naming

- `feature/short-description` — new features
- `fix/short-description` — bug fixes
- `chore/short-description` — tooling, deps, docs

## Making changes

### API changes

1. Follow layering: controller → service → repository
2. Add/update Flyway migration for schema changes (never edit applied migrations)
3. Add `@PreAuthorize` or `SecurityConfig` permitAll as appropriate
4. Add integration tests for security-sensitive endpoints
5. Update `apps/high-steak-api/openapi/openapi.yaml`
6. Run `npm run api:test`

### Web changes

1. Use `src/api/client.ts` for all HTTP
2. Auth via JWT parse — do not expect user in login response
3. Gate admin/moderation UI with `hasScope` / `RoleGate`

### Docker changes

1. Keep `VITE_API_URL` ending with `/api`
2. Rebuild and verify: `npm run docker:health`

## Architecture decisions

Non-trivial design choices should be documented as ADRs in `docs/decisions/`:

- Filename: `NNN-short-title.md`
- Include: Status, Context, Decision, Consequences
- See existing ADRs 001–003 as templates

Do not implement significant architectural changes without an ADR or explicit approval.

## AI-assisted development

Project rules live in `.cursor/rules/`. Skills for common workflows are in `.cursor/skills/`:

- `add-api-endpoint` — new REST routes
- `flyway-migration` — database changes
- `docker-dev-loop` — container dev cycle

Agents should read `AGENTS.md` at session start.

## Pull requests

Use the PR template. Ensure:

- [ ] Tests pass (`npm run api:test`)
- [ ] OpenAPI updated if API changed
- [ ] Clients updated if contract changed
- [ ] No secrets committed

## What not to commit

- `.env` files with real credentials
- JWT secrets or production passwords
- IDE-specific files not already in `.gitignore`
