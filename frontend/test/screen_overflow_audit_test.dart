import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/core/theme/app_theme.dart';
import 'package:my_first_app/features/auth/screens/role_selection_screen.dart';
import 'package:my_first_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:my_first_app/features/forecast/providers/forecast_provider.dart';
import 'package:my_first_app/features/forecast/screens/forecast_screen.dart';
import 'package:my_first_app/features/ingredients/screens/ingredients_screen.dart';
import 'package:my_first_app/features/kitchen/kitchen_screen.dart';
import 'package:my_first_app/features/pos/screens/kds_screen.dart';
import 'package:my_first_app/features/pos/screens/quick_pos_screen.dart';
import 'package:my_first_app/features/pos/screens/sales_history_screen.dart';
import 'package:my_first_app/features/recipes/screens/recipe_builder_screen.dart';
import 'package:my_first_app/features/recipes/screens/recipes_screen.dart';
import 'package:my_first_app/features/simulation/screens/what_if_simulation_screen.dart';

void main() {
  const viewports = <String, Size>{
    'Desktop Widescreen (1440x900)': Size(1440, 900),
    'Split-Screen Snapped (960x850)': Size(960, 850),
    'Small Laptop (1024x768)': Size(1024, 768),
  };

  group('Comprehensive Screen Overflow & Responsiveness Audit', () {
    for (final entry in viewports.entries) {
      final name = entry.key;
      final size = entry.value;

      testWidgets('RoleSelectionScreen on $name renders without RenderFlex overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const RoleSelectionScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(RoleSelectionScreen), findsOneWidget);
      });

      testWidgets('DashboardScreen on $name renders without RenderFlex overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const DashboardScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(DashboardScreen), findsOneWidget);
      });

      testWidgets('WhatIfSimulationScreen on $name renders without RenderFlex overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const WhatIfSimulationScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(WhatIfSimulationScreen), findsOneWidget);
      });

      testWidgets('ForecastScreen on $name renders without RenderFlex overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              forecastProvider.overrideWith(() => ForecastNotifier(autoFetch: false)),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const ForecastScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ForecastScreen), findsOneWidget);
      });

      testWidgets('QuickPosScreen on $name renders without RenderFlex overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const QuickPosScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(QuickPosScreen), findsOneWidget);
      });

      testWidgets('SalesHistoryScreen on $name renders without RenderFlex overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const SalesHistoryScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SalesHistoryScreen), findsOneWidget);
      });

      testWidgets('KdsScreen on $name renders without RenderFlex overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const KdsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(KdsScreen), findsOneWidget);
      });

      testWidgets('KitchenScreen on $name renders without RenderFlex overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const KitchenScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(KitchenScreen), findsOneWidget);
      });

      testWidgets('RecipesScreen on $name renders without RenderFlex overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const RecipesScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(RecipesScreen), findsOneWidget);
      });

      testWidgets('RecipeBuilderScreen on $name renders without RenderFlex overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const RecipeBuilderScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(RecipeBuilderScreen), findsOneWidget);
      });

      testWidgets('IngredientsScreen on $name renders without RenderFlex overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const IngredientsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(IngredientsScreen), findsOneWidget);
      });
    }
  });
}
