# ADR 010: Email Verification on Registration

## Status

Accepted

## Context

ADR 009 added transactional email via SendGrid. Registration previously created an active session immediately and sent a welcome email. We need accounts to be inactive until the user proves they control the registered email address. Email should also be immutable after signup to avoid account takeover via profile changes.

## Decision

### Verification email (auth-required)

| Email | Subject | Trigger | Service | Opt-out |
|-------|---------|---------|---------|---------|
| **Email verification** | Verify your High Steaks account | `POST /auth/register`, `POST /auth/resend-verification` | `EmailVerificationService.sendVerificationEmail()` | No — required to activate account |

Link: `{APP_BASE_URL}/verify-email?token=…` (token expires in 24 hours by default). Resend invalidates previous active tokens for that user.

### Account lifecycle

- New users are created with `email_verified = false` and **do not receive JWT tokens** on `POST /auth/register`
- `POST /auth/verify-email` validates the token, sets `email_verified = true`, sends the **welcome email** (only when `newlyVerified`), and returns `{ token, refreshToken }`
- `POST /auth/login` and refresh reject unverified accounts with a clear message
- `POST /auth/resend-verification` accepts an email and resends verification if an unverified account exists (always 204 to avoid enumeration)
- `PATCH /auth/me` no longer accepts email changes; display name and avatar only
- Bootstrap admin and existing users (V18 backfill) are `email_verified = true`
- Tests use `app.auth.auto-verify-on-register: true` to preserve integration test ergonomics (skips verification email; welcome sent on register in tests only)

See **ADR 009** for the full list of all six outbound email types and notification preferences.

## Consequences

- Web register flow shows “check your email” instead of auto-login
- New route `/verify-email` in the web app handles the link from email
- Unverified users cannot use the app until they click the link
- Users who lose the email must use resend verification; support cannot change email via API in v1

## References

- `V18__email_verification.sql`
- `EmailVerificationService`, `AuthService`, `AuthController`
- `apps/high-steak-web/src/pages/VerifyEmailPage.tsx`, `AuthPages.tsx`, `ProfilePage.tsx`
- **ADR 009** — SendGrid transport, templates, and full email catalog (types 2–6)
