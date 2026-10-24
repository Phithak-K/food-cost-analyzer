import '../../../core/constants/app_constants.dart';
import '../../recipes/models/recipe.dart';
import '../models/menu_matrix_item.dart';

/// Result report from Menu Engineering Matrix calculation.
class MenuMatrixAnalysisResult {
  final double averageVolume;
  final double averageMargin;
  final double totalRevenue;
  final double totalFoodCost;
  final double totalProfit;
  final double overallFoodCostPercentage;
  final List<MenuMatrixItem> items;

  const MenuMatrixAnalysisResult({
    required this.averageVolume,
    required this.averageMargin,
    required this.totalRevenue,
    required this.totalFoodCost,
    required this.totalProfit,
    required this.overallFoodCostPercentage,
    required this.items,
  });

  /// High Profit, High Popularity
  List<MenuMatrixItem> get stars =>
      items.where((i) => i.categoryType == MenuQuadrant.star).toList();

  /// Low Profit, High Popularity
  List<MenuMatrixItem> get plowhorses =>
      items.where((i) => i.categoryType == MenuQuadrant.plowhorse).toList();

  /// High Profit, Low Popularity
  List<MenuMatrixItem> get puzzles =>
      items.where((i) => i.categoryType == MenuQuadrant.puzzle).toList();

  /// Low Profit, Low Popularity
  List<MenuMatrixItem> get dogs =>
      items.where((i) => i.categoryType == MenuQuadrant.dog).toList();

  int get totalItemsCount => items.length;
}

/// Menu Engineering Matrix Engine based on the Kasavana & Smith model.
class MenuMatrixEngine {
  /// Analyzes a list of [Recipe] items (each containing sellingPrice, food cost, and units sold)
  /// and automatically classifies each item into one of the four quadrants.
  ///
  /// [useWeightedAverageMargin]: If true (default in restaurant analytics),
  /// average margin = Total Gross Profit / Total Units Sold.
  /// If false, average margin = Simple mean of contribution margins across all recipes.
  static MenuMatrixAnalysisResult analyzeRecipes(
    List<Recipe> recipes, {
    bool useWeightedAverageMargin = true,
  }) {
    if (recipes.isEmpty) {
      return const MenuMatrixAnalysisResult(
        averageVolume: 0.0,
        averageMargin: 0.0,
        totalRevenue: 0.0,
        totalFoodCost: 0.0,
        totalProfit: 0.0,
        overallFoodCostPercentage: 0.0,
        items: [],
      );
    }

    double totalRevenue = 0.0;
    double totalFoodCost = 0.0;
    double totalProfit = 0.0;
    int totalVolume = 0;

    for (final recipe in recipes) {
      final int volume = recipe.unitsSoldMonthly;
      final double margin = recipe.contributionMargin;
      final double cost = recipe.totalCost;

      totalRevenue += (recipe.sellingPrice * volume);
      totalFoodCost += (cost * volume);
      totalProfit += (margin * volume);
      totalVolume += volume;
    }

    // Benchmark Threshold 1: Average Sales Volume (Hurdle Rate)
    final double averageVolume = totalVolume / recipes.length;

    // Benchmark Threshold 2: Average Contribution Margin (ACM)
    final double averageMargin;
    if (useWeightedAverageMargin && totalVolume > 0) {
      averageMargin = totalProfit / totalVolume;
    } else {
      final sumMargins = recipes.fold(0.0, (acc, r) => acc + r.contributionMargin);
      averageMargin = sumMargins / recipes.length;
    }

    // Classify into 4 Quadrants
    final List<MenuMatrixItem> matrixItems = recipes.map((recipe) {
      final double margin = recipe.contributionMargin;
      final int volume = recipe.unitsSoldMonthly;

      final bool isHighMargin = margin >= averageMargin;
      final bool isHighVolume = volume >= averageVolume;

      final MenuQuadrant quadrant;
      if (isHighMargin && isHighVolume) {
        quadrant = MenuQuadrant.star;
      } else if (!isHighMargin && isHighVolume) {
        quadrant = MenuQuadrant.plowhorse;
      } else if (isHighMargin && !isHighVolume) {
        quadrant = MenuQuadrant.puzzle;
      } else {
        quadrant = MenuQuadrant.dog;
      }

      return MenuMatrixItem(
        recipe: recipe,
        salesVolume: volume,
        contributionMargin: margin,
        categoryType: quadrant,
      );
    }).toList();

    final double overallCostPct =
        totalRevenue > 0 ? (totalFoodCost / totalRevenue) * 100.0 : 0.0;

    return MenuMatrixAnalysisResult(
      averageVolume: averageVolume,
      averageMargin: averageMargin,
      totalRevenue: totalRevenue,
      totalFoodCost: totalFoodCost,
      totalProfit: totalProfit,
      overallFoodCostPercentage: overallCostPct,
      items: matrixItems,
    );
  }

  /// Custom analysis taking raw pairs of (Recipe, salesVolume)
  static MenuMatrixAnalysisResult analyze({
    required List<({Recipe recipe, int salesVolume})> salesData,
    bool useWeightedAverageMargin = true,
  }) {
    final recipes = salesData
        .map((entry) => entry.recipe.copyWith(unitsSoldMonthly: entry.salesVolume))
        .toList();
    return analyzeRecipes(recipes, useWeightedAverageMargin: useWeightedAverageMargin);
  }
}
