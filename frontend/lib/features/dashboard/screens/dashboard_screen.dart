import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass_container.dart';
import '../chart_widgets/cost_distribution_chart.dart';
import '../chart_widgets/menu_matrix_chart.dart';
import '../matrix/quadrant_card.dart';
import '../providers/dashboard_provider.dart';

import '../../recipes/models/recipe.dart';
import '../../reports/widgets/export_report_dialog.dart';
import '../chart_widgets/recipe_cost_pie_chart.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Recipe? _selectedRecipe;

  @override
  Widget build(BuildContext context) {
    final metrics = ref.watch(dashboardMetricsProvider);
    final availableRecipes = metrics.classifiedItems.map((e) => e.recipe).toList();
    final currentSelected = _selectedRecipe ?? (availableRecipes.isNotEmpty ? availableRecipes.first : null);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'แดชบอร์ดวิเคราะห์เมนู & ต้นทุนอาหาร',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ระบบ Kasavana & Smith Menu Engineering Matrix และการควบคุม Food Cost',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // What-If Simulation Button
                    ElevatedButton.icon(
                      onPressed: () => context.go('/simulation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 1,
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text(
                        'จำลองต้นทุน (What-If)',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    // Export Report Button
                    OutlinedButton.icon(
                      onPressed: () {
                        ExportReportDialog.show(
                          context,
                          metrics: metrics,
                          recipes: availableRecipes,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text(
                        'Export รายงาน (PDF / Excel)',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    // Date Period Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'รอบการขาย 30 วันล่าสุด',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 4 Executive KPI Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final double itemWidth = constraints.maxWidth > 1100
                    ? (constraints.maxWidth - 48) / 4
                    : (constraints.maxWidth > 650 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth);

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _KpiCard(
                      width: itemWidth,
                      title: 'ยอดขายรวม (Total Revenue)',
                      value: Formatters.currency(metrics.totalRevenue),
                      numericValue: metrics.totalRevenue,
                      formatter: (v) => Formatters.currency(v),
                      subtext: 'จากเมนูทั้งหมด ${metrics.classifiedItems.length} รายการ',
                      icon: Icons.payments_outlined,
                      iconColor: AppTheme.primary,
                    ),
                    _KpiCard(
                      width: itemWidth,
                      title: 'Food Cost เฉลี่ยรวม (Average Food Cost %)',
                      value: Formatters.percentage(metrics.overallFoodCostPct),
                      numericValue: metrics.overallFoodCostPct,
                      formatter: (v) => Formatters.percentage(v),
                      subtext: metrics.overallFoodCostPct <= AppConstants.targetFoodCostMax
                          ? 'อยู่ในเกณฑ์เป้าหมายมาตรฐาน'
                          : 'สูงกว่าเกณฑ์เป้าหมาย (35%)',
                      icon: Icons.pie_chart_outline_rounded,
                      iconColor: metrics.overallFoodCostPct <= AppConstants.targetFoodCostMax
                          ? AppTheme.success
                          : AppTheme.danger,
                    ),
                    _KpiCard(
                      width: itemWidth,
                      title: 'กำไรขั้นต้นรวม (Overall Margin)',
                      value: Formatters.currency(metrics.totalProfit),
                      numericValue: metrics.totalProfit,
                      formatter: (v) => Formatters.currency(v),
                      subtext: 'ต้นทุนอาหารรวม ${Formatters.compactCurrency(metrics.totalFoodCost)}',
                      icon: Icons.trending_up_rounded,
                      iconColor: AppTheme.success,
                    ),
                    _KpiCard(
                      width: itemWidth,
                      title: 'สูตรเมนูที่ใช้งาน (Total Active Recipes)',
                      value: '${metrics.classifiedItems.length} เมนู',
                      numericValue: metrics.classifiedItems.length.toDouble(),
                      formatter: (v) => '${v.toInt()} เมนู',
                      subtext: 'เมนูดาวเด่น ${metrics.stars.length} รายการ (กำไรดี-ขายดี)',
                      icon: Icons.restaurant_menu_rounded,
                      iconColor: const Color(0xFFF59E0B),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Actionable Recommendations Summary Banner
            _ActionableRecommendationsBanner(metrics: metrics),
            const SizedBox(height: 24),

            // Two Main Visual Charts: Scatter Plot & Recipe Breakdown Pie Chart
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1050;

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Matrix Quadrant Scatter Plot
                      Expanded(
                        flex: 6,
                        child: GlassContainer(
                          padding: const EdgeInsets.all(AppConstants.cardPadding),
                          child: SizedBox(
                            height: 480,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.grid_view_rounded, size: 20, color: AppTheme.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Menu Engineering Matrix (Kasavana & Smith)',
                                        style: Theme.of(context).textTheme.titleLarge,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'แกน X = ยอดขาย (Volume) | แกน Y = กำไรส่วนเกิน (Margin) | คลิกจุดเพื่อดูสัดส่วนต้นทุน',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: MenuMatrixChart(
                                    metrics: metrics,
                                    selectedRecipe: currentSelected,
                                    onRecipeSelected: (recipe) {
                                      setState(() => _selectedRecipe = recipe);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Recipe Breakdown Pie Chart
                      Expanded(
                        flex: 5,
                        child: GlassContainer(
                          padding: const EdgeInsets.all(AppConstants.cardPadding),
                          child: SizedBox(
                            height: 480,
                            child: RecipeCostPieChart(
                              recipe: currentSelected,
                              availableRecipes: availableRecipes,
                              onRecipeChanged: (recipe) {
                                setState(() => _selectedRecipe = recipe);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      GlassContainer(
                        padding: const EdgeInsets.all(AppConstants.cardPadding),
                        child: SizedBox(
                          height: 440,
                          child: MenuMatrixChart(
                            metrics: metrics,
                            selectedRecipe: currentSelected,
                            onRecipeSelected: (recipe) {
                              setState(() => _selectedRecipe = recipe);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassContainer(
                        padding: const EdgeInsets.all(AppConstants.cardPadding),
                        child: SizedBox(
                          height: 440,
                          child: RecipeCostPieChart(
                            recipe: currentSelected,
                            availableRecipes: availableRecipes,
                            onRecipeChanged: (recipe) {
                              setState(() => _selectedRecipe = recipe);
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // Quadrant Breakdown Cards Header
            Row(
              children: [
                const Icon(Icons.psychology_outlined, size: 22, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'กลยุทธ์การบริหารจัดการเมนูตาม 4 มิติ (Actionable Strategic Cards)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'คลิกที่ชื่อเมนูในการ์ดเพื่อแสดงสัดส่วนต้นทุนวัตถุดิบ (Recipe Breakdown) ด้านบน',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            // 4 Quadrants Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final double cardWidth = constraints.maxWidth > 1100
                    ? (constraints.maxWidth - 48) / 4
                    : (constraints.maxWidth > 650 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth);

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: QuadrantCard(
                        quadrant: MenuQuadrant.star,
                        items: metrics.stars,
                        selectedRecipe: currentSelected,
                        onRecipeTap: (recipe) {
                          setState(() => _selectedRecipe = recipe);
                        },
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: QuadrantCard(
                        quadrant: MenuQuadrant.plowhorse,
                        items: metrics.plowhorses,
                        selectedRecipe: currentSelected,
                        onRecipeTap: (recipe) {
                          setState(() => _selectedRecipe = recipe);
                        },
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: QuadrantCard(
                        quadrant: MenuQuadrant.puzzle,
                        items: metrics.puzzles,
                        selectedRecipe: currentSelected,
                        onRecipeTap: (recipe) {
                          setState(() => _selectedRecipe = recipe);
                        },
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: QuadrantCard(
                        quadrant: MenuQuadrant.dog,
                        items: metrics.dogs,
                        selectedRecipe: currentSelected,
                        onRecipeTap: (recipe) {
                          setState(() => _selectedRecipe = recipe);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Food Cost % Distribution Bar Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.cardPadding),
                child: SizedBox(
                  height: 380,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bar_chart_rounded, size: 20, color: AppTheme.secondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Food Cost % เปรียบเทียบรายเมนู',
                              style: Theme.of(context).textTheme.titleLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(child: CostDistributionChart(metrics: metrics)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionableRecommendationsBanner extends StatelessWidget {
  final DashboardMetrics metrics;

  const _ActionableRecommendationsBanner({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        side: const BorderSide(color: AppTheme.border),
      ),
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Actionable Business Recommendations (สรุปคำแนะนำทางธุรกิจ)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'ข้อเสนอแนะเชิงกลยุทธ์สำหรับการปรับแต่งเมนูและราคาขายเพื่อเพิ่มผลกำไรสูงสุด',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final itemWidth = isWide ? (constraints.maxWidth - 36) / 2 : constraints.maxWidth;

                return Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    // Plowhorse Recommendation
                    _RecommendationItem(
                      width: itemWidth,
                      quadrant: MenuQuadrant.plowhorse,
                      count: metrics.plowhorses.length,
                      recommendation: 'ขายดีแต่กำไรน้อย แนะนำลดสัดส่วนวัตถุดิบบางตัวหรือขึ้นราคา',
                    ),
                    // Dog Recommendation
                    _RecommendationItem(
                      width: itemWidth,
                      quadrant: MenuQuadrant.dog,
                      count: metrics.dogs.length,
                      recommendation: 'ขายไม่ออกและกำไรต่ำ แนะนำพิจารณาตัดออกจากเมนู',
                    ),
                    // Star Recommendation
                    _RecommendationItem(
                      width: itemWidth,
                      quadrant: MenuQuadrant.star,
                      count: metrics.stars.length,
                      recommendation: 'ยอดขายสูงและกำไรดี แนะนำรักษามาตรฐานคุณภาพและโปรโมตต่อเนื่อง',
                    ),
                    // Puzzle Recommendation
                    _RecommendationItem(
                      width: itemWidth,
                      quadrant: MenuQuadrant.puzzle,
                      count: metrics.puzzles.length,
                      recommendation: 'กำไรสูงแต่ขายได้น้อย แนะนำทำการตลาด ปรับตำแหน่งในเมนู หรือจัดเซ็ตคอมโบ',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationItem extends StatelessWidget {
  final double width;
  final MenuQuadrant quadrant;
  final int count;
  final String recommendation;

  const _RecommendationItem({
    required this.width,
    required this.quadrant,
    required this.count,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    final color = quadrant.color;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(quadrant.icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'กลุ่ม ${quadrant.shortName} ($count รายการ)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  recommendation,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedCounterText extends StatelessWidget {
  final double endValue;
  final String Function(double) formatter;
  final TextStyle? style;

  const _AnimatedCounterText({
    required this.endValue,
    required this.formatter,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: endValue),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          formatter(value),
          style: style,
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final double? numericValue;
  final String Function(double)? formatter;
  final String subtext;
  final IconData icon;
  final Color iconColor;

  const _KpiCard({
    required this.width,
    required this.title,
    required this.value,
    this.numericValue,
    this.formatter,
    required this.subtext,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      width: width,
      glowColor: iconColor,
      glowOpacity: 0.12,
      glowBlur: 24,
      padding: const EdgeInsets.all(AppConstants.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: iconColor.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (numericValue != null && formatter != null)
            _AnimatedCounterText(
              endValue: numericValue!,
              formatter: formatter!,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          const SizedBox(height: 6),
          Text(
            subtext,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
