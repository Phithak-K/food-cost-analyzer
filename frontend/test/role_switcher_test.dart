import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/providers/user_role_provider.dart';
import 'package:my_first_app/core/widgets/app_shell.dart';
import 'package:my_first_app/core/widgets/manager_pin_dialog.dart';

void main() {
  group('UserRole Unit Tests', () {
    test('UserRole defaults to manager', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(userRoleProvider), equals(UserRole.manager));
    });

    test('UserRole changes state correctly via notifier', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userRoleProvider.notifier);
      expect(container.read(userRoleProvider), equals(UserRole.manager));

      notifier.setRole(UserRole.cashier);
      expect(container.read(userRoleProvider), equals(UserRole.cashier));

      notifier.setRole(UserRole.kitchen);
      expect(container.read(userRoleProvider), equals(UserRole.kitchen));
    });

    test('UserRole route permissions validation', () {
      // Manager has access to all routes
      expect(UserRole.manager.canAccessRoute('/dashboard'), isTrue);
      expect(UserRole.manager.canAccessRoute('/pos'), isTrue);
      expect(UserRole.manager.canAccessRoute('/kds'), isTrue);
      expect(UserRole.manager.canAccessRoute('/orders'), isTrue);
      expect(UserRole.manager.canAccessRoute('/recipes'), isTrue);
      expect(UserRole.manager.canAccessRoute('/ingredients'), isTrue);
      expect(UserRole.manager.canAccessRoute('/simulation'), isTrue);

      // Cashier only has access to POS and Orders
      expect(UserRole.cashier.canAccessRoute('/pos'), isTrue);
      expect(UserRole.cashier.canAccessRoute('/orders'), isTrue);
      expect(UserRole.cashier.canAccessRoute('/dashboard'), isFalse);
      expect(UserRole.cashier.canAccessRoute('/recipes'), isFalse);
      expect(UserRole.cashier.canAccessRoute('/ingredients'), isFalse);
      expect(UserRole.cashier.canAccessRoute('/simulation'), isFalse);
      expect(UserRole.cashier.canAccessRoute('/kds'), isFalse);

      // Kitchen only has access to KDS
      expect(UserRole.kitchen.canAccessRoute('/kds'), isTrue);
      expect(UserRole.kitchen.canAccessRoute('/pos'), isFalse);
      expect(UserRole.kitchen.canAccessRoute('/orders'), isFalse);
      expect(UserRole.kitchen.canAccessRoute('/dashboard'), isFalse);
      expect(UserRole.kitchen.canAccessRoute('/recipes'), isFalse);
      expect(UserRole.kitchen.canAccessRoute('/ingredients'), isFalse);
      expect(UserRole.kitchen.canAccessRoute('/simulation'), isFalse);
    });

    test('UserRole emojis and labels are correctly formatted', () {
      expect(UserRole.manager.emoji, equals('👔'));
      expect(UserRole.manager.label, contains('ผู้จัดการ'));

      expect(UserRole.cashier.emoji, equals('🧾'));
      expect(UserRole.cashier.label, contains('แคชเชียร์'));

      expect(UserRole.kitchen.emoji, equals('👨‍🍳'));
      expect(UserRole.kitchen.label, contains('ครัว'));
    });

    test('UserRole pinCode is correct for all roles', () {
      expect(UserRole.manager.pinCode, equals('1234'));
      expect(UserRole.cashier.pinCode, equals('2222'));
      expect(UserRole.kitchen.pinCode, equals('3333'));
    });
  });

  group('Dynamic Navigation Filtering Widget Tests', () {
    Widget createTestApp({
      required ProviderContainer container,
      required String initialLocation,
    }) {
      final router = GoRouter(
        initialLocation: initialLocation,
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppShell(child: child),
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const Text('Dashboard Content'),
              ),
              GoRoute(
                path: '/pos',
                builder: (context, state) => const Text('POS Content'),
              ),
              GoRoute(
                path: '/kds',
                builder: (context, state) => const Text('KDS Content'),
              ),
              GoRoute(
                path: '/orders',
                builder: (context, state) => const Text('Orders Content'),
              ),
              GoRoute(
                path: '/recipes',
                builder: (context, state) => const Text('Recipes Content'),
              ),
              GoRoute(
                path: '/ingredients',
                builder: (context, state) => const Text('Ingredients Content'),
              ),
              GoRoute(
                path: '/simulation',
                builder: (context, state) => const Text('Simulation Content'),
              ),
            ],
          ),
        ],
      );

      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('Manager sees full sidebar menu', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        createTestApp(container: container, initialLocation: '/dashboard'),
      );
      await tester.pumpAndSettle();

      // Manager role should see all sidebar items
      expect(find.byKey(const Key('sidebar_dashboard')), findsOneWidget);
      expect(find.byKey(const Key('sidebar_pos')), findsOneWidget);
      expect(find.byKey(const Key('sidebar_kds')), findsOneWidget);
      expect(find.byKey(const Key('sidebar_orders')), findsOneWidget);
      expect(find.byKey(const Key('sidebar_recipes')), findsOneWidget);
      expect(find.byKey(const Key('sidebar_recipe_builder')), findsOneWidget);
      expect(find.byKey(const Key('sidebar_ingredients')), findsOneWidget);
      expect(find.byKey(const Key('sidebar_simulation')), findsOneWidget);
      expect(find.byKey(const Key('sidebar_glossary')), findsOneWidget);
    });

    testWidgets('Cashier role shows POS and Orders unlocked, and management items locked with PIN', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set Cashier role
      container.read(userRoleProvider.notifier).setRole(UserRole.cashier);

      await tester.pumpWidget(
        createTestApp(container: container, initialLocation: '/pos'),
      );
      await tester.pumpAndSettle();

      // Cashier sees POS and Orders
      expect(find.byKey(const Key('sidebar_pos')), findsOneWidget);
      expect(find.byKey(const Key('sidebar_orders')), findsOneWidget);

      // Manager-only items are present but locked with 🔒 icons
      expect(find.byKey(const Key('sidebar_dashboard')), findsOneWidget);
      expect(find.byKey(const Key('sidebar_recipes')), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsWidgets);
    });

    testWidgets('Kitchen role shows KDS unlocked, and other menus locked with PIN', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set Kitchen role
      container.read(userRoleProvider.notifier).setRole(UserRole.kitchen);

      await tester.pumpWidget(
        createTestApp(container: container, initialLocation: '/kds'),
      );
      await tester.pumpAndSettle();

      // Kitchen sees KDS
      expect(find.byKey(const Key('sidebar_kds')), findsOneWidget);

      // Other menus have 🔒 lock icons
      expect(find.byKey(const Key('sidebar_pos')), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsWidgets);
    });

    testWidgets('RoleSwitcherPill interacts and switches roles smoothly', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        createTestApp(container: container, initialLocation: '/dashboard'),
      );
      await tester.pumpAndSettle();

      // Check RoleSwitcherPill is present
      final switcherFinder = find.byKey(const Key('role_switcher_button'));
      expect(switcherFinder, findsOneWidget);
      expect(find.textContaining('👔'), findsWidgets);
      expect(find.textContaining('ผู้จัดการ'), findsWidgets);

      // Tap to open role popup menu
      await tester.tap(switcherFinder);
      await tester.pumpAndSettle();

      // Options for all 3 personas should appear
      expect(find.byKey(const Key('role_manager')), findsOneWidget);
      expect(find.byKey(const Key('role_cashier')), findsOneWidget);
      expect(find.byKey(const Key('role_kitchen')), findsOneWidget);

      // Tap Cashier
      await tester.tap(find.byKey(const Key('role_cashier')));
      await tester.pumpAndSettle();

      // PIN dialog for Cashier should appear with PIN 2222 indicator
      expect(find.byType(ManagerPinDialog), findsOneWidget);
      expect(find.textContaining('2222'), findsWidgets);

      // Tap Demo Bypass button (or enter 2222)
      await tester.tap(find.byKey(const Key('pin_bypass_button')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4)); // drain toast timer

      // Role state should now be Cashier
      expect(container.read(userRoleProvider), equals(UserRole.cashier));
      // Cashier is not allowed on /dashboard, so auto-redirects to /pos
      expect(find.text('POS Content'), findsOneWidget);
      expect(find.byKey(const Key('sidebar_pos')), findsOneWidget);
    });

    testWidgets('AppShell on mobile screen opens drawer via hamburger menu without Scaffold exception', (tester) async {
      tester.view.physicalSize = const Size(600, 900); // Mobile / Tablet width (< 1024)
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        createTestApp(container: container, initialLocation: '/dashboard'),
      );
      await tester.pumpAndSettle();

      // Find hamburger menu button
      final menuButton = find.byIcon(Icons.menu_rounded);
      expect(menuButton, findsOneWidget);

      // Tap hamburger menu - must open drawer without throwing Scaffold.of exception
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Drawer should be open and display sidebar items
      expect(find.byType(Drawer), findsOneWidget);
      expect(find.byKey(const Key('sidebar_dashboard')), findsOneWidget);
    });

    testWidgets('AppShell on mobile screen with Kitchen role renders without NavigationBar assertion error',
        (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(userRoleProvider.notifier).setRole(UserRole.kitchen);

      await tester.pumpWidget(
        createTestApp(container: container, initialLocation: '/kds'),
      );
      await tester.pumpAndSettle();

      // Kitchen role uses full screen without NavigationBar (prevents destinations.length >= 2 error)
      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}
