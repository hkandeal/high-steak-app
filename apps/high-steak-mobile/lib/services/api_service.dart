import 'dart:convert';
import 'dart:io';

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

typedef UnauthorizedHandler = void Function();

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  UnauthorizedHandler? onUnauthorized;

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

  Future<T> _handle<T>(http.Response res, T Function(dynamic body) parse) async {
    dynamic body;
    if (res.body.isNotEmpty) {
      body = jsonDecode(res.body);
    }
    if (res.statusCode == 401) {
      onUnauthorized?.call();
    }
    if (res.statusCode >= 400) {
      final message = body is Map ? body['message']?.toString() : null;
      throw ApiException(message ?? 'Request failed (${res.statusCode})');
    }
    return parse(body);
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
    return _handle(res, (body) => body as Map<String, dynamic>);
  }

  Future<AvailabilityResult> checkUsernameAvailability(String username) async {
    final res = await _client.get(
      _uri('/auth/check-username', {'username': username.trim()}),
    );
    return _handle(res, (body) => AvailabilityResult.fromJson(body as Map<String, dynamic>));
  }

  Future<AvailabilityResult> checkEmailAvailability(String email) async {
    final res = await _client.get(
      _uri('/auth/check-email', {'email': email.trim()}),
    );
    return _handle(res, (body) => AvailabilityResult.fromJson(body as Map<String, dynamic>));
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
      return _handle(res, (body) => body as Map<String, dynamic>);
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
    return _handle(res, (body) => body as Map<String, dynamic>);
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
    return _handle(res, (body) => body as Map<String, dynamic>);
  }

  Future<UserProfile> getMe(String token) async {
    final res = await _client.get(
      _uri('/auth/me'),
      headers: _headers(token: token),
    );
    return _handle(res, (body) => UserProfile.fromJson(body as Map<String, dynamic>));
  }

  Future<PageResponse<SteakPost>> fetchPosts(
    String token, {
    int page = 0,
    int size = feedPageSize,
  }) async {
    final res = await _client.get(
      _uri('/posts', {'page': '$page', 'size': '$size'}),
      headers: _headers(token: token),
    );
    return _handle(
      res,
      (body) => PageResponse.fromJson(body as Map<String, dynamic>, SteakPost.fromJson),
    );
  }

  Future<PageResponse<SteakPost>> fetchFollowingPosts(
    String token, {
    int page = 0,
    int size = feedPageSize,
  }) async {
    final res = await _client.get(
      _uri('/posts/following', {'page': '$page', 'size': '$size'}),
      headers: _headers(token: token),
    );
    return _handle(
      res,
      (body) => PageResponse.fromJson(body as Map<String, dynamic>, SteakPost.fromJson),
    );
  }

  Future<SteakPost> fetchPost(String token, String postId) async {
    final res = await _client.get(
      _uri('/posts/$postId'),
      headers: _headers(token: token),
    );
    return _handle(res, (body) => SteakPost.fromJson(body as Map<String, dynamic>));
  }

  Future<PageResponse<PostComment>> fetchPostComments(
    String token,
    String postId, {
    int page = 0,
    int size = feedPageSize,
  }) async {
    final res = await _client.get(
      _uri('/posts/$postId/comments', {'page': '$page', 'size': '$size'}),
      headers: _headers(token: token),
    );
    return _handle(
      res,
      (body) => PageResponse.fromJson(body as Map<String, dynamic>, PostComment.fromJson),
    );
  }

  Future<PostComment> addPostComment(
    String token,
    String postId,
    String bodyText,
  ) async {
    final res = await _client.post(
      _uri('/posts/$postId/comments'),
      headers: _headers(token: token, json: true),
      body: jsonEncode({'body': bodyText}),
    );
    return _handle(res, (body) => PostComment.fromJson(body as Map<String, dynamic>));
  }

  Future<PostComment> updatePostComment(
    String token,
    String postId,
    String commentId,
    String bodyText,
  ) async {
    final res = await _client.patch(
      _uri('/posts/$postId/comments/$commentId'),
      headers: _headers(token: token, json: true),
      body: jsonEncode({'body': bodyText}),
    );
    return _handle(res, (body) => PostComment.fromJson(body as Map<String, dynamic>));
  }

  Future<void> deletePostComment(
    String token,
    String postId,
    String commentId,
  ) async {
    final res = await _client.delete(
      _uri('/posts/$postId/comments/$commentId'),
      headers: _headers(token: token),
    );
    if (res.statusCode == 401) {
      onUnauthorized?.call();
    }
    if (res.statusCode >= 400) {
      dynamic body;
      if (res.body.isNotEmpty) {
        body = jsonDecode(res.body);
      }
      final message = body is Map ? body['message']?.toString() : null;
      throw ApiException(message ?? 'Request failed (${res.statusCode})');
    }
  }

  Future<void> deletePost(String token, String postId) async {
    final res = await _client.delete(
      _uri('/posts/$postId'),
      headers: _headers(token: token),
    );
    if (res.statusCode == 401) {
      onUnauthorized?.call();
    }
    if (res.statusCode >= 400) {
      dynamic body;
      if (res.body.isNotEmpty) {
        body = jsonDecode(res.body);
      }
      final message = body is Map ? body['message']?.toString() : null;
      throw ApiException(message ?? 'Request failed (${res.statusCode})');
    }
  }

  Future<PageResponse<SteakPost>> fetchBookmarkedPosts(
    String token, {
    int page = 0,
    int size = feedPageSize,
  }) async {
    final res = await _client.get(
      _uri('/bookmarks', {'page': '$page', 'size': '$size'}),
      headers: _headers(token: token),
    );
    return _handle(
      res,
      (body) => PageResponse.fromJson(body as Map<String, dynamic>, SteakPost.fromJson),
    );
  }

  Future<void> bookmarkPost(String token, String postId) async {
    final res = await _client.post(
      _uri('/posts/$postId/bookmark'),
      headers: _headers(token: token),
    );
    await _handle(res, (_) => null);
  }

  Future<void> unbookmarkPost(String token, String postId) async {
    final res = await _client.delete(
      _uri('/posts/$postId/bookmark'),
      headers: _headers(token: token),
    );
    if (res.statusCode == 401) {
      onUnauthorized?.call();
    }
    if (res.statusCode >= 400) {
      dynamic body;
      if (res.body.isNotEmpty) {
        body = jsonDecode(res.body);
      }
      final message = body is Map ? body['message']?.toString() : null;
      throw ApiException(message ?? 'Request failed (${res.statusCode})');
    }
  }

  Future<List<SteakPost>> fetchMyModerationNotices(String token) async {
    final res = await _client.get(
      _uri('/posts/mine/moderation-notices'),
      headers: _headers(token: token),
    );
    return _handle(res, (body) {
      final list = body as List<dynamic>? ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(SteakPost.fromJson)
          .toList(growable: false);
    });
  }

  Future<NotificationPreferences> fetchNotificationPreferences(String token) async {
    final res = await _client.get(
      _uri('/users/me/notification-preferences'),
      headers: _headers(token: token),
    );
    return _handle(
      res,
      (body) => NotificationPreferences.fromJson(body as Map<String, dynamic>),
    );
  }

  Future<NotificationPreferences> updateNotificationPreferences(
    String token,
    Map<String, bool> patch,
  ) async {
    final res = await _client.patch(
      _uri('/users/me/notification-preferences'),
      headers: _headers(token: token, json: true),
      body: jsonEncode(patch),
    );
    return _handle(
      res,
      (body) => NotificationPreferences.fromJson(body as Map<String, dynamic>),
    );
  }

  Future<void> requestAccountDeletion(String token) async {
    final res = await _client.post(
      _uri('/auth/request-account-deletion'),
      headers: _headers(token: token),
    );
    if (res.statusCode == 401) {
      onUnauthorized?.call();
    }
    if (res.statusCode >= 400) {
      dynamic body;
      if (res.body.isNotEmpty) {
        body = jsonDecode(res.body);
      }
      final message = body is Map ? body['message']?.toString() : null;
      throw ApiException(message ?? 'Request failed (${res.statusCode})');
    }
  }

  Future<UserPublicProfile> fetchUserProfile(String token, String userId) async {
    final res = await _client.get(
      _uri('/users/$userId'),
      headers: _headers(token: token),
    );
    return _handle(
      res,
      (body) => UserPublicProfile.fromJson(body as Map<String, dynamic>),
    );
  }

  Future<List<UserPublicProfile>> searchUsers(String token, String query) async {
    final res = await _client.get(
      _uri('/users/search', {'q': query}),
      headers: _headers(token: token),
    );
    return _handle(res, (body) {
      final list = body as List<dynamic>? ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(UserPublicProfile.fromJson)
          .toList(growable: false);
    });
  }

  Future<List<SubscriptionSummary>> listSubscriptions(String token) async {
    final res = await _client.get(
      _uri('/subscriptions'),
      headers: _headers(token: token),
    );
    return _handle(res, (body) {
      final list = body as List<dynamic>? ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(SubscriptionSummary.fromJson)
          .toList(growable: false);
    });
  }

  Future<void> subscribeToUser(String token, String userId) async {
    final res = await _client.post(
      _uri('/subscriptions/$userId'),
      headers: _headers(token: token),
    );
    await _handle(res, (_) => null);
  }

  Future<void> unsubscribeFromUser(String token, String userId) async {
    final res = await _client.delete(
      _uri('/subscriptions/$userId'),
      headers: _headers(token: token),
    );
    if (res.statusCode == 401) {
      onUnauthorized?.call();
    }
    if (res.statusCode >= 400) {
      dynamic body;
      if (res.body.isNotEmpty) {
        body = jsonDecode(res.body);
      }
      final message = body is Map ? body['message']?.toString() : null;
      throw ApiException(message ?? 'Request failed (${res.statusCode})');
    }
  }

  Future<PageResponse<SteakPost>> fetchUserPosts(
    String token,
    String userId, {
    int page = 0,
    int size = feedPageSize,
  }) async {
    final res = await _client.get(
      _uri('/users/$userId/posts', {'page': '$page', 'size': '$size'}),
      headers: _headers(token: token),
    );
    return _handle(
      res,
      (body) => PageResponse.fromJson(body as Map<String, dynamic>, SteakPost.fromJson),
    );
  }

  Future<ReviewTagCatalog> fetchReviewTags(String token) async {
    final res = await _client.get(
      _uri('/posts/review-tags'),
      headers: _headers(token: token),
    );
    return _handle(
      res,
      (body) => ReviewTagCatalog.fromJson(body as Map<String, dynamic>),
    );
  }

  Future<SteakPost> createPost(
    String token, {
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

    final streamed = await _client.send(request);
    final res = await http.Response.fromStream(streamed);
    return _handle(res, (body) => SteakPost.fromJson(body as Map<String, dynamic>));
  }

  Future<SteakPost> updatePost(
    String token,
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

    final streamed = await _client.send(request);
    final res = await http.Response.fromStream(streamed);
    return _handle(res, (body) => SteakPost.fromJson(body as Map<String, dynamic>));
  }

  Future<({String token, UserProfile user})> updateProfile(
    String token, {
    String? displayName,
    String? email,
    XFile? avatar,
  }) async {
    if (avatar != null) {
      final request = http.MultipartRequest('PATCH', _uri('/auth/me'));
      request.headers.addAll(_headers(token: token));
      if (displayName != null) request.fields['displayName'] = displayName;
      if (email != null) request.fields['email'] = email;
      request.files.add(await buildAvatarPart(avatar));

      final streamed = await _client.send(request);
      final res = await http.Response.fromStream(streamed);
      return _handle(res, (body) {
        final map = body as Map<String, dynamic>;
        return (
          token: map['token'] as String,
          user: UserProfile.fromJson(map['user'] as Map<String, dynamic>),
        );
      });
    }

    final res = await _client.patch(
      _uri('/auth/me'),
      headers: _headers(token: token, json: true),
      body: jsonEncode({
        if (displayName != null) 'displayName': displayName,
        if (email != null) 'email': email,
      }),
    );
    return _handle(res, (body) {
      final map = body as Map<String, dynamic>;
      return (
        token: map['token'] as String,
        user: UserProfile.fromJson(map['user'] as Map<String, dynamic>),
      );
    });
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
