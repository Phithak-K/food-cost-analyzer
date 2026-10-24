library;

/// Models for What-If Cost Impact Simulation
class PriceAdjustment {
  final String ingredientId;
  final double? percentChange; // e.g. 10.0 for +10%
  final double? absolutePriceChange; // e.g. 15.0 for +15 THB
  final double? newPrice;

  const PriceAdjustment({
    required this.ingredientId,
    this.percentChange,
    this.absolutePriceChange,
    this.newPrice,
  });

  Map<String, dynamic> toJson() => {
        'ingredientId': ingredientId,
        if (percentChange != null) 'percentChange': percentChange,
        if (absolutePriceChange != null) 'absolutePriceChange': absolutePriceChange,
        if (newPrice != null) 'newPrice': newPrice,
      };

  factory PriceAdjustment.fromJson(Map<String, dynamic> json) => PriceAdjustment(
        ingredientId: json['ingredientId'] as String,
        percentChange: (json['percentChange'] as num?)?.toDouble(),
        absolutePriceChange: (json['absolutePriceChange'] as num?)?.toDouble(),
        newPrice: (json['newPrice'] as num?)?.toDouble(),
      );
}

class SimulatedRecipeComparison {
  final String recipeId;
  final String recipeName;
  final String category;
  final double sellingPrice;
  final int unitsSoldMonthly;
  final double oldCost;
  final double newCost;
  final double costDifference;
  final double costPercentChange;
  final double oldFoodCostPercentage;
  final double newFoodCostPercentage;
  final double foodCostPercentageDifference;
  final double oldContributionMargin;
  final double newContributionMargin;
  final double oldMonthlyProfit;
  final double newMonthlyProfit;
  final double monthlyProfitDifference;
  final bool wasOverThreshold;
  final bool isOverThreshold;
  final bool becameCritical;
  final List<String> usedAdjustedIngredients;

  const SimulatedRecipeComparison({
    required this.recipeId,
    required this.recipeName,
    required this.category,
    required this.sellingPrice,
    required this.unitsSoldMonthly,
    required this.oldCost,
    required this.newCost,
    required this.costDifference,
    required this.costPercentChange,
    required this.oldFoodCostPercentage,
    required this.newFoodCostPercentage,
    required this.foodCostPercentageDifference,
    required this.oldContributionMargin,
    required this.newContributionMargin,
    required this.oldMonthlyProfit,
    required this.newMonthlyProfit,
    required this.monthlyProfitDifference,
    required this.wasOverThreshold,
    required this.isOverThreshold,
    required this.becameCritical,
    required this.usedAdjustedIngredients,
  });

