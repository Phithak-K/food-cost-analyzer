import { PrismaClient, OrderStatus } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seed for Food Costing & Menu Engineering...');

  // 1. Clear existing records to ensure clean state
  await prisma.orderItem.deleteMany();
  await prisma.order.deleteMany();
  await prisma.salesLog.deleteMany();
  await prisma.recipeIngredient.deleteMany();
  await prisma.recipe.deleteMany();
  await prisma.ingredient.deleteMany();

  console.log('🧹 Cleaned existing tables.');

  // 2. Insert Realistic Ingredients with initial stock and alert thresholds
  const matcha = await prisma.ingredient.create({
    data: {
      name: 'ผงมัทฉะเกรดพิธีการ (Ceremonial Uji Matcha)',
      category: 'drink',
      purchasePrice: 950.0,
      purchaseQuantity: 100.0, // 100 g
      purchaseUnit: 'g',
      costPerBaseUnit: 9.5, // 9.50 บาท/g
      yieldPercent: 100.0,
      currentStock: 500.0, // 500 g
      minStockAlert: 50.0,
    },
  });

  const milk = await prisma.ingredient.create({
    data: {
      name: 'นมสดพาสเจอร์ไรส์ Meiji (Fresh Milk)',
      category: 'dairy',
      purchasePrice: 98.0,
      purchaseQuantity: 2000.0, // 2,000 ml (2 L)
      purchaseUnit: 'l',
      costPerBaseUnit: 0.049, // 0.049 บาท/ml
      yieldPercent: 100.0,
      currentStock: 25.0, // 25 ลิตร
      minStockAlert: 5.0,
    },
  });

  const syrup = await prisma.ingredient.create({
    data: {
      name: 'น้ำเชื่อมธรรมชาติเข้มข้น (Pure Sugar Cane Syrup)',
      category: 'condiment',
      purchasePrice: 75.0,
      purchaseQuantity: 1000.0, // 1,000 ml
      purchaseUnit: 'l',
      costPerBaseUnit: 0.075, // 0.075 บาท/ml
      yieldPercent: 100.0,
      currentStock: 15.0, // 15 ลิตร
      minStockAlert: 3.0,
    },
  });

  const pork = await prisma.ingredient.create({
    data: {
      name: 'หมูสับอนามัย S-Pure (Minced Pork)',
      category: 'meat',
      purchasePrice: 180.0,
      purchaseQuantity: 1000.0, // 1,000 g
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.18, // 0.18 บาท/g
      yieldPercent: 95.0,
      currentStock: 30.0, // 30 kg
      minStockAlert: 5.0,
    },
  });

  const eggs = await prisma.ingredient.create({
    data: {
      name: 'ไข่ไก่สดคัดพิเศษเบอร์ 2 (Fresh Egg No.2)',
      category: 'egg',
      purchasePrice: 140.0,
      purchaseQuantity: 30.0, // 30 ฟอง
      purchaseUnit: 'pack',
      costPerBaseUnit: 4.67, // 4.67 บาท/ฟอง
      yieldPercent: 100.0,
      currentStock: 150.0, // 150 ฟอง
      minStockAlert: 30.0,
    },
  });

  const basilSauce = await prisma.ingredient.create({
    data: {
      name: 'ซอสผัดกะเพราสูตรโบราณ (Authentic Basil Sauce)',
      category: 'sauce',
      purchasePrice: 120.0,
      purchaseQuantity: 1000.0, // 1,000 ml
      purchaseUnit: 'l',
      costPerBaseUnit: 0.12, // 0.12 บาท/ml
      yieldPercent: 100.0,
      currentStock: 12.0, // 12 ลิตร
      minStockAlert: 2.0,
    },
  });

  const rice = await prisma.ingredient.create({
    data: {
      name: 'ข้าวหอมมะลิแท้คัดพิเศษ (Jasmine Rice)',
      category: 'grain',
      purchasePrice: 220.0,
      purchaseQuantity: 5000.0, // 5,000 g
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.044, // 0.044 บาท/g
      yieldPercent: 100.0,
      currentStock: 60.0, // 60 kg
      minStockAlert: 10.0,
    },
  });

  const wagyu = await prisma.ingredient.create({
    data: {
      name: 'เนื้อสันนอกวากิว A5 Kagoshima (Wagyu Beef A5)',
      category: 'meat',
      purchasePrice: 3200.0,
      purchaseQuantity: 1000.0, // 1,000 g
      purchaseUnit: 'kg',
      costPerBaseUnit: 3.2, // 3.20 บาท/g
      yieldPercent: 90.0,
      currentStock: 15.0, // 15 kg
      minStockAlert: 3.0,
    },
  });

  const butter = await prisma.ingredient.create({
    data: {
      name: 'เนยสดแท้ชนิดจืด Anchor (Unsalted Pure Butter)',
      category: 'dairy',
      purchasePrice: 195.0,
      purchaseQuantity: 227.0, // 227 g
      purchaseUnit: 'pack',
      costPerBaseUnit: 0.859, // 0.859 บาท/g
      yieldPercent: 100.0,
      currentStock: 25.0, // 25 pack
      minStockAlert: 5.0,
    },
  });

  const soySauce = await prisma.ingredient.create({
    data: {
      name: 'ซอสโชยุพรีเมียมญี่ปุ่น (Japanese Soy Sauce)',
      category: 'sauce',
      purchasePrice: 165.0,
      purchaseQuantity: 1000.0, // 1,000 ml
      purchaseUnit: 'l',
      costPerBaseUnit: 0.165, // 0.165 บาท/ml
      yieldPercent: 100.0,
      currentStock: 10.0, // 10 ลิตร
      minStockAlert: 2.0,
    },
  });

  const pasta = await prisma.ingredient.create({
    data: {
      name: 'เส้นสปาเก็ตตี้ De Cecco No.12 (Spaghetti)',
      category: 'pasta',
      purchasePrice: 95.0,
      purchaseQuantity: 500.0, // 500 g
      purchaseUnit: 'pack',
      costPerBaseUnit: 0.19, // 0.19 บาท/g
      yieldPercent: 100.0,
      currentStock: 50.0, // 50 pack
      minStockAlert: 5.0,
    },
  });

  const salmon = await prisma.ingredient.create({
    data: {
      name: 'ปลาแซลมอนนอร์เวย์สด (Norwegian Salmon)',
      category: 'seafood',
      purchasePrice: 650.0,
      purchaseQuantity: 1000.0, // 1,000 g
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.65, // 0.65 บาท/g
      yieldPercent: 92.0,
      currentStock: 45.0,
      minStockAlert: 5.0,
    },
  });

  const croissantDough = await prisma.ingredient.create({
    data: {
      name: 'แป้งครัวซองต์เนยสดฝรั่งเศส (Butter Croissant Dough)',
      category: 'bakery',
      purchasePrice: 35.0,
      purchaseQuantity: 1.0,
      purchaseUnit: 'pcs',
      costPerBaseUnit: 35.0,
      yieldPercent: 100.0,
      currentStock: 120.0,
      minStockAlert: 15.0,
    },
  });

  const coffeeBeans = await prisma.ingredient.create({
    data: {
      name: 'เมล็ดกาแฟอาราบิก้าคั่วพิเศษ (Arabica Beans)',
      category: 'drink',
      purchasePrice: 780.0,
      purchaseQuantity: 1000.0, // 1,000 g
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.78, // 0.78 บาท/g
      yieldPercent: 100.0,
      currentStock: 40.0,
      minStockAlert: 5.0,
    },
  });

  const frenchFries = await prisma.ingredient.create({
    data: {
      name: 'มันฝรั่งเส้นสไตล์ฝรั่งเศส (French Fries)',
      category: 'dry_goods',
      purchasePrice: 95.0,
      purchaseQuantity: 1000.0, // 1,000 g
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.095, // 0.095 บาท/g
      yieldPercent: 95.0,
      currentStock: 50.0,
      minStockAlert: 5.0,
    },
  });

  const truffleOil = await prisma.ingredient.create({
    data: {
      name: 'น้ำมันเห็ดทรัฟเฟิลขาวแท้ (White Truffle Oil)',
      category: 'sauce',
      purchasePrice: 890.0,
      purchaseQuantity: 1000.0, // 1,000 ml
      purchaseUnit: 'l',
      costPerBaseUnit: 0.89, // 0.89 บาท/ml
      yieldPercent: 100.0,
      currentStock: 12.0,
      minStockAlert: 2.0,
    },
  });

  console.log('✅ Created 16 realistic ingredients with rich stock values.');

  // 3. Create Sample Recipes & Linked Ingredients
  // --- RECIPE 1: Star (Matcha Latte - กำไรสูง ขายดีมาก) ---
  const recipeMatcha = await prisma.recipe.create({
    data: {
      name: 'Iced Ceremonial Matcha Latte (มัทฉะลาเต้เย็น)',
      category: 'drink',
      sellingPrice: 145.0,
      targetCostPercent: 30.0,
      ingredients: {
        create: [
          { ingredientId: matcha.id, quantityUsed: 4.0, unit: 'g' }, // 38.00 ฿
          { ingredientId: milk.id, quantityUsed: 150.0, unit: 'ml' }, // 7.35 ฿
          { ingredientId: syrup.id, quantityUsed: 15.0, unit: 'ml' }, // 1.13 ฿
        ],
      },
    },
  });

  // --- RECIPE 2: Plowhorse (ข้าวกะเพราหมูสับไข่ดาว - ขายดีมากแต่กำไรน้อย) ---
  const recipeKraPao = await prisma.recipe.create({
    data: {
      name: 'ข้าวกะเพราหมูสับไข่ดาวกรอบ (Holy Basil Pork Rice)',
      category: 'food',
      sellingPrice: 89.0,
      targetCostPercent: 35.0,
      ingredients: {
        create: [
          { ingredientId: pork.id, quantityUsed: 150.0, unit: 'g' }, // 27.00 ฿
          { ingredientId: rice.id, quantityUsed: 200.0, unit: 'g' }, // 8.80 ฿
          { ingredientId: eggs.id, quantityUsed: 1.0, unit: 'ฟอง' }, // 4.67 ฿
          { ingredientId: basilSauce.id, quantityUsed: 30.0, unit: 'ml' }, // 3.60 ฿
        ],
      },
    },
  });

  // --- RECIPE 3: Puzzle (สเต็กวากิว A5 - กำไรสูงมากแต่ขายได้น้อย) ---
  const recipeWagyu = await prisma.recipe.create({
    data: {
      name: 'สเต็กเนื้อวากิว A5 ย่างกระทะซอสเนยโชยุ (Wagyu A5 Steak)',
      category: 'food',
      sellingPrice: 1650.0,
      targetCostPercent: 35.0,
      ingredients: {
        create: [
          { ingredientId: wagyu.id, quantityUsed: 200.0, unit: 'g' }, // 640.00 ฿
          { ingredientId: butter.id, quantityUsed: 25.0, unit: 'g' }, // 21.48 ฿
          { ingredientId: soySauce.id, quantityUsed: 20.0, unit: 'ml' }, // 3.30 ฿
        ],
      },
    },
  });

  // --- RECIPE 4: Dog (สปาเก็ตตี้เนยซอสไข่ - ขายไม่ออกและกำไรต่ำ) ---
  const recipeDogPasta = await prisma.recipe.create({
    data: {
      name: 'สปาเก็ตตี้เนยกระเทียมไข่ดาว (Butter Garlic Spaghetti)',
      category: 'food',
      sellingPrice: 95.0,
      targetCostPercent: 32.0,
      ingredients: {
        create: [
          { ingredientId: pasta.id, quantityUsed: 120.0, unit: 'g' }, // 22.80 ฿
          { ingredientId: butter.id, quantityUsed: 25.0, unit: 'g' }, // 21.48 ฿
          { ingredientId: eggs.id, quantityUsed: 1.0, unit: 'ฟอง' }, // 4.67 ฿
          { ingredientId: soySauce.id, quantityUsed: 15.0, unit: 'ml' }, // 2.48 ฿
        ],
      },
    },
  });

  // --- RECIPE 5: Star (ข้าวไข่ข้นหมูสับซอสโชยุ) ---
  const recipeEggPork = await prisma.recipe.create({
    data: {
      name: 'ข้าวไข่ข้นหมูสับคั่วเนยโชยุ (Creamy Egg & Pork Rice)',
      category: 'food',
      sellingPrice: 139.0,
      targetCostPercent: 30.0,
      ingredients: {
        create: [
          { ingredientId: eggs.id, quantityUsed: 2.0, unit: 'ฟอง' }, // 9.34 ฿
          { ingredientId: pork.id, quantityUsed: 100.0, unit: 'g' }, // 18.00 ฿
          { ingredientId: rice.id, quantityUsed: 200.0, unit: 'g' }, // 8.80 ฿
          { ingredientId: butter.id, quantityUsed: 10.0, unit: 'g' }, // 8.59 ฿
          { ingredientId: soySauce.id, quantityUsed: 15.0, unit: 'ml' }, // 2.48 ฿
        ],
      },
    },
  });

  // --- RECIPE 6: Star (สเต๊กแซลมอนย่างนอร์เวย์) ---
  const recipeSalmon = await prisma.recipe.create({
    data: {
      name: 'สเต๊กแซลมอนย่างนอร์เวย์ (Pan-Seared Salmon)',
      category: 'food',
      sellingPrice: 490.0,
      targetCostPercent: 32.0,
      ingredients: {
        create: [
          { ingredientId: salmon.id, quantityUsed: 180.0, unit: 'g' }, // 117.00 ฿
          { ingredientId: butter.id, quantityUsed: 20.0, unit: 'g' }, // 17.18 ฿
          { ingredientId: soySauce.id, quantityUsed: 15.0, unit: 'ml' }, // 2.48 ฿
        ],
      },
    },
  });

  // --- RECIPE 7: Star (ครัวซองต์เนยฝรั่งเศสสด) ---
  const recipeCroissant = await prisma.recipe.create({
    data: {
      name: 'ครัวซองต์เนยสดฝรั่งเศส (French Butter Croissant)',
      category: 'bakery',
      sellingPrice: 120.0,
      targetCostPercent: 35.0,
      ingredients: {
        create: [
          { ingredientId: croissantDough.id, quantityUsed: 1.0, unit: 'pcs' }, // 35.00 ฿
          { ingredientId: butter.id, quantityUsed: 10.0, unit: 'g' }, // 8.59 ฿
        ],
      },
    },
  });

  // --- RECIPE 8: Star (เดอร์ตี้คอฟฟี่นมเย็นจัด) ---
  const recipeDirtyCoffee = await prisma.recipe.create({
    data: {
      name: 'เดอร์ตี้คอฟฟี่นมสดเย็นจัด (Dirty Coffee)',
      category: 'drink',
      sellingPrice: 145.0,
      targetCostPercent: 28.0,
      ingredients: {
        create: [
          { ingredientId: coffeeBeans.id, quantityUsed: 20.0, unit: 'g' }, // 15.60 ฿
          { ingredientId: milk.id, quantityUsed: 120.0, unit: 'ml' }, // 5.88 ฿
          { ingredientId: syrup.id, quantityUsed: 10.0, unit: 'ml' }, // 0.75 ฿
        ],
      },
    },
  });

  // --- RECIPE 9: Plowhorse (เฟรนช์ฟรายส์ทรัฟเฟิลพาร์เมซาน) ---
  const recipeTruffleFries = await prisma.recipe.create({
    data: {
      name: 'เฟรนช์ฟรายส์ทรัฟเฟิลพาร์เมซาน (Truffle Fries)',
      category: 'food',
      sellingPrice: 165.0,
      targetCostPercent: 30.0,
      ingredients: {
        create: [
          { ingredientId: frenchFries.id, quantityUsed: 180.0, unit: 'g' }, // 17.10 ฿
          { ingredientId: truffleOil.id, quantityUsed: 10.0, unit: 'ml' }, // 8.90 ฿
        ],
      },
    },
  });

  console.log('✅ Created 9 diverse recipes across Menu Engineering quadrants.');

  // 4. Insert Sales Logs (Monthly volume data for 4-quadrant scatter plot)
  const currentDate = new Date();

  await prisma.salesLog.createMany({
    data: [
      { recipeId: recipeMatcha.id, quantitySold: 430, period: currentDate },
      { recipeId: recipeKraPao.id, quantitySold: 510, period: currentDate },
      { recipeId: recipeWagyu.id, quantitySold: 65, period: currentDate },
      { recipeId: recipeDogPasta.id, quantitySold: 45, period: currentDate },
      { recipeId: recipeEggPork.id, quantitySold: 380, period: currentDate },
      { recipeId: recipeSalmon.id, quantitySold: 340, period: currentDate },
      { recipeId: recipeCroissant.id, quantitySold: 460, period: currentDate },
      { recipeId: recipeDirtyCoffee.id, quantitySold: 520, period: currentDate },
      { recipeId: recipeTruffleFries.id, quantitySold: 610, period: currentDate },
    ],
  });

  console.log('✅ Created monthly SalesLog records for Menu Matrix plotting.');

  // 5. Seed Initial Sample Orders (Simulated POS Transactions)
  await prisma.order.create({
    data: {
      totalAmount: 379.0, // 145 + 145 + 89
      totalCost: 139.21,
      status: OrderStatus.COMPLETED,
      items: {
        create: [
          {
            recipeId: recipeMatcha.id,
            quantity: 2,
            pricePerUnit: 145.0,
            costPerUnit: 46.48,
          },
          {
            recipeId: recipeKraPao.id,
            quantity: 1,
            pricePerUnit: 89.0,
            costPerUnit: 46.25,
          },
        ],
      },
    },
  });

  await prisma.order.create({
    data: {
      totalAmount: 1789.0, // 1650 + 139
      totalCost: 706.78,
      status: OrderStatus.COMPLETED,
      items: {
        create: [
          {
            recipeId: recipeWagyu.id,
            quantity: 1,
            pricePerUnit: 1650.0,
            costPerUnit: 664.78,
          },
          {
            recipeId: recipeEggPork.id,
            quantity: 1,
            pricePerUnit: 139.0,
            costPerUnit: 42.0,
          },
        ],
      },
    },
  });

  await prisma.order.create({
    data: {
      totalAmount: 935.0,
      totalCost: 268.0,
      status: OrderStatus.COMPLETED,
      items: {
        create: [
          {
            recipeId: recipeSalmon.id,
            quantity: 1,
            pricePerUnit: 490.0,
            costPerUnit: 136.66,
          },
          {
            recipeId: recipeCroissant.id,
            quantity: 2,
            pricePerUnit: 120.0,
            costPerUnit: 43.59,
          },
          {
            recipeId: recipeDirtyCoffee.id,
            quantity: 1,
            pricePerUnit: 145.0,
            costPerUnit: 22.23,
          },
        ],
      },
    },
  });

  await prisma.order.create({
    data: {
      totalAmount: 610.0,
      totalCost: 178.0,
      status: OrderStatus.COMPLETED,
      items: {
        create: [
          {
            recipeId: recipeTruffleFries.id,
            quantity: 2,
            pricePerUnit: 165.0,
            costPerUnit: 26.0,
          },
          {
            recipeId: recipeDirtyCoffee.id,
            quantity: 2,
            pricePerUnit: 145.0,
            costPerUnit: 22.23,
          },
        ],
      },
    },
  });

  console.log('✅ Seeded 4 sample POS orders with completed transactions.');
  console.log('🎉 Seed completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
