import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../models/recipe.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foodCost = recipe.totalFoodCost;
    final costPct = recipe.foodCostPercentage;
    final margin = recipe.contributionMargin;

    // Color code based on standard F&B target (28-35%)
    final Color costStatusColor = costPct <= AppConstants.targetFoodCostMin
        ? AppTheme.success
        : (costPct <= AppConstants.targetFoodCostMax ? AppTheme.primary : AppTheme.danger);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name & Category
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceMuted,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text(
                            recipe.category,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Selling Price Tag
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.currency(recipe.sellingPrice),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                      Text(
                        'ราคาขาย',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Cost vs Margin Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (costPct.clamp(0, 100) * 10).round(),
                        child: Container(color: costStatusColor),
                      ),
                      Expanded(
                        flex: ((100 - costPct).clamp(0, 100) * 10).round(),
                        child: Container(color: AppTheme.surfaceMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _MetricItem(
                      label: 'Food Cost %',
                      value: Formatters.percentage(costPct),
                      valueColor: costStatusColor,
                      tooltip: 'เกณฑ์มาตรฐานร้านอาหาร: 28% - 35%',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricItem(
                      label: 'ต้นทุนอาหาร',
                      value: Formatters.currency(foodCost),
                      valueColor: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricItem(
                      label: 'กำไรขั้นต้น',
                      value: Formatters.currency(margin),
                      valueColor: AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricItem(
                      label: 'ยอดขาย/เดือน',
                      value: '${recipe.unitsSoldMonthly} จาน',
                      valueColor: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 10),

              // Ingredients summary
              Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 16, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'วัตถุดิบ ${recipe.ingredients.length} ชนิดในสูตร',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'กำไรรวม: ${Formatters.compactCurrency(recipe.monthlyProfit)}/ด.',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final String? tooltip;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.valueColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (tooltip != null) ...[
              const SizedBox(width: 3),
              Tooltip(
                message: tooltip!,
                child: const Icon(Icons.info_outline, size: 11, color: AppTheme.textMuted),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
