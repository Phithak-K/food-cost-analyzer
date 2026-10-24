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
      Recipe(
        id: 'rec_7',
        name: 'Kurobuta Pork Chop with Rosemary (สเต๊กพอร์คชอปคุโรบูตะ)',
        category: 'Main Course',
        sellingPrice: 390.0,
        unitsSoldMonthly: 360, // High Volume, High Margin (Star)
        items: [
          if (ingMap.containsKey('ing_10'))
            RecipeItem(ingredient: ingMap['ing_10']!, quantityUsed: 250, unitUsed: 'g'),
          if (ingMap.containsKey('ing_14'))
            RecipeItem(ingredient: ingMap['ing_14']!, quantityUsed: 25, unitUsed: 'g'),
          if (ingMap.containsKey('ing_16'))
            RecipeItem(ingredient: ingMap['ing_16']!, quantityUsed: 15, unitUsed: 'g'),
          if (ingMap.containsKey('ing_17'))
            RecipeItem(ingredient: ingMap['ing_17']!, quantityUsed: 50, unitUsed: 'g'),
        ],
      ),
      Recipe(
        id: 'rec_8',
        name: 'Wagyu Basil Rice with Cured Yolk (ข้าวผัดกะเพราเนื้อวากิวไข่ดอง)',
        category: 'Main Course',
        sellingPrice: 220.0,
        unitsSoldMonthly: 540, // High Volume, Moderate Margin (Plowhorse)
        items: [
          if (ingMap.containsKey('ing_2'))
            RecipeItem(ingredient: ingMap['ing_2']!, quantityUsed: 60, unitUsed: 'g'),
          if (ingMap.containsKey('ing_3'))
            RecipeItem(ingredient: ingMap['ing_3']!, quantityUsed: 180, unitUsed: 'g'),
          if (ingMap.containsKey('ing_13'))
            RecipeItem(ingredient: ingMap['ing_13']!, quantityUsed: 1, unitUsed: 'pcs'),
          if (ingMap.containsKey('ing_19'))
            RecipeItem(ingredient: ingMap['ing_19']!, quantityUsed: 25, unitUsed: 'g'),
          if (ingMap.containsKey('ing_4'))
            RecipeItem(ingredient: ingMap['ing_4']!, quantityUsed: 15, unitUsed: 'ml'),
        ],
      ),
      Recipe(
        id: 'rec_9',
        name: 'Spaghetti Aglio Olio Tiger Prawn (สปาเก็ตตี้พริกแห้งกุ้งลายเสือ)',
        category: 'Pasta',
        sellingPrice: 260.0,
        unitsSoldMonthly: 460, // High Volume, Low Margin (Plowhorse)
        items: [
          if (ingMap.containsKey('ing_20'))
            RecipeItem(ingredient: ingMap['ing_20']!, quantityUsed: 110, unitUsed: 'g'),
          if (ingMap.containsKey('ing_8'))
            RecipeItem(ingredient: ingMap['ing_8']!, quantityUsed: 120, unitUsed: 'g'),
          if (ingMap.containsKey('ing_4'))
            RecipeItem(ingredient: ingMap['ing_4']!, quantityUsed: 25, unitUsed: 'ml'),
          if (ingMap.containsKey('ing_16'))
            RecipeItem(ingredient: ingMap['ing_16']!, quantityUsed: 15, unitUsed: 'g'),
        ],
      ),
      Recipe(
        id: 'rec_10',
        name: 'Truffle Champignon Cream Soup (ซุปเห็ดแชมปิญองทรัฟเฟิล)',
        category: 'Appetizer',
        sellingPrice: 220.0,
        unitsSoldMonthly: 90, // Low Volume, High Margin (Puzzle)
        items: [
          if (ingMap.containsKey('ing_18'))
            RecipeItem(ingredient: ingMap['ing_18']!, quantityUsed: 120, unitUsed: 'g'),
          if (ingMap.containsKey('ing_5'))
            RecipeItem(ingredient: ingMap['ing_5']!, quantityUsed: 10, unitUsed: 'g'),
          if (ingMap.containsKey('ing_6'))
            RecipeItem(ingredient: ingMap['ing_6']!, quantityUsed: 80, unitUsed: 'ml'),
          if (ingMap.containsKey('ing_14'))
            RecipeItem(ingredient: ingMap['ing_14']!, quantityUsed: 15, unitUsed: 'g'),
        ],
      ),
      Recipe(
        id: 'rec_11',
        name: 'Smoked Salmon Garden Salad (สลัดแซลมอนรมควันฮันนี่มัสตาร์ด)',
        category: 'Appetizer',
        sellingPrice: 240.0,
        unitsSoldMonthly: 65, // Low Volume, Low Margin (Dog)
        items: [
          if (ingMap.containsKey('ing_1'))
            RecipeItem(ingredient: ingMap['ing_1']!, quantityUsed: 90, unitUsed: 'g'),
          if (ingMap.containsKey('ing_17'))
            RecipeItem(ingredient: ingMap['ing_17']!, quantityUsed: 140, unitUsed: 'g'),
          if (ingMap.containsKey('ing_4'))
            RecipeItem(ingredient: ingMap['ing_4']!, quantityUsed: 20, unitUsed: 'ml'),
        ],
      ),
      Recipe(
        id: 'rec_12',
        name: 'Iced Ceremonial Uji Matcha Latte (มัทฉะลาเต้พรีเมียมเย็น)',
        category: 'Beverage',
        sellingPrice: 155.0,
        unitsSoldMonthly: 580, // High Volume, High Margin (Star)
        items: [
          if (ingMap.containsKey('ing_21'))
            RecipeItem(ingredient: ingMap['ing_21']!, quantityUsed: 6, unitUsed: 'g'),
          if (ingMap.containsKey('ing_15'))
            RecipeItem(ingredient: ingMap['ing_15']!, quantityUsed: 180, unitUsed: 'ml'),
        ],
      ),
      Recipe(
        id: 'rec_13',
        name: 'Sparkling Yuzu Cold Brew Espresso (ยูซุเอสเพรสโซ่สปาร์คกลิ้ง)',
        category: 'Beverage',
        sellingPrice: 165.0,
        unitsSoldMonthly: 120, // Low-Medium Volume, High Margin (Puzzle)
        items: [
          if (ingMap.containsKey('ing_23'))
            RecipeItem(ingredient: ingMap['ing_23']!, quantityUsed: 20, unitUsed: 'g'),
          if (ingMap.containsKey('ing_22'))
            RecipeItem(ingredient: ingMap['ing_22']!, quantityUsed: 35, unitUsed: 'ml'),
        ],
      ),
      Recipe(
        id: 'rec_14',
        name: 'Molten Belgian Dark Chocolate Lava (เค้กช็อกโกแลตลาวาเบลเยียม)',
        category: 'Dessert',
        sellingPrice: 220.0,
        unitsSoldMonthly: 140, // High Margin (Puzzle)
        items: [
          if (ingMap.containsKey('ing_24'))
            RecipeItem(ingredient: ingMap['ing_24']!, quantityUsed: 70, unitUsed: 'g'),
          if (ingMap.containsKey('ing_14'))
            RecipeItem(ingredient: ingMap['ing_14']!, quantityUsed: 35, unitUsed: 'g'),
          if (ingMap.containsKey('ing_13'))
            RecipeItem(ingredient: ingMap['ing_13']!, quantityUsed: 1, unitUsed: 'pcs'),
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
