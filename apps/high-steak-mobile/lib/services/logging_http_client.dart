import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Wraps [http.Client] and logs every request/response when [apiDebugLogEnabled].
///
/// Enable with `flutter run --dart-define=API_DEBUG_LOG=true` (debug builds only).
/// Logs print via [debugPrint] in the `flutter run` terminal.
class LoggingHttpClient extends http.BaseClient {
  LoggingHttpClient({http.Client? inner}) : _inner = inner ?? http.Client();

  final http.Client _inner;

  static const _prefix = '[API] ';
  static const _maxBodyChars = 8000;
  static const _debugPrintChunkSize = 800;

  static var _announced = false;

  static const _sensitiveKeys = {
    'password',
    'refreshtoken',
    'token',
    'authorization',
    'accesstoken',
  };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!apiDebugLogEnabled) {
      return _inner.send(request);
    }

    _announceOnce();

    final started = Stopwatch()..start();
    _logOutgoing(request);

    final http.StreamedResponse response;
    try {
      response = await _inner.send(request);
    } catch (error, stackTrace) {
      _printLog(
        '← ERROR ${request.method} ${request.url} (${started.elapsedMilliseconds}ms)\n'
        '$error\n$stackTrace',
      );
      rethrow;
    }

    final bytes = await response.stream.toBytes();
    started.stop();
    _logIncoming(request, response, bytes, started.elapsedMilliseconds);

    return http.StreamedResponse(
      Stream.value(bytes),
      response.statusCode,
      contentLength: bytes.length,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() {
    _inner.close();
  }

  static void _announceOnce() {
    if (_announced) return;
    _announced = true;
    _printLog(
      'HTTP logging enabled (API_DEBUG_LOG=true; request + response bodies, secrets redacted)',
    );
  }

  static void _logOutgoing(http.BaseRequest request) {
    final buffer = StringBuffer()
      ..writeln('→ ${request.method} ${request.url}')
      ..writeln('Headers: ${jsonEncode(_redactHeaders(request.headers))}');

    if (request is http.Request) {
      buffer.writeln('Body: ${_formatPayload(request.body)}');
    } else if (request is http.MultipartRequest) {
      buffer.writeln('Fields: ${jsonEncode(_redactMap(request.fields))}');
      for (final file in request.files) {
        final name = file.filename ?? file.field;
        buffer.writeln('File: $name (${file.length} bytes)');
      }
    }

    _printLog(_truncate(buffer.toString()));
  }

  static void _logIncoming(
    http.BaseRequest request,
    http.StreamedResponse response,
    List<int> bytes,
    int elapsedMs,
  ) {
    final body = utf8.decode(bytes, allowMalformed: true);
    final buffer = StringBuffer()
      ..writeln('← ${response.statusCode} ${request.method} ${request.url} (${elapsedMs}ms)')
      ..writeln('Body: ${_formatPayload(body)}');

    _printLog(_truncate(buffer.toString()));
  }

  static void _printLog(String message) {
    if (message.length <= _debugPrintChunkSize) {
      debugPrint('$_prefix$message');
      return;
    }
    for (var start = 0; start < message.length; start += _debugPrintChunkSize) {
      final end = (start + _debugPrintChunkSize < message.length)
          ? start + _debugPrintChunkSize
          : message.length;
      debugPrint('$_prefix${message.substring(start, end)}');
    }
  }

  static Map<String, String> _redactHeaders(Map<String, String> headers) {
    return headers.map((key, value) {
      if (key.toLowerCase() == 'authorization') {
        return MapEntry(key, 'Bearer ***');
      }
      return MapEntry(key, value);
    });
  }

  static Map<String, String> _redactMap(Map<String, String> values) {
    return values.map((key, value) {
      if (_isSensitiveKey(key)) {
        return MapEntry(key, '***');
      }
      return MapEntry(key, value);
    });
  }

  static bool _isSensitiveKey(String key) =>
      _sensitiveKeys.contains(key.toLowerCase().replaceAll('_', '').replaceAll('-', ''));

  static dynamic _redactJson(dynamic value) {
    if (value is Map) {
      return value.map((key, nested) {
        final keyText = key.toString();
        if (_isSensitiveKey(keyText)) {
          return MapEntry(keyText, '***');
        }
        return MapEntry(keyText, _redactJson(nested));
      });
    }
    if (value is List) {
      return value.map(_redactJson).toList();
    }
    return value;
  }

  static String _formatPayload(String body) {
    if (body.isEmpty) return '(empty)';
    try {
      final decoded = jsonDecode(body);
      final redacted = _redactJson(decoded);
      return const JsonEncoder.withIndent('  ').convert(redacted);
    } catch (_) {
      return body;
    }
  }

  static String _truncate(String text) {
    if (text.length <= _maxBodyChars) return text;
    return '${text.substring(0, _maxBodyChars)}\n… (truncated)';
  }
}
