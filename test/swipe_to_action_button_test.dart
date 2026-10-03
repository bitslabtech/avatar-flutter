import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avatar_app/widgets/common/swipe_to_action_button.dart';

void main() {
  testWidgets('SwipeToActionButton renders and triggers onSwiped on swipe/drag', (WidgetTester tester) async {
    bool swiped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: SwipeToActionButton(
                text: 'Swipe to Login & View Price',
                onSwiped: () {
                  swiped = true;
                },
              ),
            ),
          ),
        ),
      ),
    );

    // Verify prompt text
    expect(find.text('Swipe to Login & View Price'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

    // Perform swipe gesture
    await tester.drag(find.byIcon(Icons.arrow_forward_rounded), const Offset(250, 0));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 600));

    expect(swiped, isTrue);
  });

  testWidgets('SwipeToActionButton triggers onSwiped on tap fallback', (WidgetTester tester) async {
    bool swiped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: SwipeToActionButton(
                text: 'Swipe to Login & View Price',
                onSwiped: () {
                  swiped = true;
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(SwipeToActionButton));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 600));

    expect(swiped, isTrue);
  });
}
