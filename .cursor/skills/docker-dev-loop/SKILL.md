---
name: docker-dev-loop
description: Build, run, and debug the High Steak Docker Compose stack. Use when starting the dev environment, rebuilding after API changes, or fixing container issues.
---

# Docker Dev Loop

## Required after code changes

Whenever application code under `apps/` (or Docker/compose files) changes, restart the stack before finishing:

```bash
npm run docker:restart
```

This is a project rule — the user verifies changes in the running Docker environment.

## Quick start

```bash
# From repo root
npm run docker:down
npm run docker:up -- -d          # detached
npm run docker:health
```

Or foreground: `npm run docker:up`

## Verify services

| Check | Command / URL |
|-------|---------------|
| Containers running | `docker compose ps` |
| API health | `curl http://localhost:8080/api/health` |
| Server root welcome | `curl http://localhost:8080/` |
| Swagger | http://localhost:8080/api/swagger-ui.html |
| Web app | http://localhost:5173 |

## Rebuild only API

```bash
docker compose up --build -d api
sleep 8
npm run docker:health
```

Rebuild API after: `pom.xml`, `Dockerfile`, Java source, `application.yml`.

## Common failures

### API container exits on startup

```bash
docker logs high-steak-api --tail 80
```

Check: Flyway migration errors, Tomcat config, MySQL connection.

### Flyway migration failed on existing DB

Schema mismatch from prior migration. Reset volumes:

```bash
docker compose down -v
docker compose up --build -d
```

**Warning:** `-v` deletes MySQL data and uploads volume.

### Web can't reach API

Confirm compose env:

```yaml
VITE_API_URL: http://localhost:8080/api
```

Rebuild web if env changed: `docker compose up --build -d web`

### Port already in use

```bash
docker compose down
# or kill process on 8080/5173/3306
```

## Service reference

| Service | Container | Internal host (from api) |
|---------|-----------|--------------------------|
| mysql | high-steak-mysql | `mysql:3306` |
| api | high-steak-api | port 8080, context `/api` |
| web | high-steak-web | port 5173 |

## Full cycle after any code change

1. `npm run api:test` (if API touched)
2. `npm run docker:restart`
3. Manual smoke if relevant: swagger, login, feed, web UI

See `docs/runbook.md` for local (non-docker) development.
