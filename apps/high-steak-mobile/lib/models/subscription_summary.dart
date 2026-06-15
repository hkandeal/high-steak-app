import 'user.dart';

class SubscriptionSummary {
  const SubscriptionSummary({
    required this.user,
    required this.subscribedAt,
  });

  final UserPublicProfile user;
  final DateTime subscribedAt;

  factory SubscriptionSummary.fromJson(Map<String, dynamic> json) {
    return SubscriptionSummary(
      user: UserPublicProfile.fromJson(
        json['user'] as Map<String, dynamic>? ?? {},
      ),
      subscribedAt: DateTime.parse(json['subscribedAt'] as String),
    );
  }
}
