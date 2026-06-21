import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../models/subscription_summary.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import '../widgets/auth_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/user_search_card.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({
    super.key,
    required this.auth,
    required this.api,
  });

  final AuthController auth;
  final ApiService api;

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  List<SubscriptionSummary> _subscriptions = [];
  bool _loading = true;
  String? _error;
  String? _pendingUserId;

  bool get _canUnfollow => widget.auth.hasScope('subscriptions:write');

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
      final list = await widget.api.listSubscriptions();
      if (!mounted) return;
      setState(() {
        _subscriptions = list;
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

  Future<void> _unfollow(String userId) async {
    if (!_canUnfollow || _pendingUserId != null) return;

    setState(() {
      _pendingUserId = userId;
      _error = null;
    });

    try {
      await widget.api.unsubscribeFromUser(userId);
      if (!mounted) return;
      setState(() {
        _subscriptions =
            _subscriptions.where((item) => item.user.id != userId).toList();
        _pendingUserId = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _pendingUserId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const LoadingState(message: 'Loading following…');
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Text('Following', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Chefs and steak lovers you follow.',
            style: theme.textTheme.bodyMedium,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            AuthErrorBanner(message: _error!),
          ],
          if (_subscriptions.isEmpty && _error == null) ...[
            const SizedBox(height: 24),
            EmptyState(
              message: "You're not following anyone yet.",
              icon: Icons.group_outlined,
              action: widget.auth.hasScope('users:discover')
                  ? FilledButton(
                      onPressed: () => context.go('/discover'),
                      child: const Text('Find steak lovers'),
                    )
                  : null,
            ),
          ],
          if (_subscriptions.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._subscriptions.map(
              (item) => UserSearchCard(
                user: item.user,
                pending: _pendingUserId == item.user.id,
                subtitle: followingSinceSubtitle(item.user, item.subscribedAt),
                onFollowToggle:
                    _canUnfollow ? () => _unfollow(item.user.id) : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
