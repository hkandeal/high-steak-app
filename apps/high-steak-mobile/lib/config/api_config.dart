/// Base URL for the High Steak API.
///
/// - Android emulator: `http://10.0.2.2:8080`
/// - iOS simulator: `http://localhost:8080`
/// - Physical device: your machine's LAN IP
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8080',
);
