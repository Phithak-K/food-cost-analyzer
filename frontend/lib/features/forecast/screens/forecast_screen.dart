import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/capsule_toast.dart';
import '../../../core/widgets/glass_container.dart';
import '../models/ingredient_forecast.dart';
import '../providers/forecast_provider.dart';

class ForecastScreen extends ConsumerStatefulWidget {
  const ForecastScreen({super.key});

  @override
  ConsumerState<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends ConsumerState<ForecastScreen> {
  String _searchQuery = '';
  ForecastRiskLevel? _selectedFilter;
  bool _showReorderOnly = false;

  @override
  Widget build(BuildContext context) {
    final forecastState = ref.watch(forecastProvider);
    final summary = forecastState.data;

    final filteredItems = summary.items.where((item) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = item.ingredientName.toLowerCase().contains(q);
        final matchesCat = item.category.toLowerCase().contains(q);
        if (!matchesName && !matchesCat) return false;
      }
      if (_selectedFilter != null && item.riskLevel != _selectedFilter) {
        return false;
      }
      if (_showReorderOnly && item.suggestedOrder7Days <= 0) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header
                    _buildHeader(context, forecastState.isLoading),
                    const SizedBox(height: 20),

                    // KPI Metric Cards (Responsive 1/2/4 cols)
                    _buildKpiMetrics(summary),
                    const SizedBox(height: 24),

                    // Search & Filter Toolbar
                    _buildFilterToolbar(summary),
                  ],
                ),
              ),
            ),

            // Virtualized List of Forecast Cards
            if (filteredItems.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(child: _buildEmptyState()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList.separated(
                  itemCount: filteredItems.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return RepaintBoundary(
                      child: _buildForecastCard(filteredItems[index]),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isLoading) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        final titleColumn = Column(
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
                  child: const Icon(Icons.auto_graph_rounded, color: Color(0xFFF59E0B), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'พยากรณ์วัตถุดิบ & ป้องกันของเสีย (AI Waste & Demand Forecast)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'คำนวณอัตราบริโภคจริงจากประวัติการขาย (BOM Sales Velocity) พยากรณ์ความเสี่ยงเน่าเสียก่อนหมดอายุ และแนะนำยอดสั่งซื้อ',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        );

        final refreshBtn = ElevatedButton.icon(
          onPressed: isLoading
              ? null
              : () async {
                  await ref.read(forecastProvider.notifier).fetchForecast();
                  if (context.mounted) {
                    CapsuleToast.showSuccess(context, 'อัปเดตการวิเคราะห์พยากรณ์ล่าสุดเรียบร้อย');
                  }
                },
          icon: isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.refresh_rounded, size: 16),
          label: Text(isLoading ? 'กำลังคำนวณ...' : 'คำนวณใหม่ (Real-Time)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: const Color(0xFF0B0F19),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleColumn,
              const SizedBox(height: 12),
              refreshBtn,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: titleColumn),
            const SizedBox(width: 16),
            refreshBtn,
          ],
        );
      },
    );
  }

  Widget _buildKpiMetrics(ForecastSummaryData summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final card1 = _buildKpiCard(
          title: 'มูลค่าเสี่ยงเน่าเสียทิ้ง',
          value: Formatters.currency(summary.totalWasteValueAtRisk),
          subtitle: summary.criticalItemsCount > 0
              ? 'พบวัตถุดิบวิกฤต ${summary.criticalItemsCount} รายการ'
              : 'สถานะปลอดภัย ไม่มีของตกค้าง',
          icon: Icons.warning_amber_rounded,
          accentColor: summary.totalWasteValueAtRisk > 0 ? AppTheme.danger : AppTheme.success,
          highlight: summary.totalWasteValueAtRisk > 0,
        );

        final card2 = _buildKpiCard(
          title: 'วัตถุดิบวิกฤตเสี่ยงหมดอายุ',
          value: '${summary.criticalItemsCount} รายการ',
          subtitle: 'อายุสั้น (<4 วัน) คาดใช้ไม่ทัน',
          icon: Icons.hourglass_bottom_rounded,
          accentColor: summary.criticalItemsCount > 0 ? const Color(0xFFEF4444) : AppTheme.success,
        );

        final card3 = _buildKpiCard(
          title: 'งบประมาณสั่งซื้อแนะนำ 7 วัน',
          value: Formatters.currency(summary.suggestedOrderTotalValue),
          subtitle: 'คำนวณหักลบสต็อกคงเหลือปัจจุบัน',
          icon: Icons.shopping_cart_checkout_rounded,
          accentColor: AppTheme.primaryNeon,
        );

        final card4 = _buildKpiCard(
          title: 'ข้อมูลอ้างอิงในการพยากรณ์',
          value: '${summary.totalOrdersAnalyzed} บิลขาย',
          subtitle: 'วิเคราะห์เฉลี่ยรอบ ${summary.forecastBasisDays} วันล่าสุด',
          icon: Icons.analytics_rounded,
          accentColor: const Color(0xFF38BDF8),
        );

        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              card1,
              const SizedBox(height: 12),
              card2,
              const SizedBox(height: 12),
              card3,
              const SizedBox(height: 12),
              card4,
            ],
          );
        } else if (constraints.maxWidth < 950) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: 12),
                  Expanded(child: card2),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: card3),
                  const SizedBox(width: 12),
                  Expanded(child: card4),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: card1),
            const SizedBox(width: 16),
            Expanded(child: card2),
            const SizedBox(width: 16),
            Expanded(child: card3),
            const SizedBox(width: 16),
            Expanded(child: card4),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    bool highlight = false,
  }) {
    return GlassContainer(
      glowColor: highlight ? accentColor : null,
      glowOpacity: highlight ? 0.16 : 0.06,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: accentColor),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar(ForecastSummaryData summary) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 10,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300, minWidth: 180),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'ค้นหาชื่อวัตถุดิบ หรือหมวดหมู่...',
                prefixIcon: Icon(Icons.search_rounded, size: 18),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildFilterChip('ทั้งหมด', null, summary.items.length),
              _buildFilterChip('วิกฤต', ForecastRiskLevel.critical, summary.criticalItemsCount, AppTheme.danger),
              _buildFilterChip('เฝ้าระวัง', ForecastRiskLevel.warning, summary.warningItemsCount, const Color(0xFFF59E0B)),
              _buildFilterChip('ปลอดภัย', ForecastRiskLevel.safe, summary.safeItemsCount, AppTheme.success),
              const SizedBox(width: 4),
              FilterChip(
                avatar: const Icon(Icons.shopping_cart_outlined, size: 14),
                label: const Text('เฉพาะที่ต้องสั่งซื้อ'),
                selected: _showReorderOnly,
                onSelected: (val) => setState(() => _showReorderOnly = val),
                backgroundColor: Colors.white.withValues(alpha: 0.04),
                selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: _showReorderOnly ? FontWeight.w700 : FontWeight.w500,
                  color: _showReorderOnly ? AppTheme.primaryNeon : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ForecastRiskLevel? level, int count, [Color? color]) {
    final isSelected = _selectedFilter == level;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = level),
      backgroundColor: Colors.white.withValues(alpha: 0.04),
      selectedColor: (color ?? AppTheme.primary).withValues(alpha: 0.2),
      side: BorderSide(
        color: isSelected ? (color ?? AppTheme.primary) : AppTheme.border,
      ),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? (color ?? AppTheme.primaryNeon) : AppTheme.textSecondary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }

  Widget _buildForecastCard(IngredientForecastItem item) {
    final Color riskColor;
    final IconData riskIcon;
    switch (item.riskLevel) {
      case ForecastRiskLevel.critical:
        riskColor = AppTheme.danger;
        riskIcon = Icons.error_outline_rounded;
        break;
      case ForecastRiskLevel.warning:
        riskColor = const Color(0xFFF59E0B);
        riskIcon = Icons.warning_amber_rounded;
        break;
      case ForecastRiskLevel.safe:
        riskColor = AppTheme.success;
        riskIcon = Icons.check_circle_outline_rounded;
        break;
    }

    return GlassContainer(
      glowColor: item.riskLevel == ForecastRiskLevel.critical ? riskColor : null,
      glowOpacity: item.riskLevel == ForecastRiskLevel.critical ? 0.14 : 0.0,
      padding: const EdgeInsets.all(18),
      borderColor: item.riskLevel == ForecastRiskLevel.critical ? riskColor.withValues(alpha: 0.35) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: riskColor.withValues(alpha: 0.15),
                    child: Text(
                      item.ingredientName.substring(0, 1),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: riskColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.ingredientName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                      Text(
                        'หมวดหมู่: ${item.category} • อายุเก็บรักษา ~${item.shelfLifeDays} วัน',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: riskColor.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(riskIcon, size: 14, color: riskColor),
                    const SizedBox(width: 4),
                    Text(
                      item.riskLevel.label,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: riskColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 12),

          // Core Metrics Grid (Stock / Daily Usage / Runway / Waste)
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 600;
              final colCount = isSmall ? 2 : 4;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: colCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: isSmall ? 2.3 : 2.5,
                children: [
                  _buildSubStat(
                    'สต็อกปัจจุบัน',
                    '${item.currentStock.toStringAsFixed(1)} ${item.purchaseUnit}',
                    AppTheme.textPrimary,
                  ),
                  _buildSubStat(
                    'ใช้วันละเฉลี่ย',
                    '${item.dailyConsumption.toStringAsFixed(2)} ${item.purchaseUnit}/วัน',
                    const Color(0xFF38BDF8),
                  ),
                  _buildSubStat(
                    'สต็อกพอใช้อีก',
                    item.daysRemaining >= 900 ? 'เกินพอ' : '~${item.daysRemaining.toStringAsFixed(1)} วัน',
                    item.daysRemaining < 3 ? AppTheme.danger : AppTheme.primaryNeon,
                  ),
                  _buildSubStat(
                    item.potentialWasteQuantity > 0 ? 'เสี่ยงเน่าเสียทิ้ง' : 'แนะนำสั่งซื้อ 7 วัน',
                    item.potentialWasteQuantity > 0
                        ? '${item.potentialWasteQuantity.toStringAsFixed(1)} ${item.purchaseUnit} (${Formatters.currency(item.potentialWasteValue)})'
                        : (item.suggestedOrder7Days > 0
                            ? '+${item.suggestedOrder7Days.toStringAsFixed(1)} ${item.purchaseUnit}'
                            : 'สต็อกเพียงพอ'),
                    item.potentialWasteQuantity > 0 ? AppTheme.danger : AppTheme.success,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Message & Action Recommendation Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: riskColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: riskColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                      children: [
                        TextSpan(
                          text: '${item.message} — ',
                          style: TextStyle(fontWeight: FontWeight.w600, color: riskColor),
                        ),
                        TextSpan(
                          text: item.actionRecommendation,
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 48, color: AppTheme.success),
            const SizedBox(height: 12),
            const Text(
              'ไม่พบวัตถุดิบที่ตรงกับเงื่อนไขการค้นหา',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'ลองเลือกดูตัวกรองอื่น หรือกดปุ่มคำนวณใหม่เพื่ออัปเดตข้อมูล',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
