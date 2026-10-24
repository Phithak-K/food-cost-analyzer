import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/capsule_toast.dart';
import '../models/kitchen_ticket.dart';
import '../providers/kds_provider.dart';
import '../widgets/portion_guide_dialog.dart';

class KdsScreen extends ConsumerWidget {
  const KdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(kdsProvider);

    final cookingTickets = tickets.where((t) => t.status == KitchenOrderStatus.cooking).toList();
    final readyTickets = tickets.where((t) => t.status == KitchenOrderStatus.ready).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // KDS Header Bar
            _buildKdsHeader(context, cookingCount: cookingTickets.length, readyCount: readyTickets.length),

            // Main Queue Area
            Expanded(
              child: tickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_outline_rounded, size: 36, color: AppTheme.primaryNeon),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'ไม่มีออเดอร์ค้างในครัว',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'เมื่อแคชเชียร์คีย์ออเดอร์ที่หน้า POS บิลจะเด้งเข้ามาที่จอนี้ทันที',
                            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 3;
                        if (constraints.maxWidth < 750) {
                          crossAxisCount = 1;
                        } else if (constraints.maxWidth < 1150) {
                          crossAxisCount = 2;
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 310,
                          ),
                          itemCount: tickets.length,
                          itemBuilder: (context, index) {
                            final ticket = tickets[index];
                            return _buildTicketCard(context, ref, ticket);
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

  Widget _buildKdsHeader(BuildContext context, {required int cookingCount, required int readyCount}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundElevated,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.restaurant_rounded, color: AppTheme.warning, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kitchen Display System (KDS) / จอคิวอาหารในครัว',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, letterSpacing: -0.3),
                ),
                Text(
                  'รับออเดอร์เรียลไทม์ พร้อมปุ่มเปิดดู Portion Guide เพื่อคุมต้นทุนไม่ให้เชฟตักวัตถุดิบเกินสเปก',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          // Queue badges
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_bottom_rounded, size: 14, color: AppTheme.warning),
                const SizedBox(width: 6),
                Text(
                  'กำลังปรุง: $cookingCount บิล',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.warning),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppTheme.primaryNeon),
                const SizedBox(width: 6),
                Text(
                  'พร้อมเสิร์ฟ: $readyCount บิล',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryNeon),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, WidgetRef ref, KitchenTicket ticket) {
    final isReady = ticket.status == KitchenOrderStatus.ready;
    final minutes = ticket.minutesElapsed;

    Color urgencyColor = AppTheme.primary;
    if (minutes >= 15) {
      urgencyColor = AppTheme.danger;
    } else if (minutes >= 8) {
      urgencyColor = AppTheme.warning;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted.withValues(alpha: isReady ? 0.4 : 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReady
              ? AppTheme.primary.withValues(alpha: 0.5)
              : urgencyColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ticket Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: urgencyColor.withValues(alpha: isReady ? 0.1 : 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Text(
                  ticket.orderNumber,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ticket.tableNumber,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: urgencyColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 12, color: urgencyColor),
                      const SizedBox(width: 4),
                      Text(
                        isReady ? 'ปรุงเสร็จแล้ว' : '$minutes นาที',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: urgencyColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dishes List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: ticket.items.length,
              separatorBuilder: (_, _) => const Divider(color: AppTheme.border, height: 10),
              itemBuilder: (context, index) {
                final item = ticket.items[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'x${item.quantity}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primaryNeon),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.recipe.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                          if (item.note != null && item.note!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '• ${item.note}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.warning, fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Portion Guide button
                    IconButton(
                      icon: const Icon(Icons.scale_rounded, size: 16),
                      tooltip: 'ดูสเปกสัดส่วนวัตถุดิบ (Portion Guide)',
                      style: IconButton.styleFrom(
                        foregroundColor: AppTheme.primaryNeon,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(28, 28),
                      ),
                      onPressed: () => showPortionGuideDialog(context, item.recipe),
                    ),
                  ],
                );
              },
            ),
          ),

          // Card Action Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(kdsProvider.notifier).toggleStatus(ticket.id);
                  CapsuleToast.showSuccess(
                    context,
                    isReady
                        ? 'ออเดอร์ ${ticket.orderNumber} เสิร์ฟเรียบร้อย'
                        : 'ออเดอร์ ${ticket.orderNumber} ปรุงเสร็จแล้ว พร้อมเสิร์ฟ!',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReady ? Colors.white.withValues(alpha: 0.1) : AppTheme.primary,
                  foregroundColor: isReady ? AppTheme.textPrimary : const Color(0xFF0B0F19),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(
                  isReady ? Icons.done_all_rounded : Icons.check_circle_rounded,
                  size: 16,
                ),
                label: Text(
                  isReady ? 'เสิร์ฟอาหารแล้ว (Done)' : 'ปรุงเสร็จแล้ว (Mark Ready)',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
