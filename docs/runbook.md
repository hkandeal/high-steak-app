# High Steak Runbook

## Prerequisites

- Java 17+, Maven 3.9+
- Node 22+ (web)
- Docker Desktop (full stack)
- Flutter SDK (mobile, optional)

## Local development — API only

```bash
# MySQL must be running (docker or local on 3306)
cd apps/high-steak-api
mvn spring-boot:run
```

Default datasource: `localhost:3306/high_steak` (see `application.yml`).

| Check | URL |
|-------|-----|
| Welcome (server root) | http://localhost:8080/ |
| Health | http://localhost:8080/api/health |
| Swagger UI | http://localhost:8080/api/swagger-ui.html |
| OpenAPI JSON | http://localhost:8080/api/v3/api-docs |

## Local development — Web only

```bash
cp apps/high-steak-web/.env.example apps/high-steak-web/.env
# VITE_API_URL=http://localhost:8080/api

npm run web:dev
```

Web: http://localhost:5173

## Full stack (Docker)

```bash
npm run docker:up        # foreground
npm run docker:up -d     # detached (or: docker compose up --build -d)
npm run docker:down
npm run docker:restart   # down + rebuild + detached + health check
npm run docker:health
```

### Docker services

| Service | Container | Port |
|---------|-----------|------|
| mysql | high-steak-mysql | 3306 |
| api | high-steak-api | 8080 |
| web | high-steak-web | 5173 |

### Common Docker issues

**API fails after schema migration change**

Existing MySQL volume may have old schema. Reset:

```bash
docker compose down -v
docker compose up --build -d
```

**API container won't start after Tomcat/config change**

Check logs: `docker logs high-steak-api --tail 50`

**Web can't reach API**

Confirm `VITE_API_URL=http://localhost:8080/api` in compose or `.env`.

## Tests

```bash
npm run api:test
# or
cd apps/high-steak-api && mvn test
```

Test profile uses H2 in-memory with context path `/api` (`application-test.yml`).

Security integration test template: `ControllerSecurityIntegrationTest.java`.

## Build

```bash
npm run api:build
npm run web:build
```

## Environment variables (API)

| Variable | Default / notes |
|----------|-----------------|
| `SPRING_DATASOURCE_URL` | MySQL JDBC URL |
| `JWT_SECRET` | Min 32 chars in production |
| `CORS_ALLOWED_ORIGINS` | Comma-separated |
| `UPLOADS_DIR` | File upload directory |
| `SERVER_SERVLET_CONTEXT_PATH` | `/api` |
| `APP_LOG_LEVEL` | Package log level for `com.highsteak.api` (default `INFO`) |
| `APP_HTTP_LOG_LEVEL` | HTTP access filter level (default `INFO`) |
| `HTTP_ACCESS_LOG_ENABLED` | Enable/disable request logging (default `true`) |

## Logging

HTTP access and error logging are centralized — see `docs/decisions/004-api-request-logging.md`.

### Local (Maven)

```bash
# Debug all API logs
APP_LOG_LEVEL=DEBUG mvn spring-boot:run -f apps/high-steak-api/pom.xml

# Debug HTTP access lines only
APP_HTTP_LOG_LEVEL=DEBUG mvn spring-boot:run -f apps/high-steak-api/pom.xml
```

### Docker

Set on the `api` service in `docker-compose.yml`:

```yaml
APP_LOG_LEVEL: DEBUG
APP_HTTP_LOG_LEVEL: DEBUG
```

Then rebuild: `docker compose up --build -d api`

View logs:

```bash
docker logs high-steak-api -f
```

### Spring Boot standard override

```bash
LOGGING_LEVEL_COM_HIGHSTEAK_API=DEBUG
```

### Example log output

```
INFO  GET /posts -> 200 (12ms)
DEBUG GET /posts -> 200 (12ms) user=anonymous
DEBUG response body GET /posts: [{"id":1,"title":"Ribeye",...}]
DEBUG POST /posts -> 201 (45ms) user=a1b2c3d4-...
DEBUG request body POST /posts: [multipart omitted]
WARN  POST /auth/login -> 401: Bad credentials
```

At DEBUG, JSON/text request and response bodies are logged (max 4KB each). `/auth/*` bodies are never logged. Enable with `APP_HTTP_LOG_LEVEL=DEBUG` or `APP_LOG_LEVEL=DEBUG`.

## Environment variables (Web)

| Variable | Example |
|----------|---------|
| `VITE_API_URL` | `http://localhost:8080/api` |

## Mobile

```bash
cd apps/high-steak-mobile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
```

Android emulator uses `10.0.2.2` for host localhost.
