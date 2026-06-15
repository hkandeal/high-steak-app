import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Base URL for the High Steak API (must include `/api` context path).
///
/// Override at build/run time:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/api`
///
/// **HTTP Toolkit / Charles / mitmproxy on Android emulator:** use localhost +
/// adb port reverse so the proxy on your Mac can reach the API:
/// ```bash
/// adb reverse tcp:8080 tcp:8080
/// flutter run --dart-define=API_PROXY_DEBUG=true
/// ```
/// (`10.0.2.2` works without a proxy, but hangs when traffic is intercepted
/// because the proxy forwards to `10.0.2.2` on the host, not your machine.)
///
/// Defaults when not overridden:
/// - Android emulator → `10.0.2.2` (host machine)
/// - iOS simulator, macOS, Linux, etc. → `127.0.0.1`
String get apiBaseUrl {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;

  const proxyDebug = bool.fromEnvironment('API_PROXY_DEBUG');

  if (kIsWeb) return 'http://127.0.0.1:8080/api';
  if (Platform.isAndroid) {
    if (proxyDebug) return 'http://127.0.0.1:8080/api';
    return 'http://10.0.2.2:8080/api';
  }
  return 'http://127.0.0.1:8080/api';
}
