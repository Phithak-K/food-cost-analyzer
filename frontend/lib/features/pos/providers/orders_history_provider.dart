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
        id: 'ORD-1010',
        totalAmount: 935.0,
        totalCost: 268.0,
        status: 'COMPLETED',
        createdAt: now.subtract(const Duration(minutes: 6)),
        items: const [
          OrderHistoryItem(
            id: 'item-10-1',
            recipeName: 'โทสต์แซลมอนรมควันอะโวคาโด',
            category: 'Main Course',
            quantity: 2,
            pricePerUnit: 290.0,
            costPerUnit: 82.0,
          ),
          OrderHistoryItem(
            id: 'item-10-2',
            recipeName: 'เดอร์ตี้คอฟฟี่นมเย็นจัด',
            category: 'Beverage',
            quantity: 1,
            pricePerUnit: 145.0,
            costPerUnit: 34.0,
          ),
          OrderHistoryItem(
            id: 'item-10-3',
            recipeName: 'ครัวซองต์เนยฝรั่งเศสสด',
            category: 'Bakery',
            quantity: 1,
            pricePerUnit: 120.0,
            costPerUnit: 35.0,
          ),
        ],
      ),
      OrderHistoryRecord(
        id: 'ORD-1009',
        totalAmount: 1850.0,
        totalCost: 615.0,
        status: 'COMPLETED',
        createdAt: now.subtract(const Duration(minutes: 24)),
        items: const [
          OrderHistoryItem(
            id: 'item-9-1',
            recipeName: 'สเต๊กเนื้อวากิวริบอาย A5',
            category: 'Main Course',
            quantity: 1,
            pricePerUnit: 1450.0,
            costPerUnit: 485.0,
          ),
          OrderHistoryItem(
            id: 'item-9-2',
            recipeName: 'เฟรนช์ฟรายส์ทรัฟเฟิลพาร์เมซาน',
            category: 'Appetizer',
            quantity: 1,
            pricePerUnit: 165.0,
            costPerUnit: 42.0,
          ),
          OrderHistoryItem(
            id: 'item-9-3',
            recipeName: 'มัทฉะลาเต้พรีเมียมเย็น',
            category: 'Beverage',
            quantity: 1,
            pricePerUnit: 155.0,
            costPerUnit: 38.0,
          ),
        ],
      ),
      OrderHistoryRecord(
        id: 'ORD-1008',
        totalAmount: 1360.0,
        totalCost: 395.0,
        status: 'COMPLETED',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 5)),
        items: const [
          OrderHistoryItem(
            id: 'item-8-1',
            recipeName: 'สเต๊กแซลมอนย่างนอร์เวย์',
            category: 'Main Course',
            quantity: 2,
            pricePerUnit: 490.0,
            costPerUnit: 142.0,
          ),
          OrderHistoryItem(
            id: 'item-8-2',
            recipeName: 'เฟตตูชินีครีมทรัฟเฟิล',
            category: 'Pasta',
            quantity: 1,
            pricePerUnit: 380.0,
            costPerUnit: 111.0,
          ),
        ],
      ),
      OrderHistoryRecord(
        id: 'ORD-1007',
        totalAmount: 645.0,
        totalCost: 172.0,
        status: 'COMPLETED',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 48)),
        items: const [
          OrderHistoryItem(
            id: 'item-7-1',
            recipeName: 'สเต๊กพอร์คชอปคุโรบูตะ',
            category: 'Main Course',
            quantity: 1,
            pricePerUnit: 390.0,
            costPerUnit: 98.0,
          ),
          OrderHistoryItem(
            id: 'item-7-2',
            recipeName: 'โคลด์บรูว์ยูซุเสาวรส',
            category: 'Beverage',
            quantity: 1,
            pricePerUnit: 175.0,
            costPerUnit: 44.0,
          ),
          OrderHistoryItem(
            id: 'item-7-3',
            recipeName: 'ผักโขมอบชีส',
            category: 'Appetizer',
            quantity: 1,
            pricePerUnit: 190.0,
            costPerUnit: 52.0,
          ),
        ],
      ),
      OrderHistoryRecord(
        id: 'ORD-1006',
        totalAmount: 1100.0,
        totalCost: 312.0,
        status: 'COMPLETED',
        createdAt: now.subtract(const Duration(hours: 2, minutes: 15)),
        items: const [
          OrderHistoryItem(
            id: 'item-6-1',
            recipeName: 'ข้าวผัดกะเพราเนื้อวากิวไข่ดอง',
            category: 'Main Course',
            quantity: 3,
            pricePerUnit: 220.0,
            costPerUnit: 64.0,
          ),
          OrderHistoryItem(
            id: 'item-6-2',
            recipeName: 'เค้กช็อกโกแลตลาวาเบลเยียม',
            category: 'Dessert',
            quantity: 2,
            pricePerUnit: 220.0,
            costPerUnit: 60.0,
          ),
        ],
      ),
      OrderHistoryRecord(
        id: 'ORD-1005',
        totalAmount: 780.0,
        totalCost: 218.0,
        status: 'COMPLETED',
        createdAt: now.subtract(const Duration(hours: 3, minutes: 30)),
        items: const [
          OrderHistoryItem(
            id: 'item-5-1',
            recipeName: 'สปาเก็ตตี้พริกแห้งกุ้งลายเสือ',
            category: 'Pasta',
            quantity: 2,
            pricePerUnit: 260.0,
            costPerUnit: 74.0,
          ),
          OrderHistoryItem(
            id: 'item-5-2',
            recipeName: 'สปาร์คกลิ้งยูซุเอสเพรสโซ่',
            category: 'Beverage',
            quantity: 1,
            pricePerUnit: 165.0,
            costPerUnit: 39.0,
          ),
        ],
      ),
      OrderHistoryRecord(
        id: 'ORD-1004',
        totalAmount: 560.0,
        totalCost: 148.0,
        status: 'COMPLETED',
        createdAt: now.subtract(const Duration(hours: 4, minutes: 10)),
        items: const [
          OrderHistoryItem(
            id: 'item-4-1',
            recipeName: 'กุ้งลายเสือผัดเนยกระเทียม',
            category: 'Seafood',
            quantity: 2,
            pricePerUnit: 280.0,
            costPerUnit: 74.0,
          ),
        ],
      ),
      OrderHistoryRecord(
        id: 'ORD-1003',
        totalAmount: 1850.0,
        totalCost: 615.0,
        status: 'COMPLETED',
        createdAt: now.subtract(const Duration(hours: 5, minutes: 25)),
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
        createdAt: now.subtract(const Duration(hours: 6, minutes: 40)),
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
        createdAt: now.subtract(const Duration(hours: 7, minutes: 55)),
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
