import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../recipes/models/recipe.dart';
import '../providers/dashboard_provider.dart';

class MenuMatrixChart extends StatelessWidget {
  final DashboardMetrics metrics;
  final Recipe? selectedRecipe;
  final ValueChanged<Recipe>? onRecipeSelected;

  const MenuMatrixChart({
    super.key,
    required this.metrics,
    this.selectedRecipe,
    this.onRecipeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = metrics.classifiedItems;
    if (items.isEmpty) {
      return const Center(child: Text('ไม่มีข้อมูลสำหรับสร้างกราฟ'));
    }

    final avgMargin = metrics.averageContributionMargin;
    final avgVolume = metrics.averageUnitsSold;

    // Determine bounds
    double maxVolume = 100;
    double maxMargin = 500;
    for (final item in items) {
      if (item.recipe.unitsSoldMonthly > maxVolume) {
        maxVolume = item.recipe.unitsSoldMonthly.toDouble();
      }
      if (item.recipe.contributionMargin > maxMargin) {
        maxMargin = item.recipe.contributionMargin;
      }
    }
    maxVolume = (maxVolume * 1.15).ceilToDouble();
    maxMargin = (maxMargin * 1.15).ceilToDouble();

    final scatterSpots = items.map((item) {
      final isSelected = selectedRecipe != null && item.recipe.id == selectedRecipe!.id;

      return ScatterSpot(
        item.recipe.unitsSoldMonthly.toDouble(),
        item.recipe.contributionMargin,
        dotPainter: _GlowDotPainter(
          radius: isSelected ? 9.0 : 6.5,
          color: item.quadrant.color,
          strokeColor: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.85),
          strokeWidth: isSelected ? 2.5 : 1.5,
          glowRadius: isSelected ? 20.0 : 13.0,
          glowOpacity: isSelected ? 0.45 : 0.28,
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend & Threshold Indicators
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: MenuQuadrant.values.map((q) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: q.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: q.color.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      q.shortName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.straighten_rounded, size: 14, color: AppTheme.primaryNeon),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'เส้นประนีออน: จุดตัดกำไร ${Formatters.currency(avgMargin)} / ยอดขาย ${avgVolume.toStringAsFixed(0)} จาน',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Scatter Chart with quadrant indicators and dashed threshold lines
        Expanded(
          child: Stack(
            children: [
              // Quadrant background labels
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(left: 45, bottom: 30, right: 15, top: 15),
                  child: Row(
                    children: [
                      // Left (Low Volume)
                      Expanded(
                        child: Column(
                          children: [
                            // Top-Left: Puzzle
                            Expanded(
                              child: Container(
                                alignment: Alignment.topLeft,
                                padding: const EdgeInsets.all(8),
                                color: MenuQuadrant.puzzle.color.withValues(alpha: 0.025),
                                child: Text(
                                  'PUZZLE (กำไรสูง / ยอดขายน้อย)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: MenuQuadrant.puzzle.color.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ),
                            // Bottom-Left: Dog
                            Expanded(
                              child: Container(
                                alignment: Alignment.bottomLeft,
                                padding: const EdgeInsets.all(8),
                                color: MenuQuadrant.dog.color.withValues(alpha: 0.025),
                                child: Text(
                                  'DOG (กำไรต่ำ / ยอดขายน้อย)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: MenuQuadrant.dog.color.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right (High Volume)
                      Expanded(
                        child: Column(
                          children: [
                            // Top-Right: Star
                            Expanded(
                              child: Container(
                                alignment: Alignment.topRight,
                                padding: const EdgeInsets.all(8),
                                color: MenuQuadrant.star.color.withValues(alpha: 0.025),
                                child: Text(
                                  'STAR (กำไรสูง / ยอดขายสูง)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: MenuQuadrant.star.color.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ),
                            // Bottom-Right: Plowhorse
                            Expanded(
                              child: Container(
                                alignment: Alignment.bottomRight,
                                padding: const EdgeInsets.all(8),
                                color: MenuQuadrant.plowhorse.color.withValues(alpha: 0.025),
                                child: Text(
                                  'PLOWHORSE (กำไรต่ำ / ยอดขายสูง)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: MenuQuadrant.plowhorse.color.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Scatter Plot
              ScatterChart(
                ScatterChartData(
                  scatterSpots: scatterSpots,
                  minX: 0,
                  maxX: maxVolume,
                  minY: 0,
                  maxY: maxMargin,
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: true,
                    checkToShowHorizontalLine: (val) {
                      return (val - avgMargin).abs() < 1.0 || val % (maxMargin / 4).round() == 0;
                    },
                    getDrawingHorizontalLine: (val) {
                      final isAvgLine = (val - avgMargin).abs() < 2.0;
                      if (isAvgLine) {
                        return FlLine(
                          color: AppTheme.primaryNeon.withValues(alpha: 0.8),
                          strokeWidth: 1.8,
                          dashArray: [6, 4], // Dashed neon threshold line
                        );
                      }
                      return FlLine(
                        color: Colors.white.withValues(alpha: 0.05),
                        strokeWidth: 1,
                        dashArray: [4, 6], // Minimal subtle grey gridlines
                      );
                    },
                    checkToShowVerticalLine: (val) {
                      return (val - avgVolume).abs() < 1.0 || val % (maxVolume / 4).round() == 0;
                    },
                    getDrawingVerticalLine: (val) {
                      final isAvgLine = (val - avgVolume).abs() < 2.0;
                      if (isAvgLine) {
                        return FlLine(
                          color: AppTheme.primaryNeon.withValues(alpha: 0.8),
                          strokeWidth: 1.8,
                          dashArray: [6, 4], // Dashed neon threshold line
                        );
                      }
                      return FlLine(
                        color: Colors.white.withValues(alpha: 0.05),
                        strokeWidth: 1,
                        dashArray: [4, 6], // Minimal subtle grey gridlines
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text(
                        'แกน X: Sales Volume (ยอดขายรายเดือน - จาน)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      axisNameSize: 26,
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == maxVolume) return const SizedBox();
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text(
                        'แกน Y: Contribution Margin (กำไรส่วนเกินต่อจาน - ฿)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      axisNameSize: 26,
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == maxMargin) return const SizedBox();
                          return Text(
                            Formatters.compactCurrency(value),
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          );
                        },
                      ),
                    ),
                  ),
                  scatterTouchData: ScatterTouchData(
                    enabled: true,
                    touchCallback: (event, touchResponse) {
                      if (touchResponse != null && touchResponse.touchedSpot != null) {
                        final spot = touchResponse.touchedSpot!.spot;
                        final matched = items.firstWhere(
                          (item) =>
                              item.recipe.unitsSoldMonthly.toDouble() == spot.x &&
                              (item.recipe.contributionMargin - spot.y).abs() < 0.5,
                          orElse: () => items.first,
                        );
                        if (onRecipeSelected != null) {
                          onRecipeSelected!(matched.recipe);
                        }
                      }
                    },
                    touchTooltipData: ScatterTouchTooltipData(
                      getTooltipColor: (spot) => const Color(0xE60F172A), // Dark Glassmorphism
                      tooltipBorder: const BorderSide(color: Color(0x33FFFFFF), width: 1.0),
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (ScatterSpot touchedSpot) {
                        final matched = items.firstWhere(
                          (item) =>
                              item.recipe.unitsSoldMonthly.toDouble() == touchedSpot.x &&
                              (item.recipe.contributionMargin - touchedSpot.y).abs() < 0.5,
                          orElse: () => items.first,
                        );

                        return ScatterTooltipItem(
                          '${matched.recipe.name}\n',
                          textStyle: const TextStyle(
                            color: Color(0xFFF8FAFC),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: 'สถานะ: [ ${matched.quadrant.displayName} ]\n',
                              style: TextStyle(
                                color: matched.quadrant.color,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                height: 1.5,
                              ),
                            ),
                            TextSpan(
                              text: 'ราคาขาย: ${Formatters.currency(matched.recipe.sellingPrice)} | ต้นทุน: ${Formatters.currency(matched.recipe.totalFoodCost)}\n'
                                  'กำไร (Margin): ${Formatters.currency(matched.recipe.contributionMargin)} (${Formatters.percentage(matched.recipe.foodCostPercentage)})\n'
                                  'ยอดขาย: ${matched.recipe.unitsSoldMonthly} จาน/เดือน (คลิกดูส่วนประกอบ)',
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom Dot Painter that draws radiant glowing halo aura around scatter points
class _GlowDotPainter extends FlDotCirclePainter {
  final double glowRadius;
  final double glowOpacity;

  _GlowDotPainter({
    required super.radius,
    required super.color,
    super.strokeWidth = 1.5,
    super.strokeColor = Colors.white,
    this.glowRadius = 13.0,
    this.glowOpacity = 0.28,
  });

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    // 1. Radiant Glowing Halo
    final glowPaint = Paint()
      ..color = color.withValues(alpha: glowOpacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius * 0.5);
    canvas.drawCircle(offsetInCanvas, glowRadius, glowPaint);

    // 2. Secondary soft aura
    final auraPaint = Paint()..color = color.withValues(alpha: glowOpacity * 0.7);
    canvas.drawCircle(offsetInCanvas, radius + 2.5, auraPaint);

    // 3. Central Dot & Stroke
    super.draw(canvas, spot, offsetInCanvas);
  }
}
