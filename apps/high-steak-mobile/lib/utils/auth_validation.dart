import '../constants/api_constraints.dart';

final _usernamePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$');
final _emailPattern = RegExp(r'^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

String sanitizeUsernameInput(String value) {
  var next = value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
  if (next.isNotEmpty && RegExp(r'^[0-9]').hasMatch(next)) {
    next = next.replaceFirst(RegExp(r'^[0-9]+'), '');
  }
  if (next.length > ApiConstraints.usernameMax) {
    next = next.substring(0, ApiConstraints.usernameMax);
  }
  return next;
}

String? validateUsernameFormat(String username) {
  final trimmed = username.trim();
  if (trimmed.isEmpty) return 'Username is required.';
  if (trimmed.length < ApiConstraints.usernameMin) {
    return 'Username must be at least ${ApiConstraints.usernameMin} characters.';
  }
  if (trimmed.length > ApiConstraints.usernameMax) {
    return 'Username must be at most ${ApiConstraints.usernameMax} characters.';
  }
  if (RegExp(r'^[0-9]').hasMatch(trimmed)) {
    return 'Username must not start with a number.';
  }
  if (!_usernamePattern.hasMatch(trimmed)) {
    return 'Username can only contain letters, numbers, underscores, and hyphens.';
  }
  return null;
}

String? validateEmailFormat(String email) {
  final trimmed = email.trim();
  if (trimmed.isEmpty) return 'Email is required.';
  if (trimmed.length > ApiConstraints.emailMax) {
    return 'Email must be at most ${ApiConstraints.emailMax} characters.';
  }
  if (!_emailPattern.hasMatch(trimmed)) {
    return 'Enter a valid email address.';
  }
  return null;
}

String? validateTextLength(
  String value,
  String label, {
  int? min,
  required int max,
  bool required = false,
}) {
  final trimmed = value.trim();
  if (required && trimmed.isEmpty) {
    return '$label is required.';
  }
  if (min != null && trimmed.isNotEmpty && trimmed.length < min) {
    return '$label must be at least $min characters.';
  }
  if (trimmed.length > max) {
    return '$label must be at most $max characters.';
  }
  return null;
}

String? validateRegisterForm({
  required String username,
  required String email,
  required String password,
  required String passwordConfirm,
  required String displayName,
}) {
  return validateTextLength(
        displayName,
        'Display name',
        required: true,
        min: ApiConstraints.displayNameMin,
        max: ApiConstraints.displayNameMax,
      ) ??
      validateUsernameFormat(username) ??
      validateEmailFormat(email) ??
      validateTextLength(
        password,
        'Password',
        required: true,
        min: ApiConstraints.passwordMin,
        max: ApiConstraints.passwordMax,
      ) ??
      (password != passwordConfirm ? 'Passwords do not match.' : null);
}

String? validateResetPasswordForm({
  required String password,
  required String passwordConfirm,
}) {
  return validateTextLength(
        password,
        'Password',
        required: true,
        min: ApiConstraints.passwordMin,
        max: ApiConstraints.passwordMax,
      ) ??
      (password != passwordConfirm ? 'Passwords do not match.' : null);
}
