# ADR 011: Mobile Deep Linking for Password Reset

## Status

Accepted

## Context

Password reset is implemented on web and mobile (`POST /auth/request-password-reset`, `POST /auth/reset-password`). Reset emails include:

| Link | URL pattern | Intended target |
|------|-------------|-----------------|
| **Reset password** (primary CTA) | `{APP_BASE_URL}/reset-password?token=…` | Web reset page |
| **Open in app** (secondary CTA) | `highsteaks://reset-password?token=…` | Mobile app via custom URL scheme |

Production domain: `https://steaks.apps.hossam.io` (`APP_BASE_URL` / `mail.baseUrl` in Helm).

The mobile app registers:

- Custom scheme `highsteaks://reset-password` (iOS `Info.plist`, Android `AndroidManifest.xml`)
- HTTPS path `/reset-password` on `steaks.apps.hossam.io` (Android intent-filter with `autoVerify="true"`)
- `app_links` + `DeepLinkService` routing to `/reset-password?token=…` in `go_router`

**Problem observed in production email (Outlook mobile):** the **Open in app** button is often disabled or non-functional. Outlook and many corporate mail clients block or strip non-HTTPS links (`highsteaks://`) in HTML for security. This is expected client behaviour, not an app bug.

**Universal Links (iOS) and App Links (Android)** allow a single **HTTPS** link in email to open the installed app directly, with the browser as fallback when the app is not installed. This requires server-side verification files and an iOS app entitlement — not only in-app manifest entries.

The mobile app is **not yet published** on the App Store or Play Store. We plan to publish later. Store listing is not required to implement or test verified HTTPS deep links (TestFlight, internal APK, or local installs are sufficient).

## Decision

### Email links (v1 production behaviour until Universal/App Links ship)

1. **Rely on the HTTPS reset link** as the supported path for all users and all mail clients (including Outlook).
2. **Treat `highsteaks://` in email as best-effort only** — do not depend on it for production UX; it may be removed or de-emphasised in a future email template change once HTTPS app links are verified.
3. Web reset remains the **universal fallback** when the app is not installed or verified links are not yet active on the user’s build.

### Target architecture (to implement before / at mobile public launch)

Use **one HTTPS link** in password-reset email:

```
https://steaks.apps.hossam.io/reset-password?token=…
```

| User state | Expected behaviour |
|------------|-------------------|
| App installed + verified link | OS opens High Steaks → in-app reset screen |
| App not installed | Browser opens web reset page |
| Old app build (no Associated Domains) | Browser opens web reset page |

Do **not** require a separate `highsteaks://` button in email for the primary mobile flow once verified HTTPS links are live.

### Server-side verification (required for HTTPS → app)

Host on `steaks.apps.hossam.io`:

| File | Platform | Path |
|------|----------|------|
| `apple-app-site-association` | iOS | `/.well-known/apple-app-site-association` (or domain root) |
| `assetlinks.json` | Android | `/.well-known/assetlinks.json` |

**iOS AASA** must declare app ID `TEAMID.com.highsteak.highSteakMobile` and paths such as `/reset-password` (Team ID from Apple Developer account).

**Android assetlinks** must declare package `com.highsteak.high_steak_mobile` and the **SHA-256 certificate fingerprint** of the signing key used for release (Play App Signing upload key or release keystore).

Files must be served over HTTPS without redirects on the well-known URLs.

### In-app configuration (required for HTTPS → app)

| Platform | Requirement | Current state |
|----------|-------------|---------------|
| iOS | **Associated Domains** entitlement: `applinks:steaks.apps.hossam.io` | Not yet added (custom scheme only) |
| Android | Intent-filter for `https://steaks.apps.hossam.io/reset-password` + matching `assetlinks.json` | Manifest present; domain verification pending |
| Both | `DeepLinkService` handles `/reset-password` + `token` query param | Implemented |

### Distribution and timing

1. **Pre-store:** Domain verification files and iOS entitlement can be added and tested via TestFlight (iOS) and internal / debug-signed APK (Android). Public store presence is **not** a prerequisite for the mechanism.
2. **At store launch:** Ship a release build that includes Associated Domains (iOS) and matches the production signing cert in `assetlinks.json` (Android). Users must install that build (or newer) for email links to open the app.
3. **Until verified HTTPS links are live:** Password reset from email is **web-only** for reliable UX; mobile users complete reset in the browser, then log in on the app.

### Optional interim bridge (not chosen as primary path)

An HTTPS “smart link” page (e.g. `/open/reset-password`) that loads in the browser and attempts `highsteaks://` before falling back to web was considered. **Deferred** in favour of proper Universal/App Links, which work from Outlook with a single HTTPS URL and avoid an extra browser hop.

## Consequences

- Password-reset email works reliably in Outlook and corporate mail today via **HTTPS web reset**.
- **Open in app** (`highsteaks://`) in email should not be documented as a supported production flow.
- Follow-up work before mobile launch:
  - [ ] Host `apple-app-site-association` and `assetlinks.json` on prod web / ingress
  - [ ] Add iOS Associated Domains entitlement
  - [ ] Confirm Android release signing fingerprint in `assetlinks.json`
  - [ ] Test end-to-end from mail on TestFlight / internal install
  - [ ] Simplify email template to HTTPS-only CTA when verified links are confirmed
- Updating ADR 009’s email catalog: password reset is implemented (see this ADR); ADR 009 “not implemented” note is stale.

## References

- `PasswordResetService`, `EmailTemplateService.passwordReset()`
- `apps/high-steak-mobile/lib/navigation/deep_link_service.dart`
- `apps/high-steak-mobile/android/app/src/main/AndroidManifest.xml`
- `apps/high-steak-mobile/ios/Runner/Info.plist`
- iOS bundle ID: `com.highsteak.highSteakMobile`
- Android application ID: `com.highsteak.high_steak_mobile`
- **ADR 009** — transactional email transport and `APP_BASE_URL`
- **ADR 010** — email verification (separate auth link pattern)
