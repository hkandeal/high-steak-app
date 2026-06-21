import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../controllers/paginated_list_controller.dart';
import '../models/post_comment.dart';
import '../models/steak_post.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import '../utils/api_image_url.dart';
import '../utils/date_format.dart';
import '../widgets/comment_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/star_rating.dart';
import '../widgets/user_avatar.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.auth,
    required this.api,
  });

  final String postId;
  final AuthController auth;
  final ApiService api;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  SteakPost? _post;
  bool _loadingPost = true;
  String? _postError;
  late PaginatedListController<PostComment> _comments;
  final _commentController = TextEditingController();
  bool _submitting = false;
  int _totalComments = 0;
  int _activeImage = 0;
  bool _bookmarked = false;
  bool _bookmarkBusy = false;
  bool _deleteBusy = false;

  bool get _canComment => widget.auth.hasScope('comments:write');
  bool get _canBookmark => widget.auth.hasScope('bookmarks:write');
  bool get _isOwner => _post?.author.id == widget.auth.user?.id;

  @override
  void initState() {
    super.initState();
    _comments = PaginatedListController<PostComment>(
      (page) => widget.api.fetchPostComments(widget.postId, page: page),
    );
    _loadPost();
    _comments.reload().then((_) {
      if (mounted) {
        setState(() => _totalComments = _comments.totalElements);
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _comments.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    setState(() {
      _loadingPost = true;
      _postError = null;
    });
    try {
      final post = await widget.api.fetchPost(widget.postId);
      if (!mounted) return;
      setState(() {
        _post = post;
        _bookmarked = post.bookmarked;
        _loadingPost = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _postError = e.toString();
        _loadingPost = false;
      });
    }
  }

  Future<void> _submitComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      final created = await widget.api.addPostComment(widget.postId, body);
      _comments.addItem(created);
      _commentController.clear();
      setState(() => _totalComments += 1);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _toggleBookmark() async {
    if (!_canBookmark || _bookmarkBusy) return;
    setState(() => _bookmarkBusy = true);
    try {
      if (_bookmarked) {
        await widget.api.unbookmarkPost(widget.postId);
      } else {
        await widget.api.bookmarkPost(widget.postId);
      }
      if (!mounted) return;
      setState(() => _bookmarked = !_bookmarked);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _bookmarkBusy = false);
    }
  }

  Future<void> _confirmDeletePost() async {
    if (!_isOwner || !widget.auth.hasScope('posts:write') || _deleteBusy) return;
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
      await widget.api.deletePost(widget.postId);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      setState(() => _deleteBusy = false);
    }
  }

  Future<void> _updateComment(PostComment comment, String body) async {
    final updated = await widget.api.updatePostComment(
      widget.postId,
      comment.id,
      body,
    );
    _comments.replaceItem(
      (item) => item.id == comment.id,
      updated,
    );
    if (mounted) setState(() {});
  }

  Future<void> _deleteComment(PostComment comment) async {
    await widget.api.deletePostComment(widget.postId, comment.id);
    _comments.removeItem((item) => item.id == comment.id);
    if (mounted) {
      setState(() => _totalComments = (_totalComments - 1).clamp(0, 999999));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPost) {
      return const LoadingState(message: 'Loading post…');
    }

    if (_postError != null || _post == null) {
      return ErrorState(message: _postError ?? 'Post not found', onRetry: _loadPost);
    }

    final post = _post!;
    final images = post.imageUrls;
    final theme = Theme.of(context);
    final palette = context.palette;
    final userId = widget.auth.user?.id;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 240) {
          if (_comments.hasMore && !_comments.loadingMore) {
            _comments.loadMore().then((_) {
              if (mounted) setState(() {});
            });
          }
        }
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          if (images.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  resolveApiImageUrl(images[_activeImage]),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: palette.charcoalLight,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
            if (images.length > 1) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 68,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final selected = index == _activeImage;
                    return InkWell(
                      onTap: () => setState(() => _activeImage = index),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selected ? palette.gold : palette.cardBorder,
                            width: selected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            resolveApiImageUrl(images[index]),
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              UserAvatar(displayName: post.author.displayName, radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/users/${post.author.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
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
              if (_canBookmark)
                IconButton(
                  tooltip: _bookmarked ? 'Remove bookmark' : 'Bookmark',
                  onPressed: _bookmarkBusy ? null : _toggleBookmark,
                  icon: _bookmarkBusy
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette.gold,
                          ),
                        )
                      : Icon(
                          _bookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: _bookmarked ? palette.gold : palette.creamMuted,
                        ),
                ),
              if (_isOwner && widget.auth.hasScope('posts:write'))
                PopupMenuButton<String>(
                  enabled: !_deleteBusy,
                  icon: Icon(Icons.more_vert, color: palette.gold),
                  onSelected: (value) {
                    if (value == 'edit') {
                      context.push('/posts/${post.id}/edit');
                    } else if (value == 'delete') {
                      _confirmDeletePost();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit post')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete post')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(post.title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 10),
          StarRating(value: post.rating, size: 22),
          if (post.restaurantName != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.restaurant, size: 18, color: palette.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    post.restaurantLocation != null
                        ? '${post.restaurantName} · ${post.restaurantLocation}'
                        : post.restaurantName!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
          if (post.comment != null && post.comment!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.cardBorder),
              ),
              child: Text(
                post.comment!,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
            ),
          ],
          const SizedBox(height: 28),
          Row(
            children: [
              Text('Comments', style: theme.textTheme.titleLarge),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.accentSelectedBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_totalComments',
                  style: TextStyle(
                    color: palette.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_canComment)
            CommentComposer(
              controller: _commentController,
              submitting: _submitting,
              onSubmit: _submitComment,
            )
          else
            Text(
              'Log in with comment permissions to join the conversation.',
              style: theme.textTheme.bodyMedium,
            ),
          const SizedBox(height: 16),
          if (_comments.items.isEmpty && !_comments.loading)
            const EmptyState(
              message: 'No comments yet. Start the conversation.',
              icon: Icons.chat_bubble_outline,
            ),
          ..._comments.items.map(
            (comment) => CommentTile(
              comment: comment,
              currentUserId: userId,
              postAuthorId: post.author.id,
              canEdit: widget.auth.hasScope('comments:write'),
              onEdit: (body) => _updateComment(comment, body),
              onDelete: () => _deleteComment(comment),
            ),
          ),
          if (_comments.loadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
