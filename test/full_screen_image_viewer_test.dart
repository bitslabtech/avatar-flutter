import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avatar_app/widgets/common/full_screen_image_viewer.dart';

void main() {
  testWidgets('FullScreenImageViewer renders images and closes on button tap', (WidgetTester tester) async {
    final images = [
      'https://example.com/test1.jpg',
      'https://example.com/test2.jpg',
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                FullScreenImageViewer.open(
                  context,
                  imageUrls: images,
                  initialIndex: 0,
                );
              },
              child: const Text('Open Viewer'),
            ),
          ),
        ),
      ),
    );

    // Tap to open viewer
    await tester.tap(find.text('Open Viewer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify counter and close button
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // Tap close button
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify closed
    expect(find.text('1 / 2'), findsNothing);
  });
}
