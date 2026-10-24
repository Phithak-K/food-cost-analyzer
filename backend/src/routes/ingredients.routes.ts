import { Router, Request, Response } from 'express';
import { prisma } from '../prisma';
import { UnitConverter } from '../utils/unitConverter';

const router = Router();

// GET /api/ingredients - Fetch all ingredients
router.get('/', async (_req: Request, res: Response) => {
  try {
    const ingredients = await prisma.ingredient.findMany({
      orderBy: { name: 'asc' },
    });
    return res.json({ success: true, data: ingredients });
  } catch (error) {
    console.error('Error fetching ingredients:', error);
    return res.status(500).json({ success: false, error: 'Failed to fetch ingredients' });
  }
});

// POST /api/ingredients - Create new ingredient
router.post('/', async (req: Request, res: Response) => {
  try {
    const { name, category, purchasePrice, purchaseQuantity, purchaseUnit, yieldPercent } = req.body;

    if (!name || !purchasePrice || !purchaseQuantity || !purchaseUnit) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: name, purchasePrice, purchaseQuantity, purchaseUnit',
      });
    }

    const price = parseFloat(purchasePrice);
    const qty = parseFloat(purchaseQuantity);
    const yPct = yieldPercent ? parseFloat(yieldPercent) : 100.0;

    const baseQty = UnitConverter.toBaseUnit(qty, purchaseUnit);
    const costPerBaseUnit = baseQty > 0 ? price / baseQty : 0;

    const created = await prisma.ingredient.create({
      data: {
        name,
        category: category || 'general',
        purchasePrice: price,
        purchaseQuantity: qty,
        purchaseUnit,
        costPerBaseUnit: parseFloat(costPerBaseUnit.toFixed(4)),
        yieldPercent: yPct,
      },
    });

    return res.status(201).json({ success: true, data: created });
  } catch (error) {
    console.error('Error creating ingredient:', error);
    return res.status(500).json({ success: false, error: 'Failed to create ingredient' });
  }
});

// PUT /api/ingredients/:id - Update ingredient details
router.put('/:id', async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    const { name, category, purchasePrice, purchaseQuantity, purchaseUnit, yieldPercent } = req.body;

    const existing = await prisma.ingredient.findUnique({ where: { id } });
    if (!existing) {
      return res.status(404).json({ success: false, error: 'Ingredient not found' });
    }

    const price = purchasePrice !== undefined ? parseFloat(purchasePrice) : Number(existing.purchasePrice);
    const qty = purchaseQuantity !== undefined ? parseFloat(purchaseQuantity) : Number(existing.purchaseQuantity);
    const unit = purchaseUnit || existing.purchaseUnit;
    const yPct = yieldPercent !== undefined ? parseFloat(yieldPercent) : Number(existing.yieldPercent);

    const baseQty = UnitConverter.toBaseUnit(qty, unit);
    const costPerBaseUnit = baseQty > 0 ? price / baseQty : 0;

    const updated = await prisma.ingredient.update({
      where: { id },
      data: {
        name: name || existing.name,
        category: category || existing.category,
        purchasePrice: price,
        purchaseQuantity: qty,
        purchaseUnit: unit,
        costPerBaseUnit: parseFloat(costPerBaseUnit.toFixed(4)),
        yieldPercent: yPct,
      },
    });

    return res.json({ success: true, data: updated });
  } catch (error) {
    console.error('Error updating ingredient:', error);
    return res.status(500).json({ success: false, error: 'Failed to update ingredient' });
  }
});

// PATCH /api/ingredients/:id/price - Fast price update
router.patch('/:id/price', async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    const { purchasePrice } = req.body;

    if (purchasePrice === undefined || purchasePrice === null) {
      return res.status(400).json({ success: false, error: 'purchasePrice is required' });
    }

    const existing = await prisma.ingredient.findUnique({ where: { id } });
    if (!existing) {
      return res.status(404).json({ success: false, error: 'Ingredient not found' });
    }

    const price = parseFloat(purchasePrice);
    const qty = Number(existing.purchaseQuantity);
    const baseQty = UnitConverter.toBaseUnit(qty, existing.purchaseUnit);
    const costPerBaseUnit = baseQty > 0 ? price / baseQty : 0;

    const updated = await prisma.ingredient.update({
      where: { id },
      data: {
        purchasePrice: price,
        costPerBaseUnit: parseFloat(costPerBaseUnit.toFixed(4)),
      },
    });

    return res.json({ success: true, data: updated });
  } catch (error) {
    console.error('Error patching ingredient price:', error);
    return res.status(500).json({ success: false, error: 'Failed to update ingredient price' });
  }
});

// DELETE /api/ingredients/:id - Delete ingredient
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    await prisma.ingredient.delete({ where: { id } });
    return res.json({ success: true, message: 'Ingredient deleted successfully' });
  } catch (error) {
    console.error('Error deleting ingredient:', error);
    return res.status(500).json({ success: false, error: 'Failed to delete ingredient' });
  }
});

export default router;
