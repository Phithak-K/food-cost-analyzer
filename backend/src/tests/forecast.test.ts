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

  // 2. Full Forecast Execution
  const forecast = await ForecastService.getDemandAndWasteForecast();
  assert(typeof forecast.totalWasteValueAtRisk === 'number', 'Expected totalWasteValueAtRisk to be a number');
  assert(Array.isArray(forecast.items), 'Expected forecast items to be an array');
  assert(forecast.items.length > 0, 'Expected at least 1 ingredient forecast item');

  // Check structure of first item
  const first = forecast.items[0];
  assert(typeof first.ingredientId === 'string', 'Expected ingredientId');
  assert(typeof first.dailyConsumption === 'number', 'Expected dailyConsumption');
  assert(['CRITICAL', 'WARNING', 'SAFE'].includes(first.riskLevel), 'Expected valid riskLevel');
  assert(typeof first.suggestedOrder7Days === 'number', 'Expected suggestedOrder7Days');

  console.log(`  [OK] Forecast computation succeeded for ${forecast.items.length} ingredients (Risk at stake: ฿${forecast.totalWasteValueAtRisk})`);
  console.log('[SUCCESS] All Forecast Unit Tests Passed Successfully!');
}

runForecastTests().catch((err) => {
  console.error('[FAILED] Forecast test failed:', err);
  process.exit(1);
});
