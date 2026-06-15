class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    required this.avatarUrl,
  });

  final String id;
  final String username;
  final String email;
  final String displayName;
  final String? avatarUrl;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class UserSummary extends UserProfile {
  const UserSummary({
    required super.id,
    required super.username,
    required super.email,
    required super.displayName,
    required super.avatarUrl,
    required this.role,
    required this.scopes,
  });

  final String role;
  final List<String> scopes;

  bool hasScope(String scope) => scopes.contains(scope);

  bool hasRole(String roleName) => role == roleName;

  UserSummary copyWithProfile(UserProfile profile) {
    return UserSummary(
      id: profile.id,
      username: profile.username,
      email: profile.email,
      displayName: profile.displayName,
      avatarUrl: profile.avatarUrl,
      role: role,
      scopes: scopes,
    );
  }
}

class UserPublicProfile {
  const UserPublicProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.postCount,
    required this.subscribed,
    this.blocked,
    this.role,
  });

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final int postCount;
  final bool subscribed;
  final bool? blocked;
  final String? role;

  factory UserPublicProfile.fromJson(Map<String, dynamic> json) {
    return UserPublicProfile(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      postCount: json['postCount'] as int? ?? 0,
      subscribed: json['subscribed'] as bool? ?? false,
      blocked: json['blocked'] as bool?,
      role: json['role'] as String?,
    );
  }

  UserPublicProfile copyWith({
    bool? subscribed,
    String? displayName,
    String? avatarUrl,
  }) {
    return UserPublicProfile(
      id: id,
      username: username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      postCount: postCount,
      subscribed: subscribed ?? this.subscribed,
      blocked: blocked,
      role: role,
    );
  }
}
