import { PrismaClient, Prisma } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🔄 Refilling all existing ingredients stock in PostgreSQL...');

  // 1. Refill existing ingredients
  const allIngredients = await prisma.ingredient.findMany();
  for (const ing of allIngredients) {
    let newStock = 100.0;
    const unit = ing.purchaseUnit.toLowerCase();
    if (unit === 'g') {
      newStock = 5000.0;
    } else if (unit === 'pcs' || unit === 'can' || unit === 'pack') {
      newStock = 250.0;
    } else if (ing.name.includes('Rice') || ing.name.includes('ข้าว')) {
      newStock = 300.0;
    } else {
      newStock = 120.0;
    }

    await prisma.ingredient.update({
      where: { id: ing.id },
      data: { currentStock: new Prisma.Decimal(newStock.toFixed(2)) },
    });
  }
  console.log(`✅ Refilled ${allIngredients.length} existing ingredients stock to healthy levels.`);

  // 2. Add 6 New Specialty Ingredients if not already present
  const newIngredientsData = [
    {
      name: 'Hokkaido Scallops Sashimi Grade (หอยเชลล์ฮอกไกโดเกรดซาชิมิ)',
      category: 'seafood',
      purchasePrice: 1200.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 1.263, // 1.20 / 0.95
      yieldPercent: 95.0,
      currentStock: 60.0,
      minStockAlert: 10.0,
    },
    {
      name: 'Italian Squid Ink Spaghetti (เส้นสปาเก็ตตี้หมึกดำอิตาเลียน)',
      category: 'grain',
      purchasePrice: 190.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.19,
      yieldPercent: 100.0,
      currentStock: 80.0,
      minStockAlert: 15.0,
    },
    {
      name: 'French Foie Gras Rougié (ตับห่านฟัวกราส์ฝรั่งเศส)',
      category: 'meat',
      purchasePrice: 2400.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 2.666, // 2.40 / 0.90
      yieldPercent: 90.0,
      currentStock: 40.0,
      minStockAlert: 8.0,
    },
    {
      name: 'Artisan Burrata Cheese (ชีสบูร์ราตาอิตาเลียนสด)',
      category: 'dairy',
      purchasePrice: 160.0,
      purchaseQuantity: 1.0,
      purchaseUnit: 'pcs',
      costPerBaseUnit: 160.0,
      yieldPercent: 100.0,
      currentStock: 120.0,
      minStockAlert: 20.0,
    },
    {
      name: 'Fuji Apple & Cinnamon Compote (แอปเปิ้ลฟูจิและซินนามอน)',
      category: 'produce',
      purchasePrice: 220.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.22,
      yieldPercent: 100.0,
      currentStock: 70.0,
      minStockAlert: 10.0,
    },
    {
      name: 'Craft Japanese Yuzu Soda & Tonic (คราฟต์ยูซุโซดาโทนิก)',
      category: 'beverage',
      purchasePrice: 45.0,
      purchaseQuantity: 1.0,
      purchaseUnit: 'can',
      costPerBaseUnit: 45.0,
      yieldPercent: 100.0,
      currentStock: 250.0,
      minStockAlert: 30.0,
    },
  ];

  const ingMap = new Map<string, any>();
  const refreshedIngs = await prisma.ingredient.findMany();
  for (const ing of refreshedIngs) {
    ingMap.set(ing.name, ing);
  }

  for (const nIng of newIngredientsData) {
    let ingRecord = ingMap.get(nIng.name);
    if (!ingRecord) {
      ingRecord = await prisma.ingredient.create({
        data: {
          name: nIng.name,
          category: nIng.category,
          purchasePrice: new Prisma.Decimal(nIng.purchasePrice),
          purchaseQuantity: new Prisma.Decimal(nIng.purchaseQuantity),
          purchaseUnit: nIng.purchaseUnit,
          costPerBaseUnit: new Prisma.Decimal(nIng.costPerBaseUnit),
          yieldPercent: new Prisma.Decimal(nIng.yieldPercent),
          currentStock: new Prisma.Decimal(nIng.currentStock),
          minStockAlert: new Prisma.Decimal(nIng.minStockAlert),
        },
      });
      console.log(`✨ Added new ingredient: ${nIng.name}`);
    } else {
      await prisma.ingredient.update({
        where: { id: ingRecord.id },
        data: { currentStock: new Prisma.Decimal(nIng.currentStock) },
      });
    }
    ingMap.set(nIng.name, ingRecord);
  }

  const getIng = (nameSub: string) => {
    for (const [k, v] of ingMap.entries()) {
      if (k.toLowerCase().includes(nameSub.toLowerCase())) return v;
    }
    return null;
  };

  // 3. Add 6 New Signature Recipes
  const newRecipesData = [
    {
      id: 'rec_20',
      name: 'Pan-Seared Hokkaido Scallops with Truffle Cream (สเต๊กหอยเชลล์ฮอกไกโดซอสครีมทรัฟเฟิล)',
      category: 'food',
      sellingPrice: 650.0,
      targetCostPercent: 28.0,
      ingredients: [
        { ing: getIng('Hokkaido Scallops'), qty: 160, unit: 'g' },
        { ing: getIng('Heavy Cream'), qty: 80, unit: 'ml' },
        { ing: getIng('Truffle Paste'), qty: 15, unit: 'g' },
        { ing: getIng('Olive Oil'), qty: 15, unit: 'ml' },
      ],
    },
    {
      id: 'rec_21',
      name: 'Squid Ink Pasta with Tiger Prawns (สปาเก็ตตี้หมึกดำผัดกุ้งลายเสือ)',
      category: 'food',
      sellingPrice: 390.0,
      targetCostPercent: 32.0,
      ingredients: [
        { ing: getIng('Squid Ink'), qty: 120, unit: 'g' },
        { ing: getIng('Tiger Prawns'), qty: 120, unit: 'g' },
        { ing: getIng('Olive Oil'), qty: 20, unit: 'ml' },
      ],
    },
    {
      id: 'rec_22',
      name: 'Burrata Cheese Garden Salad (สลัดชีสบูร์ราตาสดมะเขือเทศเชอร์รี่)',
      category: 'food',
      sellingPrice: 340.0,
      targetCostPercent: 30.0,
      ingredients: [
        { ing: getIng('Burrata'), qty: 1, unit: 'pcs' },
        { ing: getIng('Salad'), qty: 100, unit: 'g' },
        { ing: getIng('Olive Oil'), qty: 20, unit: 'ml' },
      ],
    },
    {
      id: 'rec_23',
      name: 'Seared French Foie Gras on Toast (ฟัวกราส์ย่างกระทะเสิร์ฟพร้อมซอสผลไม้)',
      category: 'food',
      sellingPrice: 790.0,
      targetCostPercent: 28.0,
      ingredients: [
        { ing: getIng('Foie Gras'), qty: 80, unit: 'g' },
        { ing: getIng('Butter'), qty: 15, unit: 'g' },
      ],
    },
    {
      id: 'rec_24',
      name: 'Craft Japanese Yuzu Tonic Cooler (ยูซุโทนิกโซดาเย็นคราฟต์)',
      category: 'drink',
      sellingPrice: 135.0,
      targetCostPercent: 22.0,
      ingredients: [
        { ing: getIng('Yuzu Soda'), qty: 1, unit: 'can' },
        { ing: getIng('Yuzu Purée'), qty: 20, unit: 'ml' },
      ],
    },
    {
      id: 'rec_25',
      name: 'Warm Apple Cinnamon Croissant Tart (ทาร์ตครัวซองต์เนยสดแอปเปิ้ลซินนามอน)',
      category: 'dessert',
      sellingPrice: 185.0,
      targetCostPercent: 25.0,
      ingredients: [
        { ing: getIng('Croissant'), qty: 1, unit: 'pcs' },
        { ing: getIng('Apple'), qty: 80, unit: 'g' },
        { ing: getIng('Butter'), qty: 15, unit: 'g' },
      ],
    },
  ];

  for (const r of newRecipesData) {
    const existingRecipe = await prisma.recipe.findFirst({
      where: {
        OR: [{ id: r.id }, { name: r.name }],
      },
    });

    if (!existingRecipe) {
      const created = await prisma.recipe.create({
        data: {
          id: r.id,
          name: r.name,
          category: r.category,
          sellingPrice: new Prisma.Decimal(r.sellingPrice),
          targetCostPercent: new Prisma.Decimal(r.targetCostPercent),
        },
      });

      for (const item of r.ingredients) {
        if (item.ing) {
          await prisma.recipeIngredient.create({
            data: {
              recipeId: created.id,
              ingredientId: item.ing.id,
              quantityUsed: new Prisma.Decimal(item.qty),
              unit: item.unit,
            },
          });
        }
      }
      console.log(`🍽️ Added new recipe: ${r.name} (ID: ${r.id})`);
    } else {
      console.log(`ℹ️ Recipe already exists: ${r.name}`);
    }
  }

  console.log('🎉 Refill & Expansion Completed Successfully!');
}

main()
  .catch((e) => {
    console.error('Error during refill script:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

