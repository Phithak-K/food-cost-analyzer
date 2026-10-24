import { InsufficientStockError } from '../services/orders.service';
import { UnitConverter } from '../utils/unitConverter';

function assert(condition: boolean, message: string) {
  if (!condition) {
    throw new Error(`Assertion failed: ${message}`);
  }
}

console.log('[TEST] Running Orders & BOM Deduction Unit Tests...');

// 1. Test InsufficientStockError construction
const error = new InsufficientStockError('Stock is low', [
  {
    ingredientId: 'ing-1',
    name: 'Wagyu A5',
    availableStock: 0.1,
    requiredStock: 0.4,
    unit: 'kg',
  },
]);

assert(error instanceof Error, 'InsufficientStockError should inherit from Error');
assert(error.name === 'InsufficientStockError', 'Error name should match');
assert(error.insufficientItems.length === 1, 'Should contain 1 insufficient item');
assert(error.insufficientItems[0].name === 'Wagyu A5', 'Item name should match');
console.log('  [OK] InsufficientStockError structures passed');

// 2. Test Multi-Unit Recipe to Stock Deduction Conversion
// Recipe uses 200g of Minced Pork per dish, ordered 3 dishes = 600g
// Stock is stored in 'kg'. Expected deduction: 0.6 kg
const qtyDish = 200; // g
const dishesOrdered = 3;
const totalGrams = qtyDish * dishesOrdered;
const stockDeductionKg = UnitConverter.convert(totalGrams, 'g', 'kg');
assert(Math.abs(stockDeductionKg - 0.6) < 0.0001, `Expected 0.6 kg, got ${stockDeductionKg}`);
console.log('  [OK] Recipe BOM deduction (200g x 3 -> 0.6kg) passed');

// 3. Test Liquid Recipe to Stock Deduction Conversion
// Recipe uses 150ml milk per drink, ordered 10 drinks = 1500ml
// Stock is stored in 'l'. Expected deduction: 1.5 L
const drinkMl = 150;
const drinksOrdered = 10;
const totalMl = drinkMl * drinksOrdered;
const stockDeductionL = UnitConverter.convert(totalMl, 'ml', 'l');
assert(Math.abs(stockDeductionL - 1.5) < 0.0001, `Expected 1.5 L, got ${stockDeductionL}`);
console.log('  [OK] Liquid BOM deduction (150ml x 10 -> 1.5L) passed');

// 4. Test Single Unit Item (Eggs)
// Recipe uses 2 eggs per dish, ordered 5 dishes = 10 eggs
const eggsPerDish = 2;
const eggsOrdered = 5;
const totalEggs = eggsPerDish * eggsOrdered;
const stockDeductionEggs = UnitConverter.convert(totalEggs, 'ฟอง', 'pack'); // 1:1 count base
assert(stockDeductionEggs === 10, `Expected 10 eggs, got ${stockDeductionEggs}`);
console.log('  [OK] Countable BOM deduction (2 eggs x 5 -> 10 eggs) passed');

console.log('[SUCCESS] All Orders & BOM Deduction Unit Tests Passed Successfully!');
