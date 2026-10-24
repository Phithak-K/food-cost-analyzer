import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_container.dart';
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

    return GlassContainer(
      glowColor: color,
      glowOpacity: 0.1,
      glowBlur: 20,
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
                (item) => _QuadrantMenuItemTile(
                  item: item,
                  color: color,
                  isSelected: selectedRecipe != null && item.recipe.id == selectedRecipe!.id,
                  onTap: onRecipeTap != null ? () => onRecipeTap!(item.recipe) : null,
                ),
              ),
          ],
        ),
      );
    }
}

class _QuadrantMenuItemTile extends StatefulWidget {
  final MenuMatrixItem item;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  const _QuadrantMenuItemTile({
    required this.item,
    required this.color,
    required this.isSelected,
    this.onTap,
  });

  @override
  State<_QuadrantMenuItemTile> createState() => _QuadrantMenuItemTileState();
}

class _QuadrantMenuItemTileState extends State<_QuadrantMenuItemTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected || _isHovered;

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -2.0 : 0.0, 0),
        margin: const EdgeInsets.symmetric(vertical: 2.5),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.color.withValues(alpha: 0.16)
                  : (_isHovered ? widget.color.withValues(alpha: 0.10) : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.isSelected
                    ? widget.color.withValues(alpha: 0.6)
                    : (_isHovered ? widget.color.withValues(alpha: 0.35) : Colors.transparent),
                width: 1,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (active) ...[
                        Icon(Icons.arrow_right_rounded, size: 18, color: widget.color),
                        const SizedBox(width: 2),
                      ],
                      Expanded(
                        child: Text(
                          widget.item.recipe.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: active ? FontWeight.bold : FontWeight.w500,
                            color: active ? Colors.white : AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${widget.item.recipe.unitsSoldMonthly} จาน',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: active ? widget.color : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
