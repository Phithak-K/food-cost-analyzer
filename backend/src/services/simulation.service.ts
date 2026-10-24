import { prisma } from '../prisma';
import { UnitConverter } from '../utils/unitConverter';

export interface PriceAdjustment {
  ingredientId: string;
  percentChange?: number; // e.g. 10 for +10%, -5 for -5%
  absolutePriceChange?: number; // e.g. 15 for +15 THB
  newPrice?: number; // exact new purchase price
}

export interface SimulationRequest {
  adjustments: PriceAdjustment[];
  targetCostThreshold?: number; // default 35.0%
}

export interface SimulatedRecipeComparison {
  recipeId: string;
  recipeName: string;
  category: string;
  sellingPrice: number;
  unitsSoldMonthly: number;
  oldCost: number;
  newCost: number;
  costDifference: number;
  costPercentChange: number;
  oldFoodCostPercentage: number;
  newFoodCostPercentage: number;
  foodCostPercentageDifference: number;
  oldContributionMargin: number;
  newContributionMargin: number;
  oldMonthlyProfit: number;
  newMonthlyProfit: number;
  monthlyProfitDifference: number;
  wasOverThreshold: boolean;
  isOverThreshold: boolean;
  becameCritical: boolean;
  usedAdjustedIngredients: string[];
}

export interface StoreSimulationSummary {
  totalMonthlyRevenue: number;
  oldMonthlyTotalCost: number;
  newMonthlyTotalCost: number;
  totalCostDifference: number;
  oldMonthlyGrossProfit: number;
  newMonthlyGrossProfit: number;
  netProfitDifference: number; // e.g. -5000 (profit decreased by 5000 THB)
  oldOverallCostPercentage: number;
  newOverallCostPercentage: number;
  costPercentageDifference: number;
  impactedRecipesCount: number;
  newlyCriticalRecipesCount: number;
  totalCriticalRecipesCount: number;
  adjustedIngredientsSummary: Array<{
    id: string;
    name: string;
    originalPurchasePrice: number;
    simulatedPurchasePrice: number;
    originalCostPerBaseUnit: number;
    simulatedCostPerBaseUnit: number;
    percentChange: number;
  }>;
}

export interface SimulationResult {
  summary: StoreSimulationSummary;
  recipeComparisons: SimulatedRecipeComparison[];
}

