import 'package:flutter/material.dart';

class IngredientCategoryBadge extends StatelessWidget {
  final String category;

  const IngredientCategoryBadge({super.key, required this.category});

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'seafood':
        return const Color(0xFF0284C7); // Sky blue
      case 'meat':
        return const Color(0xFFE11D48); // Rose red
      case 'produce':
        return const Color(0xFF16A34A); // Green
      case 'dairy':
        return const Color(0xFFD97706); // Amber
      case 'specialty':
        return const Color(0xFF7C3AED); // Violet
      case 'dry goods':
        return const Color(0xFF475569); // Slate
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
