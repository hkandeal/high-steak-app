---
name: add-api-endpoint
description: Add or change a REST endpoint on the High Steak Spring Boot API. Use when creating routes, updating controller auth, or modifying the API contract.
---

# Add API Endpoint

Follow this checklist in order. Read `AGENTS.md`, `.cursor/rules/api-security.mdc`, and `.cursor/rules/api-logging.mdc` first.

## 1. Design

- Confirm servlet-relative path (context path is `/api`)
- Decide auth: public, authenticated, or scope-based (`hasAuthority`)
- Check if `ResourceAuthorizationService` needed for ownership

## 2. Implementation

| Layer | File | Action |
|-------|------|--------|
| DTO | `apps/high-steak-api/.../dto/` | Add request/response records with validation |
| Service | `.../service/` | Business logic, `@Transactional` if needed |
| Controller | `.../controller/` | Mapping, `@Valid`, `@PreAuthorize` |
| Security | `SecurityConfig.java` | Add to `permitAll` if public |
| Repository | `.../repository/` | Only if new queries needed |

**Logging** (automatic — do not add per-controller request logs):

- `ApiRequestLoggingFilter` logs every HTTP request at INFO (summary) or DEBUG (query + user id)
- `GlobalExceptionHandler` logs 4xx at WARN and unhandled 5xx at ERROR
- Add service-level `@Slf4j` DEBUG only for non-obvious business events

## 3. Security

```java
// Scoped endpoint
@PreAuthorize("hasAuthority('posts:write')")

// Owner or admin delete
@PreAuthorize("@resourceAuth.can('posts', #id, 'delete', 'delete', authentication)")
```

If public GET, add to SecurityConfig:

```java
.requestMatchers(HttpMethod.GET, "/your-path").permitAll()
```

## 4. Tests

Add cases to `ControllerSecurityIntegrationTest.java` or a new test class:

- Unauthenticated → 401
- Wrong scope → 403
- Correct scope → 200/201

Use `@WithMockUser(authorities = {"scope:name"})` and `@MockitoBean` for services.

Run: `npm run api:test`

## 5. OpenAPI

Update `apps/high-steak-api/openapi/openapi.yaml`:

- Path under server `http://localhost:8080/api`
- Request/response schemas
- `security: [bearerAuth: []]` if protected

## 6. Clients (if user-facing)

| Client | File |
|--------|------|
| Web | `apps/high-steak-web/src/api/client.ts` |
| Mobile | `apps/high-steak-mobile/lib/services/api_service.dart` |

Paths are servlet-relative (`/auth/login`, not `/api/auth/login`).

## 7. Verify

```bash
npm run api:test
npm run docker:health   # if docker running
```

## Do not

- Return JPA entities from controllers
- Skip SecurityConfig for new public routes
- Forget openapi update
- Add `/api` prefix to `@RequestMapping` (context path handles it)
- Add manual request logging in controllers (use centralized filter)

See `reference.md` for endpoint inventory.
