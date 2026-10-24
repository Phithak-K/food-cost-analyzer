import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../providers/dashboard_provider.dart';

class CostDistributionChart extends StatelessWidget {
  final DashboardMetrics metrics;

  const CostDistributionChart({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final items = metrics.classifiedItems;
    if (items.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            const Text(
              'สัดส่วน Food Cost % เทียบเป้าหมาย (28% - 35%)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _buildDot(AppTheme.success, '< 28% ดีเยี่ยม'),
                _buildDot(AppTheme.primary, '28-35% ตามเกณฑ์'),
                _buildDot(AppTheme.danger, '> 35% สูงเกินเกณฑ์'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 60,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppTheme.textPrimary,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final item = items[group.x.toInt()];
                    return BarTooltipItem(
                      '${item.recipe.name}\n'
                      'Food Cost: ${Formatters.percentage(item.recipe.foodCostPercentage)}\n'
                      'ต้นทุน: ${Formatters.currency(item.recipe.totalFoodCost)}',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (val, _) => Text(
                      '${val.toInt()}%',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx < 0 || idx >= items.length) return const SizedBox();
                      final shortName = items[idx].recipe.name.split(' ').first;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          shortName,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 15,
                getDrawingHorizontalLine: (val) => FlLine(
                  color: AppTheme.borderSubtle,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final costPct = item.recipe.foodCostPercentage;

                Color rodColor = AppTheme.success;
                if (costPct > AppConstants.targetFoodCostMax) {
                  rodColor = AppTheme.danger;
                } else if (costPct >= AppConstants.targetFoodCostMin) {
                  rodColor = AppTheme.primary;
                }

                return BarChartGroupData(
                  x: idx,
                  barRods: [
                    BarChartRodData(
                      toY: costPct,
                      color: rodColor,
                      width: 24,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}
