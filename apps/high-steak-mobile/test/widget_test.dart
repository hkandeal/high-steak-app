import 'package:flutter_test/flutter_test.dart';
import 'package:high_steak_mobile/main.dart';

void main() {
  testWidgets('shows High Steak branding', (WidgetTester tester) async {
    await tester.pumpWidget(const HighSteakApp());
    expect(find.text('High Steak'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
