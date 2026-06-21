import 'package:flutter/material.dart';

import '../constants/api_constraints.dart';
import '../models/post_comment.dart';
import '../theme/app_palette.dart';
import '../utils/date_format.dart';
import 'user_avatar.dart';

class CommentTile extends StatefulWidget {
  const CommentTile({
    super.key,
    required this.comment,
    this.currentUserId,
    this.postAuthorId,
    this.canEdit = false,
    this.onEdit,
    this.onDelete,
  });

  final PostComment comment;
  final String? currentUserId;
  final String? postAuthorId;
  final bool canEdit;
  final Future<void> Function(String body)? onEdit;
  final Future<void> Function()? onDelete;

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool _editing = false;
  bool _busy = false;
  late final TextEditingController _editController;

  bool get _isCommentAuthor =>
      widget.currentUserId != null && widget.currentUserId == widget.comment.author.id;

  bool get _isPostAuthor =>
      widget.postAuthorId != null && widget.postAuthorId == widget.currentUserId;

  bool get _canEditComment => _isCommentAuthor && widget.canEdit && widget.onEdit != null;

  bool get _canDeleteComment =>
      (_isCommentAuthor || _isPostAuthor) && widget.onDelete != null;

  bool get _showMenu => !_editing && (_canEditComment || _canDeleteComment);

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.comment.body);
  }

  @override
  void didUpdateWidget(CommentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.comment.id != widget.comment.id) {
      _editController.text = widget.comment.body;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  Future<void> _saveEdit() async {
    final body = _editController.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment cannot be empty.')),
      );
      return;
    }
    if (body.length > ApiConstraints.commentBodyMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Comment must be at most ${ApiConstraints.commentBodyMax} characters.',
          ),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onEdit!(body);
      if (mounted) setState(() => _editing = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This cannot be undone.'),
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

    setState(() => _busy = true);
    try {
      await widget.onDelete!();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final comment = widget.comment;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  displayName: comment.author.displayName,
                  radius: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.author.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: 14,
                            ),
                      ),
                      Text(
                        formatPostDate(comment.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: palette.creamMuted,
                            ),
                      ),
                    ],
                  ),
                ),
                if (_showMenu)
                  PopupMenuButton<String>(
                    enabled: !_busy,
                    icon: Icon(Icons.more_vert, color: palette.creamMuted, size: 20),
                    onSelected: (value) {
                      if (value == 'edit') {
                        setState(() {
                          _editing = true;
                          _editController.text = comment.body;
                        });
                      } else if (value == 'delete') {
                        _confirmDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      if (_canEditComment)
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      if (_canDeleteComment)
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_editing)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CommentComposer(
                    controller: _editController,
                    submitting: _busy,
                    submitLabel: 'Save',
                    onSubmit: _saveEdit,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _editing = false;
                                _editController.text = comment.body;
                              }),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              )
            else
              Text(
                comment.body,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      height: 1.45,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

class CommentComposer extends StatelessWidget {
  const CommentComposer({
    super.key,
    required this.controller,
    required this.submitting,
    required this.onSubmit,
    this.submitLabel = 'Post',
  });

  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSubmit;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Share your thoughts…',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: submitting ? null : onSubmit,
            style: FilledButton.styleFrom(
              minimumSize: const Size(72, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(submitting ? '…' : submitLabel),
          ),
        ],
      ),
    );
  }
}
