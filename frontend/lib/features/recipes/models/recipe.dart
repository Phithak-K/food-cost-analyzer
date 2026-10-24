import 'recipe_item.dart';

/// Represents a dish / menu recipe with cost breakdown, margin, and sales volume.
class Recipe {
  final String id;
  final String name;
  final String category;
  final double sellingPrice;
  final List<RecipeItem> items;
  final int unitsSoldMonthly; // Sales volume for matrix calculations

  const Recipe({
    required this.id,
    required this.name,
    this.category = 'Main Course',
    required this.sellingPrice,
    required this.items,
    this.unitsSoldMonthly = 0,
  });

  /// Alias for items
  List<RecipeItem> get ingredients => items;

  /// Total Food Cost = Sum of item costs in this recipe
  double get totalCost {
    return items.fold(0.0, (acc, item) => acc + item.itemCost);
  }

  /// Alias for totalCost
  double get totalFoodCost => totalCost;

  /// Contribution Margin (Gross Profit per dish) = Selling Price - Total Food Cost
  double get contributionMargin {
    return sellingPrice - totalCost;
  }

  /// Food Cost Percentage = (Total Food Cost / Selling Price) * 100
  double get foodCostPercentage {
    if (sellingPrice <= 0) return 0.0;
    return (totalCost / sellingPrice) * 100.0;
  }

  /// Total Monthly Revenue = Selling Price * Units Sold
  double get monthlyRevenue => sellingPrice * unitsSoldMonthly;

  /// Total Monthly Food Cost = Total Cost * Units Sold
  double get monthlyFoodCost => totalCost * unitsSoldMonthly;

  /// Total Monthly Profit = Contribution Margin * Units Sold
  double get monthlyProfit => contributionMargin * unitsSoldMonthly;

  Recipe copyWith({
    String? id,
    String? name,
    String? category,
    double? sellingPrice,
    List<RecipeItem>? items,
    int? unitsSoldMonthly,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      items: items ?? this.items,
      unitsSoldMonthly: unitsSoldMonthly ?? this.unitsSoldMonthly,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'sellingPrice': sellingPrice,
        'items': items.map((i) => i.toJson()).toList(),
        'unitsSoldMonthly': unitsSoldMonthly,
        'totalCost': totalCost,
        'foodCostPercentage': foodCostPercentage,
        'contributionMargin': contributionMargin,
      };

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String,
        name: json['name'] as String,
        category: (json['category'] as String?) ?? 'Main Course',
        sellingPrice: (json['sellingPrice'] as num).toDouble(),
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => RecipeItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        unitsSoldMonthly: (json['unitsSoldMonthly'] as num?)?.toInt() ?? 0,
      );
}
