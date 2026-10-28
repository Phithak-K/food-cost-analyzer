import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../recipes/models/recipe.dart';

class RecipeCostPieChart extends StatefulWidget {
  final Recipe? recipe;
  final List<Recipe> availableRecipes;
  final ValueChanged<Recipe>? onRecipeChanged;

  const RecipeCostPieChart({
    super.key,
    required this.recipe,
    required this.availableRecipes,
    this.onRecipeChanged,
  });

  @override
  State<RecipeCostPieChart> createState() => _RecipeCostPieChartState();
}

class _RecipeCostPieChartState extends State<RecipeCostPieChart> {
  int _touchedIndex = -1;

  final List<Color> _sliceColors = const [
    Color(0xFF2563EB), // Royal Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFF14B8A6), // Teal
    Color(0xFFF97316), // Orange
    Color(0xFF64748B), // Slate
  ];

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe ?? (widget.availableRecipes.isNotEmpty ? widget.availableRecipes.first : null);

    if (recipe == null || recipe.items.isEmpty) {
      return const Center(
        child: Text('ไม่มีข้อมูลวัตถุดิบสำหรับเมนูที่เลือก'),
      );
    }

    final totalCost = recipe.totalCost;
    final costPct = recipe.foodCostPercentage;

    final isOptimal = costPct <= AppConstants.targetFoodCostMax;
    final statusColor = costPct <= AppConstants.targetFoodCostMin
        ? AppTheme.success
        : (isOptimal ? AppTheme.primary : AppTheme.danger);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown to pick or switch recipe
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'สัดส่วนต้นทุนวัตถุดิบ (Recipe Breakdown)',
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'คลิกเลือกจุดบนกราฟ หรือเลือกเมนูจากรายการ',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 230, minWidth: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: recipe.id,
                  items: widget.availableRecipes.map((r) {
                    return DropdownMenuItem<String>(
                      value: r.id,
                      child: Text(
                        r.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (id) {
                    if (id != null && widget.onRecipeChanged != null) {
                      final found = widget.availableRecipes.firstWhere((r) => r.id == id);
                      widget.onRecipeChanged!(found);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Recipe Header Summary Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'ราคาขาย: ${Formatters.currency(recipe.sellingPrice)} | กำไร: ${Formatters.currency(recipe.contributionMargin)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Food Cost ${Formatters.percentage(costPct)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Pie Chart & Legend Row
        Expanded(
          child: Row(
            children: [
              // Donut Pie Chart
              Expanded(
                flex: 5,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 3,
                    centerSpaceRadius: 38,
                    sections: recipe.items.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      final isTouched = i == _touchedIndex;
                      final fontSize = isTouched ? 14.0 : 11.0;
                      final radius = isTouched ? 65.0 : 54.0;
                      final color = _sliceColors[i % _sliceColors.length];

                      final slicePct = totalCost > 0 ? (item.itemCost / totalCost) * 100.0 : 0.0;

                      return PieChartSectionData(
                        color: color,
                        value: item.itemCost,
                        title: '${slicePct.toStringAsFixed(0)}%',
                        radius: radius,
                        titleStyle: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(color: Colors.black45, blurRadius: 2),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Ingredients Breakdown Legend & List
              Expanded(
                flex: 6,
                child: ListView.separated(
                  itemCount: recipe.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final item = recipe.items[idx];
                    final color = _sliceColors[idx % _sliceColors.length];
                    final isHighlighted = idx == _touchedIndex;
                    final slicePct = totalCost > 0 ? (item.itemCost / totalCost) * 100.0 : 0.0;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isHighlighted ? color.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isHighlighted ? color.withValues(alpha: 0.4) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.ingredient.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                                    color: AppTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${item.quantityUsed} ${item.unitUsed}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                Formatters.currency(item.itemCost),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${slicePct.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Bottom Total
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceMuted,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'ต้นทุนรวมวัตถุดิบต่อจาน:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  Formatters.currency(totalCost),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.danger),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
