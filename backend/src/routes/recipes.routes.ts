import { Router, Request, Response } from 'express';
import { prisma } from '../prisma';
import { CalculatorService } from '../services/calculator.service';

const router = Router();

// GET /api/recipes - Fetch all recipes with their ingredients and latest sales logs
router.get('/', async (_req: Request, res: Response) => {
  try {
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
      orderBy: { name: 'asc' },
    });

    // Augment with calculated totalCost and contributionMargin
    const enriched = await Promise.all(
      recipes.map(async (r) => {
        const breakdown = await CalculatorService.getRecipeCostBreakdown(r.id);
        const unitsSold = r.salesLogs.length > 0 ? r.salesLogs[0].quantitySold : 0;
        return {
          ...r,
          totalCost: breakdown?.totalCost ?? 0,
          foodCostPercentage: breakdown?.foodCostPercentage ?? 0,
          contributionMargin: breakdown?.contributionMargin ?? 0,
          unitsSoldMonthly: unitsSold,
        };
      })
    );

    return res.json({ success: true, data: enriched });
  } catch (error) {
    console.error('Error fetching recipes:', error);
    return res.status(500).json({ success: false, error: 'Failed to fetch recipes' });
  }
});

// GET /api/recipes/:id - Fetch single recipe by ID
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    const recipe = await prisma.recipe.findUnique({
      where: { id },
      include: {
        ingredients: {
          include: { ingredient: true },
        },
        salesLogs: {
          orderBy: { period: 'desc' },
        },
      },
    });

    if (!recipe) {
      return res.status(404).json({ success: false, error: 'Recipe not found' });
    }

    const breakdown = await CalculatorService.getRecipeCostBreakdown(id);

    return res.json({
      success: true,
      data: {
        ...recipe,
        breakdown,
      },
    });
  } catch (error) {
    console.error('Error fetching recipe:', error);
    return res.status(500).json({ success: false, error: 'Failed to fetch recipe' });
  }
});

// GET /api/recipes/:id/cost-breakdown - Core calculation endpoint for recipe cost breakdown
router.get('/:id/cost-breakdown', async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    const breakdown = await CalculatorService.getRecipeCostBreakdown(id);

    if (!breakdown) {
      return res.status(404).json({ success: false, error: 'Recipe not found' });
    }

    return res.json({ success: true, data: breakdown });
  } catch (error) {
    console.error('Error getting cost breakdown:', error);
    return res.status(500).json({ success: false, error: 'Failed to calculate cost breakdown' });
  }
});

// POST /api/recipes - Create new recipe with components
router.post('/', async (req: Request, res: Response) => {
  try {
    const { name, category, sellingPrice, targetCostPercent, items, initialSalesVolume } = req.body;

    if (!name || sellingPrice === undefined) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: name, sellingPrice',
      });
    }

    const price = parseFloat(sellingPrice);
    const targetPct = targetCostPercent ? parseFloat(targetCostPercent) : 30.0;

    const created = await prisma.recipe.create({
      data: {
        name,
        category: category || 'food',
        sellingPrice: price,
        targetCostPercent: targetPct,
        ingredients: {
          create: (items || []).map((item: any) => ({
            ingredientId: item.ingredientId,
            quantityUsed: parseFloat(item.quantityUsed),
            unit: item.unit,
          })),
        },
        salesLogs: initialSalesVolume
          ? {
              create: {
                quantitySold: parseInt(initialSalesVolume, 10),
                period: new Date(),
              },
            }
          : undefined,
      },
      include: {
        ingredients: {
          include: { ingredient: true },
        },
      },
    });

    const breakdown = await CalculatorService.getRecipeCostBreakdown(created.id);

    return res.status(201).json({
      success: true,
      data: {
        ...created,
        breakdown,
      },
    });
  } catch (error) {
    console.error('Error creating recipe:', error);
    return res.status(500).json({ success: false, error: 'Failed to create recipe' });
  }
});

// PUT /api/recipes/:id - Update recipe and replace ingredient list
router.put('/:id', async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    const { name, category, sellingPrice, targetCostPercent, items } = req.body;

    const existing = await prisma.recipe.findUnique({ where: { id } });
    if (!existing) {
      return res.status(404).json({ success: false, error: 'Recipe not found' });
    }

    // Update recipe in a transaction
    await prisma.$transaction(async (tx) => {
      // 1. Update recipe info
      await tx.recipe.update({
        where: { id },
        data: {
          name: name || existing.name,
          category: category || existing.category,
          sellingPrice: sellingPrice !== undefined ? parseFloat(sellingPrice) : existing.sellingPrice,
          targetCostPercent: targetCostPercent !== undefined ? parseFloat(targetCostPercent) : existing.targetCostPercent,
        },
      });

      // 2. If items provided, replace ingredients
      if (items && Array.isArray(items)) {
        await tx.recipeIngredient.deleteMany({ where: { recipeId: id } });
        await tx.recipeIngredient.createMany({
          data: items.map((item: any) => ({
            recipeId: id,
            ingredientId: item.ingredientId,
            quantityUsed: parseFloat(item.quantityUsed),
            unit: item.unit,
          })),
        });
      }
    });

    const updated = await prisma.recipe.findUnique({
      where: { id },
      include: {
        ingredients: {
          include: { ingredient: true },
        },
      },
    });

    const breakdown = await CalculatorService.getRecipeCostBreakdown(id);

    return res.json({
      success: true,
      data: {
        ...updated,
        breakdown,
      },
    });
  } catch (error) {
    console.error('Error updating recipe:', error);
    return res.status(500).json({ success: false, error: 'Failed to update recipe' });
  }
});

// DELETE /api/recipes/:id - Delete recipe
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    await prisma.recipe.delete({ where: { id } });
    return res.json({ success: true, message: 'Recipe deleted successfully' });
  } catch (error) {
    console.error('Error deleting recipe:', error);
    return res.status(500).json({ success: false, error: 'Failed to delete recipe' });
  }
});

export default router;
