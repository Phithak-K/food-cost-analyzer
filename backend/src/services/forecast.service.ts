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
   * Pure calculation logic for ingredient forecast, waste risks, and suggested reorders
   */
  static calculateItemForecast(params: {
    ingredientId: string;
    ingredientName: string;
    category: string;
    purchaseUnit: string;
    currentStock: number;
    unitCost: number;
    dailyConsumption: number;
    shelfLifeDays: number;
  }): IngredientForecast {
    const {
      ingredientId,
      ingredientName,
      category,
      purchaseUnit,
      currentStock,
      unitCost,
      dailyConsumption,
      shelfLifeDays,
    } = params;

    const daysRemaining = dailyConsumption > 0 ? currentStock / dailyConsumption : 999;

    let riskLevel: 'CRITICAL' | 'WARNING' | 'SAFE' = 'SAFE';
    let potentialWasteQuantity = 0;
    let potentialWasteValue = 0;
    let suggestedOrder7Days = 0;
    let suggestedOrderValue = 0;
    let message = 'ระดับสต็อกเพียงพอและอยู่ในเกณฑ์ปลอดภัย';
    let actionRecommendation = 'ยังไม่ต้องสั่งซื้อเพิ่มเติมในสัปดาห์นี้';

    if (daysRemaining > shelfLifeDays && currentStock > 0) {
      riskLevel = 'CRITICAL';
      const usableStockBeforeExpiry = dailyConsumption * shelfLifeDays;
      potentialWasteQuantity = Math.max(0, currentStock - usableStockBeforeExpiry);
      potentialWasteValue = potentialWasteQuantity * unitCost;
      message = `เสี่ยงเน่าเสียสูง! สต็อกจะหมดอายุในอีก ${shelfLifeDays} วัน แต่ปริมาณบริโภคทันเพียง ${usableStockBeforeExpiry.toFixed(1)} ${purchaseUnit}`;
      actionRecommendation = `แนะนำจัดโปรโมชั่นลดราคาหรือเพิ่มเมนูแนะนำที่ใช้วัตถุดิบนี้ด่วน เพื่อระบายสต็อก ${potentialWasteQuantity.toFixed(1)} ${purchaseUnit}`;
    } else if (daysRemaining <= 2.0) {
      riskLevel = 'WARNING';
      const demand7Days = dailyConsumption * 7.0;
      suggestedOrder7Days = Math.max(0, demand7Days - currentStock);
      suggestedOrderValue = suggestedOrder7Days * unitCost;
      message = `สต็อกใกล้หมด! เหลือพอใช้เพียง ${daysRemaining.toFixed(1)} วัน (อัตราใช้ ${dailyConsumption.toFixed(2)} ${purchaseUnit}/วัน)`;
      actionRecommendation = `ควรสั่งซื้อเพิ่มประมาณ ${suggestedOrder7Days.toFixed(1)} ${purchaseUnit} เพื่อสำรองการใช้งาน 7 วัน`;
    } else {
      riskLevel = 'SAFE';
      const demand7Days = dailyConsumption * 7.0;
      if (currentStock < demand7Days) {
        suggestedOrder7Days = demand7Days - currentStock;
        suggestedOrderValue = suggestedOrder7Days * unitCost;
        actionRecommendation = `สต็อกปลอดภัย แต่สามารถสั่งเพิ่ม ${suggestedOrder7Days.toFixed(1)} ${purchaseUnit} เพื่อสำรองให้ครบ 7 วัน`;
      }
    }

    return {
      ingredientId,
      ingredientName,
      category,
      purchaseUnit,
      currentStock: Number(currentStock.toFixed(2)),
      shelfLifeDays,
      dailyConsumption: Number(dailyConsumption.toFixed(3)),
      daysRemaining: Number(daysRemaining.toFixed(1)),
      riskLevel,
      potentialWasteQuantity: Number(potentialWasteQuantity.toFixed(2)),
      potentialWasteValue: Number(potentialWasteValue.toFixed(2)),
      suggestedOrder7Days: Number(suggestedOrder7Days.toFixed(2)),
      suggestedOrderValue: Number(suggestedOrderValue.toFixed(2)),
      message,
      actionRecommendation,
    };
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

      const itemForecast = ForecastService.calculateItemForecast({
        ingredientId: ing.id,
        ingredientName: ing.name,
        category: ing.category,
        purchaseUnit,
        currentStock,
        unitCost,
        dailyConsumption,
        shelfLifeDays,
      });

      if (itemForecast.riskLevel === 'CRITICAL') {
        criticalItemsCount++;
        totalWasteValueAtRisk += itemForecast.potentialWasteValue;
      } else if (itemForecast.riskLevel === 'WARNING') {
        warningItemsCount++;
        totalWasteValueAtRisk += itemForecast.potentialWasteValue;
      } else {
        safeItemsCount++;
      }

      suggestedOrderTotalValue += itemForecast.suggestedOrderValue;
      items.push(itemForecast);
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
