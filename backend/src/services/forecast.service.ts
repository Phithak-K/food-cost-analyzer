import { prisma } from '../prisma';
import { UnitConverter } from '../utils/unitConverter';

export interface IngredientForecast {
  ingredientId: string;
  ingredientName: string;
  category: string;
  purchaseUnit: string;
  currentStock: number;
  shelfLifeDays: number;
  dailyConsumption: number; // Consumption rate in purchaseUnit per day
  daysRemaining: number; // Days until stock runs out at current consumption
  riskLevel: 'CRITICAL' | 'WARNING' | 'SAFE';
  potentialWasteQuantity: number;
  potentialWasteValue: number;
  suggestedOrder7Days: number;
  suggestedOrderValue: number;
  message: string;
  actionRecommendation: string;
}

export interface ForecastSummary {
  totalWasteValueAtRisk: number;
  criticalItemsCount: number;
  warningItemsCount: number;
  safeItemsCount: number;
  suggestedOrderTotalValue: number;
  items: IngredientForecast[];
  forecastBasisDays: number;
  totalOrdersAnalyzed: number;
  generatedAt: string;
}

export class ForecastService {
  /**
   * Intelligently estimate shelf-life (days) based on ingredient characteristics
   */
  static getEstimatedShelfLife(name: string, category: string): number {
    const lowerName = name.toLowerCase();
    const lowerCat = category.toLowerCase();

    if (
      lowerName.includes('ข้าว') ||
      lowerName.includes('แป้ง') ||
      lowerName.includes('ซอส') ||
      lowerName.includes('น้ำมัน') ||
      lowerName.includes('น้ำปลา') ||
      lowerName.includes('น้ำตาล') ||
      lowerName.includes('rice') ||
      lowerName.includes('sauce') ||
      lowerName.includes('oil') ||
      lowerCat.includes('dry') ||
      lowerCat.includes('sauce') ||
      lowerCat.includes('condiment')
    ) {
      return 45; // Dry pantry goods & shelf-stable condiments have ~45 days
    }

    if (
      lowerName.includes('เนื้อ') ||
      lowerName.includes('หมู') ||
      lowerName.includes('ไก่') ||
      lowerName.includes('กุ้ง') ||
      lowerName.includes('ปลา') ||
      lowerName.includes('beef') ||
      lowerName.includes('pork') ||
      lowerName.includes('chicken') ||
      lowerName.includes('shrimp') ||
      lowerCat.includes('meat') ||
      lowerCat.includes('seafood')
    ) {
      return 3; // Fresh raw meats/seafood have ~3 days shelf-life
    }

    if (
      lowerName.includes('กะเพรา') ||
      lowerName.includes('ผัก') ||
      lowerName.includes('พริก') ||
      lowerName.includes('มะนาว') ||
      lowerName.includes('ต้นหอม') ||
      lowerName.includes('หอมแดง') ||
      lowerName.includes('หอมใหญ่') ||
      lowerName.includes('basil') ||
      lowerName.includes('chili') ||
      lowerCat.includes('veg') ||
      lowerCat.includes('produce')
    ) {
      return 4; // Fresh herbs & leafy vegetables have ~4 days
    }

    if (
      lowerName.includes('นม') ||
      lowerName.includes('ครีม') ||
      lowerName.includes('ไข่') ||
      lowerName.includes('milk') ||
      lowerName.includes('cream') ||
      lowerName.includes('egg') ||
      lowerCat.includes('dairy')
    ) {
      return 6; // Fresh dairy & eggs have ~6 days
    }

    return 7; // Standard default 7 days
  }