export class SimulationService {
  /**
   * Performs What-If Simulation on ingredient price changes without updating the database.
   */
  static async simulateCostImpact(request: SimulationRequest): Promise<SimulationResult> {
    const threshold = request.targetCostThreshold ?? 35.0;
    const adjustmentsMap = new Map<string, PriceAdjustment>();

    for (const adj of request.adjustments) {
      adjustmentsMap.set(adj.ingredientId, adj);
    }

    // 1. Fetch all ingredients
    const allIngredients = await prisma.ingredient.findMany();
    const simulatedIngredientsMap = new Map<
      string,
      {
        id: string;
        name: string;
        origPurchasePrice: number;
        simPurchasePrice: number;
        origCostPerBase: number;
        simCostPerBase: number;
        yieldPercent: number;
        percentChange: number;
      }
    >();

    const adjustedSummary: StoreSimulationSummary['adjustedIngredientsSummary'] = [];

    for (const ing of allIngredients) {
      const origPurchasePrice = Number(ing.purchasePrice);
      const purchaseQty = Number(ing.purchaseQuantity);
      const origCostPerBase = Number(ing.costPerBaseUnit);
      const yieldPct = Number(ing.yieldPercent);

      let simPurchasePrice = origPurchasePrice;
      let simCostPerBase = origCostPerBase;
      let percentChange = 0;

      if (adjustmentsMap.has(ing.id)) {
        const adj = adjustmentsMap.get(ing.id)!;
        if (adj.newPrice !== undefined && adj.newPrice !== null) {
          simPurchasePrice = adj.newPrice;
          percentChange = origPurchasePrice > 0 ? ((simPurchasePrice - origPurchasePrice) / origPurchasePrice) * 100 : 0;
          const baseUnits = UnitConverter.toBaseUnit(purchaseQty, ing.purchaseUnit);
          simCostPerBase = baseUnits > 0 ? simPurchasePrice / baseUnits : origCostPerBase;
        } else if (adj.percentChange !== undefined && adj.percentChange !== null) {
          percentChange = adj.percentChange;
          simPurchasePrice = origPurchasePrice * (1 + adj.percentChange / 100.0);
          simCostPerBase = origCostPerBase * (1 + adj.percentChange / 100.0);
        } else if (adj.absolutePriceChange !== undefined && adj.absolutePriceChange !== null) {
          simPurchasePrice = origPurchasePrice + adj.absolutePriceChange;
          percentChange = origPurchasePrice > 0 ? (adj.absolutePriceChange / origPurchasePrice) * 100 : 0;
          const baseUnits = UnitConverter.toBaseUnit(purchaseQty, ing.purchaseUnit);
          simCostPerBase = baseUnits > 0 ? simPurchasePrice / baseUnits : origCostPerBase;
        }

        if (simPurchasePrice < 0) simPurchasePrice = 0;
        if (simCostPerBase < 0) simCostPerBase = 0;
      }

      simulatedIngredientsMap.set(ing.id, {
        id: ing.id,
        name: ing.name,
        origPurchasePrice,
        simPurchasePrice,
        origCostPerBase,
        simCostPerBase,
        yieldPercent: yieldPct,
        percentChange,
      });

      if (adjustmentsMap.has(ing.id)) {
        adjustedSummary.push({
          id: ing.id,
          name: ing.name,
          originalPurchasePrice: Number(origPurchasePrice.toFixed(2)),
          simulatedPurchasePrice: Number(simPurchasePrice.toFixed(2)),
          originalCostPerBaseUnit: Number(origCostPerBase.toFixed(4)),
          simulatedCostPerBaseUnit: Number(simCostPerBase.toFixed(4)),
          percentChange: Number(percentChange.toFixed(1)),
        });
      }
    }

    // 2. Fetch all recipes with components and sales logs
    const recipes = await prisma.recipe.findMany({
      include: {
        ingredients: {
          include: { ingredient: true },
        },
        salesLogs: {
          orderBy: { period: 'desc' },
          take: 1,
        },
      },
    });

    const comparisons: SimulatedRecipeComparison[] = [];
    let totalMonthlyRevenue = 0;
    let oldMonthlyTotalCost = 0;
    let newMonthlyTotalCost = 0;
    let impactedCount = 0;
    let newlyCriticalCount = 0;
    let totalCriticalCount = 0;

    for (const r of recipes) {
      const sellingPrice = Number(r.sellingPrice);
      const unitsSold = r.salesLogs.length > 0 ? r.salesLogs[0].quantitySold : 0;

      let oldCost = 0;
      let newCost = 0;
      const usedAdjusted: string[] = [];

      for (const ri of r.ingredients) {
        const ingData = simulatedIngredientsMap.get(ri.ingredientId);
        const qty = Number(ri.quantityUsed);

        if (ingData) {
          const itemOldCost = UnitConverter.calculateItemCost(
            ingData.origCostPerBase,
            qty,
            ri.unit,
            ingData.yieldPercent
          );
          const itemNewCost = UnitConverter.calculateItemCost(
            ingData.simCostPerBase,
            qty,
            ri.unit,
            ingData.yieldPercent
          );

          oldCost += itemOldCost;
          newCost += itemNewCost;

          if (adjustmentsMap.has(ri.ingredientId)) {
            usedAdjusted.push(ingData.name);
          }
        }
      }

      const costDiff = newCost - oldCost;
      const costPctChange = oldCost > 0 ? (costDiff / oldCost) * 100 : 0;

      const oldFoodCostPct = sellingPrice > 0 ? (oldCost / sellingPrice) * 100 : 0;
      const newFoodCostPct = sellingPrice > 0 ? (newCost / sellingPrice) * 100 : 0;
      const foodCostPctDiff = newFoodCostPct - oldFoodCostPct;

      const oldMargin = sellingPrice - oldCost;
      const newMargin = sellingPrice - newCost;

      const oldMonthlyProfit = oldMargin * unitsSold;
      const newMonthlyProfit = newMargin * unitsSold;
      const monthlyProfitDiff = newMonthlyProfit - oldMonthlyProfit;

      const wasOver = oldFoodCostPct > threshold;
      const isOver = newFoodCostPct > threshold;
      const becameCritical = !wasOver && isOver;

      if (usedAdjusted.length > 0) impactedCount++;
      if (becameCritical) newlyCriticalCount++;
      if (isOver) totalCriticalCount++;

      totalMonthlyRevenue += sellingPrice * unitsSold;
      oldMonthlyTotalCost += oldCost * unitsSold;
      newMonthlyTotalCost += newCost * unitsSold;

      comparisons.push({
        recipeId: r.id,
        recipeName: r.name,
        category: r.category,
        sellingPrice: Number(sellingPrice.toFixed(2)),
        unitsSoldMonthly: unitsSold,
        oldCost: Number(oldCost.toFixed(2)),
        newCost: Number(newCost.toFixed(2)),
        costDifference: Number(costDiff.toFixed(2)),
        costPercentChange: Number(costPctChange.toFixed(1)),
        oldFoodCostPercentage: Number(oldFoodCostPct.toFixed(2)),
        newFoodCostPercentage: Number(newFoodCostPct.toFixed(2)),
        foodCostPercentageDifference: Number(foodCostPctDiff.toFixed(2)),
        oldContributionMargin: Number(oldMargin.toFixed(2)),
        newContributionMargin: Number(newMargin.toFixed(2)),
        oldMonthlyProfit: Number(oldMonthlyProfit.toFixed(2)),
        newMonthlyProfit: Number(newMonthlyProfit.toFixed(2)),
        monthlyProfitDifference: Number(monthlyProfitDiff.toFixed(2)),
        wasOverThreshold: wasOver,
        isOverThreshold: isOver,
        becameCritical,
        usedAdjustedIngredients: usedAdjusted,
      });
    }

    // Sort comparisons: Impacted and newly critical first, then by monthly loss
    comparisons.sort((a, b) => a.monthlyProfitDifference - b.monthlyProfitDifference);

    const oldMonthlyGrossProfit = totalMonthlyRevenue - oldMonthlyTotalCost;
    const newMonthlyGrossProfit = totalMonthlyRevenue - newMonthlyTotalCost;
    const netProfitDiff = newMonthlyGrossProfit - oldMonthlyGrossProfit;
    const totalCostDiff = newMonthlyTotalCost - oldMonthlyTotalCost;

    const oldOverallCostPct = totalMonthlyRevenue > 0 ? (oldMonthlyTotalCost / totalMonthlyRevenue) * 100 : 0;
    const newOverallCostPct = totalMonthlyRevenue > 0 ? (newMonthlyTotalCost / totalMonthlyRevenue) * 100 : 0;
    const costPctDiff = newOverallCostPct - oldOverallCostPct;

    const summary: StoreSimulationSummary = {
      totalMonthlyRevenue: Number(totalMonthlyRevenue.toFixed(2)),
      oldMonthlyTotalCost: Number(oldMonthlyTotalCost.toFixed(2)),
      newMonthlyTotalCost: Number(newMonthlyTotalCost.toFixed(2)),
      totalCostDifference: Number(totalCostDiff.toFixed(2)),
      oldMonthlyGrossProfit: Number(oldMonthlyGrossProfit.toFixed(2)),
      newMonthlyGrossProfit: Number(newMonthlyGrossProfit.toFixed(2)),
      netProfitDifference: Number(netProfitDiff.toFixed(2)),
      oldOverallCostPercentage: Number(oldOverallCostPct.toFixed(2)),
      newOverallCostPercentage: Number(newOverallCostPct.toFixed(2)),
      costPercentageDifference: Number(costPctDiff.toFixed(2)),
      impactedRecipesCount: impactedCount,
      newlyCriticalRecipesCount: newlyCriticalCount,
      totalCriticalRecipesCount: totalCriticalCount,
      adjustedIngredientsSummary: adjustedSummary,
    };

    return {
      summary,
      recipeComparisons: comparisons,
    };
  }
}
