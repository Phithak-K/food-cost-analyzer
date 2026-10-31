import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/core/providers/user_role_provider.dart';
import 'package:my_first_app/features/ingredients/models/ingredient.dart';
import 'package:my_first_app/features/ingredients/providers/ingredients_provider.dart';
import 'package:my_first_app/features/pos/models/cart_item.dart';
import 'package:my_first_app/features/pos/providers/orders_provider.dart';
import 'package:my_first_app/features/pos/screens/quick_pos_screen.dart';
import 'package:my_first_app/features/pos/widgets/insufficient_stock_dialog.dart';
import 'package:my_first_app/features/recipes/models/recipe.dart';
import 'package:my_first_app/features/recipes/models/recipe_item.dart';

void main() {
  group('POS Unit & Provider Tests', () {
    late Ingredient salmon;
    late Ingredient wagyu;
    late Recipe salmonRecipe;
    late Recipe wagyuRecipe;

    setUp(() {
      salmon = Ingredient(
        id: 'ing_salmon',
        name: 'Salmon Fillet',
        purchaseCost: 500,
        purchaseQuantity: 1,
        purchaseUnit: 'kg',
        currentStock: 2.0, // 2 kg
      );

      wagyu = Ingredient(
        id: 'ing_wagyu',
        name: 'Wagyu Beef',
        purchaseCost: 2000,
        purchaseQuantity: 1,
        purchaseUnit: 'kg',
        currentStock: 0.1, // only 100g in stock
      );

      salmonRecipe = Recipe(
        id: 'rec_salmon',
        name: 'Salmon Steak',
        sellingPrice: 350.0,
        items: [
          RecipeItem(ingredient: salmon, quantityUsed: 200, unitUsed: 'g'),
        ],
      );

      wagyuRecipe = Recipe(
        id: 'rec_wagyu',
        name: 'Wagyu Steak',
        sellingPrice: 1200.0,
        items: [
          RecipeItem(ingredient: wagyu, quantityUsed: 250, unitUsed: 'g'), // needs 250g, but only 100g available
        ],
      );
    });

    test('CartItem calculates subtotal, totalCost, and profit accurately', () {
      final cartItem = CartItem(recipe: salmonRecipe, quantity: 3);
      expect(cartItem.subtotal, 1050.0);
      expect(cartItem.profit, greaterThan(0));
    });

    test('OrderState calculates totalAmount and totalQuantity accurately', () {
      final state = OrderState(
        items: [
          CartItem(recipe: salmonRecipe, quantity: 2), // 700
          CartItem(recipe: wagyuRecipe, quantity: 1), // 1200
        ],
      );

      expect(state.totalAmount, 1900.0);
      expect(state.totalQuantity, 3);
      expect(state.isEmpty, isFalse);
    });

    test('IngredientsNotifier calculates maxPortionsAvailable accurately', () {
      final container = ProviderContainer(
        overrides: [
          ingredientsProvider.overrideWith(() => _MockIngredientsNotifier([salmon, wagyu])),
        ],
      );

      final notifier = container.read(ingredientsProvider.notifier);

      // Salmon has 2kg, needs 200g per portion -> 10 portions
      expect(notifier.maxPortionsAvailable(salmonRecipe), 10);

      // Wagyu has 100g, needs 250g per portion -> 0 portions
      expect(notifier.maxPortionsAvailable(wagyuRecipe), 0);
    });

    test('IngredientsNotifier detects stock sufficiency and shortages accurately', () {
      final container = ProviderContainer(
        overrides: [
          ingredientsProvider.overrideWith(() => _MockIngredientsNotifier([salmon, wagyu])),
        ],
      );

      final notifier = container.read(ingredientsProvider.notifier);

      // Salmon has 2kg, recipe needs 200g -> Can cook!
      expect(notifier.canCookRecipe(salmonRecipe), isTrue);

      // Wagyu has 100g, recipe needs 250g -> Cannot cook!
      expect(notifier.canCookRecipe(wagyuRecipe), isFalse);

      final missing = notifier.getMissingIngredients(wagyuRecipe);
      expect(missing.length, 1);
      expect(missing.first, contains('Wagyu Beef'));
    });

    test('IngredientsNotifier deducts stock atomically when order is confirmed', () {
      final container = ProviderContainer(
        overrides: [
          ingredientsProvider.overrideWith(() => _MockIngredientsNotifier([salmon, wagyu])),
        ],
      );

      final notifier = container.read(ingredientsProvider.notifier);

      // Deduct 2 portions of salmon steak (2 * 200g = 400g = 0.4kg)
      final errors = notifier.deductStockForOrder([
        (recipe: salmonRecipe, quantity: 2),
      ]);

      expect(errors, isEmpty);

      final remainingSalmon = container.read(ingredientsProvider).firstWhere((i) => i.id == 'ing_salmon');
      expect(remainingSalmon.currentStock, closeTo(1.6, 0.01));
    });
  });

  group('QuickPosScreen Widget Tests', () {
    testWidgets('Renders QuickPosScreen header, search bar, and empty cart state', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: QuickPosScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Quick POS / รับออเดอร์หน้าร้าน'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('รายการสั่งซื้อ (Cart)'), findsOneWidget);
      expect(find.text('ยังไม่มีรายการอาหาร'), findsOneWidget);
    });

    testWidgets('Tapping a recipe card adds it to the cart and updates totals', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: QuickPosScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the first recipe card text (e.g. Pan-Seared Norwegian Salmon)
      final firstCard = find.text('Pan-Seared Norwegian Salmon (สเต๊กแซลมอนย่าง)');
      expect(firstCard, findsOneWidget);

      // Tap on the card to add to cart
      await tester.tap(firstCard);
      await tester.pumpAndSettle();

      // Verify cart now shows items and checkout button
      expect(find.text('จำนวนรวม (1 รายการ)'), findsOneWidget);
      expect(find.text('ยืนยันออเดอร์ & ตัดสต็อก (Confirm & Deduct)'), findsOneWidget);
      expect(find.text('ล้างตะกร้า'), findsOneWidget);

      // Increment quantity
      final plusButton = find.byIcon(Icons.add_rounded);
      await tester.tap(plusButton.first);
      await tester.pumpAndSettle();

      expect(find.text('จำนวนรวม (2 รายการ)'), findsOneWidget);

      // Clear cart
      final clearButton = find.text('ล้างตะกร้า');
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(find.text('ยังไม่มีรายการอาหาร'), findsOneWidget);
    });

    testWidgets('InsufficientStockDialog renders correctly with shortage details for Manager', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: InsufficientStockDialog(
                insufficientItems: [
                  'Wagyu Beef (คงเหลือ 0.1 kg, ต้องการ 0.5 kg)',
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('วัตถุดิบไม่เพียงพอ (Out of Stock)'), findsOneWidget);
      expect(find.textContaining('Wagyu Beef'), findsOneWidget);
      expect(find.text('ปิดหน้าต่าง'), findsOneWidget);
      expect(find.text('ไปที่คลังเพื่อเติมสต็อก'), findsOneWidget);
    });

    testWidgets('InsufficientStockDialog in Cashier role shows advice and hides direct restock button', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(userRoleProvider.notifier).setRole(UserRole.cashier);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: InsufficientStockDialog(
                insufficientItems: [
                  'Fresh Heavy Cream 35% (คงเหลือ 30.0 L, ต้องการ 170.0 L)',
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('วัตถุดิบไม่เพียงพอ (Out of Stock)'), findsOneWidget);
      expect(find.textContaining('Fresh Heavy Cream'), findsOneWidget);
      expect(find.text('รับทราบ (ปิดหน้าต่าง)'), findsOneWidget);
      expect(find.text('ผู้จัดการเติมของ'), findsOneWidget);
      expect(find.text('ไปที่คลังเพื่อเติมสต็อก'), findsNothing);
    });
  });
}

class _MockIngredientsNotifier extends IngredientsNotifier {
  final List<Ingredient> _mockIngredients;

  _MockIngredientsNotifier(this._mockIngredients);

  @override
  List<Ingredient> build() {
    return _mockIngredients;
  }
}
