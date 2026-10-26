import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../models/order_history.dart';
import '../providers/orders_history_provider.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(ordersHistoryProvider);
    final isDesktop = Responsive.isDesktop(context);

    final filteredOrders = historyState.orders.where((order) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final matchesId = order.id.toLowerCase().contains(query);
      final matchesItem = order.items.any((i) => i.recipeName.toLowerCase().contains(query));
      return matchesId || matchesItem;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(context, historyState),

            // Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KPI Summary Cards
                    _buildKpiSummary(historyState, isDesktop),
                    const SizedBox(height: 24),

                    // Search & Filter Bar
                    _buildSearchBar(),
                    const SizedBox(height: 16),

                    // Order History List
                    if (filteredOrders.isEmpty)
                      _buildEmptyState()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredOrders.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildOrderCard(context, filteredOrders[index]);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, OrdersHistoryState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundElevated,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF38BDF8), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ประวัติการขาย (Sales & Order History)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isNarrow)
                      Text(
                        'บันทึกรายการขายทั้งหมด การตัดสต็อกต้นทุน และมาร์จิ้นกำไรรายบิล',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_rounded, size: 14, color: AppTheme.primaryNeon),
                    const SizedBox(width: 4),
                    Text(
                      '${state.totalOrdersCount} บิล',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildKpiSummary(OrdersHistoryState state, bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int count;
        final double aspectRatio;
        if (constraints.maxWidth < 520) {
          count = 1;
          aspectRatio = 2.8;
        } else if (constraints.maxWidth < 960) {
          count = 2;
          aspectRatio = 2.0;
        } else {
          count = 4;
          aspectRatio = isDesktop ? 2.3 : 1.9;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: count,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: aspectRatio,
          children: [
            _buildKpiCard(
              title: 'ยอดขายรวม (Total Revenue)',
              value: '฿${state.totalRevenue.toStringAsFixed(0)}',
              icon: Icons.payments_rounded,
              accentColor: const Color(0xFF38BDF8),
              subtitle: 'จาก ${state.totalOrdersCount} รายการสั่งซื้อ',
            ),
            _buildKpiCard(
              title: 'กำไรขั้นต้นรวม (Gross Profit)',
              value: '฿${state.totalProfit.toStringAsFixed(0)}',
              icon: Icons.trending_up_rounded,
              accentColor: AppTheme.primaryNeon,
              subtitle: 'หักต้นทุนวัตถุดิบ BOM เรียบร้อย',
            ),
            _buildKpiCard(
              title: 'ต้นทุนวัตถุดิบรวม (BOM Cost)',
              value: '฿${state.totalCost.toStringAsFixed(0)}',
              icon: Icons.inventory_2_rounded,
              accentColor: const Color(0xFFF59E0B),
              subtitle: 'คำนวณตามสูตรอาหารจริง',
            ),
            _buildKpiCard(
              title: 'อัตรากำไรเฉลี่ย (Profit Margin)',
              value: '${state.overallMargin.toStringAsFixed(1)}%',
              icon: Icons.pie_chart_rounded,
              accentColor: const Color(0xFFA855F7),
              subtitle: 'เป้าหมายมาตรฐานร้านอาหาร > 65%',
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.backgroundElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'ค้นหาด้วยเลขที่บิล (ORD-...) หรือชื่อเมนูอาหาร...',
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              ),
            ),
          ),
        ),
        if (_searchQuery.isNotEmpty) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            const Text(
              'ไม่พบรายการขายที่ตรงกับเงื่อนไข',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'ลองค้นหาด้วยคำอื่น หรือเปิดรับออเดอร์ใหม่ที่หน้า Quick POS',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderHistoryRecord order) {
    final timeStr =
        '${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')} น.';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '#${order.id}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryNeon,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    timeStr,
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text(
                      'สำเร็จ (COMPLETED)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Items summary
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.quantity}x',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryNeon),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.recipeName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ),
                  Text(
                    '฿${item.subtotal.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Financial Summary Footer
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 10,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _buildStatBadge(
                    'ต้นทุน BOM',
                    '฿${order.totalCost.toStringAsFixed(0)}',
                    const Color(0xFFF59E0B),
                  ),
                  _buildStatBadge(
                    'กำไรสุทธิ',
                    '+฿${order.totalProfit.toStringAsFixed(0)}',
                    AppTheme.primaryNeon,
                  ),
                  _buildStatBadge(
                    'Margin',
                    '${order.marginPercent.toStringAsFixed(1)}%',
                    const Color(0xFFA855F7),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ยอดชำระ: ', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  Text(
                    '฿${order.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.print_outlined, size: 20, color: AppTheme.textSecondary),
                    tooltip: 'พิมพ์ใบเสร็จ',
                    onPressed: () => _showReceiptModal(context, order),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  void _showReceiptModal(BuildContext context, OrderHistoryRecord order) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2433),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_rounded, size: 36, color: AppTheme.primaryNeon),
              const SizedBox(height: 10),
              const Text('ใบเสร็จรับเงิน / สรุปบิล', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('#${order.id}', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 16),
              const Divider(),
              ...order.items.map((i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('${i.quantity}x ${i.recipeName}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                        ),
                        Text('฿${i.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ยอดรวมสุทธิ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('฿${order.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primaryNeon)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: const Color(0xFF0B0F19),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('ปิดหน้าต่าง', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
