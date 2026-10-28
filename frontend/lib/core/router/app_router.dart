import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/forecast/screens/forecast_screen.dart';
import '../../features/ingredients/screens/ingredients_screen.dart';
import '../../features/kitchen/kitchen_screen.dart';
import '../../features/pos/screens/quick_pos_screen.dart';
import '../../features/pos/screens/sales_history_screen.dart';
import '../../features/recipes/models/recipe.dart';
import '../../features/recipes/screens/recipe_builder_screen.dart';
import '../../features/recipes/screens/recipes_screen.dart';
import '../../features/simulation/screens/what_if_simulation_screen.dart';
import '../widgets/app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/role-select',
  routes: [
    GoRoute(
      path: '/role-select',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: RoleSelectionScreen(),
      ),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return AppShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/pos',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: QuickPosScreen(),
          ),
        ),
        GoRoute(
          path: '/kds',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: KitchenScreen(),
          ),
        ),
        GoRoute(
          path: '/orders',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SalesHistoryScreen(),
          ),
        ),
        GoRoute(
          path: '/recipes',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: RecipesScreen(),
          ),
          routes: [
            GoRoute(
              path: 'builder',
              pageBuilder: (context, state) => NoTransitionPage(
                child: RecipeBuilderScreen(
                  initialRecipe: state.extra as Recipe?,
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/ingredients',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: IngredientsScreen(),
          ),
        ),
        GoRoute(
          path: '/forecast',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ForecastScreen(),
          ),
        ),
        GoRoute(
          path: '/simulation',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: WhatIfSimulationScreen(),
          ),
        ),
      ],
    ),
  ],
);
