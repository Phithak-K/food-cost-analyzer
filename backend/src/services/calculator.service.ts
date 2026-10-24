import { prisma } from '../prisma';
import { UnitConverter } from '../utils/unitConverter';

export interface IngredientCostDetail {
  ingredientId: string;
  name: string;
  category: string;
  quantityUsed: number;
  unit: string;
  costPerBaseUnit: number;
  yieldPercent: number;
  itemCost: number;
  percentageOfTotalCost: number;
}

export interface RecipeCostBreakdown {
  id: string;
  name: string;
  category: string;
  sellingPrice: number;
  targetCostPercent: number;
  totalCost: number;
  foodCostPercentage: number;
  contributionMargin: number;
  isOverTarget: boolean;
  status: 'EXCELLENT' | 'OPTIMAL' | 'CRITICAL';
  items: IngredientCostDetail[];
}

export interface MenuMatrixItem {
  recipeId: string;
  name: string;
  category: string;
  sellingPrice: number;
  totalCost: number;
  contributionMargin: number;
  foodCostPercentage: number;
  unitsSold: number;
  totalRevenue: number;
  totalProfit: number;
  quadrant: 'STAR' | 'PLOWHORSE' | 'PUZZLE' | 'DOG';
  quadrantName: string;
  strategy: string;
}

export interface MenuMatrixAnalytics {
  averageUnitsSold: number;
  averageContributionMargin: number;
  totalRevenue: number;
  totalFoodCost: number;
  totalGrossProfit: number;
  overallFoodCostPercentage: number;
  quadrantCounts: {
    stars: number;
    plowhorses: number;
    puzzles: number;
    dogs: number;
  };
  recommendations: {
    plowhorseStrategy: string;
    dogStrategy: string;
    starStrategy: string;
    puzzleStrategy: string;
  };
  items: MenuMatrixItem[];
}

export class CalculatorService {
  /**
   * Computes the detailed cost breakdown of a single recipe.
   */
  static async getRecipeCostBreakdown(recipeId: string): Promise<RecipeCostBreakdown | null> {
    const recipe = await prisma.recipe.findUnique({
      where: { id: recipeId },
      include: {
        ingredients: {
          include: {
            ingredient: true,
          },
        },
      },
    });

    if (!recipe) return null;

    const sellingPrice = Number(recipe.sellingPrice);
    const targetCostPercent = Number(recipe.targetCostPercent);

    // Compute cost per item
    let totalCost = 0;
    const rawItems = recipe.ingredients.map((ri) => {
      const costPerBase = Number(ri.ingredient.costPerBaseUnit);
      const yieldPct = Number(ri.ingredient.yieldPercent);
      const qty = Number(ri.quantityUsed);

      const itemCost = UnitConverter.calculateItemCost(costPerBase, qty, ri.unit, yieldPct);
      totalCost += itemCost;

      return {
        ingredientId: ri.ingredient.id,
        name: ri.ingredient.name,
        category: ri.ingredient.category,
        quantityUsed: qty,
        unit: ri.unit,
        costPerBaseUnit: costPerBase,
        yieldPercent: yieldPct,
        itemCost: Number(itemCost.toFixed(2)),
      };
    });

    const foodCostPercentage = sellingPrice > 0 ? (totalCost / sellingPrice) * 100 : 0;
    const contributionMargin = sellingPrice - totalCost;

    const items: IngredientCostDetail[] = rawItems.map((item) => ({
      ...item,
      percentageOfTotalCost: totalCost > 0 ? Number(((item.itemCost / totalCost) * 100).toFixed(1)) : 0,
    }));

    const isOverTarget = foodCostPercentage > targetCostPercent;
    let status: 'EXCELLENT' | 'OPTIMAL' | 'CRITICAL' = 'OPTIMAL';
    if (foodCostPercentage <= 28) status = 'EXCELLENT';
    else if (foodCostPercentage > 35) status = 'CRITICAL';

    return {
      id: recipe.id,
      name: recipe.name,
      category: recipe.category,
      sellingPrice: Number(sellingPrice.toFixed(2)),
      targetCostPercent: Number(targetCostPercent.toFixed(1)),
      totalCost: Number(totalCost.toFixed(2)),
      foodCostPercentage: Number(foodCostPercentage.toFixed(2)),
      contributionMargin: Number(contributionMargin.toFixed(2)),
      isOverTarget,
      status,
      items,
    };
  }

