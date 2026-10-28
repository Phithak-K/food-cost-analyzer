import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/providers/user_role_provider.dart';
import 'package:my_first_app/core/router/app_router.dart';
import 'package:my_first_app/core/theme/app_theme.dart';
import 'package:my_first_app/features/forecast/providers/forecast_provider.dart';

void main() {
  final routes = [
    '/dashboard',
    '/pos',
    '/kds',
    '/orders',
    '/recipes',
    '/recipes/builder',
    '/ingredients',
    '/forecast',
    '/simulation',
  ];

  final viewports = [
    const Size(1440, 900),
    const Size(1024, 768),
    const Size(960, 850),
    const Size(950, 600),
    const Size(800, 600),
    const Size(720, 800),
    const Size(600, 800),
    const Size(480, 800),
    const Size(390, 844),
  ];

  for (final route in routes) {
    for (final size in viewports) {
      testWidgets('Audit appRouter route $route at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final container = ProviderContainer(
          overrides: [
            forecastProvider.overrideWith(() => ForecastNotifier(autoFetch: false)),
          ],
        );
        addTearDown(container.dispose);

        // Ensure userRole is manager
        container.read(userRoleProvider.notifier).setRole(UserRole.manager);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              theme: AppTheme.darkTheme,
              routerConfig: appRouter,
            ),
          ),
        );

        appRouter.go(route);
        await tester.pumpAndSettle();
      });
    }
  }
}
