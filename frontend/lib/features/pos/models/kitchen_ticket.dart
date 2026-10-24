import '../../recipes/models/recipe.dart';

enum KitchenOrderStatus {
  cooking,
  ready,
  served;

  String get label {
    switch (this) {
      case KitchenOrderStatus.cooking:
        return 'กำลังปรุง (Cooking)';
      case KitchenOrderStatus.ready:
        return 'ปรุงเสร็จแล้ว (Ready)';
      case KitchenOrderStatus.served:
        return 'เสิร์ฟแล้ว (Served)';
    }
  }
}

class KitchenOrderItem {
  final Recipe recipe;
  final int quantity;
  final String? note;

  const KitchenOrderItem({
    required this.recipe,
    required this.quantity,
    this.note,
  });
}

class KitchenTicket {
  final String id;
  final String orderNumber;
  final String orderType; // 'ทานที่ร้าน (Dine-In)' or 'กลับบ้าน (Takeaway)'
  final String tableNumber;
  final DateTime createdAt;
  final List<KitchenOrderItem> items;
  final KitchenOrderStatus status;

  const KitchenTicket({
    required this.id,
    required this.orderNumber,
    this.orderType = 'ทานที่ร้าน (Dine-In)',
    this.tableNumber = 'โต๊ะ 01',
    required this.createdAt,
    required this.items,
    this.status = KitchenOrderStatus.cooking,
  });

  int get minutesElapsed => DateTime.now().difference(createdAt).inMinutes;
  DateTime get orderedAt => createdAt;

  KitchenTicket copyWith({
    String? id,
    String? orderNumber,
    String? orderType,
    String? tableNumber,
    DateTime? createdAt,
    List<KitchenOrderItem>? items,
    KitchenOrderStatus? status,
  }) {
    return KitchenTicket(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      orderType: orderType ?? this.orderType,
      tableNumber: tableNumber ?? this.tableNumber,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      status: status ?? this.status,
    );
  }
}
