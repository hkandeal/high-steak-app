import '../constants/api_constraints.dart';

import 'auth_validation.dart';

String? validateDisplayName(String displayName) {
  return validateTextLength(
    displayName,
    'Display name',
    required: true,
    min: ApiConstraints.displayNameMin,
    max: ApiConstraints.displayNameMax,
  );
}

String? validateEmail(String email) => validateEmailFormat(email);

String? validateProfileForm({
  required String displayName,
  required bool hasNewAvatar,
  required int avatarBytes,
}) {
  final nameError = validateDisplayName(displayName);
  if (nameError != null) return nameError;

  if (hasNewAvatar && avatarBytes > ApiConstraints.maxImageBytes) {
    return 'Avatar must be ${ApiConstraints.maxImageMb} MB or smaller.';
  }

  return null;
}
