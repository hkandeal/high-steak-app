import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:high_steak_mobile/auth/auth_controller.dart';
import 'package:high_steak_mobile/main.dart';
import 'package:high_steak_mobile/services/api_service.dart';
import 'package:high_steak_mobile/utils/feed_layout_controller.dart';
import 'package:high_steak_mobile/theme/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows landing screen when logged out', (WidgetTester tester) async {
    final api = ApiService();
    final auth = AuthController(api: api);
    final theme = ThemeController();
    final feedLayout = FeedLayoutController();
    await auth.initialize();
    await theme.initialize();
    await feedLayout.initialize();

    await tester.pumpWidget(
      AppRoot(auth: auth, api: api, theme: theme, feedLayout: feedLayout),
    );
    // Avoid pumpAndSettle — router/theme rebuilds never fully "settle" in tests.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('High Steaks'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
