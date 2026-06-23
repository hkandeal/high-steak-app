import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/api_constraints.dart';
import '../services/api_service.dart';
import '../theme/theme_controller.dart';
import '../utils/auth_validation.dart';
import '../widgets/auth_card.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/brand_background.dart';
import '../widgets/password_field.dart';
import '../widgets/theme_toggle.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.token,
    required this.api,
    required this.themeController,
  });

  final String token;
  final ApiService api;
  final ThemeController themeController;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  bool _loading = false;
  bool _success = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _password.addListener(_onFormChanged);
    _passwordConfirm.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _password.removeListener(_onFormChanged);
    _passwordConfirm.removeListener(_onFormChanged);
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  void _onFormChanged() => setState(() {});

  FieldFeedback get _passwordFeedback {
    final value = _password.text;
    if (value.isEmpty) return FieldFeedback.idle;
    final message = validateTextLength(
      value,
      'Password',
      required: true,
      min: ApiConstraints.passwordMin,
      max: ApiConstraints.passwordMax,
    );
    return message == null
        ? const FieldFeedback(tone: FieldFeedbackTone.success, message: 'Strong enough')
        : FieldFeedback(tone: FieldFeedbackTone.error, message: message);
  }

  FieldFeedback get _passwordConfirmFeedback {
    final value = _passwordConfirm.text;
    if (value.isEmpty) return FieldFeedback.idle;
    if (_password.text != value) {
      return const FieldFeedback(
        tone: FieldFeedbackTone.error,
        message: 'Passwords do not match.',
      );
    }
    return const FieldFeedback(
      tone: FieldFeedbackTone.success,
      message: 'Passwords match',
    );
  }

  bool get _canSubmit =>
      widget.token.isNotEmpty &&
      _passwordFeedback.tone == FieldFeedbackTone.success &&
      _passwordConfirmFeedback.tone == FieldFeedbackTone.success &&
      !_loading;

  Future<void> _submit() async {
    if (widget.token.isEmpty) {
      setState(() => _error = 'Reset link is missing or invalid.');
      return;
    }

    final validationError = validateResetPasswordForm(
      password: _password.text,
      passwordConfirm: _passwordConfirm.text,
    );
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.api.resetPassword(
        token: widget.token,
        password: _password.text,
        passwordConfirm: _passwordConfirm.text,
      );
      if (!mounted) return;
      setState(() => _success = true);
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BrandBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.go('/login'),
          ),
          actions: [
            ThemeToggle(themeController: widget.themeController),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              AuthCard(
                title: _success ? 'Password updated' : 'Choose a new password',
                subtitle: _success
                    ? 'Your password has been reset. Redirecting to login…'
                    : widget.token.isEmpty
                        ? 'Reset link is missing or invalid.'
                        : 'Enter and confirm your new password.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      AuthErrorBanner(message: _error!),
                      const SizedBox(height: 14),
                    ],
                    if (!_success && widget.token.isNotEmpty) ...[
                      AuthFormField(
                        label: 'New password',
                        feedback: _passwordFeedback,
                        child: PasswordField(
                          controller: _password,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AuthFormField(
                        label: 'Confirm password',
                        feedback: _passwordConfirmFeedback,
                        child: PasswordField(
                          controller: _passwordConfirm,
                          onSubmitted: (_) => _submit(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _canSubmit ? _submit : null,
                        child: Text(_loading ? 'Please wait…' : 'Reset password'),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Back to login'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
