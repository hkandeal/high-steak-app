import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class AuthorFollowButton extends StatelessWidget {
  const AuthorFollowButton({
    super.key,
    required this.subscribed,
    required this.busy,
    required this.onPressed,
  });

  final bool subscribed;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final label = busy ? '…' : subscribed ? 'Following' : 'Follow';

    final style = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 28),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      foregroundColor: subscribed ? palette.creamMuted : palette.gold,
      side: BorderSide(
        color: subscribed ? palette.cardBorder : palette.gold.withValues(alpha: 0.65),
      ),
    );

    return OutlinedButton(
      onPressed: busy ? null : onPressed,
      style: style,
      child: Text(label),
    );
  }
}
