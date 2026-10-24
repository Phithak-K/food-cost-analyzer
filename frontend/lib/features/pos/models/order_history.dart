class OrderHistoryItem {
  final String id;
  final String recipeName;
  final String category;
  final int quantity;
  final double pricePerUnit;
  final double costPerUnit;

  const OrderHistoryItem({
    required this.id,
    required this.recipeName,
    required this.category,
    required this.quantity,
    required this.pricePerUnit,
    required this.costPerUnit,
  });

  double get subtotal => pricePerUnit * quantity;
  double get totalCost => costPerUnit * quantity;
  double get profit => subtotal - totalCost;

  factory OrderHistoryItem.fromJson(Map<String, dynamic> json) {
    final recipe = json['recipe'] as Map<String, dynamic>?;
    return OrderHistoryItem(
      id: json['id'] as String? ?? '',
      recipeName: recipe?['name'] as String? ?? json['recipeName'] as String? ?? 'เมนูอาหาร',
      category: recipe?['category'] as String? ?? json['category'] as String? ?? 'ทั่วไป',
      quantity: json['quantity'] as int? ?? 1,
      pricePerUnit: double.tryParse(json['pricePerUnit']?.toString() ?? '0') ?? 0.0,
      costPerUnit: double.tryParse(json['costPerUnit']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class OrderHistoryRecord {
  final String id;
  final double totalAmount;
  final double totalCost;
  final String status;
  final DateTime createdAt;
  final List<OrderHistoryItem> items;

  const OrderHistoryRecord({
    required this.id,
    required this.totalAmount,
    required this.totalCost,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  double get totalProfit => totalAmount - totalCost;
  double get marginPercent => totalAmount > 0 ? (totalProfit / totalAmount) * 100 : 0.0;
  int get totalItemCount => items.fold(0, (sum, i) => sum + i.quantity);

  factory OrderHistoryRecord.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>?)
            ?.map((i) => OrderHistoryItem.fromJson(i as Map<String, dynamic>))
            .toList() ??
        [];

    return OrderHistoryRecord(
      id: json['id'] as String? ?? 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
      totalCost: double.tryParse(json['totalCost']?.toString() ?? '0') ?? 0.0,
      status: json['status'] as String? ?? 'COMPLETED',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      items: itemsList,
    );
  }
}
