import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/user.dart';
import '../theme/app_palette.dart';
import '../utils/date_format.dart';
import 'user_avatar.dart';

class UserSearchCard extends StatelessWidget {
  const UserSearchCard({
    super.key,
    required this.user,
    required this.onFollowToggle,
    this.pending = false,
    this.subtitle,
  });

  final UserPublicProfile user;
  final VoidCallback? onFollowToggle;
  final bool pending;
  final String? subtitle;

  bool get _showFollowAction => onFollowToggle != null;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Row(
        children: [
          UserAvatar(
            displayName: user.displayName,
            avatarUrl: user.avatarUrl,
            radius: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => context.push('/users/${user.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
                  ),
                  Text(
                    '@${user.username}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: palette.gold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle ??
                        '${user.postCount} ${user.postCount == 1 ? 'post' : 'posts'}',
                    style: theme.textTheme.bodySmall?.copyWith(color: palette.creamMuted),
                  ),
                ],
              ),
            ),
          ),
          if (_showFollowAction) ...[
            const SizedBox(width: 8),
            user.subscribed
                ? OutlinedButton(
                    onPressed: pending ? null : onFollowToggle,
                    child: Text(pending ? '…' : 'Unfollow'),
                  )
                : FilledButton(
                    onPressed: pending ? null : onFollowToggle,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(88, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: Text(pending ? '…' : 'Follow'),
                  ),
          ],
        ],
      ),
    );
  }
}

String followingSinceSubtitle(UserPublicProfile user, DateTime subscribedAt) {
  return '${user.postCount} ${user.postCount == 1 ? 'post' : 'posts'} · followed ${formatPostDate(subscribedAt)}';
}
