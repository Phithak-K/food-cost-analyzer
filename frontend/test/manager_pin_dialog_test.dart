import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/providers/user_role_provider.dart';
import 'package:my_first_app/core/widgets/app_shell.dart';
import 'package:my_first_app/core/widgets/manager_pin_dialog.dart';

void main() {
  group('Manager PIN Dialog & Gated Access Tests', () {
    testWidgets('ManagerPinDialog renders keypad, PIN dots, and bypass button', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ManagerPinDialog(targetTitle: 'สูตรอาหาร'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ยืนยันรหัสผ่านผู้จัดการ'), findsOneWidget);
      expect(find.textContaining('สูตรอาหาร'), findsOneWidget);
      expect(find.byKey(const Key('pin_bypass_button')), findsOneWidget);

      // Check digits 0-9 and C
      for (int i = 0; i <= 9; i++) {
        expect(find.byKey(Key('pin_key_$i')), findsOneWidget);
      }
      expect(find.byKey(const Key('pin_key_clear')), findsOneWidget);
      expect(find.byKey(const Key('pin_key_backspace')), findsOneWidget);
    });

    testWidgets('Entering wrong PIN shakes and displays error message', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ManagerPinDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter wrong PIN: 9, 9, 9, 9
      await tester.tap(find.byKey(const Key('pin_key_9')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pin_key_9')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pin_key_9')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pin_key_9')));
      await tester.pump();

      // Should show error text
      expect(find.textContaining('รหัสผ่านไม่ถูกต้อง'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 700));
    });

    testWidgets('Tapping Demo Bypass button immediately verifies and closes dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    dialogResult = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => const ManagerPinDialog(),
                    );
                  },
                  child: const Text('Open PIN'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open PIN'));
      await tester.pumpAndSettle();

      // Tap Demo Bypass Button (⚡ 1234)
      await tester.tap(find.byKey(const Key('pin_bypass_button')));
      await tester.pumpAndSettle();

      expect(dialogResult, isTrue);
      expect(find.byType(ManagerPinDialog), findsNothing);
    });

    testWidgets('Clicking locked sidebar item opens PIN dialog and unlocks Manager access upon 1234',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Start as Cashier
      container.read(userRoleProvider.notifier).setRole(UserRole.cashier);

      final router = GoRouter(
        initialLocation: '/pos',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppShell(child: child),
            routes: [
              GoRoute(
                path: '/pos',
                builder: (context, state) => const Text('POS View'),
              ),
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const Text('Dashboard View'),
              ),
              GoRoute(
                path: '/orders',
                builder: (context, state) => const Text('Orders View'),
              ),
              GoRoute(
                path: '/recipes',
                builder: (context, state) => const Text('Recipes View'),
              ),
              GoRoute(
                path: '/kds',
                builder: (context, state) => const Text('KDS View'),
              ),
              GoRoute(
                path: '/ingredients',
                builder: (context, state) => const Text('Ingredients View'),
              ),
              GoRoute(
                path: '/simulation',
                builder: (context, state) => const Text('Simulation View'),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('POS View'), findsOneWidget);

      // In Cashier mode, dashboard is a locked sidebar item
      final dashboardFinder = find.byKey(const Key('sidebar_dashboard'));
      expect(dashboardFinder, findsOneWidget);

      // Tap locked Dashboard
      await tester.tap(dashboardFinder);
      await tester.pumpAndSettle();

      // PIN dialog should now be visible
      expect(find.byType(ManagerPinDialog), findsOneWidget);

      // Tap 1, 2, 3, 4 manually
      await tester.tap(find.byKey(const Key('pin_key_1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pin_key_2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pin_key_3')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pin_key_4')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4)); // drain toast timer

      // Should now be unlocked, role switched to manager, and navigated to Dashboard
      expect(container.read(userRoleProvider), equals(UserRole.manager));
      expect(find.text('Dashboard View'), findsOneWidget);
    });
  });
}
