import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/unit_converter.dart';
import '../../recipes/models/recipe.dart';
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

  /// Check if an ingredient has enough stock for a single recipe portion
  bool canCookRecipe(Recipe recipe, {int quantity = 1}) {
    for (final item in recipe.items) {
      final currentIng = state.firstWhere(
        (i) => i.id == item.ingredient.id,
        orElse: () => item.ingredient,
      );
      final totalBaseNeeded = UnitConverter.toBaseUnit(item.quantityUsed * quantity, item.unitUsed);
      final basePerStockUnit = UnitConverter.toBaseUnit(1.0, currentIng.purchaseUnit);
      final stockNeeded = basePerStockUnit > 0 ? (totalBaseNeeded / basePerStockUnit) : 0.0;
      if (currentIng.currentStock < stockNeeded) {
        return false;
      }
    }
    return true;
  }

  /// Get list of missing ingredient descriptions if stock is not sufficient
  List<String> getMissingIngredients(Recipe recipe, {int quantity = 1}) {
    final List<String> missing = [];
    for (final item in recipe.items) {
      final currentIng = state.firstWhere(
        (i) => i.id == item.ingredient.id,
        orElse: () => item.ingredient,
      );
      final totalBaseNeeded = UnitConverter.toBaseUnit(item.quantityUsed * quantity, item.unitUsed);
      final basePerStockUnit = UnitConverter.toBaseUnit(1.0, currentIng.purchaseUnit);
      final stockNeeded = basePerStockUnit > 0 ? (totalBaseNeeded / basePerStockUnit) : 0.0;
      if (currentIng.currentStock < stockNeeded) {
        missing.add(
          '${currentIng.name} (เหลือ ${currentIng.currentStock.toStringAsFixed(1)} ${currentIng.purchaseUnit}, ต้องการ ${stockNeeded.toStringAsFixed(1)} ${currentIng.purchaseUnit})',
        );
      }
    }
    return missing;
  }

  /// Deducts stock for a list of recipes and quantities.
  /// Returns empty list if successful, or list of insufficient items if failed.
  List<String> deductStockForOrder(List<({Recipe recipe, int quantity})> orderItems) {
    // 1. Calculate required quantities per ingredient
    final Map<String, double> requiredStockMap = {};
    for (final orderItem in orderItems) {
      for (final item in orderItem.recipe.items) {
        final currentIng = state.firstWhere(
          (i) => i.id == item.ingredient.id,
          orElse: () => item.ingredient,
        );
        final totalBaseNeeded = UnitConverter.toBaseUnit(item.quantityUsed * orderItem.quantity, item.unitUsed);
        final basePerStockUnit = UnitConverter.toBaseUnit(1.0, currentIng.purchaseUnit);
        final stockNeeded = basePerStockUnit > 0 ? (totalBaseNeeded / basePerStockUnit) : 0.0;
        requiredStockMap[currentIng.id] = (requiredStockMap[currentIng.id] ?? 0.0) + stockNeeded;
      }
    }

    // 2. Validate all stock
    final List<String> insufficient = [];
    for (final entry in requiredStockMap.entries) {
      final ing = state.firstWhere((i) => i.id == entry.key);
      if (ing.currentStock < entry.value) {
        insufficient.add(
          '${ing.name} (คงเหลือ ${ing.currentStock.toStringAsFixed(1)} ${ing.purchaseUnit}, ต้องการ ${entry.value.toStringAsFixed(1)} ${ing.purchaseUnit})',
        );
      }
    }

    if (insufficient.isNotEmpty) {
      return insufficient;
    }

    // 3. Deduct stock atomically
    state = [
      for (final ing in state)
        if (requiredStockMap.containsKey(ing.id))
          ing.copyWith(
            currentStock: double.parse(
              (ing.currentStock - requiredStockMap[ing.id]!).clamp(0.0, double.infinity).toStringAsFixed(2),
            ),
          )
        else
          ing,
    ];

    return [];
  }

  void restock(String ingredientId, double amount) {
    state = [
      for (final item in state)
        if (item.id == ingredientId)
          item.copyWith(currentStock: item.currentStock + amount)
        else
          item,
    ];
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
      currentStock: 80.0,
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
      currentStock: 50.0,
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
      currentStock: 80.0,
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
      currentStock: 5000.0,
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
      currentStock: 250.0,
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
      currentStock: 45.0,
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
      currentStock: 60.0,
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
      currentStock: 35.0,
      supplier: 'Green Valley Organic',
    ),
    Ingredient(
      id: 'ing_10',
      name: 'Kurobuta Pork Chop (พอร์คชอปคุโรบูตะ)',
      category: 'Meat',
      purchaseUnit: 'kg',
      purchaseCost: 360.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 92.0,
      currentStock: 60.0,
      supplier: 'Prime Butcher Supply',
    ),
    Ingredient(
      id: 'ing_11',
      name: 'S-Pure Chicken Breast (อกไก่ออร์แกนิก)',
      category: 'Meat',
      purchaseUnit: 'kg',
      purchaseCost: 135.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 95.0,
      currentStock: 60.0,
      supplier: 'Betagro Fresh',
    ),
    Ingredient(
      id: 'ing_12',
      name: 'Smoked Streaky Bacon (เบคอนรมควันไม้แอปเปิ้ล)',
      category: 'Meat',
      purchaseUnit: 'kg',
      purchaseCost: 290.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 98.0,
      currentStock: 18.0,
      supplier: 'Artisan Smokehouse',
    ),
    Ingredient(
      id: 'ing_13',
      name: 'Organic Hen Eggs No.1 (ไข่ไก่ออร์แกนิกคัดพิเศษ)',
      category: 'Dairy',
      purchaseUnit: 'pack',
      purchaseCost: 165.0,
      purchaseQuantity: 30.0,
      yieldPercentage: 100.0,
      currentStock: 120.0,
      supplier: 'Happy Hen Farm',
    ),
    Ingredient(
      id: 'ing_14',
      name: 'Pure Anchor Butter Unsalted (เนยสดแท้ชนิดจืด)',
      category: 'Dairy',
      purchaseUnit: 'kg',
      purchaseCost: 260.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 100.0,
      currentStock: 22.0,
      supplier: 'Fonterra Foodservices',
    ),
    Ingredient(
      id: 'ing_15',
      name: 'Meiji Pasteurized Fresh Milk (นมสดพาสเจอร์ไรส์)',
      category: 'Dairy',
      purchaseUnit: 'L',
      purchaseCost: 98.0,
      purchaseQuantity: 2.0,
      yieldPercentage: 100.0,
      currentStock: 300.0,
      supplier: 'CP-Meiji Supply',
    ),
    Ingredient(
      id: 'ing_16',
      name: 'Fresh Garlic & French Rosemary (กระเทียมและโรสแมรี่สด)',
      category: 'Produce',
      purchaseUnit: 'kg',
      purchaseCost: 120.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 88.0,
      currentStock: 25.0,
      supplier: 'Royal Project Foundation',
    ),
    Ingredient(
      id: 'ing_17',
      name: 'Hydroponic Salad Greens & Tomatoes (ผักสลัดรวมและมะเขือเทศเชอร์รี่)',
      category: 'Produce',
      purchaseUnit: 'kg',
      purchaseCost: 160.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 90.0,
      currentStock: 30.0,
      supplier: 'Green Valley Organic',
    ),
    Ingredient(
      id: 'ing_18',
      name: 'Fresh Champignon Mushrooms (เห็ดแชมปิญองสด)',
      category: 'Produce',
      purchaseUnit: 'kg',
      purchaseCost: 190.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 92.0,
      currentStock: 28.0,
      supplier: 'Royal Project Foundation',
    ),
    Ingredient(
      id: 'ing_19',
      name: 'Wild Holy Basil & Bird Eye Chili (ใบกะเพราป่าและพริกขี้หนู)',
      category: 'Produce',
      purchaseUnit: 'kg',
      purchaseCost: 95.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 85.0,
      currentStock: 20.0,
      supplier: 'Thai Fresh Market',
    ),
    Ingredient(
      id: 'ing_20',
      name: 'Italian Bronze-Cut Spaghetti No.12 (เส้นสปาเก็ตตี้อิตาเลียน)',
      category: 'Dry Goods',
      purchaseUnit: 'kg',
      purchaseCost: 140.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 100.0,
      currentStock: 60.0,
      supplier: 'Euro Imports Co.',
    ),
    Ingredient(
      id: 'ing_21',
      name: 'Ceremonial Uji Matcha Powder (ผงมัทฉะอุจิแท้เกรดพิธีการ)',
      category: 'Specialty',
      purchaseUnit: 'g',
      purchaseCost: 850.0,
      purchaseQuantity: 100.0,
      yieldPercentage: 100.0,
      currentStock: 2000.0,
      supplier: 'Kyoto Tea Imports',
    ),
    Ingredient(
      id: 'ing_22',
      name: '100% Japanese Yuzu Purée (น้ำส้มยูซุคั้นสดแท้)',
      category: 'Specialty',
      purchaseUnit: 'L',
      purchaseCost: 690.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 100.0,
      currentStock: 35.0,
      supplier: 'Tokyo Gourmet Direct',
    ),
    Ingredient(
      id: 'ing_23',
      name: 'Single Origin Arabica Beans (เมล็ดกาแฟอาราบิก้าคั่วพิเศษ)',
      category: 'Specialty',
      purchaseUnit: 'kg',
      purchaseCost: 780.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 100.0,
      currentStock: 45.0,
      supplier: 'Chiang Mai Artisan Roasters',
    ),
    Ingredient(
      id: 'ing_24',
      name: 'Belgian Dark Chocolate 70.5% Callets (ดาร์กช็อกโกแลตเบลเยียม)',
      category: 'Specialty',
      purchaseUnit: 'kg',
      purchaseCost: 520.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 100.0,
      currentStock: 40.0,
      supplier: 'Callebaut Thailand',
    ),
    Ingredient(
      id: 'ing_25',
      name: 'Golden French Butter Croissant Dough (แป้งครัวซองต์เนยสดฝรั่งเศส)',
      category: 'Bakery',
      purchaseUnit: 'pcs',
      purchaseCost: 35.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 100.0,
      currentStock: 3.0, // Low Stock for Live Demo (เหลือ 3 ชิ้น)
      supplier: 'Bridor Gourmet France',
    ),
    Ingredient(
      id: 'ing_26',
      name: 'Avocado Hass Grade A (อะโวคาโดแฮสส์คัดสด)',
      category: 'Produce',
      purchaseUnit: 'kg',
      purchaseCost: 240.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 70.0,
      currentStock: 80.0,
      supplier: 'New Zealand Fresh Produce',
    ),
    Ingredient(
      id: 'ing_27',
      name: 'Organic Passion Fruit Purée (เสาวรสสดแท้ 100%)',
      category: 'Specialty',
      purchaseUnit: 'L',
      purchaseCost: 280.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 100.0,
      currentStock: 60.0,
      supplier: 'Royal Project Foundation',
    ),
    Ingredient(
      id: 'ing_28',
      name: 'French Crispy Potato Fries (มันฝรั่งเส้นสไตล์ฝรั่งเศส)',
      category: 'Dry Goods',
      purchaseUnit: 'kg',
      purchaseCost: 95.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 95.0,
      currentStock: 120.0,
      supplier: 'McCain Foods',
    ),
    Ingredient(
      id: 'ing_29',
      name: 'White Truffle Olive Oil (น้ำมันเห็ดทรัฟเฟิลขาวเข้มข้น)',
      category: 'Specialty',
      purchaseUnit: 'L',
      purchaseCost: 890.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 100.0,
      currentStock: 50.0,
      supplier: 'Urbani Tartufi Italy',
    ),
    Ingredient(
      id: 'ing_30',
      name: 'Hokkaido Scallops Sashimi Grade (หอยเชลล์ฮอกไกโดเกรดซาชิมิ)',
      category: 'Seafood',
      purchaseUnit: 'kg',
      purchaseCost: 1200.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 95.0,
      currentStock: 50.0,
      supplier: 'Hokkaido Seafood Direct',
    ),
    Ingredient(
      id: 'ing_31',
      name: 'Italian Squid Ink Spaghetti (เส้นสปาเก็ตตี้หมึกดำอิตาเลียน)',
      category: 'Dry Goods',
      purchaseUnit: 'kg',
      purchaseCost: 190.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 100.0,
      currentStock: 60.0,
      supplier: 'De Cecco Italy',
    ),
    Ingredient(
      id: 'ing_32',
      name: 'French Foie Gras Rougié (ตับห่านฟัวกราส์ฝรั่งเศส)',
      category: 'Meat',
      purchaseUnit: 'kg',
      purchaseCost: 2400.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 90.0,
      currentStock: 0.1, // Critical Low Stock for Live Demo (เหลือ 100g = สั่งได้แค่ 1 จาน)
      supplier: 'Rougié Gourmet France',
    ),
    Ingredient(
      id: 'ing_33',
      name: 'Artisan Burrata Cheese (ชีสบูร์ราตาอิตาเลียนสด)',
      category: 'Dairy',
      purchaseUnit: 'pcs',
      purchaseCost: 160.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 100.0,
      currentStock: 2.0, // Critical Low Stock for Live Demo (เหลือ 2 ลูก = สั่งได้แค่ 2 จาน)
      supplier: 'Caseificio Italiano',
    ),
    Ingredient(
      id: 'ing_34',
      name: 'Fuji Apple & Cinnamon Compote (แอปเปิ้ลฟูจิและซินนามอน)',
      category: 'Specialty',
      purchaseUnit: 'kg',
      purchaseCost: 220.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 100.0,
      currentStock: 60.0,
      supplier: 'Aomori Apple Supply',
    ),
    Ingredient(
      id: 'ing_35',
      name: 'Craft Japanese Yuzu Soda & Tonic (คราฟต์ยูซุโซดาโทนิก)',
      category: 'Beverage',
      purchaseUnit: 'can',
      purchaseCost: 45.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 100.0,
      currentStock: 250.0,
      supplier: 'Kochi Citrus Direct',
    ),
    Ingredient(
      id: 'ing_36',
      name: 'Fresh Atlantic Black Mussels (หอยแมลงภู่ดำแอตแลนติกสด)',
      category: 'Seafood',
      purchaseUnit: 'kg',
      purchaseCost: 350.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 80.0,
      currentStock: 40.0,
      supplier: 'Ocean Fresh Co.',
    ),
    Ingredient(
      id: 'ing_37',
      name: 'White Wine Pinot Grigio for Cooking (ไวน์ขาวสำหรับปรุงอาหาร)',
      category: 'Oil & Condiments',
      purchaseUnit: 'L',
      purchaseCost: 280.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 100.0,
      currentStock: 35.0,
      supplier: 'Euro Imports Co.',
    ),
    Ingredient(
      id: 'ing_38',
      name: 'Japanese A5 Miyazaki Wagyu Striploin (เนื้อวากิวมิยาซากิ A5 คัดพิเศษ)',
      category: 'Meat',
      purchaseUnit: 'kg',
      purchaseCost: 3200.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 98.0,
      currentStock: 20.0,
      supplier: 'Miyazaki Wagyu Guild Japan',
    ),
    Ingredient(
      id: 'ing_39',
      name: 'Matcha Green Tea Espuma & Whipped Cream (เอสพูม่าชาเขียวมัทฉะเข้มข้น)',
      category: 'Dairy',
      purchaseUnit: 'L',
      purchaseCost: 260.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 100.0,
      currentStock: 35.0,
      supplier: 'Uji Tea Master Farm',
    ),
    Ingredient(
      id: 'ing_40',
      name: 'Italian Ladyfingers Savoiardi (บิสกิตเลดี้ฟิงเกอร์แท้)',
      category: 'Bakery',
      purchaseUnit: 'pack',
      purchaseCost: 85.0,
      purchaseQuantity: 1.0,
      yieldPercentage: 100.0,
      currentStock: 80.0,
      supplier: 'Vicenzi Bakery Italy',
    ),
  ];
}

final ingredientsProvider =
    NotifierProvider<IngredientsNotifier, List<Ingredient>>(
  IngredientsNotifier.new,
);
