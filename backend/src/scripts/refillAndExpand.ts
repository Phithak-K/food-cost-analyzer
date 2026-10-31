import { PrismaClient, Prisma } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🔄 Refilling all existing ingredients stock in PostgreSQL...');

  // 1. Refill existing ingredients
  const allIngredients = await prisma.ingredient.findMany();
  for (const ing of allIngredients) {
    let newStock = 100.0;
    const unit = ing.purchaseUnit.toLowerCase();

    // Check for specific demo low-stock test items
    if (ing.name.includes('Foie Gras') || ing.name.includes('ฟัวกราส์')) {
      newStock = 0.1; // 100g (สเต๊ก 1 จานใช้ 80g -> สั่งได้แค่ 1 จาน พอสั่งจานที่ 2 จะแจ้งเตือนบล็อกทันที)
    } else if (ing.name.includes('Burrata') || ing.name.includes('บูร์ราตา')) {
      newStock = 2.0; // 2 ชิ้น (สั่งได้แค่ 2 จาน)
    } else if (ing.name.includes('Croissant') || ing.name.includes('ครัวซองต์')) {
      newStock = 3.0; // 3 ชิ้น (สั่งได้แค่ 3 ชิ้น)
    } else if (unit === 'g') {
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
  console.log(`✅ Refilled ${allIngredients.length} existing ingredients stock.`);

  // 2. Add New Specialty Ingredients if not already present
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
      currentStock: 0.1, // Demo Critical Low Stock (เหลือ 100g)
      minStockAlert: 5.0,
    },
    {
      name: 'Artisan Burrata Cheese (ชีสบูร์ราตาอิตาเลียนสด)',
      category: 'dairy',
      purchasePrice: 160.0,
      purchaseQuantity: 1.0,
      purchaseUnit: 'pcs',
      costPerBaseUnit: 160.0,
      yieldPercent: 100.0,
      currentStock: 2.0, // Demo Critical Low Stock (เหลือ 2 ลูก)
      minStockAlert: 10.0,
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
    // Added in expand phase 2
    {
      name: 'Fresh Atlantic Black Mussels (หอยแมลงภู่ดำแอตแลนติกสด)',
      category: 'seafood',
      purchasePrice: 350.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.4375, // 0.35 / 0.80
      yieldPercent: 80.0,
      currentStock: 40.0,
      minStockAlert: 8.0,
    },
    {
      name: 'White Wine Pinot Grigio for Cooking (ไวน์ขาวสำหรับปรุงอาหาร)',
      category: 'condiment',
      purchasePrice: 280.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'L',
      costPerBaseUnit: 0.28,
      yieldPercent: 100.0,
      currentStock: 35.0,
      minStockAlert: 5.0,
    },
    {
      name: 'Japanese A5 Miyazaki Wagyu Striploin (เนื้อวากิวมิยาซากิ A5 คัดพิเศษ)',
      category: 'meat',
      purchasePrice: 3200.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 3.265, // 3.20 / 0.98
      yieldPercent: 98.0,
      currentStock: 20.0,
      minStockAlert: 5.0,
    },
    {
      name: 'Matcha Green Tea Espuma & Whipped Cream (เอสพูม่าชาเขียวมัทฉะเข้มข้น)',
      category: 'dairy',
      purchasePrice: 260.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'L',
      costPerBaseUnit: 0.26,
      yieldPercent: 100.0,
      currentStock: 35.0,
      minStockAlert: 5.0,
    },
    {
      name: 'Italian Ladyfingers Savoiardi (บิสกิตเลดี้ฟิงเกอร์แท้)',
      category: 'bakery',
      purchasePrice: 85.0,
      purchaseQuantity: 1.0,
      purchaseUnit: 'pack',
      costPerBaseUnit: 85.0,
      yieldPercent: 100.0,
      currentStock: 80.0,
      minStockAlert: 15.0,
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

  // 3. Add Signature Recipes (rec_20 to rec_30)
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
    {
      id: 'rec_26',
      name: 'Steamed Atlantic Black Mussels in White Wine (หอยแมลงภู่ดำแอตแลนติกอบไวน์ขาว)',
      category: 'food',
      sellingPrice: 420.0,
      targetCostPercent: 30.0,
      ingredients: [
        { ing: getIng('Black Mussels'), qty: 250, unit: 'g' },
        { ing: getIng('White Wine'), qty: 50, unit: 'ml' },
        { ing: getIng('Butter'), qty: 20, unit: 'g' },
        { ing: getIng('Garlic'), qty: 15, unit: 'g' },
      ],
    },
    {
      id: 'rec_27',
      name: 'Miyazaki Wagyu A5 Striploin Steak (สเต๊กเนื้อวากิวมิยาซากิ A5 ย่างเตาถ่าน)',
      category: 'food',
      sellingPrice: 1850.0,
      targetCostPercent: 38.0,
      ingredients: [
        { ing: getIng('Miyazaki Wagyu'), qty: 200, unit: 'g' },
        { ing: getIng('Butter'), qty: 20, unit: 'g' },
        { ing: getIng('Olive Oil'), qty: 15, unit: 'ml' },
      ],
    },
    {
      id: 'rec_28',
      name: 'Classic Venetian Tiramisu (ทีรามิสุสไตล์เวนิสดั้งเดิม)',
      category: 'dessert',
      sellingPrice: 220.0,
      targetCostPercent: 26.0,
      ingredients: [
        { ing: getIng('Ladyfingers'), qty: 1, unit: 'pack' },
        { ing: getIng('Heavy Cream'), qty: 60, unit: 'ml' },
        { ing: getIng('Chocolate'), qty: 15, unit: 'g' },
        { ing: getIng('Coffee'), qty: 20, unit: 'g' },
      ],
    },
    {
      id: 'rec_29',
      name: 'Matcha Espuma Cloud Latte (มัทฉะเอสพูม่าคลาวด์ลาเต้เย็น)',
      category: 'drink',
      sellingPrice: 165.0,
      targetCostPercent: 24.0,
      ingredients: [
        { ing: getIng('Matcha Powder'), qty: 10, unit: 'g' },
        { ing: getIng('Matcha Green Tea Espuma'), qty: 40, unit: 'ml' },
        { ing: getIng('Milk'), qty: 120, unit: 'ml' },
      ],
    },
    {
      id: 'rec_30',
      name: 'Crispy Bacon & Truffle Carbonara (สปาเก็ตตี้คาโบนาร่าเบคอนกรอบทรัฟเฟิล)',
      category: 'food',
      sellingPrice: 320.0,
      targetCostPercent: 28.0,
      ingredients: [
        { ing: getIng('Spaghetti'), qty: 120, unit: 'g' },
        { ing: getIng('Bacon'), qty: 60, unit: 'g' },
        { ing: getIng('Egg'), qty: 2, unit: 'pcs' },
        { ing: getIng('Parmigiano'), qty: 30, unit: 'g' },
        { ing: getIng('Truffle Oil'), qty: 15, unit: 'ml' },
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

  console.log('🎉 Refill & Expansion (rec_20 - rec_30) Completed Successfully!');
}

main()
  .catch((e) => {
    console.error('Error during refill script:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
