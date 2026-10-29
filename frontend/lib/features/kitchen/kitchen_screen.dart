import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/capsule_toast.dart';
import '../../../core/services/kds_websocket_service.dart';
import '../pos/models/kitchen_ticket.dart';
import '../pos/providers/kds_provider.dart';
import 'widgets/portion_guide_modal.dart';

class KitchenScreen extends ConsumerStatefulWidget {
  const KitchenScreen({super.key});

  @override
  ConsumerState<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends ConsumerState<KitchenScreen> {
  // Tab filter: 0 = ทั้งหมด, 1 = กำลังทำ (Cooking), 2 = เสร็จแล้ว (Done)
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(kdsProvider);

    final cookingTickets = tickets.where((t) => t.status == KitchenOrderStatus.cooking).toList();
    final doneTickets = tickets.where((t) => t.status == KitchenOrderStatus.ready).toList();

    List<KitchenTicket> displayTickets;
    if (_selectedTab == 1) {
      displayTickets = cookingTickets;
    } else if (_selectedTab == 2) {
      displayTickets = doneTickets;
    } else {
      displayTickets = tickets;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildHeader(context, cookingCount: cookingTickets.length, doneCount: doneTickets.length),

            // Content Area
            Expanded(
              child: displayTickets.isEmpty
                  ? _buildEmptyState()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 3;
                        if (constraints.maxWidth < 800) {
                          crossAxisCount = 1;
                        } else if (constraints.maxWidth < 1200) {
                          crossAxisCount = 2;
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 380,
                          ),
                          itemCount: displayTickets.length,
                          itemBuilder: (context, index) {
                            return _buildOrderTicketCard(context, displayTickets[index]);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required int cookingCount,
    required int doneCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1050;

        final syncIndicator = Builder(
          builder: (context) {
            final wsState = ref.watch(kdsWebSocketProvider);
            final isConnected = wsState.status == WebSocketConnectionStatus.connected;
            final isConnecting = wsState.status == WebSocketConnectionStatus.connecting;

            final color = isConnected
                ? const Color(0xFF10B981)
                : (isConnecting ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isConnected
                            ? 'Live Sync'
                            : (isConnecting ? 'Sync (กำลังต่อ...)' : 'Sync (ออฟไลน์)'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'ทดสอบเสียงกระดิ่งครัว (Bell Chime)',
                  icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFFF59E0B), size: 20),
                  onPressed: () {
                    ref.read(kdsWebSocketProvider.notifier).testChime();
                    CapsuleToast.showInfo(context, 'ทดสอบเสียงกระดิ่งครัว (Ding!)');
                  },
                ),
              ],
            );
          },
        );

        final filterTabs = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFilterTab(0, 'ทั้งหมด (${cookingCount + doneCount})', null),
                const SizedBox(width: 4),
                _buildFilterTab(1, 'กำลังทำ ($cookingCount)', const Color(0xFFF59E0B)),
                const SizedBox(width: 4),
                _buildFilterTab(2, 'เสร็จแล้ว ($doneCount)', const Color(0xFF10B981)),
              ],
            ),
          ),
        );

        return Container(
          padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppTheme.backgroundElevated,
            border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
          ),
          child: isWide
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                      ),
                      child: const Icon(
                        Icons.soup_kitchen_rounded,
                        size: 24,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'จอคิวอาหารในครัว (Kitchen Display System - KDS)',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            'คุมเวลาเสิร์ฟ ตรวจสอบสถานะ และเปิดดูคู่มือสเปกการตักปรุง (Portion Guide) เพื่อคุม Food Cost %',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    syncIndicator,
                    const SizedBox(width: 12),
                    filterTabs,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                          ),
                          child: const Icon(
                            Icons.soup_kitchen_rounded,
                            size: 20,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'จอคิวอาหาร (KDS)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                          ),
                        ),
                        syncIndicator,
                      ],
                    ),
                    const SizedBox(height: 10),
                    filterTabs,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildFilterTab(int index, String label, Color? dotColor) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primary.withValues(alpha: 0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.soup_kitchen_outlined,
              size: 38,
              color: Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ไม่มีออเดอร์ในหมวดหมู่นี้',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'เมื่อแคชเชียร์รับออเดอร์ที่หน้า Quick POS บิลจะเด้งเข้าสู่จอครัวทันที',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTicketCard(BuildContext context, KitchenTicket ticket) {
    final isCooking = ticket.status == KitchenOrderStatus.cooking;
    final accentColor = isCooking ? const Color(0xFFF59E0B) : const Color(0xFF10B981);

    final timeStr =
        '${ticket.orderedAt.hour.toString().padLeft(2, '0')}:${ticket.orderedAt.minute.toString().padLeft(2, '0')} น.';
    final minutesAgo = DateTime.now().difference(ticket.orderedAt).inMinutes;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withValues(alpha: isCooking ? 0.45 : 0.25),
          width: isCooking ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isCooking ? 0.08 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order Ticket Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(17),
                topRight: Radius.circular(17),
              ),
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text(
                            '#${ticket.orderNumber}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: ticket.isTakeaway
                                ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
                                : const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: ticket.isTakeaway
                                  ? const Color(0xFF38BDF8).withValues(alpha: 0.4)
                                  : const Color(0xFF10B981).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                ticket.isTakeaway
                                    ? Icons.shopping_bag_outlined
                                    : Icons.table_restaurant_rounded,
                                size: 12,
                                color: ticket.isTakeaway
                                    ? const Color(0xFF38BDF8)
                                    : const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ticket.isTakeaway ? 'กลับบ้าน' : ticket.tableNumber,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: ticket.isTakeaway ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Elapsed time pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCooking
                        ? (minutesAgo > 15 ? AppTheme.danger.withValues(alpha: 0.15) : const Color(0xFFF59E0B).withValues(alpha: 0.15))
                        : const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCooking ? Icons.timer_outlined : Icons.check_circle_outline_rounded,
                        size: 13,
                        color: accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCooking ? '$minutesAgo นาทีที่แล้ว' : 'ปรุงเสร็จแล้ว',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accentColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu Items List with Portion Guide Button
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: ticket.items.length,
              separatorBuilder: (context, index) => const Divider(color: AppTheme.border, height: 12),
              itemBuilder: (context, idx) {
                final item = ticket.items[idx];
                return Row(
                  children: [
                    // Quantity Badge
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${item.quantity}x',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryNeon,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Recipe Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.recipe.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            item.recipe.category,
                            style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    // ⚖️ Portion Guide Button (ฟังก์ชันคุมต้นทุนเชฟ)
                    Tooltip(
                      message: 'สเปกการปรุง (Portion Guide)',
                      child: InkWell(
                        key: Key('portion_guide_${item.recipe.id}'),
                        onTap: () => showKitchenPortionGuideModal(context, item.recipe),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.scale_rounded,
                                size: 13,
                                color: AppTheme.primaryNeon,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'สเปก',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryNeon,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const Divider(color: AppTheme.border, height: 1),

          // Status Action Buttons: 'กำลังทำ (Cooking)' vs 'เสร็จแล้ว (Done)'
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 'กำลังทำ (Cooking)' Button
                Expanded(
                  child: OutlinedButton(
                    key: Key('status_cooking_${ticket.id}'),
                    onPressed: isCooking
                        ? null
                        : () {
                            ref.read(kdsProvider.notifier).updateTicketStatus(ticket.id, KitchenOrderStatus.cooking);
                            CapsuleToast.showInfo(context, 'ออเดอร์ #${ticket.orderNumber} กำลังปรุงอาหาร');
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      backgroundColor: isCooking ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : Colors.transparent,
                      side: BorderSide(
                        color: isCooking ? const Color(0xFFF59E0B) : AppTheme.border,
                        width: isCooking ? 1.5 : 1,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.soup_kitchen_rounded, size: 14, color: Color(0xFFF59E0B)),
                          SizedBox(width: 4),
                          Text('กำลังทำ (Cooking)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 'เสร็จแล้ว (Done)' Button
                Expanded(
                  child: ElevatedButton(
                    key: Key('status_done_${ticket.id}'),
                    onPressed: !isCooking
                        ? null
                        : () {
                            ref.read(kdsProvider.notifier).updateTicketStatus(ticket.id, KitchenOrderStatus.ready);
                            CapsuleToast.showSuccess(context, 'ออเดอร์ #${ticket.orderNumber} ปรุงเสร็จพร้อมเสิร์ฟแล้ว!');
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: const Color(0xFF0B0F19),
                      disabledBackgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                      disabledForegroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle_rounded, size: 14),
                          SizedBox(width: 4),
                          Text('เสร็จแล้ว (Done)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),

                // 'เสิร์ฟแล้ว (Served)' Button (Active when ticket is ready)
                if (ticket.status == KitchenOrderStatus.ready) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      key: Key('status_served_${ticket.id}'),
                      onPressed: () {
                        ref.read(kdsProvider.notifier).markAsServed(ticket.id);
                        CapsuleToast.showSuccess(context, 'ออเดอร์ #${ticket.orderNumber} เสิร์ฟเรียบร้อยแล้ว!');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        foregroundColor: const Color(0xFF0B0F19),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.room_service_rounded, size: 14),
                            SizedBox(width: 4),
                            Text('เสิร์ฟแล้ว', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
