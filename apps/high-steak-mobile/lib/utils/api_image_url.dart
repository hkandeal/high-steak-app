import '../config/api_config.dart';

/// Resolves API-relative asset paths (e.g. `/uploads/...`) to full URLs.
///
/// Uploads are served under the same servlet context as the REST API:
/// `http://host:8080/api/uploads/...` (see docs/architecture.md).
String resolveApiImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;

  final base = apiBaseUrl.endsWith('/')
      ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
      : apiBaseUrl;
  final normalized = path.startsWith('/') ? path : '/$path';
  return '$base$normalized';
}

/// All image URLs for a post, resolved for network image widgets.
List<String> resolvePostImageUrls(Iterable<String> paths) {
  return paths
      .map(resolveApiImageUrl)
      .where((url) => url.isNotEmpty)
      .toList(growable: false);
}
