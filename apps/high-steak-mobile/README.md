# High Steak Mobile

Flutter client for the High Steak API.

## Run

Ensure the API is up from the repo root:

```bash
npm run docker:health
```

```bash
cd apps/high-steak-mobile
flutter pub get

# iOS simulator or macOS (default — uses 127.0.0.1:8080)
flutter run

# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api

# Android emulator + HTTP Toolkit (or any host proxy) — required or API calls hang
adb reverse tcp:8080 tcp:8080
flutter run --dart-define=API_PROXY_DEBUG=true

# Physical phone on same Wi‑Fi (replace with your machine's IP)
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/api
```

The app picks a sensible default per platform. You only need `--dart-define` when the default is wrong (Android emulator override is optional since Android is auto-detected).

## Phase 1 (current)

- Persistent login (`shared_preferences`)
- JWT scopes for feature gates
- **Feed** — Everyone / Following tabs, infinite scroll pagination
- **Post detail** — gallery, comments with pagination, add comment
- **Profile** — view user + paginated posts
- **Routing** — `go_router` with auth redirects

## Parity roadmap (vs web)

| Phase | Features |
|-------|----------|
| **1** ✅ | Auth, feed, post detail, profile (read) |
| **2** | Create/edit post (multipart + image picker), delete |
| **3** | Discover, follow/unfollow, following list |
| **4** | Notifications, moderation notices |
| **5** | Moderator/admin manage screens |

See `apps/high-steak-web` for the reference implementation.
