import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../constants/api_constraints.dart';
import '../services/api_service.dart';
import '../theme/app_palette.dart';
import '../theme/theme_controller.dart';
import '../utils/auth_validation.dart';
import '../widgets/auth_card.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/brand_background.dart';
import '../widgets/password_field.dart';
import '../widgets/theme_toggle.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.auth,
    required this.api,
    required this.themeController,
  });

  final AuthController auth;
  final ApiService api;
  final ThemeController themeController;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _displayName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  bool _loading = false;
  String? _error;
  String? _verificationEmail;

  Timer? _usernameDebounce;
  Timer? _emailDebounce;
  String _debouncedUsername = '';
  String _debouncedEmail = '';

  FieldFeedback _usernameCheck = FieldFeedback.idle;
  FieldFeedback _emailCheck = FieldFeedback.idle;

  @override
  void initState() {
    super.initState();
    _username.addListener(_scheduleUsernameCheck);
    _email.addListener(_scheduleEmailCheck);
    _password.addListener(_onFormChanged);
    _passwordConfirm.addListener(_onFormChanged);
    _displayName.addListener(_onFormChanged);
  }

  void _onFormChanged() => setState(() {});

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _emailDebounce?.cancel();
    _displayName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  void _scheduleUsernameCheck() {
    _usernameDebounce?.cancel();
    _usernameDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _debouncedUsername = _username.text.trim());
      _runUsernameAvailabilityCheck();
    });
  }

  void _scheduleEmailCheck() {
    _emailDebounce?.cancel();
    _emailDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _debouncedEmail = _email.text.trim());
      _runEmailAvailabilityCheck();
    });
  }

  Future<void> _runUsernameAvailabilityCheck() async {
    final value = _debouncedUsername;
    if (value.isEmpty) {
      setState(() => _usernameCheck = FieldFeedback.idle);
      return;
    }

    final formatError = validateUsernameFormat(value);
    if (formatError != null) {
      setState(() => _usernameCheck = FieldFeedback(
            tone: FieldFeedbackTone.error,
            message: formatError,
          ));
      return;
    }

    setState(() => _usernameCheck = const FieldFeedback(
          tone: FieldFeedbackTone.checking,
          message: 'Checking availability…',
        ));

    try {
      final result = await widget.api.checkUsernameAvailability(value);
      if (!mounted || value != _debouncedUsername) return;
      setState(() => _usernameCheck = FieldFeedback(
            tone: result.available
                ? FieldFeedbackTone.success
                : FieldFeedbackTone.error,
            message: result.message,
          ));
    } catch (_) {
      if (!mounted || value != _debouncedUsername) return;
      setState(() => _usernameCheck = const FieldFeedback(
            tone: FieldFeedbackTone.error,
            message: 'Could not check username.',
          ));
    }
  }

  Future<void> _runEmailAvailabilityCheck() async {
    final value = _debouncedEmail;
    if (value.isEmpty) {
      setState(() => _emailCheck = FieldFeedback.idle);
      return;
    }

    final formatError = validateEmailFormat(value);
    if (formatError != null) {
      setState(() => _emailCheck = FieldFeedback(
            tone: FieldFeedbackTone.error,
            message: formatError,
          ));
      return;
    }

    setState(() => _emailCheck = const FieldFeedback(
          tone: FieldFeedbackTone.checking,
          message: 'Checking email…',
        ));

    try {
      final result = await widget.api.checkEmailAvailability(value);
      if (!mounted || value != _debouncedEmail) return;
      setState(() => _emailCheck = FieldFeedback(
            tone: result.available
                ? FieldFeedbackTone.success
                : FieldFeedbackTone.error,
            message: result.message,
          ));
    } catch (_) {
      if (!mounted || value != _debouncedEmail) return;
      setState(() => _emailCheck = const FieldFeedback(
            tone: FieldFeedbackTone.error,
            message: 'Could not check email.',
          ));
    }
  }

  FieldFeedback get _displayNameFeedback {
    final value = _displayName.text;
    if (value.isEmpty) return FieldFeedback.idle;
    final message = validateTextLength(
      value,
      'Display name',
      required: true,
      min: ApiConstraints.displayNameMin,
      max: ApiConstraints.displayNameMax,
    );
    return message == null
        ? const FieldFeedback(tone: FieldFeedbackTone.success, message: 'Looks good')
        : FieldFeedback(tone: FieldFeedbackTone.error, message: message);
  }

  FieldFeedback get _usernameFeedback {
    final value = _username.text;
    if (value.isEmpty) return FieldFeedback.idle;
    final formatError = validateUsernameFormat(value);
    if (formatError != null) {
      return FieldFeedback(tone: FieldFeedbackTone.error, message: formatError);
    }
    return _usernameCheck;
  }

  FieldFeedback get _emailFeedback {
    final value = _email.text;
    if (value.isEmpty) return FieldFeedback.idle;
    final formatError = validateEmailFormat(value);
    if (formatError != null) {
      return FieldFeedback(tone: FieldFeedbackTone.error, message: formatError);
    }
    return _emailCheck;
  }

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
      !_loading &&
      _displayNameFeedback.tone == FieldFeedbackTone.success &&
      _usernameFeedback.tone == FieldFeedbackTone.success &&
      _emailFeedback.tone == FieldFeedbackTone.success &&
      _passwordFeedback.tone == FieldFeedbackTone.success &&
      _passwordConfirmFeedback.tone == FieldFeedbackTone.success;

  void _onUsernameChanged(String value) {
    final sanitized = sanitizeUsernameInput(value);
    if (sanitized == value) {
      setState(() {});
      return;
    }
    _username.value = TextEditingValue(
      text: sanitized,
      selection: TextSelection.collapsed(offset: sanitized.length),
    );
  }

  Future<void> _submit() async {
    final validationError = validateRegisterForm(
      username: _username.text,
      email: _email.text,
      password: _password.text,
      passwordConfirm: _passwordConfirm.text,
      displayName: _displayName.text,
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
      final result = await widget.auth.register(
        username: _username.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        displayName: _displayName.text.trim(),
      );
      if (!mounted) return;

      if (result.verificationRequired) {
        setState(() {
          _verificationEmail = result.verificationEmail ?? _email.text.trim();
          _loading = false;
        });
        return;
      }

      context.go('/feed');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted && _verificationEmail == null) {
        setState(() => _loading = false);
      }
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
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
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
              if (_verificationEmail != null)
                _VerificationCard(email: _verificationEmail!)
              else
                AuthCard(
                  title: 'Join High Steaks',
                  subtitle: 'Start sharing your best cuts.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthFormField(
                        label: 'Display name',
                        feedback: _displayNameFeedback,
                        child: TextField(
                          controller: _displayName,
                          textInputAction: TextInputAction.next,
                          maxLength: ApiConstraints.displayNameMax,
                          decoration: authFieldDecoration(
                            palette: palette,
                            prefixIcon: Icons.badge_outlined,
                          ).copyWith(counterText: ''),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AuthFormField(
                        label: 'Username',
                        hint: 'Letters, numbers, _ and -. Cannot start with a number.',
                        feedback: _usernameFeedback,
                        child: TextField(
                          controller: _username,
                          onChanged: _onUsernameChanged,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          maxLength: ApiConstraints.usernameMax,
                          decoration: authFieldDecoration(
                            palette: palette,
                            prefixIcon: Icons.alternate_email,
                          ).copyWith(counterText: ''),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AuthFormField(
                        label: 'Email',
                        feedback: _emailFeedback,
                        child: TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          maxLength: ApiConstraints.emailMax,
                          decoration: authFieldDecoration(
                            palette: palette,
                            prefixIcon: Icons.mail_outline,
                          ).copyWith(counterText: ''),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AuthFormField(
                        label: 'Password',
                        feedback: _passwordFeedback,
                        child: PasswordField(
                          controller: _password,
                          maxLength: ApiConstraints.passwordMax,
                        ),
                      ),
                      const SizedBox(height: 18),
                      AuthFormField(
                        label: 'Confirm password',
                        feedback: _passwordConfirmFeedback,
                        child: PasswordField(
                          controller: _passwordConfirm,
                          maxLength: ApiConstraints.passwordMax,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (_canSubmit) _submit();
                          },
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        AuthErrorBanner(message: _error!),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _canSubmit ? _submit : null,
                        child: Text(_loading ? 'Please wait…' : 'Continue'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Already grilling? Log in'),
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

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);

    return AuthCard(
      title: 'Check your email',
      subtitle: 'One more step before you join the grill.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'We sent a verification link to $email. Open it to activate your account, then log in.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            "Didn't get it? Check spam or ask your admin to resend verification.",
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.creamMuted),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/login'),
            child: const Text('Go to log in'),
          ),
        ],
      ),
    );
  }
}
