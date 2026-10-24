import '../../../core/utils/unit_converter.dart';
import '../../ingredients/models/ingredient.dart';

/// Represents a specific portion of an ingredient used in a recipe.
class RecipeItem {
  final Ingredient ingredient;
  final double quantityUsed;
  final String unitUsed;
  final double itemCost;

  RecipeItem({
    required this.ingredient,
    required this.quantityUsed,
    required this.unitUsed,
    double? itemCost,
  }) : itemCost = itemCost ??
            UnitConverter.calculateItemCost(
              costPerBaseUnit: ingredient.costPerBaseUnit,
              quantityUsed: quantityUsed,
              unitUsed: unitUsed,
            );

  // Backward-compatible getters
  double get quantity => quantityUsed;
  double get cost => itemCost;

  RecipeItem copyWith({
    Ingredient? ingredient,
    double? quantityUsed,
    String? unitUsed,
    double? itemCost,
  }) {
    return RecipeItem(
      ingredient: ingredient ?? this.ingredient,
      quantityUsed: quantityUsed ?? this.quantityUsed,
      unitUsed: unitUsed ?? this.unitUsed,
      itemCost: itemCost ?? this.itemCost,
    );
  }

  Map<String, dynamic> toJson() => {
        'ingredient': ingredient.toJson(),
        'quantityUsed': quantityUsed,
        'unitUsed': unitUsed,
        'itemCost': itemCost,
      };

  factory RecipeItem.fromJson(Map<String, dynamic> json) => RecipeItem(
        ingredient: Ingredient.fromJson(json['ingredient'] as Map<String, dynamic>),
        quantityUsed: (json['quantityUsed'] as num).toDouble(),
        unitUsed: json['unitUsed'] as String,
        itemCost: (json['itemCost'] as num?)?.toDouble(),
      );
}

/// Type alias for backward compatibility
typedef RecipeIngredient = RecipeItem;
