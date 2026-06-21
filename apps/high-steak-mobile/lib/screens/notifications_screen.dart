import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../models/steak_post.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import '../widgets/empty_state.dart';

enum _NoticeKind { hidden, restored }

class _ModerationNotice {
  const _ModerationNotice({required this.kind, required this.post});

  final _NoticeKind kind;
  final SteakPost post;
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.auth, required this.api});

  final AuthController auth;
  final ApiService api;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<_ModerationNotice> _notices = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await widget.api.fetchMyModerationNotices(widget.auth.token!);
      final notices = <_ModerationNotice>[
        ...posts
            .where((post) => post.hidden)
            .map((post) => _ModerationNotice(kind: _NoticeKind.hidden, post: post)),
        ...posts
            .where((post) => !post.hidden && post.moderationRestoredAt != null)
            .map((post) => _ModerationNotice(kind: _NoticeKind.restored, post: post)),
      ];
      notices.sort((a, b) {
        final aTime = a.kind == _NoticeKind.restored && a.post.moderationRestoredAt != null
            ? DateTime.tryParse(a.post.moderationRestoredAt!) ?? a.post.createdAt
            : a.post.createdAt;
        final bTime = b.kind == _NoticeKind.restored && b.post.moderationRestoredAt != null
            ? DateTime.tryParse(b.post.moderationRestoredAt!) ?? b.post.createdAt
            : b.post.createdAt;
        return bTime.compareTo(aTime);
      });
      if (!mounted) return;
      setState(() {
        _notices = notices;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    if (_loading) {
      return const LoadingState(message: 'Loading notifications…');
    }

    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _load);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(
          'Notifications',
          style: theme.textTheme.titleLarge?.copyWith(color: palette.creamMuted),
        ),
        const SizedBox(height: 4),
        Text(
          'Updates when moderators hide or restore your posts.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        if (_notices.isEmpty)
          const EmptyState(
            message: 'No moderation notices right now.',
            icon: Icons.notifications_none_outlined,
          )
        else
          ..._notices.map((notice) => _NoticeCard(notice: notice)),
      ],
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice});

  final _ModerationNotice notice;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final post = notice.post;
    final isRestored = notice.kind == _NoticeKind.restored;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/posts/${post.id}'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isRestored ? palette.gold.withValues(alpha: 0.4) : palette.cardBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isRestored ? Icons.check_circle_outline : Icons.visibility_off_outlined,
                      color: isRestored ? palette.gold : palette.creamMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isRestored ? 'Post restored to feeds' : 'Post removed from feeds',
                        style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  post.title,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (!isRestored && post.moderationReason != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    post.moderationReason!,
                    style: theme.textTheme.bodyMedium?.copyWith(color: palette.creamMuted),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
