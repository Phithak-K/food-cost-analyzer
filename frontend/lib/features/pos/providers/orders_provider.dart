import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/capsule_toast.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../ingredients/providers/ingredients_provider.dart';
import '../../recipes/models/recipe.dart';
import '../../recipes/providers/recipes_provider.dart';
import '../models/cart_item.dart';
import '../models/order_history.dart';
import '../widgets/insufficient_stock_dialog.dart';
import 'kds_provider.dart';
import 'orders_history_provider.dart';

class OrderState {
  final List<CartItem> items;
  final bool isSubmitting;
  final String? lastOrderNumber;
  final String orderType; // 'ทานที่ร้าน (Dine-In)' or 'กลับบ้าน (Takeaway)'
  final String tableNumber; // e.g. 'โต๊ะ 01'

  const OrderState({
    this.items = const [],
    this.isSubmitting = false,
    this.lastOrderNumber,
    this.orderType = 'ทานที่ร้าน (Dine-In)',
    this.tableNumber = 'โต๊ะ 01',
  });

  double get totalAmount => items.fold(0.0, (sum, i) => sum + i.subtotal);
  double get totalCost => items.fold(0.0, (sum, i) => sum + i.totalCost);
  double get totalProfit => totalAmount - totalCost;
  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);
  bool get isEmpty => items.isEmpty;

  int getQuantityForRecipe(String recipeId) {
    for (final item in items) {
      if (item.recipe.id == recipeId) return item.quantity;
    }
    return 0;
  }

  OrderState copyWith({
    List<CartItem>? items,
    bool? isSubmitting,
    String? lastOrderNumber,
    String? orderType,
    String? tableNumber,
  }) {
    return OrderState(
      items: items ?? this.items,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastOrderNumber: lastOrderNumber ?? this.lastOrderNumber,
      orderType: orderType ?? this.orderType,
      tableNumber: tableNumber ?? this.tableNumber,
    );
  }
}

class OrdersNotifier extends Notifier<OrderState> {
  late final Dio _dio;

