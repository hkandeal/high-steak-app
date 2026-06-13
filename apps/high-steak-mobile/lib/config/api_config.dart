/// Base URL for the High Steak API (includes `/api` context path).
///
/// - Android emulator: `http://10.0.2.2:8080/api`
/// - iOS simulator: `http://localhost:8080/api`
/// - Physical device: your machine's LAN IP with `/api` suffix
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8080/api',
);
