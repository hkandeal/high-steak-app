import 'package:flutter_test/flutter_test.dart';

import 'package:high_steak_mobile/auth/auth_controller.dart';
import 'package:high_steak_mobile/main.dart';
import 'package:high_steak_mobile/services/api_service.dart';
import 'package:high_steak_mobile/theme/theme_controller.dart';

void main() {
  testWidgets('shows landing screen when logged out', (WidgetTester tester) async {
    final api = ApiService();
    final auth = AuthController(api: api);
    final theme = ThemeController();
    await auth.initialize();
    await theme.initialize();

    await tester.pumpWidget(AppRoot(auth: auth, api: api, theme: theme));
    await tester.pumpAndSettle();

    expect(find.text('High Steak'), findsWidgets);
    expect(find.text('Log in'), findsOneWidget);
  });
}
