import 'dart:async';

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
  String? _refreshToken;
  UserSummary? _user;
  bool _initializing = true;
  Timer? _refreshTimer;

  String? get token => _token;
  UserSummary? get user => _user;
  bool get isAuthenticated => _token != null && _refreshToken != null && _user != null;
  bool get initializing => _initializing;

  bool hasScope(String scope) => _user?.hasScope(scope) ?? false;

  Future<void> initialize() async {
    _api.sessionHandlers = ApiSessionHandlers(
      getAccessToken: () => _token,
      getRefreshToken: () => _refreshToken,
      onSessionRefreshed: _onSessionRefreshedFromApi,
      onLogout: logout,
    );

    final savedAccess = await _storage.readToken();
    final savedRefresh = await _storage.readRefreshToken();
    if (savedAccess != null && savedRefresh != null) {
      await _applyTokens(savedAccess, savedRefresh, refreshProfile: true);
    } else if (savedAccess != null || savedRefresh != null) {
      await _storage.clearToken();
    }
    _initializing = false;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final result = await _api.login(username: username, password: password);
    await _persistTokens(
      result['token'] as String,
      result['refreshToken'] as String,
    );
  }

  Future<RegisterResult> register({
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

    if (result['verificationRequired'] == true) {
      return RegisterResult.verificationPending(
        result['email']?.toString() ?? email,
      );
    }

    final token = result['token'] as String?;
    final refreshToken = result['refreshToken'] as String?;
    if (token == null || refreshToken == null) {
      throw ApiException('Registration succeeded but no session was returned.');
    }

    await _persistTokens(token, refreshToken);
    return RegisterResult.loggedIn();
  }

  Future<void> _persistTokens(String accessToken, String refreshToken) async {
    await _storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    await _applyTokens(accessToken, refreshToken, refreshProfile: true);
    notifyListeners();
  }

  void _onSessionRefreshedFromApi(String accessToken, String refreshToken) {
    _token = accessToken;
    _refreshToken = refreshToken;
    _user = JwtUtils.userFromToken(accessToken);
    unawaited(
      _storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken),
    );
    _scheduleProactiveRefresh(accessToken, refreshToken);
    notifyListeners();
  }

  Future<void> _applyTokens(
    String accessToken,
    String refreshToken, {
    required bool refreshProfile,
  }) async {
    _token = accessToken;
    _refreshToken = refreshToken;
    var summary = JwtUtils.userFromToken(accessToken);
    if (refreshProfile) {
      try {
        final profile = await _api.getMe();
        summary = summary.copyWithProfile(profile);
      } catch (_) {
        // Keep JWT claims if profile refresh fails transiently.
      }
    }
    _user = summary;
    _scheduleProactiveRefresh(accessToken, refreshToken);
  }

  void _scheduleProactiveRefresh(String accessToken, String refreshToken) {
    _refreshTimer?.cancel();
    final expiry = JwtUtils.expiryFromToken(accessToken);
    if (expiry == null) return;
    final refreshAt = expiry.subtract(const Duration(minutes: 5));
    final delay = refreshAt.difference(DateTime.now());
    _refreshTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      unawaited(_tryRefreshSession());
    });
  }

  Future<void> refreshSessionIfNeeded() async {
    final token = _token;
    if (token == null || _refreshToken == null) return;

    final expiry = JwtUtils.expiryFromToken(token);
    if (expiry == null) return;

    final refreshBy = expiry.subtract(const Duration(minutes: 5));
    if (DateTime.now().isBefore(refreshBy)) return;

    await _tryRefreshSession();
  }

  Future<void> _tryRefreshSession() async {
    final refreshToken = _refreshToken ?? await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await logout();
      return;
    }
    try {
      final result = await _api.refresh(refreshToken: refreshToken);
      await _persistTokens(
        result['token'] as String,
        result['refreshToken'] as String,
      );
    } catch (_) {
      await logout();
    }
  }

  Future<void> refreshProfile() async {
    final token = _token;
    if (token == null || _refreshToken == null) return;
    await _applyTokens(token, _refreshToken!, refreshProfile: true);
    notifyListeners();
  }

  Future<void> applySessionUpdate(String token) async {
    final refreshToken = _refreshToken ?? await _storage.readRefreshToken();
    if (refreshToken == null) return;
    await _storage.saveToken(token);
    await _applyTokens(token, refreshToken, refreshProfile: false);
    notifyListeners();
  }

  Future<void> logout() async {
    _refreshTimer?.cancel();
    final refreshToken = _refreshToken ?? await _storage.readRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _api.logout(refreshToken: refreshToken);
      } catch (_) {
        // Best-effort server logout.
      }
    }
    _token = null;
    _refreshToken = null;
    _user = null;
    await _storage.clearToken();
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

class RegisterResult {
  const RegisterResult._({
    required this.verificationRequired,
    this.verificationEmail,
    this.loggedIn = false,
  });

  factory RegisterResult.loggedIn() =>
      const RegisterResult._(verificationRequired: false, loggedIn: true);

  factory RegisterResult.verificationPending(String email) => RegisterResult._(
        verificationRequired: true,
        verificationEmail: email,
      );

  final bool verificationRequired;
  final String? verificationEmail;
  final bool loggedIn;
}
