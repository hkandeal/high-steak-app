import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

enum FieldFeedbackTone { idle, checking, success, error }

class FieldFeedback {
  const FieldFeedback({this.tone = FieldFeedbackTone.idle, this.message});

  final FieldFeedbackTone tone;
  final String? message;

  static const idle = FieldFeedback();
}

class AuthFormField extends StatelessWidget {
  const AuthFormField({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.feedback = FieldFeedback.idle,
  });

  final String label;
  final String? hint;
  final FieldFeedback feedback;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final message = feedback.message;
    final showHint = hint != null &&
        feedback.tone == FieldFeedbackTone.idle &&
        (message == null || message.isEmpty);

    Color? feedbackColor;
    switch (feedback.tone) {
      case FieldFeedbackTone.success:
        feedbackColor = palette.gold;
      case FieldFeedbackTone.error:
        feedbackColor = palette.errorText;
      case FieldFeedbackTone.checking:
        feedbackColor = palette.creamMuted;
      case FieldFeedbackTone.idle:
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: palette.creamMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
        if (showHint) ...[
          const SizedBox(height: 6),
          Text(
            hint!,
            style: theme.textTheme.bodySmall?.copyWith(color: palette.creamMuted),
          ),
        ],
        if (message != null && message.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: feedbackColor,
              fontWeight: feedback.tone == FieldFeedbackTone.success
                  ? FontWeight.w500
                  : FontWeight.normal,
            ),
          ),
        ],
      ],
    );
  }
}

InputDecoration authFieldDecoration({
  required AppPalette palette,
  IconData? prefixIcon,
}) {
  return InputDecoration(
    floatingLabelBehavior: FloatingLabelBehavior.never,
    alignLabelWithHint: false,
    prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, color: palette.gold),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
