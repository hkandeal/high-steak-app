import '../constants/api_constraints.dart';

String? validateDisplayName(String displayName) {
  final trimmed = displayName.trim();
  if (trimmed.isEmpty) return 'Display name is required.';
  if (trimmed.length < ApiConstraints.displayNameMin) {
    return 'Display name must be at least ${ApiConstraints.displayNameMin} characters.';
  }
  if (trimmed.length > ApiConstraints.displayNameMax) {
    return 'Display name must be at most ${ApiConstraints.displayNameMax} characters.';
  }
  return null;
}

String? validateEmail(String email) {
  final trimmed = email.trim();
  if (trimmed.isEmpty) return 'Email is required.';
  if (trimmed.length > ApiConstraints.emailMax) {
    return 'Email must be at most ${ApiConstraints.emailMax} characters.';
  }
  if (!trimmed.contains('@')) return 'Enter a valid email address.';
  return null;
}

String? validateProfileForm({
  required String displayName,
  required String email,
  required bool hasNewAvatar,
  required int avatarBytes,
}) {
  final nameError = validateDisplayName(displayName);
  if (nameError != null) return nameError;

  final emailError = validateEmail(email);
  if (emailError != null) return emailError;

  if (hasNewAvatar && avatarBytes > ApiConstraints.maxImageBytes) {
    return 'Avatar must be ${ApiConstraints.maxImageMb} MB or smaller.';
  }

  return null;
}
