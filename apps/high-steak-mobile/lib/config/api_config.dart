import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Production API (same as web `VITE_API_URL` in Docker prod / Helm ingress).
const productionApiBaseUrl = 'https://steaks.apps.hossam.io/api';

/// Base URL for the High Steak API (must include `/api` context path).
///
/// Override at build/run time:
/// ```bash
/// # Physical phone against production
/// flutter run --dart-define=API_BASE_URL=https://steaks.apps.hossam.io/api
///
/// # Or shorthand
/// flutter run --dart-define=ENV=production
///
/// API request/response logs print to the `flutter run` terminal in **debug**
/// builds only (tokens/passwords redacted). Not enabled in profile/release.
///
/// # Physical phone against local Docker on your Mac (same Wi‑Fi)
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/api
/// ```
///
/// **HTTP Toolkit / Charles / mitmproxy on Android emulator:** use localhost +
/// adb port reverse so the proxy on your Mac can reach the API:
/// ```bash
/// adb reverse tcp:8080 tcp:8080
/// flutter run --dart-define=API_PROXY_DEBUG=true
/// ```
///
/// Defaults when not overridden:
/// - Android emulator → `10.0.2.2` (host machine)
/// - iOS simulator, macOS, Linux, etc. → `127.0.0.1`
String get apiBaseUrl {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;

  const env = String.fromEnvironment('ENV');
  if (env == 'production' || env == 'prd') return productionApiBaseUrl;

  const proxyDebug = bool.fromEnvironment('API_PROXY_DEBUG');

  if (kIsWeb) return 'http://127.0.0.1:8080/api';
  if (Platform.isAndroid) {
    if (proxyDebug) return 'http://127.0.0.1:8080/api';
    return 'http://10.0.2.2:8080/api';
  }
  return 'http://127.0.0.1:8080/api';
}
