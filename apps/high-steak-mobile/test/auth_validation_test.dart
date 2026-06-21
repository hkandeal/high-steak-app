import 'package:flutter_test/flutter_test.dart';
import 'package:high_steak_mobile/utils/auth_validation.dart';

void main() {
  test('sanitizeUsernameInput strips invalid characters and leading digits', () {
    expect(sanitizeUsernameInput('99chef'), 'chef');
    expect(sanitizeUsernameInput('chef@!'), 'chef');
  });

  test('validateRegisterForm requires matching passwords', () {
    expect(
      validateRegisterForm(
        username: 'chef',
        email: 'chef@example.com',
        password: 'password1',
        passwordConfirm: 'password2',
        displayName: 'Chef',
      ),
      'Passwords do not match.',
    );
  });

  test('validateUsernameFormat rejects short usernames', () {
    expect(validateUsernameFormat('ab'), isNotNull);
    expect(validateUsernameFormat('chef123'), isNull);
  });
}