  factory SimulatedRecipeComparison.fromJson(Map<String, dynamic> json) =>
      SimulatedRecipeComparison(
        recipeId: json['recipeId'] as String,
        recipeName: json['recipeName'] as String,
        category: (json['category'] as String?) ?? 'General',
        sellingPrice: (json['sellingPrice'] as num).toDouble(),
        unitsSoldMonthly: (json['unitsSoldMonthly'] as num).toInt(),
        oldCost: (json['oldCost'] as num).toDouble(),
        newCost: (json['newCost'] as num).toDouble(),
        costDifference: (json['costDifference'] as num).toDouble(),
        costPercentChange: (json['costPercentChange'] as num).toDouble(),
        oldFoodCostPercentage: (json['oldFoodCostPercentage'] as num).toDouble(),
        newFoodCostPercentage: (json['newFoodCostPercentage'] as num).toDouble(),
        foodCostPercentageDifference:
            (json['foodCostPercentageDifference'] as num).toDouble(),
        oldContributionMargin: (json['oldContributionMargin'] as num).toDouble(),
        newContributionMargin: (json['newContributionMargin'] as num).toDouble(),
        oldMonthlyProfit: (json['oldMonthlyProfit'] as num).toDouble(),
        newMonthlyProfit: (json['newMonthlyProfit'] as num).toDouble(),
        monthlyProfitDifference: (json['monthlyProfitDifference'] as num).toDouble(),
        wasOverThreshold: json['wasOverThreshold'] as bool,
        isOverThreshold: json['isOverThreshold'] as bool,
        becameCritical: json['becameCritical'] as bool,
        usedAdjustedIngredients: (json['usedAdjustedIngredients'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

class AdjustedIngredientDetail {
  final String id;
  final String name;
  final double originalPurchasePrice;
  final double simulatedPurchasePrice;
  final double originalCostPerBaseUnit;
  final double simulatedCostPerBaseUnit;
  final double percentChange;

  const AdjustedIngredientDetail({
    required this.id,
    required this.name,
    required this.originalPurchasePrice,
    required this.simulatedPurchasePrice,
    required this.originalCostPerBaseUnit,
    required this.simulatedCostPerBaseUnit,
    required this.percentChange,
  });

  factory AdjustedIngredientDetail.fromJson(Map<String, dynamic> json) =>
      AdjustedIngredientDetail(
        id: json['id'] as String,
        name: json['name'] as String,
        originalPurchasePrice: (json['originalPurchasePrice'] as num).toDouble(),
        simulatedPurchasePrice: (json['simulatedPurchasePrice'] as num).toDouble(),
        originalCostPerBaseUnit: (json['originalCostPerBaseUnit'] as num).toDouble(),
        simulatedCostPerBaseUnit: (json['simulatedCostPerBaseUnit'] as num).toDouble(),
        percentChange: (json['percentChange'] as num).toDouble(),
      );
}

class StoreSimulationSummary {
  final double totalMonthlyRevenue;
  final double oldMonthlyTotalCost;
  final double newMonthlyTotalCost;
  final double totalCostDifference;
  final double oldMonthlyGrossProfit;
  final double newMonthlyGrossProfit;
  final double netProfitDifference;
  final double oldOverallCostPercentage;
  final double newOverallCostPercentage;
  final double costPercentageDifference;
  final int impactedRecipesCount;
  final int newlyCriticalRecipesCount;
  final int totalCriticalRecipesCount;
  final List<AdjustedIngredientDetail> adjustedIngredientsSummary;

  const StoreSimulationSummary({
    required this.totalMonthlyRevenue,
    required this.oldMonthlyTotalCost,
    required this.newMonthlyTotalCost,
    required this.totalCostDifference,
    required this.oldMonthlyGrossProfit,
    required this.newMonthlyGrossProfit,
    required this.netProfitDifference,
    required this.oldOverallCostPercentage,
    required this.newOverallCostPercentage,
    required this.costPercentageDifference,
    required this.impactedRecipesCount,
    required this.newlyCriticalRecipesCount,
    required this.totalCriticalRecipesCount,
    required this.adjustedIngredientsSummary,
  });

  factory StoreSimulationSummary.fromJson(Map<String, dynamic> json) =>
      StoreSimulationSummary(
        totalMonthlyRevenue: (json['totalMonthlyRevenue'] as num).toDouble(),
        oldMonthlyTotalCost: (json['oldMonthlyTotalCost'] as num).toDouble(),
        newMonthlyTotalCost: (json['newMonthlyTotalCost'] as num).toDouble(),
        totalCostDifference: (json['totalCostDifference'] as num).toDouble(),
        oldMonthlyGrossProfit: (json['oldMonthlyGrossProfit'] as num).toDouble(),
        newMonthlyGrossProfit: (json['newMonthlyGrossProfit'] as num).toDouble(),
        netProfitDifference: (json['netProfitDifference'] as num).toDouble(),
        oldOverallCostPercentage:
            (json['oldOverallCostPercentage'] as num).toDouble(),
        newOverallCostPercentage:
            (json['newOverallCostPercentage'] as num).toDouble(),
        costPercentageDifference:
            (json['costPercentageDifference'] as num).toDouble(),
        impactedRecipesCount: (json['impactedRecipesCount'] as num).toInt(),
        newlyCriticalRecipesCount:
            (json['newlyCriticalRecipesCount'] as num).toInt(),
        totalCriticalRecipesCount:
            (json['totalCriticalRecipesCount'] as num).toInt(),
        adjustedIngredientsSummary:
            (json['adjustedIngredientsSummary'] as List<dynamic>?)
                    ?.map((e) =>
                        AdjustedIngredientDetail.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                [],
      );
}

class SimulationResult {
  final StoreSimulationSummary summary;
  final List<SimulatedRecipeComparison> recipeComparisons;

  const SimulationResult({
    required this.summary,
    required this.recipeComparisons,
  });

  factory SimulationResult.fromJson(Map<String, dynamic> json) => SimulationResult(
        summary: StoreSimulationSummary.fromJson(
            json['summary'] as Map<String, dynamic>),
        recipeComparisons: (json['recipeComparisons'] as List<dynamic>)
            .map((e) =>
                SimulatedRecipeComparison.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
