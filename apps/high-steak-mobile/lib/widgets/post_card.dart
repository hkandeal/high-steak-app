import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../models/steak_post.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import '../utils/api_image_url.dart';
import '../utils/date_format.dart';
import 'image_lightbox.dart';
import 'post_venue.dart';
import 'author_follow_button.dart';
import 'star_rating.dart';
import 'user_avatar.dart';

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    this.auth,
    this.api,
    this.dense = false,
    this.showAuthorHeader = true,
    this.showBookmark = false,
    this.showOwnerActions = false,
    this.showAuthorFollow = false,
    this.followBusy = false,
    this.onToggleAuthorFollow,
    this.onBookmarkChanged,
    this.onDeleted,
  });

  final SteakPost post;
  final AuthController? auth;
  final ApiService? api;
  /// Compact tile for multi-column feed grids.
  final bool dense;
  /// Hide author row (e.g. on profile grids).
  final bool showAuthorHeader;
  final bool showBookmark;
  final bool showOwnerActions;
  final bool showAuthorFollow;
  final bool followBusy;
  final VoidCallback? onToggleAuthorFollow;
  final VoidCallback? onBookmarkChanged;
  final VoidCallback? onDeleted;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _bookmarked;
  bool _bookmarkBusy = false;
  bool _deleteBusy = false;

  @override
  void initState() {
    super.initState();
    _bookmarked = widget.post.bookmarked;
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.bookmarked != widget.post.bookmarked) {
      _bookmarked = widget.post.bookmarked;
    }
  }

  bool get _canBookmark =>
      widget.showBookmark &&
      widget.auth != null &&
      widget.api != null &&
      widget.auth!.hasScope('bookmarks:write');

  bool get _canDelete =>
      widget.showOwnerActions &&
      widget.auth != null &&
      widget.api != null &&
      widget.auth!.hasScope('posts:write') &&
      widget.auth!.user?.id == widget.post.author.id;

  Future<void> _toggleBookmark() async {
    if (!_canBookmark || _bookmarkBusy) return;
    final api = widget.api!;
    setState(() => _bookmarkBusy = true);
    try {
      if (_bookmarked) {
        await api.unbookmarkPost(widget.post.id);
      } else {
        await api.bookmarkPost(widget.post.id);
      }
      if (!mounted) return;
      setState(() => _bookmarked = !_bookmarked);
      widget.onBookmarkChanged?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _bookmarkBusy = false);
    }
  }

  Future<void> _confirmDelete() async {
    if (!_canDelete || _deleteBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This steak review will be removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleteBusy = true);
    try {
      await widget.api!.deletePost(widget.post.id);
      widget.onDeleted?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _deleteBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dense) {
      return _buildDenseCard(context);
    }
    return _buildListCard(context);
  }

  Widget _buildListCard(BuildContext context) {
    final post = widget.post;
    final palette = context.palette;
    final imageUrl = resolveApiImageUrl(post.primaryImageUrl);
    final theme = Theme.of(context);
    final showActions = _canBookmark || _canDelete;
    final showFollow = widget.showAuthorFollow &&
        widget.post.author.subscribed != null &&
        widget.onToggleAuthorFollow != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => ImageLightbox.show(
                context,
                imageUrls: post.imageUrls,
                title: post.title,
              ),
              child: IgnorePointer(
                child: _PostHeroImage(
                  imageUrl: imageUrl,
                  extraCount: post.imageUrls.length - 1,
                  followersOnly: post.visibility == PostVisibility.followersOnly,
                ),
              ),
            ),
          InkWell(
            onTap: () => context.push('/posts/${post.id}'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showAuthorHeader)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserAvatar(
                          displayName: post.author.displayName,
                          avatarUrl: post.author.avatarUrl,
                          avatarThumbnailUrl: post.author.avatarThumbnailUrl,
                          radius: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => context.push('/users/${post.author.id}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.author.displayName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 14,
                                    color: palette.gold,
                                  ),
                                ),
                                Text(
                                  formatPostDate(post.createdAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: palette.creamMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (showFollow) ...[
                          AuthorFollowButton(
                            subscribed: post.author.subscribed!,
                            busy: widget.followBusy,
                            onPressed: widget.onToggleAuthorFollow!,
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (_canDelete)
                          IconButton(
                            tooltip: 'Delete post',
                            onPressed: _deleteBusy ? null : _confirmDelete,
                            icon: _deleteBusy
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: palette.creamMuted,
                                    ),
                                  )
                                : Icon(Icons.delete_outline, color: palette.creamMuted),
                          ),
                      ],
                    ),
                  if (widget.showAuthorHeader) const SizedBox(height: 12),
                  Text(
                    post.title,
                    style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  StarRating(value: post.rating, size: 18),
                  if (post.restaurantName != null) ...[
                    const SizedBox(height: 10),
                    PostVenue(
                      post: post,
                      showLocation: post.place != null,
                      useChip: true,
                    ),
                  ],
                  if (post.comment != null && post.comment!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      post.comment!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        color: palette.cream.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                  if (showActions) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (_canBookmark)
                          IconButton(
                            tooltip: _bookmarked ? 'Remove bookmark' : 'Bookmark',
                            onPressed: _bookmarkBusy ? null : _toggleBookmark,
                            icon: _bookmarkBusy
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: palette.gold,
                                    ),
                                  )
                                : Icon(
                                    _bookmarked
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: _bookmarked ? palette.gold : palette.creamMuted,
                                  ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDenseCard(BuildContext context) {
    final post = widget.post;
    final palette = context.palette;
    final imageUrl = resolveApiImageUrl(post.primaryImageUrl);
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push('/posts/${post.id}'),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight;
            final imageHeight = imageUrl.isNotEmpty && maxHeight.isFinite
                ? maxHeight * 0.54
                : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (imageUrl.isNotEmpty)
                  SizedBox(
                    height: imageHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => ImageLightbox.show(
                            context,
                            imageUrls: post.imageUrls,
                            title: post.title,
                          ),
                          child: IgnorePointer(
                            child: _PostHeroImage(
                              imageUrl: imageUrl,
                              extraCount: post.imageUrls.length - 1,
                              followersOnly:
                                  post.visibility == PostVisibility.followersOnly,
                              aspectRatio: 1,
                              compactBadges: true,
                              fillHeight: true,
                            ),
                          ),
                        ),
                        if (_canBookmark)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Material(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(20),
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.all(6),
                                tooltip:
                                    _bookmarked ? 'Remove bookmark' : 'Bookmark',
                                onPressed: _bookmarkBusy ? null : _toggleBookmark,
                                icon: _bookmarkBusy
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        _bookmarked
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                        size: 18,
                                        color: _bookmarked
                                            ? palette.gold
                                            : palette.cream,
                                      ),
                              ),
                            ),
                          ),
                        if (_canDelete)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Material(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(20),
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.all(6),
                                tooltip: 'Delete post',
                                onPressed: _deleteBusy ? null : _confirmDelete,
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: palette.cream,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        StarRating(value: post.rating, size: 14),
                        if (widget.showAuthorHeader) ...[
                          const SizedBox(height: 4),
                          Text(
                            post.author.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.gold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if (post.restaurantName != null) ...[
                          const Spacer(),
                          PostVenue(
                            post: post,
                            dense: true,
                            showLocation: false,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PostHeroImage extends StatelessWidget {
  const _PostHeroImage({
    required this.imageUrl,
    required this.extraCount,
    required this.followersOnly,
    this.aspectRatio = 16 / 10,
    this.compactBadges = false,
    this.fillHeight = false,
  });

  final String imageUrl;
  final int extraCount;
  final bool followersOnly;
  final double aspectRatio;
  final bool compactBadges;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final image = Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: palette.charcoalLight,
            alignment: Alignment.center,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: palette.creamMuted.withValues(alpha: 0.5),
              size: 40,
            ),
          ),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  palette.charcoal.withValues(alpha: 0.55),
                ],
                stops: const [0.55, 1.0],
              ),
            ),
          ),
        ),
        if (followersOnly)
          Positioned(
            left: compactBadges ? 6 : 10,
            top: compactBadges ? 6 : 10,
            child: IgnorePointer(
              child: _Badge(
                label: compactBadges ? 'Followers' : 'Followers only',
                icon: Icons.lock_outline,
                compact: compactBadges,
              ),
            ),
          ),
        if (extraCount > 0)
          Positioned(
            right: compactBadges ? 6 : 10,
            bottom: compactBadges ? 6 : 10,
            child: IgnorePointer(
              child: _Badge(
                label: compactBadges ? '+$extraCount' : '+$extraCount photos',
                icon: Icons.photo_library_outlined,
                compact: compactBadges,
              ),
            ),
          ),
      ],
    );

    if (fillHeight) {
      return image;
    }

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: image,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.icon,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 11 : 14, color: palette.gold),
          if (label.isNotEmpty) ...[
            SizedBox(width: compact ? 2 : 4),
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w600,
                color: palette.cream,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
