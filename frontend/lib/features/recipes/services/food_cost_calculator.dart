import '../models/recipe.dart';
import '../models/recipe_item.dart';

/// Dedicated service for performing culinary food cost calculations and pricing recommendations.
class FoodCostCalculator {
  /// Default recommended food cost percentage range in standard F&B industry
  static const double defaultTargetMin = 28.0; // 28%
  static const double defaultTargetMax = 35.0; // 35%

  /// Calculates total dish cost from a list of recipe items.
  static double calculateTotalCost(List<RecipeItem> items) {
    return items.fold(0.0, (acc, item) => acc + item.itemCost);
  }

  /// Calculates the Food Cost Percentage: (Total Cost / Selling Price) * 100
  static double calculateFoodCostPercentage({
    required double totalCost,
    required double sellingPrice,
  }) {
    if (sellingPrice <= 0) return 0.0;
    return (totalCost / sellingPrice) * 100.0;
  }

  /// Calculates the Contribution Margin (Gross Profit per dish): Selling Price - Total Cost
  static double calculateContributionMargin({
    required double sellingPrice,
    required double totalCost,
  }) {
    return sellingPrice - totalCost;
  }

  /// Suggests a target selling price based on total food cost and desired food cost percentage.
  /// Formula: Suggested Price = Total Cost / (Target % / 100)
  static double suggestSellingPrice({
    required double totalCost,
    double targetFoodCostPercentage = 30.0,
  }) {
    if (targetFoodCostPercentage <= 0) return totalCost;
    return totalCost / (targetFoodCostPercentage / 100.0);
  }

  /// Returns whether the recipe's food cost percentage falls within standard target bounds.
  static bool isFoodCostOptimal(
    double foodCostPercentage, {
    double min = defaultTargetMin,
    double max = defaultTargetMax,
  }) {
    return foodCostPercentage >= min && foodCostPercentage <= max;
  }

  /// Comprehensive calculation summary for a recipe
  static RecipeCostSummary analyzeRecipe(Recipe recipe) {
    return RecipeCostSummary(
      recipeId: recipe.id,
      recipeName: recipe.name,
      sellingPrice: recipe.sellingPrice,
      totalCost: recipe.totalCost,
      contributionMargin: recipe.contributionMargin,
      foodCostPercentage: recipe.foodCostPercentage,
      suggestedPriceAt30Pct: suggestSellingPrice(totalCost: recipe.totalCost, targetFoodCostPercentage: 30.0),
      isOptimal: isFoodCostOptimal(recipe.foodCostPercentage),
    );
  }
}

class RecipeCostSummary {
  final String recipeId;
  final String recipeName;
  final double sellingPrice;
  final double totalCost;
  final double contributionMargin;
  final double foodCostPercentage;
  final double suggestedPriceAt30Pct;
  final bool isOptimal;

  const RecipeCostSummary({
    required this.recipeId,
    required this.recipeName,
    required this.sellingPrice,
    required this.totalCost,
    required this.contributionMargin,
    required this.foodCostPercentage,
    required this.suggestedPriceAt30Pct,
    required this.isOptimal,
  });
}
