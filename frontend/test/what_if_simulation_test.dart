import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/features/ingredients/models/ingredient.dart';
import 'package:my_first_app/features/recipes/models/recipe.dart';
import 'package:my_first_app/features/recipes/models/recipe_item.dart';
import 'package:my_first_app/features/simulation/screens/what_if_simulation_screen.dart';
import 'package:my_first_app/features/simulation/services/simulation_engine.dart';

void main() {
  group('SimulationEngine Tests', () {
    final salmon = Ingredient(
      id: 'ing_1',
      name: 'Norwegian Salmon',
      purchaseCost: 650.0,
      purchaseQuantity: 1.0,
      purchaseUnit: 'kg',
      yieldPercentage: 90.0,
    );

    final oil = Ingredient(
      id: 'ing_2',
      name: 'Olive Oil',
      purchaseCost: 320.0,
      purchaseQuantity: 1.0,
      purchaseUnit: 'L',
      yieldPercentage: 100.0,
    );

    final recipe = Recipe(
      id: 'rec_1',
      name: 'Salmon Steak',
      sellingPrice: 400.0,
      unitsSoldMonthly: 100,
      items: [
        RecipeItem(ingredient: salmon, quantityUsed: 200, unitUsed: 'g'),
        RecipeItem(ingredient: oil, quantityUsed: 20, unitUsed: 'ml'),
      ],
    );

    test('Baseline simulation with 0% adjustment has zero differences', () {
      final result = SimulationEngine.calculate(
        recipes: [recipe],
        ingredients: [salmon, oil],
        percentAdjustments: {},
        targetCostThreshold: 35.0,
      );

      expect(result.summary.netProfitDifference, closeTo(0.0, 0.001));
      expect(result.summary.totalCostDifference, closeTo(0.0, 0.001));
      expect(result.summary.newlyCriticalRecipesCount, equals(0));
      expect(result.recipeComparisons.length, equals(1));
      expect(result.recipeComparisons[0].costDifference, closeTo(0.0, 0.001));
    });

    test('Salmon +20% price increase reduces monthly profit and updates metrics', () {
      final result = SimulationEngine.calculate(
        recipes: [recipe],
        ingredients: [salmon, oil],
        percentAdjustments: {'ing_1': 20.0},
        targetCostThreshold: 35.0,
      );

      final comp = result.recipeComparisons[0];
      expect(comp.newCost, greaterThan(comp.oldCost));
      expect(comp.newContributionMargin, lessThan(comp.oldContributionMargin));
      expect(comp.monthlyProfitDifference, lessThan(0.0));
      expect(result.summary.netProfitDifference, lessThan(0.0));
      expect(result.summary.adjustedIngredientsSummary.length, equals(1));
      expect(result.summary.adjustedIngredientsSummary[0].percentChange, equals(20.0));
    });
  });

  group('WhatIfSimulationScreen Widget Tests', () {
    testWidgets('Renders WhatIfSimulationScreen with header, presets, and table',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WhatIfSimulationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header
      expect(find.textContaining('What-If Simulation'), findsOneWidget);
      expect(find.text('Real-Time Sandbox'), findsOneWidget);

      // Check presets
      expect(find.textContaining('ค่าครองชีพขึ้นทั้งระบบ'), findsOneWidget);
      expect(find.textContaining('วิกฤตนม & แดรี่'), findsOneWidget);

      // Check metric cards
      expect(find.text('ผลกระทบต่อกำไรสุทธิรวม'), findsOneWidget);
      expect(find.text('Food Cost รวมทั้งร้าน'), findsOneWidget);

      // Check comparison table
      expect(find.textContaining('Before vs After'), findsOneWidget);
    });
  });
}
