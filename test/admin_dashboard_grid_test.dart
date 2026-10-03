import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avatar_app/features/admin/dashboard/admin_dashboard_screen.dart';
import 'package:avatar_app/providers/auth_provider.dart';
import 'package:avatar_app/models/user.dart';

import 'package:avatar_app/services/auth_service.dart';
import 'package:avatar_app/core/api/api_client.dart';

// A minimal notifier that holds a fixed AuthState — no real network calls.
// Extends AuthNotifier (required by overrideWith type constraint).
class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(
    AuthService authService,
    ApiClient apiClient,
    AuthState fixedState,
  ) : super(authService, apiClient) {
    // Immediately override whatever the parent constructor sets.
    state = fixedState;
  }
}


User _makeSuperAdmin() => User(
      id: 'admin-1',
      name: 'Super Admin',
      phone: '9999999999',
      role: 'super_admin', // isSuperAdmin getter returns true for 'super_admin'
      status: 'active',
      permissions: {
        'products': ['read', 'write'],
        'orders': ['read', 'write'],
        'dealers': ['read', 'write'],
        'users': ['read', 'write'],
        'ecommerce': ['read', 'write'],
        'configurations': ['read', 'write'],
        'reports': ['read', 'write'],
      },
    );

List<Override> _authOverrides(AuthState fixedState) => [
      authProvider.overrideWith(
        (ref) => _FixedAuthNotifier(
          ref.watch(authServiceProvider),
          ref.watch(apiClientProvider),
          fixedState,
        ),
      ),
    ];

void main() {
  testWidgets(
    'AdminDashboardScreen Management Grid renders without overflow on 360px screen',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fixedState = AuthState(
        user: _makeSuperAdmin(),
        isAuthenticated: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: _authOverrides(fixedState),
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Products'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AdminDashboardScreen Management Grid renders without overflow on 320px screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fixedState = AuthState(
        user: _makeSuperAdmin(),
        isAuthenticated: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: _authOverrides(fixedState),
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Products'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

