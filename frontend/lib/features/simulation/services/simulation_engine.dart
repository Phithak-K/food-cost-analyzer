import '../../../core/utils/unit_converter.dart';
import '../../ingredients/models/ingredient.dart';
import '../../recipes/models/recipe.dart';
import '../models/simulation_models.dart';

class SimulationEngine {
  /// Computes What-If simulation purely in-memory from existing Recipe and Ingredient models.
  /// Guarantees instant 60 FPS slider responsiveness on Flutter Web without network latency.
  static SimulationResult calculate({
    required List<Recipe> recipes,
    required List<Ingredient> ingredients,
    required Map<String, double> percentAdjustments, // ingredientId -> percent change
    double targetCostThreshold = 35.0,
  }) {
    // 1. Build simulated ingredients map
    final simulatedIngredients = <String, ({
      Ingredient original,
      double simPurchasePrice,
      double origCostPerBase,
      double simCostPerBase,
      double percentChange,
    })>{};

    final adjustedDetails = <AdjustedIngredientDetail>[];

    for (final ing in ingredients) {
      final percentChange = percentAdjustments[ing.id] ?? 0.0;
      final origPurchasePrice = ing.purchaseCost;
      final origCostPerBase = ing.costPerBaseUnit;

      final simPurchasePrice = origPurchasePrice * (1 + (percentChange / 100.0));
      final simCostPerBase = origCostPerBase * (1 + (percentChange / 100.0));

      simulatedIngredients[ing.id] = (
        original: ing,
        simPurchasePrice: simPurchasePrice > 0 ? simPurchasePrice : 0.0,
        origCostPerBase: origCostPerBase,
        simCostPerBase: simCostPerBase > 0 ? simCostPerBase : 0.0,
        percentChange: percentChange,
      );

      if (percentChange != 0.0) {
        adjustedDetails.add(AdjustedIngredientDetail(
          id: ing.id,
          name: ing.name,
          originalPurchasePrice: origPurchasePrice,
          simulatedPurchasePrice: simPurchasePrice,
          originalCostPerBaseUnit: origCostPerBase,
          simulatedCostPerBaseUnit: simCostPerBase,
          percentChange: percentChange,
        ));
      }
    }

    // 2. Compute comparisons for all recipes
    final comparisons = <SimulatedRecipeComparison>[];
    double totalMonthlyRevenue = 0.0;
    double oldMonthlyTotalCost = 0.0;
    double newMonthlyTotalCost = 0.0;
    int impactedRecipesCount = 0;
    int newlyCriticalCount = 0;
    int totalCriticalCount = 0;

    for (final recipe in recipes) {
      final sellingPrice = recipe.sellingPrice;
      final unitsSold = recipe.unitsSoldMonthly;

      double oldCost = 0.0;
      double newCost = 0.0;
      final usedAdjusted = <String>[];

      for (final item in recipe.items) {
        final ingData = simulatedIngredients[item.ingredient.id];
        final qty = item.quantityUsed;
        final unit = item.unitUsed;

        if (ingData != null) {
          final itemOld = UnitConverter.calculateItemCost(
            costPerBaseUnit: ingData.origCostPerBase,
            quantityUsed: qty,
            unitUsed: unit,
          );
          final itemNew = UnitConverter.calculateItemCost(
            costPerBaseUnit: ingData.simCostPerBase,
            quantityUsed: qty,
            unitUsed: unit,
          );

          oldCost += itemOld;
          newCost += itemNew;

          if (ingData.percentChange != 0.0) {
            usedAdjusted.add(ingData.original.name);
          }
        } else {
          oldCost += item.itemCost;
          newCost += item.itemCost;
        }
      }

      final costDiff = newCost - oldCost;
      final costPctChange = oldCost > 0 ? (costDiff / oldCost) * 100.0 : 0.0;

      final oldFcPct = sellingPrice > 0 ? (oldCost / sellingPrice) * 100.0 : 0.0;
      final newFcPct = sellingPrice > 0 ? (newCost / sellingPrice) * 100.0 : 0.0;
      final fcPctDiff = newFcPct - oldFcPct;

      final oldMargin = sellingPrice - oldCost;
      final newMargin = sellingPrice - newCost;

      final oldMonthlyProfit = oldMargin * unitsSold;
      final newMonthlyProfit = newMargin * unitsSold;
      final monthlyProfitDiff = newMonthlyProfit - oldMonthlyProfit;

      final wasOver = oldFcPct > targetCostThreshold;
      final isOver = newFcPct > targetCostThreshold;
      final becameCritical = !wasOver && isOver;

      if (usedAdjusted.isNotEmpty) impactedRecipesCount++;
      if (becameCritical) newlyCriticalCount++;
      if (isOver) totalCriticalCount++;

      totalMonthlyRevenue += sellingPrice * unitsSold;
      oldMonthlyTotalCost += oldCost * unitsSold;
      newMonthlyTotalCost += newCost * unitsSold;

      comparisons.add(SimulatedRecipeComparison(
        recipeId: recipe.id,
        recipeName: recipe.name,
        category: recipe.category,
        sellingPrice: sellingPrice,
        unitsSoldMonthly: unitsSold,
        oldCost: oldCost,
        newCost: newCost,
        costDifference: costDiff,
        costPercentChange: costPctChange,
        oldFoodCostPercentage: oldFcPct,
        newFoodCostPercentage: newFcPct,
        foodCostPercentageDifference: fcPctDiff,
        oldContributionMargin: oldMargin,
        newContributionMargin: newMargin,
        oldMonthlyProfit: oldMonthlyProfit,
        newMonthlyProfit: newMonthlyProfit,
        monthlyProfitDifference: monthlyProfitDiff,
        wasOverThreshold: wasOver,
        isOverThreshold: isOver,
        becameCritical: becameCritical,
        usedAdjustedIngredients: usedAdjusted,
      ));
    }

    // Sort: impacted & newly critical first, then worst monthly profit loss
    comparisons.sort((a, b) {
      if (a.becameCritical && !b.becameCritical) return -1;
      if (!a.becameCritical && b.becameCritical) return 1;
      return a.monthlyProfitDifference.compareTo(b.monthlyProfitDifference);
    });

    final oldGrossProfit = totalMonthlyRevenue - oldMonthlyTotalCost;
    final newGrossProfit = totalMonthlyRevenue - newMonthlyTotalCost;
    final netProfitDiff = newGrossProfit - oldGrossProfit;
    final totalCostDiff = newMonthlyTotalCost - oldMonthlyTotalCost;

    final oldOverallCostPct = totalMonthlyRevenue > 0
        ? (oldMonthlyTotalCost / totalMonthlyRevenue) * 100.0
        : 0.0;
    final newOverallCostPct = totalMonthlyRevenue > 0
        ? (newMonthlyTotalCost / totalMonthlyRevenue) * 100.0
        : 0.0;
    final costPctDiff = newOverallCostPct - oldOverallCostPct;

    final summary = StoreSimulationSummary(
      totalMonthlyRevenue: totalMonthlyRevenue,
      oldMonthlyTotalCost: oldMonthlyTotalCost,
      newMonthlyTotalCost: newMonthlyTotalCost,
      totalCostDifference: totalCostDiff,
      oldMonthlyGrossProfit: oldGrossProfit,
      newMonthlyGrossProfit: newGrossProfit,
      netProfitDifference: netProfitDiff,
      oldOverallCostPercentage: oldOverallCostPct,
      newOverallCostPercentage: newOverallCostPct,
      costPercentageDifference: costPctDiff,
      impactedRecipesCount: impactedRecipesCount,
      newlyCriticalRecipesCount: newlyCriticalCount,
      totalCriticalRecipesCount: totalCriticalCount,
      adjustedIngredientsSummary: adjustedDetails,
    );

    return SimulationResult(
      summary: summary,
      recipeComparisons: comparisons,
    );
  }
}
