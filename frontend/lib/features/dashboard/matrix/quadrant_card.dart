import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../recipes/models/recipe.dart';
import '../models/menu_matrix_item.dart';

class QuadrantCard extends StatelessWidget {
  final MenuQuadrant quadrant;
  final List<MenuMatrixItem> items;
  final Recipe? selectedRecipe;
  final ValueChanged<Recipe>? onRecipeTap;

  const QuadrantCard({
    super.key,
    required this.quadrant,
    required this.items,
    this.selectedRecipe,
    this.onRecipeTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = quadrant.color;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(quadrant.icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quadrant.displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${items.length} เมนูในกลุ่มนี้',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 16, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      quadrant.actionStrategy,
                      style: TextStyle(
                        fontSize: 12,
                        color: color.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('ไม่มีเมนูในหมวดนี้', style: Theme.of(context).textTheme.bodySmall),
              )
            else
              ...items.map(
                (item) {
                  final isSelected = selectedRecipe != null && item.recipe.id == selectedRecipe!.id;
                  return InkWell(
                    onTap: onRecipeTap != null ? () => onRecipeTap!(item.recipe) : null,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? color.withValues(alpha: 0.4) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (isSelected) ...[
                                  Icon(Icons.arrow_right_rounded, size: 16, color: color),
                                  const SizedBox(width: 2),
                                ],
                                Expanded(
                                  child: Text(
                                    item.recipe.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? color : AppTheme.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${item.recipe.unitsSoldMonthly} จาน',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? color : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
