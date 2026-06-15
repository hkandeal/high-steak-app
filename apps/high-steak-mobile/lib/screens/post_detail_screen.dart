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

  bool get _canComment => widget.auth.hasScope('comments:write');

  @override
  void initState() {
    super.initState();
    final token = widget.auth.token!;
    _comments = PaginatedListController<PostComment>(
      (page) => widget.api.fetchPostComments(token, widget.postId, page: page),
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
      final post = await widget.api.fetchPost(widget.auth.token!, widget.postId);
      if (!mounted) return;
      setState(() {
        _post = post;
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
      final created = await widget.api.addPostComment(
        widget.auth.token!,
        widget.postId,
        body,
      );
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
              if (post.author.id == widget.auth.user?.id &&
                  widget.auth.hasScope('posts:write'))
                IconButton(
                  tooltip: 'Edit post',
                  onPressed: () => context.push('/posts/${post.id}/edit'),
                  icon: Icon(Icons.edit_outlined, color: palette.gold),
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
            (comment) => CommentTile(comment: comment),
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
