# API Endpoint Reference

Current servlet-relative paths (external prefix: `/api`).

## Public

| Method | Path | Notes |
|--------|------|-------|
| GET | `/health` | Health check |
| POST | `/auth/register` | Returns `{ token }` |
| POST | `/auth/login` | Returns `{ token }` |
| GET | `/posts` | Public feed |
| GET | `/posts/{id}` | Public (non-hidden) |
| GET | `/posts/{id}/comments` | Public |
| GET | `/users/{id}` | Public profile |
| GET | `/users/{id}/posts` | Public (non-hidden posts) |
| GET | `/uploads/**` | Static images |

## Authenticated

| Method | Path | Scope |
|--------|------|-------|
| GET | `/auth/me` | any valid JWT |
| GET | `/posts/mine` | `posts:read:own` |
| GET | `/posts/hidden` | `posts:moderate` |
| GET | `/posts/following` | `subscriptions:read` |
| POST | `/posts` | `posts:write` |
| DELETE | `/posts/{id}` | owner or `posts:delete:any` |
| PATCH | `/posts/{id}/hide` | `posts:moderate` |
| POST | `/posts/{id}/comments` | `comments:write` |
| GET | `/users/search?q=` | `users:discover` |
| GET | `/subscriptions` | `subscriptions:read` |
| POST | `/subscriptions/{userId}` | `subscriptions:write` |
| DELETE | `/subscriptions/{userId}` | `subscriptions:write` |
| GET | `/users` | `users:read` |
| PATCH | `/users/{id}/role` | `users:manage` |

## Swagger

- UI: `/swagger-ui.html`
- JSON: `/v3/api-docs`

## Test template

```java
@Test
void myEndpointRequiresAuth() throws Exception {
    mockMvc.perform(get("/your-path"))
            .andExpect(status().isUnauthorized());
}

@Test
@WithMockUser(authorities = {"your:scope"})
void myEndpointAllowedWithScope() throws Exception {
    mockMvc.perform(get("/your-path"))
            .andExpect(status().isOk());
}
```

MockMvc paths are servlet-relative; context path `/api` is applied automatically in tests.
