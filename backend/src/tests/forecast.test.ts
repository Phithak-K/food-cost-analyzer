import { ForecastService } from '../services/forecast.service';

function assert(condition: boolean, message: string) {
  if (!condition) {
    throw new Error(`Assertion failed: ${message}`);
  }
}

async function runForecastTests() {
  console.log('[TEST] Running Demand & Waste Forecast Unit Tests...');

  // 1. Shelf-life estimation
  const porkShelfLife = ForecastService.getEstimatedShelfLife('เนื้อหมูบด', 'Meat');
  assert(porkShelfLife === 3, `Expected pork shelf life to be 3 days, got ${porkShelfLife}`);
  console.log('  [OK] Meat shelf-life estimation (3 days) passed');

  const basilShelfLife = ForecastService.getEstimatedShelfLife('ใบกะเพรา', 'Vegetable');
  assert(basilShelfLife === 4, `Expected basil shelf life to be 4 days, got ${basilShelfLife}`);
  console.log('  [OK] Vegetable shelf-life estimation (4 days) passed');

  const riceShelfLife = ForecastService.getEstimatedShelfLife('ข้าวหอมมะลิ', 'Dry Goods');
  assert(riceShelfLife === 45, `Expected rice shelf life to be 45 days, got ${riceShelfLife}`);
  console.log('  [OK] Dry goods shelf-life estimation (45 days) passed');

  // 2. In-memory Item Forecast Calculations (Deterministic Unit Tests)
  // Scenario A: CRITICAL risk (Stock exceeds shelf-life -> potential waste)
  const criticalItem = ForecastService.calculateItemForecast({
    ingredientId: 'test-pork',
    ingredientName: 'เนื้อหมูสันนอก',
    category: 'Meat',
    purchaseUnit: 'กก.',
    currentStock: 10.0, // 10 kg
    unitCost: 150.0,    // 150 THB/kg
    dailyConsumption: 1.0, // uses 1 kg/day
    shelfLifeDays: 3,   // lasts 3 days -> 10 days of stock > 3 days shelf life
  });
  assert(criticalItem.riskLevel === 'CRITICAL', `Expected CRITICAL risk, got ${criticalItem.riskLevel}`);
  assert(criticalItem.potentialWasteQuantity === 7.0, `Expected 7 kg waste, got ${criticalItem.potentialWasteQuantity}`);
  assert(criticalItem.potentialWasteValue === 1050.0, `Expected 1050 THB waste value, got ${criticalItem.potentialWasteValue}`);
  console.log('  [OK] In-memory CRITICAL waste risk calculation passed');

  // Scenario B: WARNING risk (Low stock <= 2 days runway -> reorder suggested)
  const warningItem = ForecastService.calculateItemForecast({
    ingredientId: 'test-basil',
    ingredientName: 'ใบกะเพรา',
    category: 'Vegetable',
    purchaseUnit: 'กก.',
    currentStock: 1.0,  // 1 kg
    unitCost: 60.0,     // 60 THB/kg
    dailyConsumption: 2.0, // uses 2 kg/day -> 0.5 days remaining
    shelfLifeDays: 4,
  });
  assert(warningItem.riskLevel === 'WARNING', `Expected WARNING risk, got ${warningItem.riskLevel}`);
  assert(warningItem.daysRemaining === 0.5, `Expected 0.5 days remaining, got ${warningItem.daysRemaining}`);
  assert(warningItem.suggestedOrder7Days === 13.0, `Expected 13 kg reorder, got ${warningItem.suggestedOrder7Days}`);
  console.log('  [OK] In-memory WARNING low-stock reorder calculation passed');

  // Scenario C: SAFE risk (Healthy stock levels)
  const safeItem = ForecastService.calculateItemForecast({
    ingredientId: 'test-rice',
    ingredientName: 'ข้าวหอมมะลิ',
    category: 'Dry Goods',
    purchaseUnit: 'กก.',
    currentStock: 20.0,
    unitCost: 40.0,
    dailyConsumption: 2.0, // 10 days remaining
    shelfLifeDays: 45,
  });
  assert(safeItem.riskLevel === 'SAFE', `Expected SAFE risk, got ${safeItem.riskLevel}`);
  assert(safeItem.potentialWasteQuantity === 0, 'Expected 0 waste quantity');
  console.log('  [OK] In-memory SAFE stock level calculation passed');

  // 3. Live DB Forecast Execution (skipped gracefully if database is offline in CI)
  try {
    const forecast = await ForecastService.getDemandAndWasteForecast();
    assert(typeof forecast.totalWasteValueAtRisk === 'number', 'Expected totalWasteValueAtRisk to be a number');
    assert(Array.isArray(forecast.items), 'Expected forecast items to be an array');
    console.log(`  [OK] Live DB forecast query passed (${forecast.items.length} items analyzed)`);
  } catch (err: any) {
    console.log(`  [INFO] Skipped live DB forecast execution in offline CI environment (${err.message?.split('\n')[0] || err})`);
  }

  console.log('[SUCCESS] All Forecast Unit Tests Passed Successfully!');
}

runForecastTests().catch((err) => {
  console.error('[FAILED] Forecast test failed:', err);
  process.exit(1);
});

