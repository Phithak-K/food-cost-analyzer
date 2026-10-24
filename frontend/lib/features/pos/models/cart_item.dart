import '../../recipes/models/recipe.dart';

/// Represents a selected recipe item in the POS cart.
class CartItem {
  final Recipe recipe;
  final int quantity;

  const CartItem({
    required this.recipe,
    required this.quantity,
  });

  double get subtotal => recipe.sellingPrice * quantity;
  double get totalCost => recipe.totalCost * quantity;
  double get profit => subtotal - totalCost;

  CartItem copyWith({
    Recipe? recipe,
    int? quantity,
  }) {
    return CartItem(
      recipe: recipe ?? this.recipe,
      quantity: quantity ?? this.quantity,
    );
  }
}
