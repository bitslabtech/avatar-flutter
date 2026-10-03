import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avatar_app/features/admin/screens/product_add_edit_screen.dart';

void main() {
  Widget buildTestScreen({double width = 360, double height = 800}) {
    return ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, height)),
          child: const ProductAddEditScreen(),
        ),
      ),
    );
  }

  testWidgets('ProductAddEditScreen renders summary cards without overflow on 360px screen', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestScreen(width: 360, height: 800));
    await tester.pumpAndSettle();

    // Verify Variations and Pricing Summary Cards are rendered
    expect(find.text('Variations & Grouping'), findsOneWidget);
    expect(find.text('Pricing & Cost Breakdown'), findsOneWidget);
    expect(find.text('Dealer Price (D.P.)'), findsOneWidget);
    expect(find.text('Consumer MRP'), findsOneWidget);
  });

  testWidgets('ProductAddEditScreen renders without overflow on ultra-compact 320px screen', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestScreen(width: 320, height: 700));
    await tester.pumpAndSettle();

    // Verify key titles and Green DP Box render cleanly
    expect(find.text('Variations & Grouping'), findsOneWidget);
    expect(find.text('Pricing & Cost Breakdown'), findsOneWidget);
    expect(find.text('Dealer Price (D.P.)'), findsOneWidget);
  });

  testWidgets('Tapping Pricing card opens Pricing bottom sheet with all calculator fields', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestScreen(width: 390, height: 844));
    await tester.pump();

    // Tap the pricing card to open bottom sheet
    await tester.tap(find.text('Pricing & Cost Breakdown'));
    await tester.pumpAndSettle();

    // Verify bottom sheet title and sections
    expect(find.text('Pricing & Cost Calculator'), findsOneWidget);
    expect(find.text('1. Direct Costs'), findsOneWidget);
    expect(find.text('2. Margin (% of Purchase Cost)'), findsOneWidget);
    expect(find.text('3. GST Slab'), findsOneWidget);
    expect(find.text('Net Sales Price'), findsWidgets);
    expect(find.text('Apply Pricing'), findsOneWidget);
  });

  testWidgets('Tapping Variations card opens Variations bottom sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestScreen(width: 390, height: 844));
    await tester.pump();

    // Tap the variations card to open bottom sheet
    await tester.tap(find.text('Variations & Grouping'));
    await tester.pumpAndSettle();

    // Verify bottom sheet title and fields
    expect(find.text('Product Variations'), findsOneWidget);
    expect(find.text('Group Identification'), findsOneWidget);
    expect(find.text('Apply Variations'), findsOneWidget);
  });
}
