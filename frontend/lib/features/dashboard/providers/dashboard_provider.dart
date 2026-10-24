import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../recipes/models/recipe.dart';
import '../../recipes/providers/recipes_provider.dart';
import '../models/menu_matrix_item.dart';
import '../services/menu_matrix_engine.dart';

class DashboardMetrics {
  final double totalRevenue;
  final double totalFoodCost;
  final double totalProfit;
  final double overallFoodCostPct;
  final double averageContributionMargin;
  final double averageUnitsSold;
  final List<MenuMatrixItem> classifiedItems;

  const DashboardMetrics({
    required this.totalRevenue,
    required this.totalFoodCost,
    required this.totalProfit,
    required this.overallFoodCostPct,
    required this.averageContributionMargin,
    required this.averageUnitsSold,
    required this.classifiedItems,
  });

  factory DashboardMetrics.fromRecipes(List<Recipe> recipes) {
    final analysis = MenuMatrixEngine.analyzeRecipes(recipes);
    return DashboardMetrics(
      totalRevenue: analysis.totalRevenue,
      totalFoodCost: analysis.totalFoodCost,
      totalProfit: analysis.totalProfit,
      overallFoodCostPct: analysis.overallFoodCostPercentage,
      averageContributionMargin: analysis.averageMargin,
      averageUnitsSold: analysis.averageVolume,
      classifiedItems: analysis.items,
    );
  }

  List<MenuMatrixItem> get stars =>
      classifiedItems.where((i) => i.categoryType == MenuQuadrant.star).toList();

  List<MenuMatrixItem> get plowhorses =>
      classifiedItems.where((i) => i.categoryType == MenuQuadrant.plowhorse).toList();

  List<MenuMatrixItem> get puzzles =>
      classifiedItems.where((i) => i.categoryType == MenuQuadrant.puzzle).toList();

  List<MenuMatrixItem> get dogs =>
      classifiedItems.where((i) => i.categoryType == MenuQuadrant.dog).toList();
}

final dashboardMetricsProvider = Provider<DashboardMetrics>((ref) {
  final recipes = ref.watch(recipesProvider);
  return DashboardMetrics.fromRecipes(recipes);
});

/// Alias for dashboardMetricsProvider
final dashboardProvider = dashboardMetricsProvider;

