import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/api_constraints.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import '../theme/theme_controller.dart';
import '../utils/auth_validation.dart';
import '../widgets/auth_card.dart';
import '../widgets/brand_background.dart';
import '../widgets/theme_toggle.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.api,
    required this.themeController,
  });

  final ApiService api;
  final ThemeController themeController;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _message;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final usernameError = validateTextLength(
      _username.text,
      'Username',
      required: true,
      max: ApiConstraints.usernameMax,
    );
    final emailError = validateEmailFormat(_email.text);
    if (usernameError != null || emailError != null) {
      setState(() => _error = usernameError ?? emailError);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });

    try {
      final message = await widget.api.requestPasswordReset(
        username: _username.text.trim(),
        email: _email.text.trim(),
      );
      if (!mounted) return;
      setState(() => _message = message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return BrandBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.canPop() ? context.pop() : context.go('/login'),
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
                title: 'Reset your password',
                subtitle:
                    'Enter your username and email. We\'ll send a reset link if they match your account.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      AuthErrorBanner(message: _error!),
                      const SizedBox(height: 14),
                    ],
                    if (_message != null)
                      Text(
                        _message!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: palette.creamMuted,
                            ),
                      )
                    else ...[
                      TextField(
                        controller: _username,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_outline, color: palette.gold),
                        ),
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _email,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined, color: palette.gold),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: Text(_loading ? 'Please wait…' : 'Send reset link'),
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
