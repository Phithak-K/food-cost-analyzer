import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/kds_websocket_service.dart';
import '../../../core/utils/audio_chime.dart';
import '../../recipes/providers/recipes_provider.dart';
import '../models/cart_item.dart';
import '../models/kitchen_ticket.dart';

class KdsNotifier extends Notifier<List<KitchenTicket>> {
  @override
  List<KitchenTicket> build() {
    final recipes = ref.watch(recipesProvider);
    final recipeMap = {for (final r in recipes) r.id: r};

    // Initial realistic queue tickets for demonstration
    return [
      if (recipeMap.containsKey('rec_1') && recipeMap.containsKey('rec_2'))
        KitchenTicket(
          id: 'kds_1',
          orderNumber: 'ORD-7801',
          tableNumber: 'โต๊ะ 04',
          orderType: 'ทานที่ร้าน (Dine-In)',
          createdAt: DateTime.now().subtract(const Duration(minutes: 6)),
          items: [
            KitchenOrderItem(
              recipe: recipeMap['rec_1']!,
              quantity: 2,
              note: 'สุก Medium-Well',
            ),
            KitchenOrderItem(
              recipe: recipeMap['rec_2']!,
              quantity: 1,
              note: 'เพิ่มพริกไทยดำ',
            ),
          ],
          status: KitchenOrderStatus.cooking,
        ),
      if (recipeMap.containsKey('rec_3'))
        KitchenTicket(
          id: 'kds_2',
          orderNumber: 'ORD-7802',
          tableNumber: 'โต๊ะ 08',
          orderType: 'ทานที่ร้าน (Dine-In)',
          createdAt: DateTime.now().subtract(const Duration(minutes: 14)),
          items: [
            KitchenOrderItem(
              recipe: recipeMap['rec_3']!,
              quantity: 1,
              note: 'ความสุก Medium-Rare',
            ),
          ],
          status: KitchenOrderStatus.cooking,
        ),
      if (recipeMap.containsKey('rec_4') && recipeMap.containsKey('rec_5'))
        KitchenTicket(
          id: 'kds_3',
          orderNumber: 'ORD-7803',
          tableNumber: 'รับกลับบ้าน (Takeaway)',
          orderType: 'กลับบ้าน (Takeaway)',
          createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
          items: [
            KitchenOrderItem(recipe: recipeMap['rec_4']!, quantity: 2),
            KitchenOrderItem(
              recipe: recipeMap['rec_5']!,
              quantity: 1,
              note: 'แยกซอส',
            ),
          ],
          status: KitchenOrderStatus.cooking,
        ),
    ];
  }

  void addTicketFromCart(
    String orderNumber,
    List<CartItem> cartItems, {
    String table = 'โต๊ะ 01',
    String orderType = 'ทานที่ร้าน (Dine-In)',
  }) {
    final newTicket = KitchenTicket(
      id: 'kds_${DateTime.now().millisecondsSinceEpoch}',
      orderNumber: orderNumber,
      tableNumber: table,
      orderType: orderType,
      createdAt: DateTime.now(),
      items: cartItems
          .map((c) => KitchenOrderItem(recipe: c.recipe, quantity: c.quantity))
          .toList(),
      status: KitchenOrderStatus.cooking,
    );

    addTicket(newTicket);
  }

  void markAsServed(String ticketId, {bool broadcast = true}) {
    updateTicketStatus(
      ticketId,
      KitchenOrderStatus.served,
      broadcast: broadcast,
    );
  }

  void addTicket(KitchenTicket ticket) {
    if (state.any(
      (t) => t.id == ticket.id || t.orderNumber == ticket.orderNumber,
    )) {
      return;
    }
    state = [ticket, ...state];
  }

  void addTicketFromWebSocket(KitchenTicket ticket) {
    addTicket(ticket);
    AudioChime.play();
  }

  void toggleStatus(String ticketId) {
    for (final ticket in state) {
      if (ticket.id == ticketId || ticket.orderNumber == ticketId) {
        final nextStatus = ticket.status == KitchenOrderStatus.cooking
            ? KitchenOrderStatus.ready
            : KitchenOrderStatus.served;
        updateTicketStatus(ticketId, nextStatus);
        return;
      }
    }
  }

  void updateTicketStatus(
    String ticketId,
    KitchenOrderStatus status, {
    String? orderNumber,
    bool broadcast = true,
  }) {
    String? matchedOrderNumber = orderNumber;
    state = [
      for (final ticket in state)
          if (ticket.id == ticketId ||
              ticket.orderNumber == ticketId ||
              (orderNumber != null && ticket.orderNumber == orderNumber) ||
              ticket.orderNumber.replaceAll('#', '').trim().toLowerCase() ==
                  ticketId.replaceAll('#', '').trim().toLowerCase() ||
              (orderNumber != null &&
                  ticket.orderNumber.replaceAll('#', '').trim().toLowerCase() ==
                      orderNumber.replaceAll('#', '').trim().toLowerCase()))
            () {
              matchedOrderNumber = ticket.orderNumber;
              return ticket.copyWith(status: status);
            }()
          else
            ticket,
    ];

    if (broadcast) {
      try {
        ref
            .read(kdsWebSocketProvider.notifier)
            .broadcastStatusChange(
              ticketId,
              status,
              orderNumber: matchedOrderNumber ?? orderNumber,
            );
      } catch (_) {}
    }
  }

  void removeTicket(String ticketId) {
    state = state.where((t) => t.id != ticketId).toList();
  }
}

final kdsProvider = NotifierProvider<KdsNotifier, List<KitchenTicket>>(
  KdsNotifier.new,
);
