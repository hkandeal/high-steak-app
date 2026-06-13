# ADR 004: Centralized API Request Logging

## Status

Accepted

## Context

As the API grows, we need consistent observability for HTTP traffic and errors. Per-controller logging leads to duplication, inconsistent formats, and risk of logging sensitive auth data.

## Decision

- **HTTP access logs** — single `ApiRequestLoggingFilter` registered after `JwtAuthFilter` in the security chain
  - INFO: `{method} {servletPath} -> {status} ({duration}ms)`
  - DEBUG: adds query string, authenticated user id, and JSON/text request/response bodies (truncated to 4KB)
  - Skips body logging on `/auth/*`; multipart logged as `[multipart omitted]`
  - Skips noisy paths entirely: `/health`, `/swagger-ui`, `/v3/api-docs`, `/uploads`
- **Error logs** — `GlobalExceptionHandler` with SLF4J
  - WARN: 4xx (validation, forbidden, unauthorized, ResponseStatusException)
  - ERROR + stack trace: unhandled exceptions (500)
- **Configuration** via `application.yml` and env vars: `APP_LOG_LEVEL`, `APP_HTTP_LOG_LEVEL`, `HTTP_ACCESS_LOG_ENABLED`
- **No per-controller request logging** — new endpoints inherit logging automatically

## Consequences

- Agents must not add manual request logging in controllers (enforced via `.cursor/rules/api-logging.mdc`)
- Auth request bodies and JWTs are never logged
- Test profile disables HTTP access logs and sets `com.highsteak.api` to WARN
- Docker compose documents default log env vars on the `api` service

## References

- `ApiRequestLoggingFilter.java`, `ApiLoggingProperties.java`
- `GlobalExceptionHandler.java`
- `application.yml` → `app.logging.*`, `logging.level.*`
- `.cursor/rules/api-logging.mdc`
