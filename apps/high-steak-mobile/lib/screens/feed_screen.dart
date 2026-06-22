import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../controllers/paginated_list_controller.dart';
import '../models/steak_post.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import '../widgets/paginated_list_view.dart';
import '../widgets/pill_tab_bar.dart';
import '../widgets/post_card.dart';

enum FeedTab { everyone, following }

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, required this.auth, required this.api});

  final AuthController auth;
  final ApiService api;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  FeedTab _tab = FeedTab.everyone;
  PaginatedListController<SteakPost>? _controller;
  String? _pendingFollowAuthorId;

  bool get _showFollowingTab => widget.auth.hasScope('subscriptions:read');
  bool get _showAuthorFollow =>
      _tab == FeedTab.everyone && widget.auth.hasScope('subscriptions:write');

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _initController() {
    _controller?.dispose();
    _controller = PaginatedListController<SteakPost>((page) {
      if (_tab == FeedTab.following) {
        return widget.api.fetchFollowingPosts(page: page);
      }
      return widget.api.fetchPosts(page: page);
    });
    _controller!.reload();
  }

  void _switchTab(FeedTab tab) {
    if (_tab == tab) return;
    setState(() {
      _tab = tab;
      _pendingFollowAuthorId = null;
    });
    _initController();
  }

  Future<void> _toggleAuthorFollow(SteakPost post) async {
    final author = post.author;
    if (author.subscribed == null || _pendingFollowAuthorId != null) return;

    setState(() => _pendingFollowAuthorId = author.id);
    try {
      if (author.subscribed!) {
        await widget.api.unsubscribeFromUser(author.id);
      } else {
        await widget.api.subscribeToUser(author.id);
      }
      if (!mounted) return;
      final subscribed = !author.subscribed!;
      _controller!.updateWhere(
        (item) => item.author.id == author.id,
        (item) => item.copyWith(author: item.author.copyWith(subscribed: subscribed)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _pendingFollowAuthorId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    final theme = Theme.of(context);
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Steak feed',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: palette.creamMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _tab == FeedTab.following
                    ? 'Posts from people you follow'
                    : 'Fresh cuts from the community',
                style: theme.textTheme.bodyMedium,
              ),
              if (_showFollowingTab) ...[
                const SizedBox(height: 14),
                PillTabBar<FeedTab>(
                  tabs: const [
                    PillTab(value: FeedTab.everyone, label: 'Everyone'),
                    PillTab(value: FeedTab.following, label: 'Following'),
                  ],
                  selected: _tab,
                  onSelected: _switchTab,
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: PaginatedListView(
            controller: controller,
            emptyMessage: _tab == FeedTab.following
                ? "You're not following anyone yet."
                : 'No steaks yet. Be the first to fire up the grill!',
            emptyIcon: _tab == FeedTab.following
                ? Icons.group_outlined
                : Icons.local_fire_department_outlined,
            action: _tab == FeedTab.following &&
                    widget.auth.hasScope('users:discover')
                ? FilledButton(
                    onPressed: () => context.go('/discover'),
                    child: const Text('Find steak lovers'),
                  )
                : null,
            itemBuilder: (context, item) => PostCard(
              post: item,
              auth: widget.auth,
              api: widget.api,
              showBookmark: widget.auth.hasScope('bookmarks:write'),
              showAuthorFollow: _showAuthorFollow,
              followBusy: _pendingFollowAuthorId == item.author.id,
              onToggleAuthorFollow: _showAuthorFollow && item.author.subscribed != null
                  ? () => _toggleAuthorFollow(item)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
