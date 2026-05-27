import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('$apiBaseUrl$path');

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    final res = await _client.post(
      _uri('/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'displayName': displayName,
      }),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final res = await _client.post(
      _uri('/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    return _decode(res);
  }

  Future<List<dynamic>> fetchPosts() async {
    final res = await _client.get(_uri('/api/posts'));
    if (res.statusCode >= 400) {
      _decode(res);
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  Map<String, dynamic> _decode(http.Response res) {
    final body = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body);
    if (res.statusCode >= 400) {
      final message = body is Map ? body['message']?.toString() : null;
      throw Exception(message ?? 'Request failed (${res.statusCode})');
    }
    return body is Map<String, dynamic> ? body : {'data': body};
  }
}
