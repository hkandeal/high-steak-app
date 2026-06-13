# ADR 001: API Context Path `/api`

## Status

Accepted

## Context

The API serves REST endpoints, Swagger UI, static uploads, and a server-root welcome page. Clients (web, mobile) need a stable base URL. We want clear separation between the server root and the application.

## Decision

- Set `server.servlet.context-path=/api` in Spring Boot
- Controller `@RequestMapping` paths are servlet-relative (`/auth`, `/posts`, not `/api/auth`)
- External URLs: `http://host:8080/api/...`
- Server root `http://host:8080/` serves a separate Tomcat welcome servlet (not part of Spring context)
- `/api/` redirects to Swagger UI

## Consequences

- Spring Security matchers omit `/api` prefix
- Web/mobile `API_BASE_URL` / `VITE_API_URL` must include `/api` suffix; client paths are servlet-relative
- MockMvc tests use servlet-relative paths; context path applied automatically
- OpenAPI server URL: `http://localhost:8080/api`

## References

- `apps/high-steak-api/src/main/resources/application.yml`
- `apps/high-steak-api/.../config/TomcatRootContextConfig.java`
- `docs/architecture.md`
