# ADR 009: Transactional Email via Twilio SendGrid

## Status

Accepted

## Context

High Steaks needs transactional email for user-facing events (welcome, comments, follows, moderation). Users must be able to opt out per category.

We evaluated:

| Option | Pros | Cons |
|--------|------|------|
| **Self-hosted Postal on K8s** | Full control, no per-message SaaS cost | ~1.7 Gi cluster memory (MariaDB, RabbitMQ, web, SMTP, worker), ops burden, DNS/DKIM setup, deliverability tuning |
| **Twilio SendGrid (SaaS)** | No infra, built-in activity/DKIM tooling, free tier for low volume | Per-message cost at scale, shared IPs on free tier, junk folder risk for new domains |

The production cluster has limited memory. SendGrid removes an entire mail stack from Kubernetes and matches our transactional volume.

## Decision

### Provider and transport

- **Twilio SendGrid** for outbound mail
- **SMTP** via Spring Boot Mail (`spring-boot-starter-mail`) to `smtp.sendgrid.net:587`
- SMTP username is always `apikey`; password is the SendGrid API key (stored in secrets, never in Git)
- Sending domain: **`notify.hossam.io`**
- From address: `High Steaks <noreply@notify.hossam.io>` (`MAIL_FROM` / `mail.from` in Helm)

### Application architecture

- **`MailService`** — async HTML + plain-text send via `JavaMailSender`; no-op when `MAIL_ENABLED=false`
- **`EmailTemplateService`** + **`EmailHtmlLayout`** — branded HTML templates (dark steak theme, gold accents, CTA buttons)
- **`NotificationService`** — loads user/post/comment data and checks preferences before send
- **Domain events** — services publish `NotificationEvent` records; **`NotificationEventListener`** handles them with `@TransactionalEventListener(AFTER_COMMIT)` + `@Async("mailTaskExecutor")` so mail never rolls back the triggering transaction
- **Preferences** — `user_notification_preferences` (V17); `GET/PATCH /users/me/notification-preferences`; web page `/settings/notifications`

### All outbound emails (v1)

Six email types are implemented. See **ADR 010** for verification (auth-required, not preference-gated).

| # | Email | Subject (approx.) | Trigger | Service / path | Recipient | Preference gate |
|---|-------|-------------------|---------|----------------|-----------|-----------------|
| 1 | **Email verification** | Verify your High Steaks account | `POST /auth/register`, `POST /auth/resend-verification` | `EmailVerificationService.sendVerificationEmail()` | Registrant | None (required for signup) |
| 2 | **Welcome** | Welcome to High Steaks | `POST /auth/verify-email` when newly verified; `POST /auth/register` only when `app.auth.auto-verify-on-register=true` (tests) | `NotificationService.sendWelcome()` via `NotificationEvent.Welcome` | New user | Master `emailEnabled` + `welcomeEmail` |
| 3 | **New comment** | `{name} commented on "{post title}"` | Someone comments on a post | `PostCommentService.addComment()` → `NotificationEvent.NewComment` | Post author | Master + `commentEmail`; skip self-comment |
| 4 | **New follower** | `{name} started following you` | User follows another user | `SubscriptionService.subscribe()` → `NotificationEvent.NewFollower` | Followed user | Master + `followerEmail` |
| 5 | **Post hidden** | Your post "{title}" was hidden from the feed | Moderator hides a post | `SteakPostService.hidePost()` → `NotificationEvent.PostHidden` | Post author | Master + `moderationEmail` |
| 6 | **Post restored** | Your post "{title}" is back on the feed | Moderator restores a post | `SteakPostService.unhidePost()` → `NotificationEvent.PostRestored` | Post author | Master + `moderationEmail` |

**Not emailed:** bookmarks, likes, login alerts, password reset (not implemented), email change (email is immutable after signup per ADR 010).

Welcome is sent at most once per account (`newlyVerified` guard on verify; duplicate verify / Strict Mode does not re-send).

### Notification events (preference-gated)

