import { UnitConverter } from '../utils/unitConverter';

function assert(condition: boolean, message: string) {
  if (!condition) {
    throw new Error(`Assertion failed: ${message}`);
  }
}

console.log('🧪 Running Backend Unit Tests...');

// 1. Mass Conversion Test
const kgToBase = UnitConverter.toBaseUnit(1.5, 'kg');
assert(kgToBase === 1500, `Expected 1500g, got ${kgToBase}g`);
console.log('  ✓ Mass conversion (1.5kg -> 1500g) passed');

// 2. Volume Conversion Test
const lToBase = UnitConverter.toBaseUnit(2.0, 'l');
assert(lToBase === 2000, `Expected 2000ml, got ${lToBase}ml`);
console.log('  ✓ Volume conversion (2.0L -> 2000ml) passed');

// 3. Item Cost Calculation with Yield
// Cost per base unit = 0.5 THB/g, Quantity = 200g, Yield = 90% -> Effective qty = 200 / 0.9 = 222.22g -> Cost = 111.11 THB
const itemCost = UnitConverter.calculateItemCost(0.5, 200, 'g', 90);
assert(Math.abs(itemCost - 111.11) < 0.05, `Expected ~111.11, got ${itemCost}`);
console.log('  ✓ Item cost calculation with yield (90%) passed');

console.log('🎉 All Backend Unit Tests Passed Successfully!');
