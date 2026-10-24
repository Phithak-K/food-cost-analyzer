import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/features/kitchen/kitchen_screen.dart';
import 'package:my_first_app/features/pos/models/kitchen_ticket.dart';
import 'package:my_first_app/features/pos/providers/kds_provider.dart';
import 'package:my_first_app/features/recipes/models/recipe.dart';
import 'package:my_first_app/features/recipes/models/recipe_item.dart';
import 'package:my_first_app/features/ingredients/models/ingredient.dart';

void main() {
  group('Kitchen Display System (KDS) & Portion Guide Tests', () {
    final sampleIngredient1 = Ingredient(
      id: 'ing_pork',
      name: 'เนื้อหมู',
      purchaseCost: 160.0,
      purchaseQuantity: 1.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.16,
      currentStock: 15.0,
    );

    final sampleIngredient2 = Ingredient(
      id: 'ing_sauce',
      name: 'ซอสปรุงรส',
      purchaseCost: 45.0,
      purchaseQuantity: 1.0,
      purchaseUnit: 'l',
      costPerBaseUnit: 0.045,
      currentStock: 10.0,
    );

    final sampleIngredient3 = Ingredient(
      id: 'ing_basil',
      name: 'ใบกะเพรา',
      purchaseCost: 80.0,
      purchaseQuantity: 1.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.08,
      currentStock: 5.0,
    );

    final sampleRecipe = Recipe(
      id: 'rec_basil_pork',
      name: 'ข้าวกะเพราหมูสับกระทะเหล็ก',
      category: 'Main Course',
      sellingPrice: 89.0,
      unitsSoldMonthly: 25,
      items: [
        RecipeItem(ingredient: sampleIngredient1, quantityUsed: 120.0, unitUsed: 'g'),
        RecipeItem(ingredient: sampleIngredient2, quantityUsed: 20.0, unitUsed: 'ml'),
        RecipeItem(ingredient: sampleIngredient3, quantityUsed: 15.0, unitUsed: 'g'),
      ],
    );

    final sampleTicket = KitchenTicket(
      id: 'ticket_test_1',
      orderNumber: 'ORD-9901',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      status: KitchenOrderStatus.cooking,
      items: [
        KitchenOrderItem(recipe: sampleRecipe, quantity: 2),
      ],
    );

    Widget createTestApp(ProviderContainer container) {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: KitchenScreen(),
        ),
      );
    }

    testWidgets('KitchenScreen renders ticket, order number, and menu items', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          kdsProvider.overrideWith(() => _CustomKdsNotifier([sampleTicket])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(container));
      await tester.pumpAndSettle();

      // Check Header & Ticket
      expect(find.textContaining('จอคิวอาหารในครัว'), findsOneWidget);
      expect(find.text('#ORD-9901'), findsOneWidget);
      expect(find.text('2x'), findsOneWidget);
      expect(find.text('ข้าวกะเพราหมูสับกระทะเหล็ก'), findsOneWidget);

      // Check Status Action Buttons
      expect(find.byKey(const Key('status_cooking_ticket_test_1')), findsOneWidget);
      expect(find.byKey(const Key('status_done_ticket_test_1')), findsOneWidget);

      // Check Portion Guide Button
      expect(find.byKey(const Key('portion_guide_rec_basil_pork')), findsOneWidget);
    });

    testWidgets('Tapping Portion Guide icon opens Glassmorphism Portion Guide Modal with specs and warning',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          kdsProvider.overrideWith(() => _CustomKdsNotifier([sampleTicket])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(container));
      await tester.pumpAndSettle();

      // Tap ⚖️ Portion Guide button
      await tester.tap(find.byKey(const Key('portion_guide_rec_basil_pork')));
      await tester.pumpAndSettle();

      // Verify Portion Guide Modal is shown
      expect(find.text('สเปกการปรุง (Portion Guide)'), findsOneWidget);
      expect(find.text('คุมต้นทุนเชฟ'), findsOneWidget);

      // Verify the Food Cost warning requirement
      expect(
        find.text('กรุณาชั่งตวงตามสเปก เพื่อรักษามาตรฐานรสชาติและควบคุม Food Cost % ของร้าน'),
        findsOneWidget,
      );

      // Verify exact ingredients and weights
      expect(find.text('เนื้อหมู'), findsOneWidget);
      expect(find.text('120 g'), findsOneWidget);
      expect(find.text('ซอสปรุงรส'), findsOneWidget);
      expect(find.text('20 ml'), findsOneWidget);
      expect(find.text('ใบกะเพรา'), findsOneWidget);
      expect(find.text('15 g'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('รับทราบสเปกการปรุง (เข้าใจแล้ว)'));
      await tester.pumpAndSettle();

      expect(find.text('สเปกการปรุง (Portion Guide)'), findsNothing);
    });

    testWidgets('Tapping Done button updates ticket status to ready/done', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          kdsProvider.overrideWith(() => _CustomKdsNotifier([sampleTicket])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(container));
      await tester.pumpAndSettle();

      // Tap 'เสร็จแล้ว (Done)'
      await tester.tap(find.byKey(const Key('status_done_ticket_test_1')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4)); // drain toast timer

      // Verify ticket is now ready/done
      final tickets = container.read(kdsProvider);
      expect(tickets.first.status, equals(KitchenOrderStatus.ready));
      expect(find.text('ปรุงเสร็จแล้ว'), findsOneWidget);
    });
  });
}

class _CustomKdsNotifier extends KdsNotifier {
  final List<KitchenTicket> initialTickets;
  _CustomKdsNotifier(this.initialTickets);

  @override
  List<KitchenTicket> build() {
    return initialTickets;
  }
}
