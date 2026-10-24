import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ingredients/providers/ingredients_provider.dart';
import '../models/recipe.dart';
import '../models/recipe_item.dart';

class RecipesNotifier extends Notifier<List<Recipe>> {
  @override
  List<Recipe> build() {
    final ings = ref.watch(ingredientsProvider);
    final ingMap = {for (var i in ings) i.id: i};

    return [
      Recipe(
        id: 'rec_1',
        name: 'Pan-Seared Norwegian Salmon (สเต๊กแซลมอนย่าง)',
        category: 'Main Course',
        sellingPrice: 490.0,
        unitsSoldMonthly: 380, // High Volume
        items: [
          if (ingMap.containsKey('ing_1'))
            RecipeItem(ingredient: ingMap['ing_1']!, quantityUsed: 180, unitUsed: 'g'),
          if (ingMap.containsKey('ing_4'))
            RecipeItem(ingredient: ingMap['ing_4']!, quantityUsed: 20, unitUsed: 'ml'),
          if (ingMap.containsKey('ing_9'))
            RecipeItem(ingredient: ingMap['ing_9']!, quantityUsed: 80, unitUsed: 'g'),
        ],
      ),
      Recipe(
        id: 'rec_2',
        name: 'Truffle Cream Fettuccine (เฟตตูชินีครีมทรัฟเฟิล)',
        category: 'Pasta',
        sellingPrice: 380.0,
        unitsSoldMonthly: 430, // High Volume
        items: [
          if (ingMap.containsKey('ing_5'))
            RecipeItem(ingredient: ingMap['ing_5']!, quantityUsed: 15, unitUsed: 'g'),
          if (ingMap.containsKey('ing_6'))
            RecipeItem(ingredient: ingMap['ing_6']!, quantityUsed: 120, unitUsed: 'ml'),
          if (ingMap.containsKey('ing_7'))
            RecipeItem(ingredient: ingMap['ing_7']!, quantityUsed: 30, unitUsed: 'g'),
        ],
      ),
      Recipe(
        id: 'rec_3',
        name: 'Wagyu Ribeye MB4/5 Steak (สเต๊กวากิวริบอาย)',
        category: 'Steak',
        sellingPrice: 1450.0,
        unitsSoldMonthly: 85, // Low Volume, High Margin (Puzzle)
        items: [
          if (ingMap.containsKey('ing_2'))
            RecipeItem(ingredient: ingMap['ing_2']!, quantityUsed: 250, unitUsed: 'g'),
          if (ingMap.containsKey('ing_4'))
            RecipeItem(ingredient: ingMap['ing_4']!, quantityUsed: 20, unitUsed: 'ml'),
        ],
      ),
      Recipe(
        id: 'rec_4',
        name: 'Tiger Prawn Garlic Butter (กุ้งลายเสือผัดเนยกระเทียม)',
        category: 'Seafood',
        sellingPrice: 280.0,
        unitsSoldMonthly: 490, // High Volume, Low Margin (Plowhorse)
        items: [
          if (ingMap.containsKey('ing_8'))
            RecipeItem(ingredient: ingMap['ing_8']!, quantityUsed: 200, unitUsed: 'g'),
          if (ingMap.containsKey('ing_4'))
            RecipeItem(ingredient: ingMap['ing_4']!, quantityUsed: 30, unitUsed: 'ml'),
        ],
      ),
      Recipe(
        id: 'rec_5',
        name: 'Creamy Spinach Gratin (ผักโขมอบชีส)',
        category: 'Appetizer',
        sellingPrice: 190.0,
        unitsSoldMonthly: 210, // Moderate
        items: [
          if (ingMap.containsKey('ing_9'))
            RecipeItem(ingredient: ingMap['ing_9']!, quantityUsed: 150, unitUsed: 'g'),
          if (ingMap.containsKey('ing_6'))
            RecipeItem(ingredient: ingMap['ing_6']!, quantityUsed: 80, unitUsed: 'ml'),
          if (ingMap.containsKey('ing_7'))
            RecipeItem(ingredient: ingMap['ing_7']!, quantityUsed: 40, unitUsed: 'g'),
        ],
      ),
      Recipe(
        id: 'rec_6',
        name: 'Seafood Saffron Risotto (รีซอตโต้ซีฟู้ด)',
        category: 'Main Course',
        sellingPrice: 360.0,
        unitsSoldMonthly: 55, // Low Volume, Low Margin (Dog)
        items: [
          if (ingMap.containsKey('ing_8'))
            RecipeItem(ingredient: ingMap['ing_8']!, quantityUsed: 150, unitUsed: 'g'),
          if (ingMap.containsKey('ing_3'))
            RecipeItem(ingredient: ingMap['ing_3']!, quantityUsed: 100, unitUsed: 'g'),
          if (ingMap.containsKey('ing_6'))
            RecipeItem(ingredient: ingMap['ing_6']!, quantityUsed: 50, unitUsed: 'ml'),
          if (ingMap.containsKey('ing_7'))
            RecipeItem(ingredient: ingMap['ing_7']!, quantityUsed: 30, unitUsed: 'g'),
        ],
      ),
    ];
  }

  void addRecipe(Recipe recipe) {
    state = [...state, recipe];
  }

  void updateRecipe(Recipe recipe) {
    state = [
      for (final r in state)
        if (r.id == recipe.id) recipe else r,
    ];
  }

  void deleteRecipe(String id) {
    state = state.where((r) => r.id != id).toList();
  }
}

final recipesProvider = NotifierProvider<RecipesNotifier, List<Recipe>>(
  RecipesNotifier.new,
);
