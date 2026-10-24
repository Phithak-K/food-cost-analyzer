import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/core/constants/app_constants.dart';
import 'package:my_first_app/features/dashboard/services/menu_matrix_engine.dart';
import 'package:my_first_app/features/ingredients/models/ingredient.dart';
import 'package:my_first_app/features/recipes/models/recipe.dart';
import 'package:my_first_app/features/recipes/models/recipe_item.dart';

void main() {
  group('MenuMatrixEngine Tests', () {
    final ing = Ingredient(
      id: 'i1',
      name: 'Base Ing',
      purchaseUnit: 'g',
      purchaseCost: 100.0,
      purchaseQuantity: 100.0, // 1 THB/g
    );

    // Let's craft 4 recipes representing Star, Plowhorse, Puzzle, Dog:
    // Recipe 1: High Margin (400 THB profit), High Volume (300 units) -> STAR
    final starRecipe = Recipe(
      id: 'star',
      name: 'Star Dish',
      sellingPrice: 500.0,
      items: [RecipeItem(ingredient: ing, quantityUsed: 100, unitUsed: 'g')], // cost = 100, margin = 400
      unitsSoldMonthly: 300,
    );

    // Recipe 2: Low Margin (100 THB profit), High Volume (350 units) -> PLOWHORSE
    final plowhorseRecipe = Recipe(
      id: 'plowhorse',
      name: 'Plowhorse Dish',
      sellingPrice: 200.0,
      items: [RecipeItem(ingredient: ing, quantityUsed: 100, unitUsed: 'g')], // cost = 100, margin = 100
      unitsSoldMonthly: 350,
    );

    // Recipe 3: High Margin (400 THB profit), Low Volume (50 units) -> PUZZLE
    final puzzleRecipe = Recipe(
      id: 'puzzle',
      name: 'Puzzle Dish',
      sellingPrice: 500.0,
      items: [RecipeItem(ingredient: ing, quantityUsed: 100, unitUsed: 'g')], // cost = 100, margin = 400
      unitsSoldMonthly: 50,
    );

    // Recipe 4: Low Margin (50 THB profit), Low Volume (40 units) -> DOG
    final dogRecipe = Recipe(
      id: 'dog',
      name: 'Dog Dish',
      sellingPrice: 150.0,
      items: [RecipeItem(ingredient: ing, quantityUsed: 100, unitUsed: 'g')], // cost = 100, margin = 50
      unitsSoldMonthly: 40,
    );

    test('calculates averageVolume and averageMargin correctly', () {
      final recipes = [starRecipe, plowhorseRecipe, puzzleRecipe, dogRecipe];
      // Total volume: 300 + 350 + 50 + 40 = 740
      // averageVolume = 740 / 4 = 185.0
      // Total Profit: (400*300) + (100*350) + (400*50) + (50*40)
      //             = 120,000 + 35,000 + 20,000 + 2,000 = 177,000
      // averageMargin (weighted): 177,000 / 740 ≈ 239.19 THB

      final result = MenuMatrixEngine.analyzeRecipes(recipes);

      expect(result.averageVolume, 185.0);
      expect(result.averageMargin, closeTo(239.19, 0.05));
    });

    test('classifies all 4 items into their correct respective quadrants', () {
      final recipes = [starRecipe, plowhorseRecipe, puzzleRecipe, dogRecipe];
      final result = MenuMatrixEngine.analyzeRecipes(recipes);

      expect(result.stars.length, 1);
      expect(result.stars.first.recipe.id, 'star');
      expect(result.stars.first.categoryType, MenuQuadrant.star);

      expect(result.plowhorses.length, 1);
      expect(result.plowhorses.first.recipe.id, 'plowhorse');
      expect(result.plowhorses.first.categoryType, MenuQuadrant.plowhorse);

      expect(result.puzzles.length, 1);
      expect(result.puzzles.first.recipe.id, 'puzzle');
      expect(result.puzzles.first.categoryType, MenuQuadrant.puzzle);

      expect(result.dogs.length, 1);
      expect(result.dogs.first.recipe.id, 'dog');
      expect(result.dogs.first.categoryType, MenuQuadrant.dog);
    });
  });
}
