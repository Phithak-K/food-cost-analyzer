import '../../../core/utils/unit_converter.dart';

/// Represents a raw culinary ingredient in food inventory and recipe costing.
class Ingredient {
  final String id;
  final String name;
  final String category;
  final double purchaseCost; // Total cost per purchase package/unit
  final double purchaseQuantity; // Amount per package (e.g. 1 for 1 kg, 500 for 500 g)
  final String purchaseUnit; // e.g. 'kg', 'g', 'L', 'ml', 'pcs'
  final double costPerBaseUnit; // Cost per 1 g, 1 ml, or 1 pcs (after yield)
  final double yieldPercentage; // e.g. 85.0 (85%) after trimming/waste
  final double currentStock;
  final String supplier;

  Ingredient({
    required this.id,
    required this.name,
    this.category = 'General',
    required this.purchaseCost,
    required this.purchaseQuantity,
    required this.purchaseUnit,
    double? costPerBaseUnit,
    this.yieldPercentage = 100.0,
    this.currentStock = 0.0,
    this.supplier = 'ทั่วไป',
  }) : costPerBaseUnit = costPerBaseUnit ??
            _calculateCostPerBaseUnit(
              purchaseCost: purchaseCost,
              purchaseQuantity: purchaseQuantity,
              purchaseUnit: purchaseUnit,
              yieldPercentage: yieldPercentage,
            );

  /// Helper to calculate cost per base unit (1g / 1ml / 1pcs) with yield adjustment:
  /// Cost per Base Unit = Purchase Cost / (Base Quantity * (Yield % / 100))
  static double _calculateCostPerBaseUnit({
    required double purchaseCost,
    required double purchaseQuantity,
    required String purchaseUnit,
    required double yieldPercentage,
  }) {
    if (purchaseCost <= 0 || purchaseQuantity <= 0 || yieldPercentage <= 0) {
      return 0.0;
    }
    final double totalBaseQuantity = UnitConverter.toBaseUnit(purchaseQuantity, purchaseUnit);
    final double effectiveBaseQuantity = totalBaseQuantity * (yieldPercentage / 100.0);
    return effectiveBaseQuantity > 0 ? (purchaseCost / effectiveBaseQuantity) : 0.0;
  }

  /// Canonical base unit name for this ingredient ('g', 'ml', or 'pcs').
  String get baseUnit => UnitConverter.getBaseUnitName(purchaseUnit);

  // Backward-compatible getters for UI
  double get purchasePrice => purchaseCost;
  String get unit => purchaseUnit;
  double get usableUnitCost {
    // Return cost per purchase unit
    final double baseInOnePurchaseUnit = UnitConverter.toBaseUnit(1.0, purchaseUnit);
    return costPerBaseUnit * baseInOnePurchaseUnit;
  }

  Ingredient copyWith({
    String? id,
    String? name,
    String? category,
    double? purchaseCost,
    double? purchaseQuantity,
    String? purchaseUnit,
    double? costPerBaseUnit,
    double? yieldPercentage,
    double? currentStock,
    String? supplier,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      purchaseCost: purchaseCost ?? this.purchaseCost,
      purchaseQuantity: purchaseQuantity ?? this.purchaseQuantity,
      purchaseUnit: purchaseUnit ?? this.purchaseUnit,
      costPerBaseUnit: costPerBaseUnit ?? this.costPerBaseUnit,
      yieldPercentage: yieldPercentage ?? this.yieldPercentage,
      currentStock: currentStock ?? this.currentStock,
      supplier: supplier ?? this.supplier,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'purchaseCost': purchaseCost,
        'purchaseQuantity': purchaseQuantity,
        'purchaseUnit': purchaseUnit,
        'costPerBaseUnit': costPerBaseUnit,
        'yieldPercentage': yieldPercentage,
        'currentStock': currentStock,
        'supplier': supplier,
      };

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
        id: json['id'] as String,
        name: json['name'] as String,
        category: (json['category'] as String?) ?? 'General',
        purchaseCost: (json['purchaseCost'] as num).toDouble(),
        purchaseQuantity: (json['purchaseQuantity'] as num).toDouble(),
        purchaseUnit: json['purchaseUnit'] as String,
        costPerBaseUnit: (json['costPerBaseUnit'] as num?)?.toDouble(),
        yieldPercentage: (json['yieldPercentage'] as num?)?.toDouble() ?? 100.0,
        currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0.0,
        supplier: (json['supplier'] as String?) ?? 'ทั่วไป',
      );
}
