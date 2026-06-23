import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';

/// Routes incoming app / universal links into [GoRouter].
class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  GoRouter? _router;

  void attach(GoRouter router) {
    _router = router;
  }

  Future<void> initialize() async {
    await _subscription?.cancel();
    _subscription = _appLinks.uriLinkStream.listen(_handleUri, onError: (_) {});

    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      _handleUri(initial);
    }
  }

  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _router = null;
  }

  void _handleUri(Uri uri) {
    final router = _router;
    if (router == null) return;

    final path = _normalizedPath(uri);
    if (path == '/reset-password') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        router.go('/reset-password?token=${Uri.encodeComponent(token)}');
      }
    }
  }

  String _normalizedPath(Uri uri) {
    if (uri.scheme == 'highsteaks') {
      return '/${uri.host}${uri.path}';
    }
    final path = uri.path;
    if (path.isEmpty) return '/';
    return path.startsWith('/') ? path : '/$path';
  }
}
