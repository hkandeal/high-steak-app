import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../constants/pagination.dart';
import '../models/notification_preferences.dart';
import '../models/page_response.dart';
import '../models/post_comment.dart';
import '../models/review_tag_catalog.dart';
import '../models/subscription_summary.dart';
import '../models/steak_post.dart';
import '../models/user.dart';
import '../utils/post_image_picker.dart';
import 'logging_http_client.dart';

class ApiSessionHandlers {
  const ApiSessionHandlers({
    required this.getAccessToken,
    required this.getRefreshToken,
    required this.onSessionRefreshed,
    required this.onLogout,
  });

  final String? Function() getAccessToken;
  final String? Function() getRefreshToken;
  final void Function(String accessToken, String refreshToken) onSessionRefreshed;
  final Future<void> Function() onLogout;
}

class ApiService {
  ApiService({http.Client? client})
      : _client = client ?? (kDebugMode ? LoggingHttpClient() : http.Client());

  static const _authRefreshPaths = [
    '/auth/refresh',
    '/auth/login',
    '/auth/register',
    '/auth/logout',
    '/auth/verify-email',
  ];

  final http.Client _client;
  ApiSessionHandlers? sessionHandlers;
  Future<bool>? _refreshInFlight;

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$apiBaseUrl$normalized').replace(queryParameters: query);
  }

  Map<String, String> _headers({String? token, bool json = false}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String _requireAccessToken() {
    final token = sessionHandlers?.getAccessToken();
    if (token == null || token.isEmpty) {
      throw ApiException('Not authenticated');
    }
    return token;
  }

  bool _shouldAttemptRefresh(String path) {
    return !_authRefreshPaths.any((segment) => path.startsWith(segment));
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshInFlight != null) {
      return _refreshInFlight!;
    }

    final refreshToken = sessionHandlers?.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    _refreshInFlight = () async {
      try {
        final res = await _client.post(
          _uri('/auth/refresh'),
          headers: _headers(json: true),
          body: jsonEncode({'refreshToken': refreshToken}),
        );
        if (res.statusCode != 200) return false;
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final access = body['token'] as String?;
        final nextRefresh = body['refreshToken'] as String?;
        if (access == null || nextRefresh == null) return false;
        sessionHandlers?.onSessionRefreshed(access, nextRefresh);
        return true;
      } catch (_) {
        return false;
      } finally {
        _refreshInFlight = null;
      }
    }();

    return _refreshInFlight!;
  }

  Future<T> _parseResponse<T>(
    http.Response res,
    T Function(dynamic body) parse,
  ) async {
    dynamic body;
    if (res.body.isNotEmpty) {
      body = jsonDecode(res.body);
    }
    if (res.statusCode >= 400) {
      final message = body is Map ? body['message']?.toString() : null;
      throw ApiException(message ?? 'Request failed (${res.statusCode})');
    }
    return parse(body);
  }

  Future<T> _authorized<T>(
    String path,
    Future<http.Response> Function(String token) send,
    T Function(dynamic body) parse,
  ) async {
    Future<http.Response> sendWithCurrentToken() => send(_requireAccessToken());

    var res = await sendWithCurrentToken();
    if (res.statusCode == 401 && _shouldAttemptRefresh(path)) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        res = await sendWithCurrentToken();
      } else {
        await sessionHandlers?.onLogout();
        throw ApiException('Session expired. Please sign in again.');
      }
    }
    return _parseResponse(res, parse);
  }

  Future<T> _authorizedMultipart<T>(
    String path,
    Future<http.StreamedResponse> Function(String token) send,
    T Function(dynamic body) parse,
  ) async {
    return _authorized(
      path,
      (token) async => http.Response.fromStream(await send(token)),
      parse,
    );
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    final res = await _client.post(
      _uri('/auth/register'),
      headers: _headers(json: true),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'displayName': displayName,
      }),
    );
    return _parseResponse(res, (body) => body as Map<String, dynamic>);
  }

  Future<AvailabilityResult> checkUsernameAvailability(String username) async {
    final res = await _client.get(
      _uri('/auth/check-username', {'username': username.trim()}),
    );
    return _parseResponse(res, (body) => AvailabilityResult.fromJson(body as Map<String, dynamic>));
  }

  Future<AvailabilityResult> checkEmailAvailability(String email) async {
    final res = await _client.get(
      _uri('/auth/check-email', {'email': email.trim()}),
    );
    return _parseResponse(res, (body) => AvailabilityResult.fromJson(body as Map<String, dynamic>));
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final res = await _client.post(
        _uri('/auth/login'),
        headers: _headers(json: true),
        body: jsonEncode({'username': username, 'password': password}),
      );
      return _parseResponse(res, (body) => body as Map<String, dynamic>);
    } on SocketException {
      throw ApiException(
        'Cannot reach the API at $apiBaseUrl. '
        'Is Docker running? On a physical device, use your computer\'s LAN IP '
        'via --dart-define=API_BASE_URL=http://YOUR_IP:8080/api',
      );
    }
  }

  Future<Map<String, dynamic>> refresh({required String refreshToken}) async {
    final res = await _client.post(
      _uri('/auth/refresh'),
      headers: _headers(json: true),
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    return _parseResponse(res, (body) => body as Map<String, dynamic>);
  }

  Future<void> logout({required String refreshToken}) async {
    final res = await _client.post(
      _uri('/auth/logout'),
      headers: _headers(json: true),
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    if (res.statusCode >= 400 && res.statusCode != 401) {
      throw ApiException('Logout failed (${res.statusCode})');
    }
  }

  Future<Map<String, dynamic>> fetchAppConfig() async {
    final res = await _client.get(_uri('/config'));
    return _parseResponse(res, (body) => body as Map<String, dynamic>);
  }

  Future<UserProfile> getMe() async {
    return _authorized(
      '/auth/me',
      (token) => _client.get(_uri('/auth/me'), headers: _headers(token: token)),
      (body) => UserProfile.fromJson(body as Map<String, dynamic>),
    );
  }

  Future<PageResponse<SteakPost>> fetchPosts({
    int page = 0,
    int size = feedPageSize,
  }) async {
    return _authorized(
      '/posts',
      (token) => _client.get(
        _uri('/posts', {'page': '$page', 'size': '$size'}),
        headers: _headers(token: token),
      ),
      (body) => PageResponse.fromJson(body as Map<String, dynamic>, SteakPost.fromJson),
    );
  }

  Future<PageResponse<SteakPost>> fetchFollowingPosts({
    int page = 0,
    int size = feedPageSize,
  }) async {
    return _authorized(
      '/posts/following',
      (token) => _client.get(
        _uri('/posts/following', {'page': '$page', 'size': '$size'}),
        headers: _headers(token: token),
      ),
      (body) => PageResponse.fromJson(body as Map<String, dynamic>, SteakPost.fromJson),
    );
  }

  Future<SteakPost> fetchPost(String postId) async {
    return _authorized(
      '/posts',
      (token) => _client.get(_uri('/posts/$postId'), headers: _headers(token: token)),
      (body) => SteakPost.fromJson(body as Map<String, dynamic>),
    );
  }

  Future<PageResponse<PostComment>> fetchPostComments(
    String postId, {
    int page = 0,
    int size = feedPageSize,
  }) async {
    return _authorized(
      '/posts',
      (token) => _client.get(
        _uri('/posts/$postId/comments', {'page': '$page', 'size': '$size'}),
        headers: _headers(token: token),
      ),
      (body) => PageResponse.fromJson(body as Map<String, dynamic>, PostComment.fromJson),
    );
  }

  Future<PostComment> addPostComment(String postId, String bodyText) async {
    return _authorized(
      '/posts',
      (token) => _client.post(
        _uri('/posts/$postId/comments'),
        headers: _headers(token: token, json: true),
        body: jsonEncode({'body': bodyText}),
      ),
      (body) => PostComment.fromJson(body as Map<String, dynamic>),
    );
  }

  Future<PostComment> updatePostComment(
    String postId,
    String commentId,
    String bodyText,
  ) async {
    return _authorized(
      '/posts',
      (token) => _client.patch(
        _uri('/posts/$postId/comments/$commentId'),
        headers: _headers(token: token, json: true),
        body: jsonEncode({'body': bodyText}),
      ),
      (body) => PostComment.fromJson(body as Map<String, dynamic>),
    );
  }

  Future<void> deletePostComment(String postId, String commentId) async {
    await _authorized(
      '/posts',
      (token) => _client.delete(
        _uri('/posts/$postId/comments/$commentId'),
        headers: _headers(token: token),
      ),
      (_) => null,
    );
  }

  Future<void> deletePost(String postId) async {
    await _authorized(
      '/posts',
      (token) => _client.delete(_uri('/posts/$postId'), headers: _headers(token: token)),
      (_) => null,
    );
  }

  Future<PageResponse<SteakPost>> fetchBookmarkedPosts({
    int page = 0,
    int size = feedPageSize,
  }) async {
    return _authorized(
      '/bookmarks',
      (token) => _client.get(
        _uri('/bookmarks', {'page': '$page', 'size': '$size'}),
        headers: _headers(token: token),
      ),
      (body) => PageResponse.fromJson(body as Map<String, dynamic>, SteakPost.fromJson),
    );
  }

  Future<void> bookmarkPost(String postId) async {
    await _authorized(
      '/posts',
      (token) => _client.post(
        _uri('/posts/$postId/bookmark'),
        headers: _headers(token: token),
      ),
      (_) => null,
    );
  }

  Future<void> unbookmarkPost(String postId) async {
    await _authorized(
      '/posts',
      (token) => _client.delete(
        _uri('/posts/$postId/bookmark'),
        headers: _headers(token: token),
      ),
      (_) => null,
    );
  }

  Future<List<SteakPost>> fetchMyModerationNotices() async {
    return _authorized(
      '/posts/mine/moderation-notices',
      (token) => _client.get(
        _uri('/posts/mine/moderation-notices'),
        headers: _headers(token: token),
      ),
      (body) {
        final list = body as List<dynamic>? ?? [];
        return list
            .whereType<Map<String, dynamic>>()
            .map(SteakPost.fromJson)
            .toList(growable: false);
      },
    );
  }

  Future<NotificationPreferences> fetchNotificationPreferences() async {
    return _authorized(
      '/users/me/notification-preferences',
      (token) => _client.get(
        _uri('/users/me/notification-preferences'),
        headers: _headers(token: token),
      ),
      (body) => NotificationPreferences.fromJson(body as Map<String, dynamic>),
    );
  }

  Future<NotificationPreferences> updateNotificationPreferences(
    Map<String, bool> patch,
  ) async {
    return _authorized(
      '/users/me/notification-preferences',
      (token) => _client.patch(
        _uri('/users/me/notification-preferences'),
        headers: _headers(token: token, json: true),
        body: jsonEncode(patch),
      ),
      (body) => NotificationPreferences.fromJson(body as Map<String, dynamic>),
    );
  }

  Future<void> requestAccountDeletion() async {
    await _authorized(
      '/auth/request-account-deletion',
      (token) => _client.post(
        _uri('/auth/request-account-deletion'),
        headers: _headers(token: token),
      ),
      (_) => null,
    );
  }

  Future<UserPublicProfile> fetchUserProfile(String userId) async {
    return _authorized(
      '/users',
      (token) => _client.get(_uri('/users/$userId'), headers: _headers(token: token)),
      (body) => UserPublicProfile.fromJson(body as Map<String, dynamic>),
    );
  }

  Future<List<UserPublicProfile>> searchUsers(String query) async {
    return _authorized(
      '/users/search',
      (token) => _client.get(
        _uri('/users/search', {'q': query}),
        headers: _headers(token: token),
      ),
      (body) {
        final list = body as List<dynamic>? ?? [];
        return list
            .whereType<Map<String, dynamic>>()
            .map(UserPublicProfile.fromJson)
            .toList(growable: false);
      },
    );
  }

  Future<List<SubscriptionSummary>> listSubscriptions() async {
    return _authorized(
      '/subscriptions',
      (token) => _client.get(_uri('/subscriptions'), headers: _headers(token: token)),
      (body) {
        final list = body as List<dynamic>? ?? [];
        return list
            .whereType<Map<String, dynamic>>()
            .map(SubscriptionSummary.fromJson)
            .toList(growable: false);
      },
    );
  }

  Future<void> subscribeToUser(String userId) async {
    await _authorized(
      '/subscriptions',
      (token) => _client.post(
        _uri('/subscriptions/$userId'),
        headers: _headers(token: token),
      ),
      (_) => null,
    );
  }

  Future<void> unsubscribeFromUser(String userId) async {
    await _authorized(
      '/subscriptions',
      (token) => _client.delete(
        _uri('/subscriptions/$userId'),
        headers: _headers(token: token),
      ),
      (_) => null,
    );
  }

  Future<PageResponse<SteakPost>> fetchUserPosts(
    String userId, {
    int page = 0,
    int size = feedPageSize,
  }) async {
    return _authorized(
      '/users',
      (token) => _client.get(
        _uri('/users/$userId/posts', {'page': '$page', 'size': '$size'}),
        headers: _headers(token: token),
      ),
      (body) => PageResponse.fromJson(body as Map<String, dynamic>, SteakPost.fromJson),
    );
  }

  Future<ReviewTagCatalog> fetchReviewTags() async {
    return _authorized(
      '/posts/review-tags',
      (token) => _client.get(_uri('/posts/review-tags'), headers: _headers(token: token)),
      (body) => ReviewTagCatalog.fromJson(body as Map<String, dynamic>),
    );
  }

  Future<SteakPost> createPost({
    required String title,
    required String comment,
    required int rating,
    required List<XFile> images,
    String? restaurantName,
    String? restaurantLocation,
    String visibility = 'PUBLIC',
    List<String> tagIds = const [],
  }) async {
    if (images.isEmpty) {
      throw ApiException('At least one photo is required.');
    }

    return _authorizedMultipart(
      '/posts',
      (token) async {
        final request = http.MultipartRequest('POST', _uri('/posts'));
        request.headers.addAll(_headers(token: token));
        request.fields['title'] = title;
        request.fields['comment'] = comment;
        request.fields['rating'] = '$rating';
        request.fields['visibility'] = visibility;
        if (restaurantName != null && restaurantName.isNotEmpty) {
          request.fields['restaurantName'] = restaurantName;
        }
        if (restaurantLocation != null && restaurantLocation.isNotEmpty) {
          request.fields['restaurantLocation'] = restaurantLocation;
        }
        for (final tagId in tagIds) {
          request.files.add(http.MultipartFile.fromString('tagIds', tagId));
        }
        for (final image in images) {
          request.files.add(await buildPostImagePart(image));
        }
        return _client.send(request);
      },
      (body) => SteakPost.fromJson(body as Map<String, dynamic>),
    );
  }

  Future<SteakPost> updatePost(
    String postId, {
    required String title,
    required String comment,
    required int rating,
    required List<String> keepImageUrls,
    required List<XFile> newImages,
    String? restaurantName,
    String? restaurantLocation,
    String visibility = 'PUBLIC',
    List<String> tagIds = const [],
  }) async {
    if (keepImageUrls.isEmpty && newImages.isEmpty) {
      throw ApiException('At least one photo is required.');
    }

    return _authorizedMultipart(
      '/posts',
      (token) async {
        final request = http.MultipartRequest('PATCH', _uri('/posts/$postId'));
        request.headers.addAll(_headers(token: token));
        request.fields['title'] = title;
        request.fields['comment'] = comment;
        request.fields['rating'] = '$rating';
        request.fields['visibility'] = visibility;
        if (restaurantName != null && restaurantName.isNotEmpty) {
          request.fields['restaurantName'] = restaurantName;
        }
        if (restaurantLocation != null && restaurantLocation.isNotEmpty) {
          request.fields['restaurantLocation'] = restaurantLocation;
        }
        for (final url in keepImageUrls) {
          request.files.add(http.MultipartFile.fromString('keepImageUrls', url));
        }
        for (final tagId in tagIds) {
          request.files.add(http.MultipartFile.fromString('tagIds', tagId));
        }
        for (final image in newImages) {
          request.files.add(await buildPostImagePart(image));
        }
        return _client.send(request);
      },
      (body) => SteakPost.fromJson(body as Map<String, dynamic>),
    );
  }

  Future<({String token, UserProfile user})> updateProfile({
    String? displayName,
    String? email,
    XFile? avatar,
  }) async {
    if (avatar != null) {
      return _authorizedMultipart(
        '/auth/me',
        (token) async {
          final request = http.MultipartRequest('PATCH', _uri('/auth/me'));
          request.headers.addAll(_headers(token: token));
          if (displayName != null) request.fields['displayName'] = displayName;
          if (email != null) request.fields['email'] = email;
          request.files.add(await buildAvatarPart(avatar));
          return _client.send(request);
        },
        (body) {
          final map = body as Map<String, dynamic>;
          return (
            token: map['token'] as String,
            user: UserProfile.fromJson(map['user'] as Map<String, dynamic>),
          );
        },
      );
    }

    return _authorized(
      '/auth/me',
      (token) => _client.patch(
        _uri('/auth/me'),
        headers: _headers(token: token, json: true),
        body: jsonEncode({
          if (displayName != null) 'displayName': displayName,
          if (email != null) 'email': email,
        }),
      ),
      (body) {
        final map = body as Map<String, dynamic>;
        return (
          token: map['token'] as String,
          user: UserProfile.fromJson(map['user'] as Map<String, dynamic>),
        );
      },
    );
  }
}

class AvailabilityResult {
  const AvailabilityResult({required this.available, required this.message});

  final bool available;
  final String message;

  factory AvailabilityResult.fromJson(Map<String, dynamic> json) {
    return AvailabilityResult(
      available: json['available'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
