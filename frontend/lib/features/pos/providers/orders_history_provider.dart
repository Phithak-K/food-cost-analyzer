import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_history.dart';

class OrdersHistoryState {
  final List<OrderHistoryRecord> orders;
  final bool isLoading;
  final String? errorMessage;

  const OrdersHistoryState({
    this.orders = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  double get totalRevenue => orders.fold(0.0, (sum, o) => sum + o.totalAmount);
  double get totalCost => orders.fold(0.0, (sum, o) => sum + o.totalCost);
  double get totalProfit => totalRevenue - totalCost;
  double get overallMargin => totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0.0;
  int get totalOrdersCount => orders.length;

  OrdersHistoryState copyWith({
    List<OrderHistoryRecord>? orders,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OrdersHistoryState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class OrdersHistoryNotifier extends Notifier<OrdersHistoryState> {
  late final Dio _dio;

  @override
  OrdersHistoryState build() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:5000',
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );

    // Initial mock orders to guarantee instant display even if server is offline
    final initialOrders = _getInitialMockOrders();
    _fetchOrders();
    return OrdersHistoryState(orders: initialOrders);
  }

  Future<void> _fetchOrders() async {
    try {
      final response = await _dio.get('/api/orders?limit=50');
      if (response.data != null && response.data['data'] != null) {
        final list = (response.data['data'] as List)
            .map((item) => OrderHistoryRecord.fromJson(item as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          state = state.copyWith(orders: list, isLoading: false);
        }
      }
    } catch (_) {
      // Retain offline seed list
    }
  }

  void addCompletedOrder(OrderHistoryRecord order) {
    state = state.copyWith(orders: [order, ...state.orders]);
  }

  List<OrderHistoryRecord> _getInitialMockOrders() {
    final now = DateTime.now();
    return [
      OrderHistoryRecord(
        id: 'ORD-1003',
        totalAmount: 1850.0,
        totalCost: 615.0,
        status: 'COMPLETED',
        createdAt: now.subtract(const Duration(minutes: 18)),
        items: const [
          OrderHistoryItem(
            id: 'item-1',
            recipeName: 'สเต๊กเนื้อวากิวริบอาย A5',
            category: 'Main Course',
            quantity: 2,
            pricePerUnit: 650.0,
            costPerUnit: 215.0,
          ),
          OrderHistoryItem(
            id: 'item-2',
            recipeName: 'ซุปเห็ดทรัฟเฟิลดำเข้มข้น',
            category: 'Soup',
            quantity: 2,
            pricePerUnit: 275.0,
            costPerUnit: 92.5,
          ),
        ],
      ),
      OrderHistoryRecord(
        id: 'ORD-1002',
        totalAmount: 1240.0,
        totalCost: 410.0,
        status: 'COMPLETED',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 12)),
        items: const [
          OrderHistoryItem(
            id: 'item-3',
            recipeName: 'สปาเกตตีคาโบนาราครีมชีส',
            category: 'Pasta',
            quantity: 2,
            pricePerUnit: 280.0,
            costPerUnit: 88.0,
          ),
          OrderHistoryItem(
            id: 'item-4',
            recipeName: 'สลัดแซลมอนรมควันอะโวคาโด',
            category: 'Salad',
            quantity: 2,
            pricePerUnit: 340.0,
            costPerUnit: 117.0,
          ),
        ],
      ),
      OrderHistoryRecord(
        id: 'ORD-1001',
        totalAmount: 760.0,
        totalCost: 260.0,
        status: 'COMPLETED',
        createdAt: now.subtract(const Duration(hours: 2, minutes: 45)),
        items: const [
          OrderHistoryItem(
            id: 'item-5',
            recipeName: 'สเต๊กเนื้อวากิวริบอาย A5',
            category: 'Main Course',
            quantity: 1,
            pricePerUnit: 650.0,
            costPerUnit: 215.0,
          ),
          OrderHistoryItem(
            id: 'item-6',
            recipeName: 'ชาเขียวมัทฉะลาเต้เย็น',
            category: 'Beverage',
            quantity: 1,
            pricePerUnit: 110.0,
            costPerUnit: 45.0,
          ),
        ],
      ),
    ];
  }
}

final ordersHistoryProvider =
    NotifierProvider<OrdersHistoryNotifier, OrdersHistoryState>(
  OrdersHistoryNotifier.new,
);
