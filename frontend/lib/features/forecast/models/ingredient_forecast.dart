enum ForecastRiskLevel {
  critical,
  warning,
  safe;

  static ForecastRiskLevel fromString(String val) {
    switch (val.toUpperCase()) {
      case 'CRITICAL':
        return ForecastRiskLevel.critical;
      case 'WARNING':
        return ForecastRiskLevel.warning;
      default:
        return ForecastRiskLevel.safe;
    }
  }

  String get label {
    switch (this) {
      case ForecastRiskLevel.critical:
        return 'วิกฤต (เสี่ยงเน่าเสีย)';
      case ForecastRiskLevel.warning:
        return 'เฝ้าระวัง';
      case ForecastRiskLevel.safe:
        return 'ระดับปลอดภัย';
    }
  }
}

class IngredientForecastItem {
  final String ingredientId;
  final String ingredientName;
  final String category;
  final String purchaseUnit;
  final double currentStock;
  final int shelfLifeDays;
  final double dailyConsumption;
  final double daysRemaining;
  final ForecastRiskLevel riskLevel;
  final double potentialWasteQuantity;
  final double potentialWasteValue;
  final double suggestedOrder7Days;
  final double suggestedOrderValue;
  final String message;
  final String actionRecommendation;

  IngredientForecastItem({
    required this.ingredientId,
    required this.ingredientName,
    required this.category,
    required this.purchaseUnit,
    required this.currentStock,
    required this.shelfLifeDays,
    required this.dailyConsumption,
    required this.daysRemaining,
    required this.riskLevel,
    required this.potentialWasteQuantity,
    required this.potentialWasteValue,
    required this.suggestedOrder7Days,
    required this.suggestedOrderValue,
    required this.message,
    required this.actionRecommendation,
  });

  factory IngredientForecastItem.fromJson(Map<String, dynamic> json) {
    return IngredientForecastItem(
      ingredientId: json['ingredientId'] as String? ?? '',
      ingredientName: json['ingredientName'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      purchaseUnit: json['purchaseUnit'] as String? ?? 'kg',
      currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0.0,
      shelfLifeDays: (json['shelfLifeDays'] as num?)?.toInt() ?? 7,
      dailyConsumption: (json['dailyConsumption'] as num?)?.toDouble() ?? 0.0,
      daysRemaining: (json['daysRemaining'] as num?)?.toDouble() ?? 0.0,
      riskLevel: ForecastRiskLevel.fromString(json['riskLevel'] as String? ?? 'SAFE'),
      potentialWasteQuantity: (json['potentialWasteQuantity'] as num?)?.toDouble() ?? 0.0,
      potentialWasteValue: (json['potentialWasteValue'] as num?)?.toDouble() ?? 0.0,
      suggestedOrder7Days: (json['suggestedOrder7Days'] as num?)?.toDouble() ?? 0.0,
      suggestedOrderValue: (json['suggestedOrderValue'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] as String? ?? '',
      actionRecommendation: json['actionRecommendation'] as String? ?? '',
    );
  }
}

class ForecastSummaryData {
  final double totalWasteValueAtRisk;
  final int criticalItemsCount;
  final int warningItemsCount;
  final int safeItemsCount;
  final double suggestedOrderTotalValue;
  final List<IngredientForecastItem> items;
  final int forecastBasisDays;
  final int totalOrdersAnalyzed;
  final DateTime generatedAt;

  ForecastSummaryData({
    required this.totalWasteValueAtRisk,
    required this.criticalItemsCount,
    required this.warningItemsCount,
    required this.safeItemsCount,
    required this.suggestedOrderTotalValue,
    required this.items,
    required this.forecastBasisDays,
    required this.totalOrdersAnalyzed,
    required this.generatedAt,
  });

  factory ForecastSummaryData.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>?)
            ?.map((e) => IngredientForecastItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return ForecastSummaryData(
      totalWasteValueAtRisk: (json['totalWasteValueAtRisk'] as num?)?.toDouble() ?? 0.0,
      criticalItemsCount: (json['criticalItemsCount'] as num?)?.toInt() ?? 0,
      warningItemsCount: (json['warningItemsCount'] as num?)?.toInt() ?? 0,
      safeItemsCount: (json['safeItemsCount'] as num?)?.toInt() ?? 0,
      suggestedOrderTotalValue: (json['suggestedOrderTotalValue'] as num?)?.toDouble() ?? 0.0,
      items: itemsList,
      forecastBasisDays: (json['forecastBasisDays'] as num?)?.toInt() ?? 14,
      totalOrdersAnalyzed: (json['totalOrdersAnalyzed'] as num?)?.toInt() ?? 0,
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory ForecastSummaryData.empty() {
    return ForecastSummaryData(
      totalWasteValueAtRisk: 0.0,
      criticalItemsCount: 0,
      warningItemsCount: 0,
      safeItemsCount: 0,
      suggestedOrderTotalValue: 0.0,
      items: [],
      forecastBasisDays: 14,
      totalOrdersAnalyzed: 0,
      generatedAt: DateTime.now(),
    );
  }
}