  @override
  OrderState build() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:5000',
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    return const OrderState();
  }

  /// Adds a recipe to the cart or increments its count if already present.
  void addToCart(Recipe recipe) {
    final existingIndex = state.items.indexWhere((i) => i.recipe.id == recipe.id);
    if (existingIndex >= 0) {
      final updatedList = List<CartItem>.from(state.items);
      final current = updatedList[existingIndex];
      updatedList[existingIndex] = current.copyWith(quantity: current.quantity + 1);
      state = state.copyWith(items: updatedList);
    } else {
      state = state.copyWith(
        items: [...state.items, CartItem(recipe: recipe, quantity: 1)],
      );
    }
  }

  /// Increments quantity of a recipe in the cart.
  void incrementQuantity(String recipeId) {
    final index = state.items.indexWhere((i) => i.recipe.id == recipeId);
    if (index >= 0) {
      final updatedList = List<CartItem>.from(state.items);
      final current = updatedList[index];
      updatedList[index] = current.copyWith(quantity: current.quantity + 1);
      state = state.copyWith(items: updatedList);
    }
  }

  /// Decrements quantity or removes the item if quantity drops to 0.
  void decrementQuantity(String recipeId) {
    final index = state.items.indexWhere((i) => i.recipe.id == recipeId);
    if (index >= 0) {
      final current = state.items[index];
      if (current.quantity > 1) {
        final updatedList = List<CartItem>.from(state.items);
        updatedList[index] = current.copyWith(quantity: current.quantity - 1);
        state = state.copyWith(items: updatedList);
      } else {
        removeFromCart(recipeId);
      }
    }
  }

  /// Removes an item completely from the cart.
  void removeFromCart(String recipeId) {
    state = state.copyWith(
      items: state.items.where((i) => i.recipe.id != recipeId).toList(),
    );
  }

  /// Sets the order type (Dine-In vs Takeaway).
  void setOrderType(String type) {
    state = state.copyWith(orderType: type);
  }

  /// Sets the table number for dine-in orders.
  void setTableNumber(String table) {
    state = state.copyWith(tableNumber: table);
  }

  /// Clears all cart items.
  void clearCart() {
    state = state.copyWith(items: []);
  }

  /// Confirms the current cart order, verifies inventory, calls backend API,
  /// deducts stock atomically, records sales volume, and invalidates providers.
  Future<bool> confirmAndDeductOrder(BuildContext context) async {
    if (state.isEmpty) {
      CapsuleToast.showInfo(context, 'ไม่มีรายการในตะกร้า กรุณาเลือกเมนูก่อน');
      return false;
    }

    final orderItems = state.items.map((i) => (recipe: i.recipe, quantity: i.quantity)).toList();

    // 1. Pre-flight local validation for instant feedback
    final ingredientsNotifier = ref.read(ingredientsProvider.notifier);
    // Let's check stock against ingredients without mutating first:
    final List<String> localShortages = [];
    final currentIngredients = ref.read(ingredientsProvider);
    final Map<String, double> requiredMap = {};

    for (final item in state.items) {
      for (final ingItem in item.recipe.items) {
        final ing = currentIngredients.firstWhere(
          (i) => i.id == ingItem.ingredient.id,
          orElse: () => ingItem.ingredient,
        );
        final baseNeeded = (ingItem.quantityUsed * item.quantity);
        final basePerPurchase = ing.purchaseUnit == 'kg'
            ? 1000.0
            : (ing.purchaseUnit == 'l' ? 1000.0 : 1.0);
        final stockNeeded = basePerPurchase > 0 ? (baseNeeded / basePerPurchase) : 0.0;
        requiredMap[ing.id] = (requiredMap[ing.id] ?? 0.0) + stockNeeded;
      }
    }

    for (final entry in requiredMap.entries) {
      final ing = currentIngredients.firstWhere((i) => i.id == entry.key);
      if (ing.currentStock < entry.value) {
        localShortages.add(
          '${ing.name} (คงเหลือ ${ing.currentStock.toStringAsFixed(1)} ${ing.purchaseUnit}, ต้องการ ${entry.value.toStringAsFixed(1)} ${ing.purchaseUnit})',
        );
      }
    }

    if (localShortages.isNotEmpty) {
      if (context.mounted) {
        await showInsufficientStockDialog(context, insufficientItems: localShortages);
      }
      return false;
    }

    state = state.copyWith(isSubmitting: true);

    // 2. Attempt Backend POST /api/orders (Gracefully falls back to reactive local state if offline)
    try {
      final payload = {
        'items': state.items.map((i) => {
          'recipeId': i.recipe.id,
          'quantity': i.quantity,
        }).toList(),
      };

      await _dio.post('/api/orders', data: payload);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final data = e.response?.data;
        if (data['code'] == 'INSUFFICIENT_STOCK' && data['insufficientItems'] != null) {
          state = state.copyWith(isSubmitting: false);
          final list = (data['insufficientItems'] as List)
              .map((i) => '${i['name']} (คงเหลือ ${i['availableStock']} ${i['unit']}, ต้องการ ${i['requiredStock']} ${i['unit']})')
              .toList();
          if (context.mounted) {
            await showInsufficientStockDialog(context, insufficientItems: list);
          }
          return false;
        }
      }
      // Note: If backend is offline during client-only demo, continue to update local state smoothly
    }

    // 3. Deduct stock atomically in state
    ingredientsNotifier.deductStockForOrder(orderItems);

    // 4. Record sales volume in recipesProvider
    final recipesNotifier = ref.read(recipesProvider.notifier);
    for (final item in state.items) {
      recipesNotifier.recordSale(item.recipe.id, item.quantity);
    }

    // 5. Invalidate / Trigger Refresh
    ref.invalidate(dashboardProvider);

    // 6. Generate order code, push ticket to Kitchen KDS queue, push to history, and notify
    final orderNum = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final selectedTable = state.orderType.contains('กลับบ้าน')
        ? 'รับกลับบ้าน (Takeaway)'
        : state.tableNumber;
    ref.read(kdsProvider.notifier).addTicketFromCart(
      orderNum,
      state.items,
      table: selectedTable,
      orderType: state.orderType,
    );

    ref.read(ordersHistoryProvider.notifier).addCompletedOrder(
      OrderHistoryRecord(
        id: orderNum,
        totalAmount: state.totalAmount,
        totalCost: state.totalCost,
        status: 'COMPLETED',
        createdAt: DateTime.now(),
        items: state.items
            .map(
              (i) => OrderHistoryItem(
                id: i.recipe.id,
                recipeName: i.recipe.name,
                category: i.recipe.category,
                quantity: i.quantity,
                pricePerUnit: i.recipe.sellingPrice,
                costPerUnit: i.recipe.totalCost,
              ),
            )
            .toList(),
      ),
    );

    state = state.copyWith(
      isSubmitting: false,
      lastOrderNumber: orderNum,
      items: [],
    );

    if (context.mounted) {
      CapsuleToast.showSuccess(
        context,
        'บันทึกออเดอร์ #$orderNum เรียบร้อยแล้ว (ตัดสต็อกและบันทึกยอดขายทันที)',
        title: 'ยืนยันออเดอร์สำเร็จ',
      );
    }

    return true;
  }
}

final ordersProvider = NotifierProvider<OrdersNotifier, OrderState>(
  OrdersNotifier.new,
);
