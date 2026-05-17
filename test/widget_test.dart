// Basic Flutter widget test for Avatar app
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avatar_app/main.dart';

void main() {
  testWidgets('Avatar app smoke test', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope (required for Riverpod)
    await tester.pumpWidget(
      const ProviderScope(
        child: AvatarApp(),
      ),
    );

    // Pump frames to allow splash screen to render
    await tester.pump();

    // Verify that the app loads (splash screen should be visible)
    // The splash screen contains "AVATAR" text
    expect(find.text('AVATAR'), findsOneWidget);

    // Pump additional frames to allow animations to settle
    // This prevents timer-related test failures
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
