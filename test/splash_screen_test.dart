import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avatar_app/features/splash/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders Avatar branding and Skip button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    // Initial frame shows AVATAR branding
    expect(find.text('AVATAR'), findsOneWidget);
    expect(find.text('KITCHEN & HOME APPLIANCES'), findsOneWidget);

    // Skip button is rendered
    expect(find.text('Skip'), findsOneWidget);

    // Pump to settle fallback timer
    await tester.pump(const Duration(milliseconds: 3600));
  });
}
