/// Unit types supported in culinary and beverage food costing.
enum UnitType {
  mass, // Base unit: gram (g)
  volume, // Base unit: milliliter (ml)
  count, // Base unit: pieces (pcs)
  unknown,
}

/// Service for converting culinary units and computing portion costs.
class UnitConverter {
  // Mass conversion factors to grams (g)
  static const Map<String, double> _massToGram = {
    'g': 1.0,
    'gram': 1.0,
    'grams': 1.0,
    'kg': 1000.0,
    'kilogram': 1000.0,
    'kilograms': 1000.0,
    'mg': 0.001,
    'milligram': 0.001,
    'oz': 28.3495,
    'ounce': 28.3495,
    'lb': 453.592,
    'pound': 453.592,
  };

  // Volume conversion factors to milliliters (ml)
  static const Map<String, double> _volumeToMl = {
    'ml': 1.0,
    'milliliter': 1.0,
    'milliliters': 1.0,
    'l': 1000.0,
    'liter': 1000.0,
    'liters': 1000.0,
    'cl': 10.0,
    'centiliter': 10.0,
    'tsp': 5.0,
    'teaspoon': 5.0,
    'tbsp': 15.0,
    'tablespoon': 15.0,
    'cup': 240.0,
    'fl oz': 29.5735,
    'floz': 29.5735,
  };

  // Count/Item factors to base pieces (pcs)
  static const Map<String, double> _countToPcs = {
    'pcs': 1.0,
    'pc': 1.0,
    'piece': 1.0,
    'pieces': 1.0,
    'unit': 1.0,
    'units': 1.0,
    'can': 1.0,
    'bottle': 1.0,
    'pack': 1.0,
    'egg': 1.0,
    'slice': 1.0,
    'doz': 12.0,
    'dozen': 12.0,
  };

  /// Identifies the category of the given unit.
  static UnitType getUnitType(String unit) {
    final normalized = unit.trim().toLowerCase();
    if (_massToGram.containsKey(normalized)) return UnitType.mass;
    if (_volumeToMl.containsKey(normalized)) return UnitType.volume;
    if (_countToPcs.containsKey(normalized)) return UnitType.count;
    return UnitType.unknown;
  }

  /// Returns the canonical base unit name ('g', 'ml', or 'pcs').
  static String getBaseUnitName(String unit) {
    final type = getUnitType(unit);
    switch (type) {
      case UnitType.mass:
        return 'g';
      case UnitType.volume:
        return 'ml';
      case UnitType.count:
        return 'pcs';
      case UnitType.unknown:
        return unit.trim().toLowerCase();
    }
  }

  /// Converts a given quantity and unit to its canonical base unit (g, ml, or pcs).
  static double toBaseUnit(double quantity, String unit) {
    final normalized = unit.trim().toLowerCase();
    if (_massToGram.containsKey(normalized)) {
      return quantity * _massToGram[normalized]!;
    }
    if (_volumeToMl.containsKey(normalized)) {
      return quantity * _volumeToMl[normalized]!;
    }
    if (_countToPcs.containsKey(normalized)) {
      return quantity * _countToPcs[normalized]!;
    }
    // Fallback: If unknown, assume 1:1
    return quantity;
  }

  /// Converts a quantity from one unit to another compatible unit (e.g. kg -> g, L -> ml).
  static double convert(double quantity, String fromUnit, String toUnit) {
    final fromType = getUnitType(fromUnit);
    final toType = getUnitType(toUnit);

    if (fromType != toType && fromType != UnitType.unknown && toType != UnitType.unknown) {
      throw ArgumentError(
        'Cannot convert incompatible unit types: $fromUnit ($fromType) to $toUnit ($toType)',
      );
    }

    final baseQuantity = toBaseUnit(quantity, fromUnit);
    final normalizedTo = toUnit.trim().toLowerCase();

    if (fromType == UnitType.mass && _massToGram.containsKey(normalizedTo)) {
      return baseQuantity / _massToGram[normalizedTo]!;
    }
    if (fromType == UnitType.volume && _volumeToMl.containsKey(normalizedTo)) {
      return baseQuantity / _volumeToMl[normalizedTo]!;
    }
    if (fromType == UnitType.count && _countToPcs.containsKey(normalizedTo)) {
      return baseQuantity / _countToPcs[normalizedTo]!;
    }

    return baseQuantity;
  }

  /// Calculates the cost of a recipe item based on:
  /// - [costPerBaseUnit]: cost per 1 gram, 1 ml, or 1 piece
  /// - [quantityUsed]: quantity of ingredient used
  /// - [unitUsed]: unit of measure for the quantity used (e.g. 'kg', 'g', 'ml', 'tbsp')
  static double calculateItemCost({
    required double costPerBaseUnit,
    required double quantityUsed,
    required String unitUsed,
  }) {
    final baseQuantity = toBaseUnit(quantityUsed, unitUsed);
    return baseQuantity * costPerBaseUnit;
  }
}