  /**
   * Calculate demand velocity, waste risks, and reorder suggestions for all ingredients
   */
  static async getDemandAndWasteForecast(): Promise<ForecastSummary> {
    const ingredients = await prisma.ingredient.findMany({
      include: {
        recipeItems: {
          include: {
            recipe: {
              include: {
                salesLogs: true,
              },
            },
          },
        },
      },
      orderBy: { name: 'asc' },
    });

    const recentOrders = await prisma.order.findMany({
      where: {
        status: 'COMPLETED',
      },
      include: {
        items: true,
      },
      orderBy: { createdAt: 'desc' },
      take: 200,
    });

    // 1. Calculate Recipe Daily Sales Velocity
    const recipeSalesMap = new Map<string, number>();
    let basisDays = 14;

    if (recentOrders.length > 0) {
      const now = new Date().getTime();
      const oldestOrderTime = recentOrders[recentOrders.length - 1].createdAt.getTime();
      const daysSpan = Math.max(1, Math.ceil((now - oldestOrderTime) / (1000 * 60 * 60 * 24)));
      basisDays = Math.min(30, Math.max(7, daysSpan));

      for (const order of recentOrders) {
        for (const item of order.items) {
          recipeSalesMap.set(
            item.recipeId,
            (recipeSalesMap.get(item.recipeId) || 0) + item.quantity
          );
        }
      }
    }

    // 2. Compute Ingredient Forecasts
    const items: IngredientForecast[] = [];
    let totalWasteValueAtRisk = 0;
    let criticalItemsCount = 0;
    let warningItemsCount = 0;
    let safeItemsCount = 0;
    let suggestedOrderTotalValue = 0;

    for (const ing of ingredients) {
      const currentStock = Number(ing.currentStock);
      const purchasePrice = Number(ing.purchasePrice);
      const purchaseQuantity = Number(ing.purchaseQuantity) || 1.0;
      const unitCost = purchaseQuantity > 0 ? purchasePrice / purchaseQuantity : 0;
      const purchaseUnit = ing.purchaseUnit;
      const shelfLifeDays = ForecastService.getEstimatedShelfLife(ing.name, ing.category);

      // Sum daily consumption across all recipes using this ingredient
      let dailyConsumptionBaseUnit = 0;

      for (const link of ing.recipeItems) {
        const recipe = link.recipe;
        let recipeDailySales = 0;

        if (recipeSalesMap.has(recipe.id)) {
          recipeDailySales = (recipeSalesMap.get(recipe.id) || 0) / basisDays;
        } else {
          // Fallback to monthly sales logs or default baseline (25 units / month)
          const totalSalesLogs = recipe.salesLogs.reduce((acc, log) => acc + log.quantitySold, 0);
          recipeDailySales = totalSalesLogs > 0 ? totalSalesLogs / 30.0 : 0.8;
        }

        // Amount used per recipe in base unit (grams / ml / pcs)
        const qtyUsedInRecipe = Number(link.quantityUsed);
        const baseQtyPerRecipe = UnitConverter.toBaseUnit(qtyUsedInRecipe, link.unit);
        dailyConsumptionBaseUnit += baseQtyPerRecipe * recipeDailySales;
      }

      // Convert daily consumption from base unit to purchase unit
      const baseToPurchaseUnitRatio = UnitConverter.toBaseUnit(1.0, purchaseUnit) || 1.0;
      const dailyConsumption = dailyConsumptionBaseUnit / baseToPurchaseUnitRatio;

      // Days remaining before current stock is exhausted
      const daysRemaining = dailyConsumption > 0 ? currentStock / dailyConsumption : (currentStock > 0 ? 999 : 0);

      // Waste Calculation: If current stock exceeds what will be consumed within shelf-life
      const maxUsableBeforeExpiry = dailyConsumption * shelfLifeDays;
      let potentialWasteQuantity = 0;
      let potentialWasteValue = 0;

      if (currentStock > maxUsableBeforeExpiry && shelfLifeDays < 30) {
        potentialWasteQuantity = currentStock - maxUsableBeforeExpiry;
        potentialWasteValue = potentialWasteQuantity * unitCost;
      }

      // 7-Day Smart Reorder Suggestion
      const demand7Days = dailyConsumption * 7;
      let suggestedOrder7Days = 0;
      let suggestedOrderValue = 0;

      if (demand7Days > currentStock) {
        suggestedOrder7Days = demand7Days - currentStock;
        suggestedOrderValue = suggestedOrder7Days * unitCost;
      }

      // Determine Risk Level & Actionable Recommendation
      let riskLevel: 'CRITICAL' | 'WARNING' | 'SAFE' = 'SAFE';
      let message = '';
      let actionRecommendation = '';

      if (potentialWasteQuantity > 0 && shelfLifeDays <= 4) {
        riskLevel = 'CRITICAL';
        criticalItemsCount++;
        totalWasteValueAtRisk += potentialWasteValue;
        message = `เสี่ยงเน่าเสียทิ้ง ${potentialWasteQuantity.toFixed(1)} ${purchaseUnit} (คาดใช้ไม่ทันใน ${shelfLifeDays} วัน)`;
        actionRecommendation = 'จัดโปรโมชั่นเมนูเร่งด่วน หรือเพิ่มเป็นเมนูแนะนำประจำวันเพื่อระบายสต็อก';
      } else if (potentialWasteQuantity > 0 || (daysRemaining < 2 && dailyConsumption > 0)) {
        riskLevel = 'WARNING';
        warningItemsCount++;
        totalWasteValueAtRisk += potentialWasteValue;
        if (daysRemaining < 2) {
          message = `สต็อกเหลือน้อยมาก จะหมดใน ${daysRemaining.toFixed(1)} วัน`;
          actionRecommendation = `สั่งซื้อด่วนอย่างน้อย ${suggestedOrder7Days.toFixed(1)} ${purchaseUnit}`;
        } else {
          message = `มีความเสี่ยงใช้ไม่ทันก่อนหมดอายุเล็กน้อย (~${potentialWasteQuantity.toFixed(1)} ${purchaseUnit})`;
          actionRecommendation = 'เฝ้าระวังอัตราการสั่ง และชะลอการสั่งรอบใหม่';
        }
      } else {
        riskLevel = 'SAFE';
        safeItemsCount++;
        message = 'ระดับสต็อกสมดุลกับการใช้งาน ปลอดภัย';
        actionRecommendation = 'รักษาระดับการสั่งซื้อตามปริมาณแนะนำรายสัปดาห์';
      }

      suggestedOrderTotalValue += suggestedOrderValue;

      items.push({
        ingredientId: ing.id,
        ingredientName: ing.name,
        category: ing.category,
        purchaseUnit,
        currentStock,
        shelfLifeDays,
        dailyConsumption: Number(dailyConsumption.toFixed(2)),
        daysRemaining: Number(daysRemaining.toFixed(1)),
        riskLevel,
        potentialWasteQuantity: Number(potentialWasteQuantity.toFixed(2)),
        potentialWasteValue: Number(potentialWasteValue.toFixed(2)),
        suggestedOrder7Days: Number(suggestedOrder7Days.toFixed(2)),
        suggestedOrderValue: Number(suggestedOrderValue.toFixed(2)),
        message,
        actionRecommendation,
      });
    }

    // Sort items so CRITICAL is first, then WARNING, then SAFE
    const priorityOrder = { CRITICAL: 0, WARNING: 1, SAFE: 2 };
    items.sort((a, b) => {
      const pDiff = priorityOrder[a.riskLevel] - priorityOrder[b.riskLevel];
      if (pDiff !== 0) return pDiff;
      return b.potentialWasteValue - a.potentialWasteValue;
    });

    return {
      totalWasteValueAtRisk: Number(totalWasteValueAtRisk.toFixed(2)),
      criticalItemsCount,
      warningItemsCount,
      safeItemsCount,
      suggestedOrderTotalValue: Number(suggestedOrderTotalValue.toFixed(2)),
      items,
      forecastBasisDays: basisDays,
      totalOrdersAnalyzed: recentOrders.length,
      generatedAt: new Date().toISOString(),
    };
  }
}
