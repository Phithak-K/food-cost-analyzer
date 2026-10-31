import { prisma } from '../prisma';
import { UnitConverter } from '../utils/unitConverter';
import { OrderStatus, Prisma } from '@prisma/client';

export interface CreateOrderItemInput {
  recipeId: string;
  quantity: number;
  recipeName?: string;
  pricePerUnit?: number;
}

export interface CreateOrderInput {
  items: CreateOrderItemInput[];
  orderNumber?: string;
  tableNumber?: string;
  orderType?: string;
}

export interface InsufficientIngredientDetail {
  ingredientId: string;
  name: string;
  availableStock: number;
  requiredStock: number;
  unit: string;
}

export class InsufficientStockError extends Error {
  public readonly insufficientItems: InsufficientIngredientDetail[];

  constructor(message: string, insufficientItems: InsufficientIngredientDetail[]) {
    super(message);
    this.name = 'InsufficientStockError';
    this.insufficientItems = insufficientItems;
  }
}

export class OrdersService {
  /**
   * Creates an order with atomic stock validation and automated Recipe BOM deduction.
   */
  static async createOrder(input: CreateOrderInput) {
    if (!input.items || !Array.isArray(input.items) || input.items.length === 0) {
      throw new Error('Order must contain at least one item');
    }

    // Validate quantities
    for (const item of input.items) {
      if (!item.recipeId) {
        throw new Error('Each item must specify a recipeId');
      }
      if (!Number.isInteger(item.quantity) || item.quantity <= 0) {
        throw new Error(`Quantity for recipe ${item.recipeId} must be a positive integer`);
      }
    }

    return await prisma.$transaction(async (tx) => {
      const recipeIds = Array.from(new Set(input.items.map((i) => i.recipeId)));

      // 1. Fetch recipes with their ingredient breakdown
      const recipes = await tx.recipe.findMany({
        where: { id: { in: recipeIds } },
        include: {
          ingredients: {
            include: {
              ingredient: true,
            },
          },
        },
      });

      const recipeMap = new Map<string, any>(recipes.map((r) => [r.id, r]));

      // Fallback matching: If mock client IDs like 'rec_1' are used, map to seeded recipes
      let allDbRecipes: any[] | null = null;
      for (const item of input.items) {
        if (!recipeMap.has(item.recipeId)) {
          if (!allDbRecipes) {
            allDbRecipes = await tx.recipe.findMany({
              orderBy: { createdAt: 'asc' },
              include: {
                ingredients: {
                  include: {
                    ingredient: true,
                  },
                },
              },
            });
          }
          let matched: any = null;
          if (item.recipeId.startsWith('rec_')) {
            const index = parseInt(item.recipeId.replace('rec_', ''), 10) - 1;
            if (index >= 0 && index < allDbRecipes.length) {
              matched = allDbRecipes[index];
            }
          }
          if (!matched && item.recipeName) {
            matched = allDbRecipes.find(
              (r) => r.name.trim().toLowerCase() === item.recipeName!.trim().toLowerCase()
            );
          }
          if (matched) {
            recipeMap.set(item.recipeId, matched);
          }
        }
      }

      for (const recipeId of recipeIds) {
        if (!recipeMap.has(recipeId)) {
          throw new Error(`Recipe not found with ID: ${recipeId}`);
        }
      }

      // 2. Aggregate total ingredient consumption across all ordered items (BOM calculation)
      const ingredientConsumption = new Map<
        string,
        {
          id: string;
          name: string;
          purchaseUnit: string;
          currentStock: number;
          requiredStock: number;
        }
      >();

      let totalOrderAmount = 0;
      let totalOrderCost = 0;

      const preparedOrderItems: {
        recipeId: string;
        quantity: number;
        pricePerUnit: number;
        costPerUnit: number;
      }[] = [];

      for (const item of input.items) {
        const recipe = recipeMap.get(item.recipeId)!;
        const sellingPrice = Number(recipe.sellingPrice);

        // Compute cost per unit for this recipe
        let singleRecipeCost = 0;
        for (const ri of recipe.ingredients) {
          const costPerBase = Number(ri.ingredient.costPerBaseUnit);
          const yieldPct = Number(ri.ingredient.yieldPercent);
          const qtyUsed = Number(ri.quantityUsed);

          const itemCost = UnitConverter.calculateItemCost(costPerBase, qtyUsed, ri.unit, yieldPct);
          singleRecipeCost += itemCost;

          // Convert quantity used to the ingredient's purchase/stock unit
          const totalQtyUsedForDish = qtyUsed * item.quantity;
          const qtyInStockUnit = UnitConverter.convert(totalQtyUsedForDish, ri.unit, ri.ingredient.purchaseUnit);

          const ingId = ri.ingredient.id;
          const existing = ingredientConsumption.get(ingId);
          if (existing) {
            existing.requiredStock += qtyInStockUnit;
          } else {
            ingredientConsumption.set(ingId, {
              id: ingId,
              name: ri.ingredient.name,
              purchaseUnit: ri.ingredient.purchaseUnit,
              currentStock: Number(ri.ingredient.currentStock),
              requiredStock: qtyInStockUnit,
            });
          }
        }

        const pricePerUnit = Number(sellingPrice.toFixed(2));
        const costPerUnit = Number(singleRecipeCost.toFixed(2));

        totalOrderAmount += pricePerUnit * item.quantity;
        totalOrderCost += costPerUnit * item.quantity;

        preparedOrderItems.push({
          recipeId: recipe.id,
          quantity: item.quantity,
          pricePerUnit,
          costPerUnit,
        });
      }

      // 3. Check for stock sufficiency
      const insufficientList: InsufficientIngredientDetail[] = [];

      for (const item of ingredientConsumption.values()) {
        if (item.currentStock < item.requiredStock) {
          insufficientList.push({
            ingredientId: item.id,
            name: item.name,
            availableStock: Number(item.currentStock.toFixed(2)),
            requiredStock: Number(item.requiredStock.toFixed(2)),
            unit: item.purchaseUnit,
          });
        }
      }

      if (insufficientList.length > 0) {
        const descriptions = insufficientList
          .map((i) => `"${i.name}" (คงเหลือ ${i.availableStock} ${i.unit}, ต้องการ ${i.requiredStock} ${i.unit})`)
          .join(', ');
        throw new InsufficientStockError(
          `วัตถุดิบไม่เพียงพอสำหรับการตัดสต็อก: ${descriptions}`,
          insufficientList
        );
      }

      // 4. Deduct currentStock for each consumed ingredient
      for (const item of ingredientConsumption.values()) {
        const remainingStock = Math.max(0, item.currentStock - item.requiredStock);
        await tx.ingredient.update({
          where: { id: item.id },
          data: {
            currentStock: new Prisma.Decimal(remainingStock.toFixed(2)),
          },
        });
      }

      // 5. Create Order and OrderItems
      const createdOrder = await tx.order.create({
        data: {
          totalAmount: new Prisma.Decimal(totalOrderAmount.toFixed(2)),
          totalCost: new Prisma.Decimal(totalOrderCost.toFixed(2)),
          status: OrderStatus.COMPLETED,
          items: {
            create: preparedOrderItems.map((poi) => ({
              recipeId: poi.recipeId,
              quantity: poi.quantity,
              pricePerUnit: new Prisma.Decimal(poi.pricePerUnit.toFixed(2)),
              costPerUnit: new Prisma.Decimal(poi.costPerUnit.toFixed(2)),
            })),
          },
        },
        include: {
          items: {
            include: {
              recipe: {
                select: {
                  id: true,
                  name: true,
                  category: true,
                },
              },
            },
          },
        },
      });

      // 6. Record in SalesLog for real-time analytics sync
      for (const item of input.items) {
        const recipe = recipeMap.get(item.recipeId)!;
        await tx.salesLog.create({
          data: {
            recipeId: recipe.id,
            quantitySold: item.quantity,
            period: new Date(),
          },
        });
      }

      return createdOrder;
    });
  }

  /**
   * Retrieves recent orders history with item and recipe details.
   */
  static async getOrders(limit = 50) {
    return await prisma.order.findMany({
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: {
        items: {
          include: {
            recipe: {
              select: {
                id: true,
                name: true,
                category: true,
                sellingPrice: true,
              },
            },
          },
        },
      },
    });
  }

  /**
   * Retrieves a single order by ID.
   */
  static async getOrderById(id: string) {
    return await prisma.order.findUnique({
      where: { id },
      include: {
        items: {
          include: {
            recipe: {
              select: {
                id: true,
                name: true,
                category: true,
                sellingPrice: true,
              },
            },
          },
        },
      },
    });
  }

  /**
   * Updates an order's status and returns the updated record.
   */
  static async updateOrderStatus(id: string, status: OrderStatus) {
    return await prisma.order.update({
      where: { id },
      data: { status },
      include: {
        items: {
          include: {
            recipe: {
              select: {
                id: true,
                name: true,
                category: true,
                sellingPrice: true,
              },
            },
          },
        },
      },
    });
  }
}
