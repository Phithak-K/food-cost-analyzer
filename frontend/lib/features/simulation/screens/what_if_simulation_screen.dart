import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/glass_container.dart';
import '../../ingredients/providers/ingredients_provider.dart';
import '../models/simulation_models.dart';
import '../providers/simulation_provider.dart';

class WhatIfSimulationScreen extends ConsumerStatefulWidget {
  const WhatIfSimulationScreen({super.key});

  @override
  ConsumerState<WhatIfSimulationScreen> createState() => _WhatIfSimulationScreenState();
}

class _WhatIfSimulationScreenState extends ConsumerState<WhatIfSimulationScreen>
    with SingleTickerProviderStateMixin {
  final currencyFormat = NumberFormat('#,##0.00', 'th_TH');
  final percentFormat = NumberFormat('#0.0', 'th_TH');
  String _recipeFilter = '';

  AnimationController? _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    final isTestEnvironment =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTestEnvironment) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
      _pulseAnimation = CurvedAnimation(
        parent: _pulseController!,
        curve: Curves.easeInOut,
      );
    } else {
      _pulseController = null;
      _pulseAnimation = const AlwaysStoppedAnimation<double>(0.6);
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final simState = ref.watch(simulationProvider);
    final ingredients = ref.watch(ingredientsProvider);
    final notifier = ref.read(simulationProvider.notifier);
    final isDesktop = Responsive.isDesktop(context);

    // Filter ingredients based on query
    final filteredIngredients = ingredients.where((ing) {
      if (simState.searchQuery.isEmpty) return true;
      return ing.name.toLowerCase().contains(simState.searchQuery.toLowerCase()) ||
          ing.category.toLowerCase().contains(simState.searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            _buildHeader(context, simState, notifier),
            const SizedBox(height: 20),

            // Quick Preset Scenarios
            _buildPresetBar(simState, notifier),
            const SizedBox(height: 24),

            // High-Impact Summary Cards (4 Cards)
            _buildSummaryMetricCards(simState.result.summary),
            const SizedBox(height: 20),

            // Split Comparison: Before vs After Profit Impact Card
            _buildBeforeAfterProfitCard(simState.result.summary),
            const SizedBox(height: 24),

            // Main Interactive Work Area
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Ingredient Adjustment Sliders
                  SizedBox(
                    width: 380,
                    child: _buildIngredientSlidersPanel(
                      context,
                      filteredIngredients,
                      simState,
                      notifier,
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right: Before vs After Comparison Table
                  Expanded(
                    child: _buildComparisonTableCard(
                      context,
                      simState.result,
                      simState.threshold,
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildIngredientSlidersPanel(
                    context,
                    filteredIngredients,
                    simState,
                    notifier,
                  ),
                  const SizedBox(height: 24),
                  _buildComparisonTableCard(
                    context,
                    simState.result,
                    simState.threshold,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, SimulationState state, SimulationNotifier notifier) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        final resetButton = ElevatedButton.icon(
          onPressed: state.percentAdjustments.isEmpty
              ? null
              : () => notifier.resetAll(),
          icon: const Icon(Icons.restart_alt_rounded, size: 18),
          label: const Text('รีเซ็ตทั้งหมด'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: AppTheme.primaryNeon,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              const Text(
                                'What-If Simulation (จำลองสถานการณ์ต้นทุน)',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                child: const Text(
                                  'Real-Time Sandbox',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'ทดลองปรับราคาสินค้าขึ้น/ลงเพื่อวิเคราะห์ผลกระทบต่อ % Food Cost และกำไรสุทธิรวมของร้านได้ทันที โดยไม่กระทบฐานข้อมูลจริง',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    resetButton,
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
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                          ),
                          child: const Icon(Icons.tune_rounded, color: AppTheme.primaryNeon, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'What-If Simulation',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        resetButton,
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'ทดลองปรับราคาสินค้าขึ้น/ลงเพื่อวิเคราะห์ผลกระทบต่อ % Food Cost และกำไรสุทธิรวมของร้านได้ทันที',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildPresetBar(SimulationState state, SimulationNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.flash_on_rounded, color: AppTheme.accent, size: 20),
              SizedBox(width: 8),
              Text(
                'จำลองสถานการณ์ด่วน (Presets):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildPresetChip(
                label: '+5% Inflation',
                isSelected: state.activePreset == 'inflation_5',
                onTap: () => notifier.applyPreset('inflation_5'),
              ),
              _buildPresetChip(
                label: '+10% Ingredient Shock',
                isSelected: state.activePreset == 'ingredient_shock_10',
                onTap: () => notifier.applyPreset('ingredient_shock_10'),
              ),
              _buildPresetChip(
                label: 'Reset',
                isSelected: false,
                onTap: () => notifier.resetAll(),
              ),
              _buildPresetChip(
                label: 'ค่าครองชีพขึ้นทั้งระบบ (+10%)',
                isSelected: state.activePreset == 'general_inflation',
                onTap: () => notifier.applyPreset('general_inflation'),
              ),
              _buildPresetChip(
                label: 'วิกฤตนม & แดรี่ (+20%)',
                isSelected: state.activePreset == 'dairy_spike',
                onTap: () => notifier.applyPreset('dairy_spike'),
              ),
              _buildPresetChip(
                label: 'เนื้อสัตว์ & ซีฟู้ด (+15%)',
                isSelected: state.activePreset == 'meat_seafood_spike',
                onTap: () => notifier.applyPreset('meat_seafood_spike'),
              ),
            ],
          ),
          if (state.percentAdjustments.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'กำลังปรับราคา ${state.percentAdjustments.length} รายการ',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPresetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : AppTheme.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryMetricCards(StoreSimulationSummary summary) {
    final netDiff = summary.netProfitDifference;
    final isLoss = netDiff < 0;
    final isGain = netDiff > 0;

    final profitColor = isLoss
        ? AppTheme.danger
        : (isGain ? AppTheme.success : AppTheme.textPrimary);

    return LayoutBuilder(
      builder: (context, constraints) {
        final card1 = _buildMetricCard(
          title: 'ผลกระทบต่อกำไรสุทธิรวม',
          value: '${isLoss ? '-' : (isGain ? '+' : '')}฿${currencyFormat.format(netDiff.abs())}',
          subtitle: 'ยอดกำไรต่อเดือน (${summary.newlyCriticalRecipesCount > 0 ? "ลดลง" : "เทียบกับเดิม"})',
          icon: isLoss ? Icons.trending_down_rounded : Icons.trending_up_rounded,
          accentColor: profitColor,
          highlight: true,
        );

        final card2 = _buildMetricCard(
          title: 'Food Cost รวมทั้งร้าน',
          value: '${percentFormat.format(summary.newOverallCostPercentage)}%',
          subtitle: 'เดิม ${percentFormat.format(summary.oldOverallCostPercentage)}% (${summary.costPercentageDifference >= 0 ? '+' : ''}${percentFormat.format(summary.costPercentageDifference)}%)',
          icon: Icons.pie_chart_rounded,
          accentColor: summary.costPercentageDifference > 0
              ? AppTheme.warning
              : AppTheme.info,
        );

        final card3 = _buildMetricCard(
          title: 'เมนูที่ต้นทุนทะลุเกณฑ์ (>35%)',
          value: '${summary.totalCriticalRecipesCount} เมนู',
          subtitle: summary.newlyCriticalRecipesCount > 0
              ? 'ทะลุเกณฑ์เพิ่ม ${summary.newlyCriticalRecipesCount} เมนู!'
              : 'ไม่มีเมนูใหม่ที่เกินเกณฑ์',
          icon: Icons.warning_amber_rounded,
          accentColor: summary.newlyCriticalRecipesCount > 0
              ? AppTheme.danger
              : AppTheme.success,
        );

        final card4 = _buildMetricCard(
          title: 'ต้นทุนรวมทั้งเดือน',
          value: '฿${currencyFormat.format(summary.newMonthlyTotalCost)}',
          subtitle: 'เดิม ฿${currencyFormat.format(summary.oldMonthlyTotalCost)} (${summary.totalCostDifference >= 0 ? '+' : ''}฿${currencyFormat.format(summary.totalCostDifference)})',
          icon: Icons.payments_rounded,
          accentColor: AppTheme.primary,
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    bool highlight = false,
  }) {
    return GlassContainer(
      glowColor: highlight ? accentColor : null,
      glowOpacity: highlight ? 0.16 : 0.08,
      glowBlur: 20,
      padding: const EdgeInsets.all(18),
      borderColor: highlight ? accentColor.withValues(alpha: 0.4) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: highlight ? accentColor : AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: (subtitle.contains('เพิ่ม') || subtitle.contains('ลดลง')) ? AppTheme.danger : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeforeAfterProfitCard(StoreSimulationSummary summary) {
    final netDiff = summary.netProfitDifference;
    final isLoss = netDiff < 0;
    final isGain = netDiff > 0;
    final variancePct = summary.oldMonthlyGrossProfit > 0
        ? (netDiff / summary.oldMonthlyGrossProfit * 100)
        : 0.0;

    final profitColor = isLoss
        ? AppTheme.danger
        : (isGain ? AppTheme.success : AppTheme.textPrimary);

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.compare_rounded, color: AppTheme.primaryNeon, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text(
                      'เปรียบเทียบผลกระทบกำไรสุทธิ 2 ฝั่ง (Profit Impact Comparison)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLoss
                      ? AppTheme.danger.withValues(alpha: 0.15)
                      : (isGain ? AppTheme.success.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isLoss
                        ? AppTheme.danger.withValues(alpha: 0.4)
                        : (isGain ? AppTheme.success.withValues(alpha: 0.4) : AppTheme.border),
                  ),
                ),
                child: Text(
                  isLoss
                      ? 'กำไรลดลงจากต้นทุนวัตถุดิบที่เพิ่มขึ้น'
                      : (isGain ? 'กำไรปรับตัวดีขึ้น' : 'สถานะปกติ (Baseline)'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: profitColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final sideWidth = isWide ? (constraints.maxWidth - 140) / 2 : constraints.maxWidth;

              final beforeWidget = Container(
                width: sideWidth,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'กำไรเดิม (Baseline Profit)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('BEFORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '฿${currencyFormat.format(summary.oldMonthlyGrossProfit)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('ต้นทุนรวมเดิม: ', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        Text('฿${currencyFormat.format(summary.oldMonthlyTotalCost)}', style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        const Text('Food Cost: ', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        Text('${percentFormat.format(summary.oldOverallCostPercentage)}%', style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              );

              final varianceWidget = Container(
                width: isWide ? 120 : constraints.maxWidth,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isLoss ? Icons.arrow_circle_down_rounded : (isGain ? Icons.arrow_circle_up_rounded : Icons.swap_horiz_rounded),
                      color: profitColor,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ส่วนต่างกำไรสุทธิ',
                      style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${isLoss ? "-" : (isGain ? "+" : "")}฿${currencyFormat.format(netDiff.abs())}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: profitColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '(${variancePct >= 0 ? "+" : ""}${variancePct.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: profitColor,
                      ),
                    ),
                  ],
                ),
              );

              final afterWidget = Container(
                width: sideWidth,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isLoss
                      ? AppTheme.danger.withValues(alpha: 0.04)
                      : (isGain ? AppTheme.success.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.03)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLoss
                        ? AppTheme.danger.withValues(alpha: 0.3)
                        : (isGain ? AppTheme.success.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'กำไรที่คาดการณ์ (Projected Profit)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: profitColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'AFTER',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: profitColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '฿${currencyFormat.format(summary.newMonthlyGrossProfit)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: profitColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('ต้นทุนใหม่: ', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        Text('฿${currencyFormat.format(summary.newMonthlyTotalCost)}', style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        const Text('Food Cost: ', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        Text(
                          '${percentFormat.format(summary.newOverallCostPercentage)}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: summary.newOverallCostPercentage > 35.0 ? AppTheme.danger : Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: beforeWidget),
                    varianceWidget,
                    Expanded(child: afterWidget),
                  ],
                );
              } else {
                return Column(
                  children: [
                    beforeWidget,
                    varianceWidget,
                    afterWidget,
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientSlidersPanel(
    BuildContext context,
    List<dynamic> ingredients,
    SimulationState state,
    SimulationNotifier notifier,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ปรับราคาวัตถุดิบ (Sliders & Inputs)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (state.percentAdjustments.isNotEmpty)
                TextButton(
                  onPressed: () => notifier.resetAll(),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppTheme.danger,
                  ),
                  child: const Text('รีเซ็ต', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'เลื่อนสไลเดอร์เพื่อทดสอบผลกระทบของการขึ้น/ลงราคา (-30% ถึง +50%)',
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 10),
          // Shortcut Presets
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildPresetChip(
                label: '+5% Inflation',
                isSelected: state.activePreset == 'inflation_5',
                onTap: () => notifier.applyPreset('inflation_5'),
              ),
              _buildPresetChip(
                label: '+10% Ingredient Shock',
                isSelected: state.activePreset == 'ingredient_shock_10',
                onTap: () => notifier.applyPreset('ingredient_shock_10'),
              ),
              _buildPresetChip(
                label: 'Reset',
                isSelected: false,
                onTap: () => notifier.resetAll(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search box
          TextField(
            onChanged: (val) => notifier.setSearchQuery(val),
            decoration: InputDecoration(
              hintText: 'ค้นหาวัตถุดิบ...',
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              fillColor: AppTheme.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Scrollable ingredient slider list
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 520),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: ingredients.length,
              separatorBuilder: (_, _) => const Divider(height: 16),
              itemBuilder: (context, idx) {
                final ing = ingredients[idx];
                final currentPercent = state.percentAdjustments[ing.id] ?? 0.0;
                final simPrice = ing.purchaseCost * (1 + (currentPercent / 100.0));

                return _buildIngredientSliderRow(
                  ing: ing,
                  currentPercent: currentPercent,
                  simPrice: simPrice,
                  notifier: notifier,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientSliderRow({
    required dynamic ing,
    required double currentPercent,
    required double simPrice,
    required SimulationNotifier notifier,
  }) {
    final isChanged = currentPercent != 0.0;
    final changeColor = currentPercent > 0
        ? AppTheme.danger
        : (currentPercent < 0 ? AppTheme.success : AppTheme.textPrimary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ing.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'เดิม: ฿${currencyFormat.format(ing.purchaseCost)} / ${ing.purchaseQuantity} ${ing.purchaseUnit}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isChanged
                    ? changeColor.withValues(alpha: 0.1)
                    : AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isChanged ? changeColor : AppTheme.border,
                ),
              ),
              child: Text(
                '${currentPercent >= 0 ? "+" : ""}${percentFormat.format(currentPercent)}% (฿${currencyFormat.format(simPrice)})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isChanged ? changeColor : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  showValueIndicator: ShowValueIndicator.onDrag,
                  valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
                  valueIndicatorColor: currentPercent > 0
                      ? const Color(0xFFEF4444)
                      : (currentPercent < 0 ? const Color(0xFF10B981) : const Color(0xFF3B82F6)),
                  valueIndicatorTextStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  thumbColor: currentPercent > 0
                      ? const Color(0xFFEF4444)
                      : (currentPercent < 0 ? const Color(0xFF10B981) : AppTheme.primaryNeon),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  trackHeight: 4,
                  activeTrackColor: currentPercent > 0
                      ? const Color(0xFFEF4444)
                      : (currentPercent < 0 ? const Color(0xFF10B981) : AppTheme.primary),
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                ),
                child: Slider(
                  value: currentPercent.clamp(-30.0, 50.0),
                  min: -30.0,
                  max: 50.0,
                  divisions: 80,
                  label: '${currentPercent >= 0 ? "+" : ""}${currentPercent.toStringAsFixed(1)}%',
                  onChanged: (val) {
                    notifier.setPercentAdjustment(ing.id, val);
                  },
                ),
              ),
            ),
            // Quick step buttons (-5%, +5%, +10%, Reset)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 16),
              tooltip: '-5%',
              visualDensity: VisualDensity.compact,
              onPressed: currentPercent <= -30.0
                  ? null
                  : () => notifier.adjustByStep(ing.id, -5.0),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 16),
              tooltip: '+5%',
              visualDensity: VisualDensity.compact,
              onPressed: currentPercent >= 50.0
                  ? null
                  : () => notifier.adjustByStep(ing.id, 5.0),
            ),
            IconButton(
              icon: Icon(
                Icons.flash_on_rounded,
                size: 16,
                color: currentPercent >= 50.0 ? AppTheme.textMuted : AppTheme.warning,
              ),
              tooltip: currentPercent >= 50.0 ? 'สูงสุด +50% แล้ว' : '+10%',
              visualDensity: VisualDensity.compact,
              onPressed: currentPercent >= 50.0
                  ? null
                  : () => notifier.adjustByStep(ing.id, 10.0),
            ),
            if (isChanged) ...[
              const SizedBox(width: 4),
              Container(
                width: 1,
                height: 16,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              const SizedBox(width: 2),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textMuted),
                tooltip: 'รีเซ็ตรายการนี้',
                visualDensity: VisualDensity.compact,
                onPressed: () => notifier.setPercentAdjustment(ing.id, 0.0),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildComparisonTableCard(
    BuildContext context,
    SimulationResult result,
    double threshold,
  ) {
    // Filter comparisons
    final filteredComparisons = result.recipeComparisons.where((comp) {
      if (_recipeFilter.isEmpty) return true;
      return comp.recipeName.toLowerCase().contains(_recipeFilter.toLowerCase()) ||
          comp.category.toLowerCase().contains(_recipeFilter.toLowerCase());
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows_rounded, color: AppTheme.primary, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ตารางเปรียบเทียบผลกระทบ Before vs After (จำลองต้นทุน)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'เปรียบเทียบต้นทุนต่อจาน, กำไรส่วนเกิน, % Food Cost และผลกระทบต่อกำไรรวมต่อเดือน',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              // Search in table
              SizedBox(
                width: 220,
                height: 36,
                child: TextField(
                  onChanged: (val) => setState(() => _recipeFilter = val),
                  decoration: InputDecoration(
                    hintText: 'ค้นหาเมนู...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 16),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    fillColor: AppTheme.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // At-Risk Alert Banner for recipes falling out of safe zone
          _buildAtRiskAlertBanner(filteredComparisons),

          // Comparison Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.surfaceMuted),
              columnSpacing: 22,
              horizontalMargin: 16,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 64,
              columns: const [
                DataColumn(
                  label: SizedBox(
                    width: 170,
                    child: Text(
                      'เมนูอาหาร (Recipe)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: SizedBox(
                    width: 80,
                    child: Text(
                      'ราคาขาย',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: SizedBox(
                    width: 90,
                    child: Text(
                      'ยอดขาย/ด.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 135,
                    child: Text(
                      'ต้นทุนเดิม vs ใหม่',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 160,
                    child: Text(
                      'กำไรส่วนเกินเดิม vs ใหม่',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 110,
                    child: Text(
                      '% Food Cost',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: SizedBox(
                    width: 135,
                    child: Text(
                      'ผลกระทบกำไร/เดือน',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 145,
                    child: Text(
                      'สถานะ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              rows: filteredComparisons.map((comp) {
                final isChanged = comp.costDifference != 0.0;
                final isWorse = comp.monthlyProfitDifference < 0;

                return DataRow(
                  color: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (comp.becameCritical) {
                      return AppTheme.danger.withValues(
                          alpha: 0.08 + (_pulseAnimation.value * 0.08));
                    }
                    if (isChanged) {
                      return AppTheme.warning.withValues(alpha: 0.03);
                    }
                    return null;
                  }),
                  cells: [
                    // Name & category
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            comp.recipeName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            comp.category,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    // Selling Price
                    DataCell(Text('฿${currencyFormat.format(comp.sellingPrice)}')),
                    // Monthly Sales
                    DataCell(Text('${comp.unitsSoldMonthly} จาน')),
                    // Old vs New Cost
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '฿${currencyFormat.format(comp.oldCost)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isChanged ? AppTheme.textMuted : AppTheme.textPrimary,
                                  decoration: isChanged ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              if (isChanged) ...[
                                const Icon(Icons.arrow_forward_rounded, size: 12, color: AppTheme.textMuted),
                                Text(
                                  ' ฿${currencyFormat.format(comp.newCost)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: comp.costDifference > 0 ? AppTheme.danger : AppTheme.success,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (isChanged)
                            Text(
                              '${comp.costDifference >= 0 ? "+" : ""}฿${currencyFormat.format(comp.costDifference)} (${percentFormat.format(comp.costPercentChange)}%)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: comp.costDifference > 0 ? AppTheme.danger : AppTheme.success,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Old vs New Margin
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '฿${currencyFormat.format(comp.oldContributionMargin)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isChanged ? AppTheme.textMuted : AppTheme.textPrimary,
                                  decoration: isChanged ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              if (isChanged) ...[
                                const Icon(Icons.arrow_forward_rounded, size: 12, color: AppTheme.textMuted),
                                Text(
                                  ' ฿${currencyFormat.format(comp.newContributionMargin)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: comp.newContributionMargin < comp.oldContributionMargin
                                        ? AppTheme.danger
                                        : AppTheme.success,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // % Food Cost
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${percentFormat.format(comp.oldFoodCostPercentage)}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: isChanged ? AppTheme.textMuted : AppTheme.textPrimary,
                              decoration: isChanged ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (isChanged) ...[
                            const Icon(Icons.arrow_forward_rounded, size: 12, color: AppTheme.textMuted),
                            Text(
                              ' ${percentFormat.format(comp.newFoodCostPercentage)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: comp.isOverThreshold ? AppTheme.danger : AppTheme.success,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Monthly Profit Diff
                    DataCell(
                      Text(
                        isChanged
                            ? '${isWorse ? "-" : "+"}฿${currencyFormat.format(comp.monthlyProfitDifference.abs())}'
                            : '฿0.00',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isWorse ? AppTheme.danger : (comp.monthlyProfitDifference > 0 ? AppTheme.success : AppTheme.textPrimary),
                        ),
                      ),
                    ),
                    // Status Badge
                    DataCell(
                      _buildStatusBadge(comp),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtRiskAlertBanner(List<SimulatedRecipeComparison> comparisons) {
    final atRisk = comparisons.where((c) => c.becameCritical).toList();
    if (atRisk.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        final glow = 0.25 + (_pulseAnimation.value * 0.55);
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.danger.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.danger.withValues(alpha: glow),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.danger.withValues(alpha: glow * 0.3),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'แจ้งเตือน: มี ${atRisk.length} เมนูที่กำลังจะหลุดจากโซนปลอดภัย (Food Cost พุ่งเกิน 35%)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: atRisk.map((c) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.danger.withValues(alpha: glow)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          c.recipeName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${percentFormat.format(c.oldFoodCostPercentage)}% → ${percentFormat.format(c.newFoodCostPercentage)}%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.danger),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(SimulatedRecipeComparison comp) {
    if (comp.becameCritical) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, _) {
          final glow = 0.3 + (_pulseAnimation.value * 0.65);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppTheme.danger.withValues(alpha: glow),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.danger.withValues(alpha: glow * 0.35),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, size: 12, color: AppTheme.danger),
                SizedBox(width: 4),
                Text(
                  'กำลังจะหลุดโซนปลอดภัย (>35%)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.danger,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    if (comp.isOverThreshold) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'เกินเกณฑ์ (>35%)',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.danger,
          ),
        ),
      );
    }

    if (comp.costDifference > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'ต้นทุนเพิ่มขึ้น',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.warning,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'ปกติ (ปลอดภัย)',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppTheme.success,
        ),
      ),
    );
  }
}
