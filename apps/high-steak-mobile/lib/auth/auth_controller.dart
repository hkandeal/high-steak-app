import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../utils/jwt_utils.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required ApiService api,
    AuthStorage? storage,
  })  : _api = api,
        _storage = storage ?? AuthStorage();

  final ApiService _api;
  final AuthStorage _storage;

  String? _token;
  UserSummary? _user;
  bool _initializing = true;

  String? get token => _token;
  UserSummary? get user => _user;
  bool get isAuthenticated => _token != null && _user != null;
  bool get initializing => _initializing;

  bool hasScope(String scope) => _user?.hasScope(scope) ?? false;

  Future<void> initialize() async {
    _api.onUnauthorized = logout;
    final saved = await _storage.readToken();
    if (saved != null) {
      await _applyToken(saved, refreshProfile: true);
    }
    _initializing = false;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final result = await _api.login(username: username, password: password);
    final token = result['token'] as String;
    await _persistToken(token);
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    final result = await _api.register(
      username: username,
      email: email,
      password: password,
      displayName: displayName,
    );
    final token = result['token'] as String;
    await _persistToken(token);
  }

  Future<void> _persistToken(String token) async {
    await _storage.saveToken(token);
    await _applyToken(token, refreshProfile: true);
    notifyListeners();
  }

  Future<void> _applyToken(String token, {required bool refreshProfile}) async {
    _token = token;
    var summary = JwtUtils.userFromToken(token);
    if (refreshProfile) {
      try {
        final profile = await _api.getMe(token);
        summary = summary.copyWithProfile(profile);
      } catch (_) {
        // Keep JWT claims if profile refresh fails transiently.
      }
    }
    _user = summary;
  }

  Future<void> refreshProfile() async {
    final token = _token;
    if (token == null) return;
    await _applyToken(token, refreshProfile: true);
    notifyListeners();
  }

  Future<void> applySessionUpdate(String token) async {
    await _persistToken(token);
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _storage.clearToken();
    notifyListeners();
  }
}
