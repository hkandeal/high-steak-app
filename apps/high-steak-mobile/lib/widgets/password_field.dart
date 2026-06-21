import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'auth_form_field.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.textInputAction,
    this.onSubmitted,
    this.maxLength,
  });

  final TextEditingController controller;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final int? maxLength;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return TextField(
      controller: widget.controller,
      obscureText: !_visible,
      maxLength: widget.maxLength,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      autocorrect: false,
      enableSuggestions: false,
      decoration: authFieldDecoration(
        palette: palette,
        prefixIcon: Icons.lock_outline,
      ).copyWith(
        counterText: '',
        suffixIcon: IconButton(
          tooltip: _visible ? 'Hide password' : 'Show password',
          onPressed: () => setState(() => _visible = !_visible),
          icon: Icon(
            _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: palette.creamMuted,
          ),
        ),
      ),
    );
  }
}
