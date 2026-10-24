import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ingredient.dart';

class IngredientsNotifier extends Notifier<List<Ingredient>> {
  @override
  List<Ingredient> build() {
    return _initialIngredients;
  }

  void addIngredient(Ingredient ingredient) {
    state = [...state, ingredient];
  }

  void updateIngredient(Ingredient ingredient) {
    state = [
      for (final item in state)
        if (item.id == ingredient.id) ingredient else item,
    ];
  }

  void deleteIngredient(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  static final List<Ingredient> _initialIngredients = [
    Ingredient(
      id: 'ing_1',
      name: 'Norwegian Salmon Fillet (ปลาแซลมอน)',
      category: 'Seafood',
      purchaseUnit: 'kg',
      purchaseCost: 650.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 92.0,
      currentStock: 18.5,
      supplier: 'Ocean Fresh Co.',
    ),
    Ingredient(
      id: 'ing_2',
      name: 'Australian Wagyu Ribeye MB4/5 (เนื้อวากิว)',
      category: 'Meat',
      purchaseUnit: 'kg',
      purchaseCost: 1450.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 95.0,
      currentStock: 12.0,
      supplier: 'Prime Butcher Supply',
    ),
    Ingredient(
      id: 'ing_3',
      name: 'Jasmine Rice 105 (ข้าวหอมมะลิ)',
      category: 'Dry Goods',
      purchaseUnit: 'kg',
      purchaseCost: 42.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 100.0,
      currentStock: 150.0,
      supplier: 'Thai Rice Mill Ltd.',
    ),
    Ingredient(
      id: 'ing_4',
      name: 'Extra Virgin Olive Oil (น้ำมันมะกอก)',
      category: 'Oil & Condiments',
      purchaseUnit: 'L',
      purchaseCost: 380.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 100.0,
      currentStock: 25.0,
      supplier: 'Euro Imports Co.',
    ),
    Ingredient(
      id: 'ing_5',
      name: 'Italian Black Truffle Paste (เห็ดทรัฟเฟิลดำ)',
      category: 'Specialty',
      purchaseUnit: 'g',
      purchaseCost: 1200.0,
      purchaseQuantity: 500.0, // 500g
      yieldPercentage: 100.0,
      currentStock: 1200.0,
      supplier: 'Gourmet Deli Supply',
    ),
    Ingredient(
      id: 'ing_6',
      name: 'Fresh Heavy Cream 35% (วิปปิ้งครีมสด)',
      category: 'Dairy',
      purchaseUnit: 'L',
      purchaseCost: 185.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 100.0,
      currentStock: 30.0,
      supplier: 'Dairy Farm Thailand',
    ),
    Ingredient(
      id: 'ing_7',
      name: 'Parmigiano Reggiano 24M (พาร์มีซานชีส)',
      category: 'Dairy',
      purchaseUnit: 'kg',
      purchaseCost: 980.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 96.0,
      currentStock: 8.5,
      supplier: 'Euro Imports Co.',
    ),
    Ingredient(
      id: 'ing_8',
      name: 'Fresh Tiger Prawns (กุ้งลายเสือ)',
      category: 'Seafood',
      purchaseUnit: 'kg',
      purchaseCost: 450.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 75.0, // Shelling & cleaning loss
      currentStock: 20.0,
      supplier: 'Ocean Fresh Co.',
    ),
    Ingredient(
      id: 'ing_9',
      name: 'Organic Baby Spinach (ผักโขม)',
      category: 'Produce',
      purchaseUnit: 'kg',
      purchaseCost: 180.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 88.0,
      currentStock: 14.0,
      supplier: 'Green Valley Organic',
    ),
  ];
}

final ingredientsProvider =
    NotifierProvider<IngredientsNotifier, List<Ingredient>>(
  IngredientsNotifier.new,
);
