# ADR 003: Token-Only Login Response

## Status

Accepted (amended by [ADR 008](008-refresh-tokens-sliding-sessions.md))

## Context

Login and register previously returned both a JWT and a user object. User profile data was duplicated between the response body and JWT claims.

## Decision

- `POST /auth/login` and `POST /auth/register` return `{ "token": "...", "refreshToken": "..." }`
- Full user profile (including role and scopes) available at `GET /auth/me` with Bearer token
- JWT claims include: `sub`, `uid`, `email`, `displayName`, `avatarUrl`, `roles`, `scopes`
- Web client parses user from token via `parseUserFromToken()` for immediate UI hydration
- Optional refresh via `getMe()` in `AuthContext`

## Consequences

- Web/mobile must not expect `user` in auth responses
- Client-side auth state derives from JWT payload
- Profile changes require re-fetch via `/auth/me` or re-login to refresh token

## References

- `AuthDtos.AuthResponse` (token only)
- `apps/high-steak-web/src/api/client.ts` — `parseUserFromToken`
- `docs/architecture.md` (auth flow)
