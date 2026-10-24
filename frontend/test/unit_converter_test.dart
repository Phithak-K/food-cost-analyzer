import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/core/utils/unit_converter.dart';

void main() {
  group('UnitConverter Service Tests', () {
    test('converts mass units correctly to base grams (g)', () {
      expect(UnitConverter.toBaseUnit(1.0, 'kg'), 1000.0);
      expect(UnitConverter.toBaseUnit(500.0, 'g'), 500.0);
      expect(UnitConverter.convert(2.5, 'kg', 'g'), 2500.0);
      expect(UnitConverter.convert(1500.0, 'g', 'kg'), 1.5);
    });

    test('converts volume units correctly to base milliliters (ml)', () {
      expect(UnitConverter.toBaseUnit(1.0, 'L'), 1000.0);
      expect(UnitConverter.toBaseUnit(250.0, 'ml'), 250.0);
      expect(UnitConverter.convert(1.5, 'L', 'ml'), 1500.0);
      expect(UnitConverter.convert(2000.0, 'ml', 'L'), 2.0);
      expect(UnitConverter.toBaseUnit(2.0, 'tbsp'), 30.0); // 2 tbsp = 30 ml
      expect(UnitConverter.toBaseUnit(3.0, 'tsp'), 15.0); // 3 tsp = 15 ml
    });

    test('calculates recipe item cost correctly using base unit cost', () {
      // Ingredient: Ribeye 1450 THB / 1 kg -> 1.45 THB per gram
      const costPerGram = 1.45;
      final costFor200g = UnitConverter.calculateItemCost(
        costPerBaseUnit: costPerGram,
        quantityUsed: 200,
        unitUsed: 'g',
      );
      expect(costFor200g, 290.0);

      // Using kg as unitUsed: 0.2 kg -> 200g * 1.45 = 290.0
      final costForPoint2Kg = UnitConverter.calculateItemCost(
        costPerBaseUnit: costPerGram,
        quantityUsed: 0.2,
        unitUsed: 'kg',
      );
      expect(costForPoint2Kg, 290.0);
    });

    test('throws ArgumentError on incompatible unit types', () {
      expect(
        () => UnitConverter.convert(100, 'g', 'ml'),
        throwsArgumentError,
      );
    });
  });
}
