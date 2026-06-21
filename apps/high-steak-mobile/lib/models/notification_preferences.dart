class NotificationPreferences {
  const NotificationPreferences({
    required this.emailEnabled,
    required this.welcomeEmail,
    required this.commentEmail,
    required this.followerEmail,
    required this.moderationEmail,
  });

  final bool emailEnabled;
  final bool welcomeEmail;
  final bool commentEmail;
  final bool followerEmail;
  final bool moderationEmail;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      emailEnabled: json['emailEnabled'] as bool? ?? true,
      welcomeEmail: json['welcomeEmail'] as bool? ?? true,
      commentEmail: json['commentEmail'] as bool? ?? true,
      followerEmail: json['followerEmail'] as bool? ?? true,
      moderationEmail: json['moderationEmail'] as bool? ?? true,
    );
  }

  NotificationPreferences copyWith({
    bool? emailEnabled,
    bool? welcomeEmail,
    bool? commentEmail,
    bool? followerEmail,
    bool? moderationEmail,
  }) {
    return NotificationPreferences(
      emailEnabled: emailEnabled ?? this.emailEnabled,
      welcomeEmail: welcomeEmail ?? this.welcomeEmail,
      commentEmail: commentEmail ?? this.commentEmail,
      followerEmail: followerEmail ?? this.followerEmail,
      moderationEmail: moderationEmail ?? this.moderationEmail,
    );
  }
}
