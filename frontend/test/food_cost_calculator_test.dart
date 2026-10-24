import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/features/ingredients/models/ingredient.dart';
import 'package:my_first_app/features/recipes/models/recipe.dart';
import 'package:my_first_app/features/recipes/models/recipe_item.dart';
import 'package:my_first_app/features/recipes/services/food_cost_calculator.dart';

void main() {
  group('FoodCostCalculator and Recipe Model Tests', () {
    final salmon = Ingredient(
      id: 'ing_salmon',
      name: 'Salmon Fillet',
      purchaseUnit: 'kg',
      purchaseCost: 650.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 100.0,
    );

    final oliveOil = Ingredient(
      id: 'ing_oil',
      name: 'Olive Oil',
      purchaseUnit: 'L',
      purchaseCost: 400.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 100.0,
    );

    test('calculates ingredient costPerBaseUnit accurately', () {
      // 650 THB / 1000g = 0.65 THB/g
      expect(salmon.costPerBaseUnit, 0.65);
      // 400 THB / 1000ml = 0.40 THB/ml
      expect(oliveOil.costPerBaseUnit, 0.40);
    });

    test('calculates RecipeItem costs and total recipe cost', () {
      final item1 = RecipeItem(
        ingredient: salmon,
        quantityUsed: 200, // 200g
        unitUsed: 'g',
      );
      // 200g * 0.65 = 130.0 THB
      expect(item1.itemCost, 130.0);

      final item2 = RecipeItem(
        ingredient: oliveOil,
        quantityUsed: 25, // 25ml
        unitUsed: 'ml',
      );
      // 25ml * 0.40 = 10.0 THB
      expect(item2.itemCost, 10.0);

      final recipe = Recipe(
        id: 'rec_test',
        name: 'Grilled Salmon',
        sellingPrice: 500.0,
        items: [item1, item2],
        unitsSoldMonthly: 100,
      );

      // totalCost = 130 + 10 = 140 THB
      expect(recipe.totalCost, 140.0);
      // foodCostPercentage = (140 / 500) * 100 = 28.0%
      expect(recipe.foodCostPercentage, closeTo(28.0, 0.001));
      // contributionMargin = 500 - 140 = 360.0 THB
      expect(recipe.contributionMargin, 360.0);
    });

    test('suggests optimal selling price based on target food cost %', () {
      const double cost = 150.0;
      // Target 30% -> 150 / 0.30 = 500.0 THB
      final suggestedPrice = FoodCostCalculator.suggestSellingPrice(
        totalCost: cost,
        targetFoodCostPercentage: 30.0,
      );
      expect(suggestedPrice, 500.0);
    });
  });
}
