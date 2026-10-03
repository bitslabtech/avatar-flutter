import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avatar_app/features/admin/widgets/admin_bottom_nav_bar.dart';

void main() {
  testWidgets('AdminBottomNavBar renders all 5 destinations with customer capsule style for active route', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          extendBody: true,
          bottomNavigationBar: AdminBottomNavBar(currentRoute: '/admin/products'),
        ),
      ),
    );

    // Selected destination shows its label in the active pill capsule
    expect(find.text('Products'), findsOneWidget);

    // Inactive destinations only display icons, keeping the sleek customer capsule style
    expect(find.text('Dashboard'), findsNothing);
    expect(find.text('Orders'), findsNothing);
    expect(find.text('Dealers'), findsNothing);
    expect(find.text('Settings'), findsNothing);

    // Verify all 5 navigation icons are rendered (with selected icon for Products)
    expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_rounded), findsOneWidget); // selected icon
    expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
    expect(find.byIcon(Icons.people_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });

  testWidgets('AdminBottomNavBar switches active pill to Dashboard when route is /admin', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          extendBody: true,
          bottomNavigationBar: AdminBottomNavBar(currentRoute: '/admin'),
        ),
      ),
    );

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Products'), findsNothing);
    expect(find.byIcon(Icons.dashboard_rounded), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
  });

  testWidgets('AdminBottomNavBar renders on compact 360px and 320px screens without overflow', (tester) async {
    // 360px standard Android width
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          extendBody: true,
          bottomNavigationBar: AdminBottomNavBar(currentRoute: '/admin/orders'),
        ),
      ),
    );

    expect(find.text('Orders'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 320px ultra compact width — labels are hidden on narrow screens to prevent overflow
    tester.view.physicalSize = const Size(320, 600);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          extendBody: true,
          bottomNavigationBar: AdminBottomNavBar(currentRoute: '/admin/settings'),
        ),
      ),
    );

    // On 320px screens, labels are intentionally hidden (showLabel = screenWidth >= 340)
    // to prevent overflow. The nav bar should still render without overflow.
    expect(find.text('Settings'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
