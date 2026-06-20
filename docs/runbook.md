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

## Production Flyway failures

Symptom: API pod crash-loops with `FlywayValidateException: Detected failed migration to version N`.

### Common cause (V17)

Migrations that set explicit `utf8mb4_0900_ai_ci` on `CHAR(36)` FK columns fail against prod MySQL where `users.id` uses the table default charset (`latin1` or `utf8mb4_unicode_ci`). Use plain `CHAR(36)` without charset/collation on FK columns.

### Recovery steps

Connect to prod MySQL (replace pod name if needed):

```bash
kubectl exec -it -n apps db-apps-mysql-deployment-67845dcfc6-m4l5z -- \
  mysql -uroot -p high_steak
```

```sql
-- Inspect
SELECT installed_rank, version, description, success FROM flyway_schema_history ORDER BY installed_rank DESC LIMIT 5;

-- If migration failed mid-way, drop partial objects first
-- DROP TABLE IF EXISTS user_notification_preferences;

-- Remove failed record
DELETE FROM flyway_schema_history WHERE version = '17' AND success = 0;
```

Then either:

- **Redeploy** a fixed API image so Flyway runs the corrected migration, or
- **Apply fixed SQL manually** and mark versions successful:

```sql
INSERT INTO flyway_schema_history (installed_rank, version, description, type, script, checksum, installed_by, execution_time, success)
VALUES (17, '17', 'notification preferences', 'SQL', 'V17__notification_preferences.sql', NULL, 'manual-repair', 0, 1);
```

Restart the API pod: `kubectl delete pod -n apps -l app.kubernetes.io/name=high-steak-api` (adjust label selector to match your deployment).

Verify: `curl -sf https://steaks.apps.hossam.io/api/health`

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
| `BOOTSTRAP_ADMIN_ENABLED` | Create default admin on startup if none exists (default `true`) |
| `BOOTSTRAP_ADMIN_USERNAME` | Bootstrap admin username (default `admin`) |
| `BOOTSTRAP_ADMIN_PASSWORD` | Bootstrap admin password (default `AdminPass123!`) |
| `BOOTSTRAP_ADMIN_EMAIL` | Bootstrap admin email (default `admin@high-steak.local`) |
| `BOOTSTRAP_ADMIN_DISPLAY_NAME` | Bootstrap admin display name (default `System Admin`) |

### Bootstrap admin

On first startup (when no user has the `ADMIN` role), the API creates a default admin account using the `BOOTSTRAP_ADMIN_*` variables above. Log in at `/login` with those credentials, then open **Manage** from the account menu.

Set `BOOTSTRAP_ADMIN_ENABLED=false` in production once real admins exist.

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
