# ADR 008: Refresh Tokens and Sliding Sessions

## Status

Accepted

## Context

ADR 003 established a single long-lived JWT (24h) returned on login/register. Clients store it in localStorage (web) or SharedPreferences (mobile). When the token expires, the next API call returns 401 and the client logs out. There is no silent renewal and no server-side session revocation beyond blocking the user account.

Short-lived access tokens improve security if leaked. Refresh tokens with rotation enable sliding sessions for active users without hourly password prompts.

## Decision

- **Access token (JWT):** 1 hour TTL (`JWT_ACCESS_EXPIRATION_MS`, default `3600000`)
- **Refresh token:** 14 days TTL (`JWT_REFRESH_EXPIRATION_MS`, default `1209600000`), sliding on each refresh
- **Rotation:** Each `POST /auth/refresh` revokes the presented refresh token and issues a new one in the same token family; reuse of a revoked token revokes the entire family
- **Storage:** Refresh tokens are stored server-side as SHA-256 hashes in `refresh_tokens`
- **Clients:** Login/register/refresh return `{ token, refreshToken }` in JSON; clients persist both (web localStorage, mobile secure storage)
- **Logout:** `POST /auth/logout` revokes the presented refresh token
- **Block user:** Revokes all refresh tokens for that user
- **Profile update:** Still returns a new access token; does not rotate refresh unless the client calls `/auth/refresh`

## Consequences

- ADR 003 remains valid for access-token-only responses shape (`token` field); `refreshToken` is an additive field
- Clients must implement proactive refresh (~5 minutes before access expiry) and 401 retry via refresh
- No HttpOnly cookie in v1 (cross-origin local dev); production same-host deploy can add cookies later
- Role/scope changes take effect on next refresh or `/auth/me` with a still-valid access token until access expires

## References

- `RefreshTokenService`, `V14__refresh_tokens.sql`
- `POST /auth/refresh`, `POST /auth/logout`
- `apps/high-steak-web/src/api/client.ts`, `AuthContext.tsx`
- `apps/high-steak-mobile/lib/auth/auth_controller.dart`