  /**
   * Computes the Kasavana & Smith 4-Quadrant Menu Matrix.
   */
  static async getMenuMatrixAnalytics(): Promise<MenuMatrixAnalytics> {
    const recipes = await prisma.recipe.findMany({
      include: {
        ingredients: {
          include: {
            ingredient: true,
          },
        },
        salesLogs: {
          orderBy: { period: 'desc' },
          take: 1,
        },
      },
    });

    if (recipes.length === 0) {
      return {
        averageUnitsSold: 0,
        averageContributionMargin: 0,
        totalRevenue: 0,
        totalFoodCost: 0,
        totalGrossProfit: 0,
        overallFoodCostPercentage: 0,
        quadrantCounts: { stars: 0, plowhorses: 0, puzzles: 0, dogs: 0 },
        recommendations: {
          plowhorseStrategy: 'ขายดีแต่กำไรน้อย แนะนำลดสัดส่วนวัตถุดิบบางตัวหรือขึ้นราคา',
          dogStrategy: 'ขายไม่ออกและกำไรต่ำ แนะนำพิจารณาตัดออกจากเมนู',
          starStrategy: 'ยอดขายสูงและกำไรดี แนะนำรักษามาตรฐานคุณภาพและโปรโมตต่อเนื่อง',
          puzzleStrategy: 'กำไรสูงแต่ขายได้น้อย แนะนำทำการตลาด ปรับตำแหน่งในเมนู หรือจัดเซ็ตคอมโบ',
        },
        items: [],
      };
    }

    // Calculate recipe metrics
    const evaluatedRecipes = recipes.map((r) => {
      const sellingPrice = Number(r.sellingPrice);
      let totalCost = 0;
      for (const ri of r.ingredients) {
        const costPerBase = Number(ri.ingredient.costPerBaseUnit);
        const yieldPct = Number(ri.ingredient.yieldPercent);
        const qty = Number(ri.quantityUsed);
        totalCost += UnitConverter.calculateItemCost(costPerBase, qty, ri.unit, yieldPct);
      }

      const margin = sellingPrice - totalCost;
      const costPct = sellingPrice > 0 ? (totalCost / sellingPrice) * 100 : 0;
      const unitsSold = r.salesLogs.length > 0 ? r.salesLogs[0].quantitySold : 0;

      return {
        recipeId: r.id,
        name: r.name,
        category: r.category,
        sellingPrice: Number(sellingPrice.toFixed(2)),
        totalCost: Number(totalCost.toFixed(2)),
        contributionMargin: Number(margin.toFixed(2)),
        foodCostPercentage: Number(costPct.toFixed(2)),
        unitsSold,
        totalRevenue: Number((sellingPrice * unitsSold).toFixed(2)),
        totalProfit: Number((margin * unitsSold).toFixed(2)),
        totalCostAll: Number((totalCost * unitsSold).toFixed(2)),
      };
    });

    // Averages
    const totalUnitsSold = evaluatedRecipes.reduce((sum, item) => sum + item.unitsSold, 0);
    const averageUnitsSold = recipes.length > 0 ? totalUnitsSold / recipes.length : 0;

    const totalMargin = evaluatedRecipes.reduce((sum, item) => sum + item.contributionMargin, 0);
    const averageContributionMargin = recipes.length > 0 ? totalMargin / recipes.length : 0;

    const totalRevenue = evaluatedRecipes.reduce((sum, item) => sum + item.totalRevenue, 0);
    const totalFoodCost = evaluatedRecipes.reduce((sum, item) => sum + item.totalCostAll, 0);
    const totalGrossProfit = evaluatedRecipes.reduce((sum, item) => sum + item.totalProfit, 0);
    const overallFoodCostPercentage = totalRevenue > 0 ? (totalFoodCost / totalRevenue) * 100 : 0;

    let starsCount = 0;
    let plowhorsesCount = 0;
    let puzzlesCount = 0;
    let dogsCount = 0;

    const items: MenuMatrixItem[] = evaluatedRecipes.map((item) => {
      const isHighVolume = item.unitsSold >= averageUnitsSold;
      const isHighMargin = item.contributionMargin >= averageContributionMargin;

      let quadrant: 'STAR' | 'PLOWHORSE' | 'PUZZLE' | 'DOG';
      let quadrantName: string;
      let strategy: string;

      if (isHighVolume && isHighMargin) {
        quadrant = 'STAR';
        quadrantName = 'Star (ดาวเด่น)';
        strategy = 'ยอดขายสูงและกำไรดี แนะนำรักษามาตรฐานคุณภาพและโปรโมตต่อเนื่อง';
        starsCount++;
      } else if (isHighVolume && !isHighMargin) {
        quadrant = 'PLOWHORSE';
        quadrantName = 'Plowhorse (ม้างาน)';
        strategy = 'ขายดีแต่กำไรน้อย แนะนำลดสัดส่วนวัตถุดิบบางตัวหรือขึ้นราคา';
        plowhorsesCount++;
      } else if (!isHighVolume && isHighMargin) {
        quadrant = 'PUZZLE';
        quadrantName = 'Puzzle (ปริศนา)';
        strategy = 'กำไรสูงแต่ขายได้น้อย แนะนำทำการตลาด ปรับตำแหน่งในเมนู หรือจัดเซ็ตคอมโบ';
        puzzlesCount++;
      } else {
        quadrant = 'DOG';
        quadrantName = 'Dog (ตัดทิ้ง/ปรับปรุง)';
        strategy = 'ขายไม่ออกและกำไรต่ำ แนะนำพิจารณาตัดออกจากเมนู';
        dogsCount++;
      }

      return {
        recipeId: item.recipeId,
        name: item.name,
        category: item.category,
        sellingPrice: item.sellingPrice,
        totalCost: item.totalCost,
        contributionMargin: item.contributionMargin,
        foodCostPercentage: item.foodCostPercentage,
        unitsSold: item.unitsSold,
        totalRevenue: item.totalRevenue,
        totalProfit: item.totalProfit,
        quadrant,
        quadrantName,
        strategy,
      };
    });

    return {
      averageUnitsSold: Number(averageUnitsSold.toFixed(1)),
      averageContributionMargin: Number(averageContributionMargin.toFixed(2)),
      totalRevenue: Number(totalRevenue.toFixed(2)),
      totalFoodCost: Number(totalFoodCost.toFixed(2)),
      totalGrossProfit: Number(totalGrossProfit.toFixed(2)),
      overallFoodCostPercentage: Number(overallFoodCostPercentage.toFixed(2)),
      quadrantCounts: {
        stars: starsCount,
        plowhorses: plowhorsesCount,
        puzzles: puzzlesCount,
        dogs: dogsCount,
      },
      recommendations: {
        plowhorseStrategy: 'ขายดีแต่กำไรน้อย แนะนำลดสัดส่วนวัตถุดิบบางตัวหรือขึ้นราคา',
        dogStrategy: 'ขายไม่ออกและกำไรต่ำ แนะนำพิจารณาตัดออกจากเมนู',
        starStrategy: 'ยอดขายสูงและกำไรดี แนะนำรักษามาตรฐานคุณภาพและโปรโมตต่อเนื่อง',
        puzzleStrategy: 'กำไรสูงแต่ขายได้น้อย แนะนำทำการตลาด ปรับตำแหน่งในเมนู หรือจัดเซ็ตคอมโบ',
      },
      items,
    };
  }
}
