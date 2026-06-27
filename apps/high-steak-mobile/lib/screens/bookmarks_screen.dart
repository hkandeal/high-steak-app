import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../controllers/paginated_list_controller.dart';
import '../models/steak_post.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import '../widgets/feed_layout_scope.dart';
import '../widgets/feed_layout_toggle.dart';
import '../widgets/paginated_post_feed.dart';
import '../widgets/post_card.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key, required this.auth, required this.api});

  final AuthController auth;
  final ApiService api;

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late final PaginatedListController<SteakPost> _controller;

  @override
  void initState() {
    super.initState();
    _controller = PaginatedListController<SteakPost>(
      (page) => widget.api.fetchBookmarkedPosts(page: page),
    );
    _controller.reload();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final feedLayout = FeedLayoutScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bookmarks',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: palette.creamMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Steak posts you saved for later.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              FeedLayoutToggle(controller: feedLayout),
            ],
          ),
        ),
        Expanded(
          child: PaginatedPostFeed(
            controller: _controller,
            layout: feedLayout,
            emptyMessage: 'No bookmarks yet. Tap the bookmark icon on a post to save it.',
            emptyIcon: Icons.bookmark_border,
            action: FilledButton(
              onPressed: () => context.go('/feed'),
              child: const Text('Browse feed'),
            ),
            itemBuilder: (context, item, {required bool dense}) => PostCard(
              post: item,
              dense: dense,
              auth: widget.auth,
              api: widget.api,
              showBookmark: true,
              onBookmarkChanged: () {
                _controller.removeItem((post) => post.id == item.id);
              },
            ),
          ),
        ),
      ],
    );
  }
}