Events 2–6 above are published as `NotificationEvent` records and handled by **`NotificationEventListener`** with `@TransactionalEventListener(AFTER_COMMIT)` + `@Async("mailTaskExecutor")` so mail never rolls back the triggering transaction.

| Event | Trigger | Recipient | Skip when |
|-------|---------|-----------|-----------|
| Welcome | `AuthService.verifyEmailAndLogin()` (or test auto-verify on register) | New user | `welcomeEmail` off |
| New comment | `PostCommentService.addComment()` | Post author | Self-comment, `commentEmail` off |
| New follower | `SubscriptionService.subscribe()` | Target user | `followerEmail` off |
| Post hidden | `SteakPostService.hidePost()` | Post author | `moderationEmail` off |
| Post restored | `SteakPostService.unhidePost()` | Post author | `moderationEmail` off |

Master switch: `emailEnabled`. Bookmarks do not trigger email.

Comment emails include an excerpt of the comment body, a **View post** link, and an **Open feed** link (`APP_BASE_URL` + `/feed`).

### DNS (Cloudflare, zone `hossam.io`)

SendGrid domain authentication on `notify.hossam.io`:

| Type | Name | Notes |
|------|------|-------|
| CNAME | `emXXXX.notify` | Link branding; **DNS only** (grey cloud) |
| CNAME | `s1._domainkey.notify` | DKIM |
| CNAME | `s2._domainkey.notify` | DKIM |
| TXT | `_dmarc.notify` | e.g. `v=DMARC1; p=none;` |
| TXT | `notify` | `v=spf1 include:sendgrid.net ~all` |

Orange-cloud (proxied) CNAMEs break SendGrid validation. The `emXXXX` hostname can change if domain auth is re-run — always match the value shown in SendGrid UI.

### Configuration

**Production (Helm `helm/high-steak/`):**

```yaml
mail:
  enabled: true
  from: 'High Steaks <noreply@notify.hossam.io>'
  baseUrl: https://steaks.apps.hossam.io
  smtp:
    host: smtp.sendgrid.net
    port: 587
    username: apikey
  secret:
    name: high-steak-mail-secret
    passwordKey: sendgrid-api-key
```

Secret: `kubectl create secret generic high-steak-mail-secret -n apps --from-literal=sendgrid-api-key='SG...'`

**Local (Docker Compose):**

- Copy `.env.local.example` → `.env.local` (gitignored) with SendGrid vars
- API service loads `env_file: .env.local`
- Without `.env.local`, mail stays disabled (`MAIL_ENABLED` defaults false)

**Tests:**

- `application-test.yml` sets `app.mail.enabled: false`
- Integration tests do not send real mail

### Rejected alternatives

- **Postal Helm chart** — implemented initially, removed; not deployed to cluster
- **SendGrid HTTP API** — SMTP sufficient for current volume; same API key works if we switch later
- **Mailpit in Compose** — removed; local dev uses real SendGrid via `.env.local` for faithful deliverability testing

## Consequences

- API key is a production secret; rotate if exposed; never commit to Git or chat
- New domains may land in junk until reputation builds; users should mark not junk and add SPF
- Free/shared SendGrid IPs can affect deliverability; dedicated IP optional at higher volume
- Email is fire-and-forget async; failures are logged, not retried in v1
- `APP_BASE_URL` must match the public web URL so links in emails resolve correctly
- Users who registered before V17 get preferences via migration backfill; new users get defaults on register

## References

- `V17__notification_preferences.sql`
- `MailProperties`, `MailService`, `EmailTemplateService`, `EmailHtmlLayout`, `NotificationService`, `NotificationEventListener`, `EmailVerificationService`
- `NotificationPreferenceController`, `NotificationDtos`
- `helm/high-steak/values.yaml`, `templates/configmap.yaml`, `templates/api-deployment.yaml`
- `.env.local.example`, `docker-compose.yml`
- `docs/k8s.md` (operational setup)
- `apps/high-steak-web/src/pages/NotificationSettingsPage.tsx`
- **ADR 010** — email verification on registration (email type #1 above)
