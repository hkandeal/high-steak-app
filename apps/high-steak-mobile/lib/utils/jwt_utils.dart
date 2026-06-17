import 'dart:convert';

import '../models/user.dart';

class JwtUtils {
  static Map<String, dynamic> parsePayload(String token) {
    final parts = token.split('.');
    if (parts.length < 2) {
      throw FormatException('Invalid token');
    }
    var normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    while (normalized.length % 4 != 0) {
      normalized += '=';
    }
    final decoded = utf8.decode(base64.decode(normalized));
    return jsonDecode(decoded) as Map<String, dynamic>;
  }

  static DateTime? expiryFromToken(String token) {
    try {
      final payload = parsePayload(token);
      final exp = payload['exp'];
      if (exp is! num) return null;
      return DateTime.fromMillisecondsSinceEpoch((exp * 1000).round(), isUtc: true).toLocal();
    } catch (_) {
      return null;
    }
  }

  static UserSummary userFromToken(String token) {
    final payload = parsePayload(token);
    final scopesRaw = payload['scopes'];
    final scopes = scopesRaw is List
        ? scopesRaw.map((e) => e.toString()).toList(growable: false)
        : <String>[];
    final rolesRaw = payload['roles'];
    final role = rolesRaw is List && rolesRaw.isNotEmpty
        ? rolesRaw.first.toString()
        : 'USER';

    return UserSummary(
      id: payload['uid']?.toString() ?? '',
      username: payload['sub']?.toString() ?? '',
      email: payload['email']?.toString() ?? '',
      displayName: payload['displayName']?.toString() ?? '',
      avatarUrl: payload['avatarUrl'] as String?,
      role: role,
      scopes: scopes,
    );
  }
}
