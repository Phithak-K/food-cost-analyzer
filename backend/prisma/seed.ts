import { PrismaClient, OrderStatus } from '@prisma/client';

const prisma = new PrismaClient();

// Helper to get date N days ago with specific hour & minute
function getDateDaysAgo(daysAgo: number, hour: number, minute: number): Date {
  const d = new Date();
  d.setDate(d.getDate() - daysAgo);
  d.setHours(hour, minute, Math.floor(Math.random() * 60), 0);
  return d;
}

async function main() {
  console.log('🌱 Starting comprehensive 60-day database seed for MenuEng Pro...');

  // 1. Clear existing records to ensure clean state
  await prisma.orderItem.deleteMany();
  await prisma.order.deleteMany();
  await prisma.salesLog.deleteMany();
  await prisma.recipeIngredient.deleteMany();
  await prisma.recipe.deleteMany();
  await prisma.ingredient.deleteMany();

  console.log('🧹 Cleaned existing tables.');

  // 2. Insert 32 High-Quality Ingredients with realistic stock, unit costs, and yield %
  const ingredientsData = [
    {
      name: 'Norwegian Salmon Fillet (ปลาแซลมอนนอร์เวย์สด)',
      category: 'seafood',
      purchasePrice: 650.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.7065, // after 92% yield: 0.65 / 0.92 = ~0.71/g
      yieldPercent: 92.0,
      currentStock: 18.5,
      minStockAlert: 5.0,
    },
    {
      name: 'Australian Wagyu Ribeye MB4/5 (เนื้อวากิวริบอาย)',
      category: 'meat',
      purchasePrice: 1450.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 1.5263, // 1.45 / 0.95 = ~1.53/g
      yieldPercent: 95.0,
      currentStock: 12.0,
      minStockAlert: 3.0,
    },
    {
      name: 'Jasmine Rice 105 (ข้าวหอมมะลิแท้คัดพิเศษ)',
      category: 'grain',
      purchasePrice: 42.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.042,
      yieldPercent: 100.0,
      currentStock: 150.0,
      minStockAlert: 20.0,
    },
    {
      name: 'Extra Virgin Olive Oil (น้ำมันมะกอกเอ็กซ์ตร้าเวอร์จิ้น)',
      category: 'oil',
      purchasePrice: 380.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'l',
      costPerBaseUnit: 0.38,
      yieldPercent: 100.0,
      currentStock: 25.0,
      minStockAlert: 5.0,
    },
    {
      name: 'Italian Black Truffle Paste (เห็ดทรัฟเฟิลดำอิตาลี)',
      category: 'specialty',
      purchasePrice: 1200.0,
      purchaseQuantity: 500.0,
      purchaseUnit: 'g',
      costPerBaseUnit: 2.4,
      yieldPercent: 100.0,
      currentStock: 1200.0,
      minStockAlert: 200.0,
    },
    {
      name: 'Fresh Heavy Cream 35% (วิปปิ้งครีมสดแท้)',
      category: 'dairy',
      purchasePrice: 185.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'l',
      costPerBaseUnit: 0.185,
      yieldPercent: 100.0,
      currentStock: 250.0,
      minStockAlert: 20.0,
    },
    {
      name: 'Parmigiano Reggiano 24M (พาร์มีซานชีสแท้ 24 เดือน)',
      category: 'dairy',
      purchasePrice: 980.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 1.0208,
      yieldPercent: 96.0,
      currentStock: 45.0,
      minStockAlert: 5.0,
    },
    {
      name: 'Fresh Tiger Prawns (กุ้งลายเสือสด)',
      category: 'seafood',
      purchasePrice: 450.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.60, // 450 / 0.75 = 600/kg -> 0.60/g
      yieldPercent: 75.0,
      currentStock: 60.0,
      minStockAlert: 10.0,
    },
    {
      name: 'Organic Baby Spinach (ผักโขมออร์แกนิก)',
      category: 'produce',
      purchasePrice: 180.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.2045,
      yieldPercent: 88.0,
      currentStock: 35.0,
      minStockAlert: 5.0,
    },
    {
      name: 'Kurobuta Pork Chop (สเต็กพอร์คชอปคุโรบูตะ)',
      category: 'meat',
      purchasePrice: 360.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.3913,
      yieldPercent: 92.0,
      currentStock: 16.0,
      minStockAlert: 4.0,
    },
    {
      name: 'S-Pure Chicken Breast (อกไก่ออร์แกนิก S-Pure)',
      category: 'meat',
      purchasePrice: 135.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.1421,
      yieldPercent: 95.0,
      currentStock: 25.0,
      minStockAlert: 5.0,
    },
    {
      name: 'Smoked Streaky Bacon (เบคอนรมควันไม้แอปเปิ้ล)',
      category: 'meat',
      purchasePrice: 290.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.2959,
      yieldPercent: 98.0,
      currentStock: 18.0,
      minStockAlert: 3.0,
    },
    {
      name: 'Organic Hen Eggs No.1 (ไข่ไก่ออร์แกนิกเบอร์ 1)',
      category: 'egg',
      purchasePrice: 165.0,
      purchaseQuantity: 30.0,
      purchaseUnit: 'pack',
      costPerBaseUnit: 5.5, // 5.50 บาท/ฟอง
      yieldPercent: 100.0,
      currentStock: 120.0,
      minStockAlert: 20.0,
    },
    {
      name: 'Pure Anchor Butter Unsalted (เนยสดแท้ชนิดจืด Anchor)',
      category: 'dairy',
      purchasePrice: 260.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.26,
      yieldPercent: 100.0,
      currentStock: 22.0,
      minStockAlert: 5.0,
    },
    {
      name: 'Meiji Pasteurized Fresh Milk (นมสดพาสเจอร์ไรส์ Meiji)',
      category: 'dairy',
      purchasePrice: 98.0,
      purchaseQuantity: 2000.0,
      purchaseUnit: 'l',
      costPerBaseUnit: 0.049,
      yieldPercent: 100.0,
      currentStock: 300.0,
      minStockAlert: 20.0,
    },
    {
      name: 'Fresh Garlic & French Rosemary (กระเทียมและโรสแมรี่สด)',
      category: 'produce',
      purchasePrice: 120.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.1364,
      yieldPercent: 88.0,
      currentStock: 25.0,
      minStockAlert: 5.0,
    },
    {
      name: 'Hydroponic Salad Greens & Tomatoes (ผักสลัดและมะเขือเทศเชอร์รี่)',
      category: 'produce',
      purchasePrice: 160.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.1778,
      yieldPercent: 90.0,
      currentStock: 30.0,
      minStockAlert: 5.0,
    },
    {
      name: 'Fresh Champignon Mushrooms (เห็ดแชมปิญองสด)',
      category: 'produce',
      purchasePrice: 190.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.2065,
      yieldPercent: 92.0,
      currentStock: 28.0,
      minStockAlert: 5.0,
    },
    {
      name: 'Wild Holy Basil & Bird Eye Chili (ใบกะเพราป่าและพริกขี้หนู)',
      category: 'produce',
      purchasePrice: 95.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.1118,
      yieldPercent: 85.0,
      currentStock: 20.0,
      minStockAlert: 4.0,
    },
    {
      name: 'Italian Bronze Spaghetti No.12 (เส้นสปาเก็ตตี้อิตาเลียน)',
      category: 'dry_goods',
      purchasePrice: 140.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.14,
      yieldPercent: 100.0,
      currentStock: 60.0,
      minStockAlert: 10.0,
    },
    {
      name: 'Ceremonial Uji Matcha Powder (ผงมัทฉะอุจิแท้เกรดพิธีการ)',
      category: 'specialty',
      purchasePrice: 850.0,
      purchaseQuantity: 100.0,
      purchaseUnit: 'g',
      costPerBaseUnit: 8.5,
      yieldPercent: 100.0,
      currentStock: 2000.0,
      minStockAlert: 200.0,
    },
    {
      name: '100% Japanese Yuzu Purée (น้ำส้มยูซุคั้นสดแท้)',
      category: 'specialty',
      purchasePrice: 690.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'l',
      costPerBaseUnit: 0.69,
      yieldPercent: 100.0,
      currentStock: 35.0,
      minStockAlert: 5.0,
    },
    {
      name: 'Single Origin Arabica Beans (เมล็ดกาแฟอาราบิก้าคั่วพิเศษ)',
      category: 'specialty',
      purchasePrice: 780.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.78,
      yieldPercent: 100.0,
      currentStock: 45.0,
      minStockAlert: 5.0,
    },
    {
      name: 'Belgian Dark Chocolate 70.5% (ดาร์กช็อกโกแลตเบลเยียม)',
      category: 'specialty',
      purchasePrice: 520.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.52,
      yieldPercent: 100.0,
      currentStock: 40.0,
      minStockAlert: 5.0,
    },
    {
      name: 'French Butter Croissant Dough (แป้งครัวซองต์เนยสดฝรั่งเศส)',
      category: 'bakery',
      purchasePrice: 35.0,
      purchaseQuantity: 1.0,
      purchaseUnit: 'pcs',
      costPerBaseUnit: 35.0,
      yieldPercent: 100.0,
      currentStock: 120.0,
      minStockAlert: 20.0,
    },
    {
      name: 'Avocado Hass Grade A (อะโวคาโดแฮสส์คัดพิเศษ)',
      category: 'produce',
      purchasePrice: 240.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.3429,
      yieldPercent: 70.0,
      currentStock: 25.0,
      minStockAlert: 5.0,
    },
    {
      name: 'Organic Passion Fruit Purée (เสาวรสสดแท้ 100%)',
      category: 'specialty',
      purchasePrice: 280.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'l',
      costPerBaseUnit: 0.28,
      yieldPercent: 100.0,
      currentStock: 20.0,
      minStockAlert: 3.0,
    },
    {
      name: 'French Crispy Potato Fries (มันฝรั่งเส้นสไตล์ฝรั่งเศส)',
      category: 'dry_goods',
      purchasePrice: 95.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.10,
      yieldPercent: 95.0,
      currentStock: 50.0,
      minStockAlert: 10.0,
    },
    {
      name: 'White Truffle Olive Oil (น้ำมันเห็ดทรัฟเฟิลขาวเข้มข้น)',
      category: 'specialty',
      purchasePrice: 890.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'l',
      costPerBaseUnit: 0.89,
      yieldPercent: 100.0,
      currentStock: 12.0,
      minStockAlert: 2.0,
    },
    // New Additions:
    {
      name: 'Japanese Hotate Scallops (หอยเชลล์โฮตาเตะญี่ปุ่นสด)',
      category: 'seafood',
      purchasePrice: 1100.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 1.222, // 90% yield
      yieldPercent: 90.0,
      currentStock: 15.0,
      minStockAlert: 3.0,
    },
    {
      name: 'Lump Blue Crab Meat (เนื้อปูม้าก้อนพรีเมียม)',
      category: 'seafood',
      purchasePrice: 1250.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 1.3158, // 95% yield
      yieldPercent: 95.0,
      currentStock: 14.0,
      minStockAlert: 3.0,
    },
    {
      name: 'Koshihikari Japanese Rice (ข้าวญี่ปุ่นโคชิฮิคาริ)',
      category: 'grain',
      purchasePrice: 95.0,
      purchaseQuantity: 1000.0,
      purchaseUnit: 'kg',
      costPerBaseUnit: 0.095,
      yieldPercent: 100.0,
      currentStock: 80.0,
      minStockAlert: 10.0,
    },
  ];

  const ingMap = new Map<string, any>();
  for (const item of ingredientsData) {
    const created = await prisma.ingredient.create({ data: item });
    ingMap.set(item.name, created);
  }
  console.log(`✅ Created ${ingMap.size} diverse ingredients with yield loss and base costs.`);

  // 3. Create 20 Signature Recipes across Kasavana & Smith Quadrants
  // Helper for quick ingredient lookup
  const getIng = (nameSubstring: string) => {
    for (const [key, val] of ingMap.entries()) {
      if (key.includes(nameSubstring)) return val;
    }
    throw new Error(`Ingredient containing ${nameSubstring} not found`);
  };

  const recipesData = [
    // 1. Star: High Volume, High Margin
    {
      name: 'Pan-Seared Norwegian Salmon (สเต๊กแซลมอนย่าง)',
      category: 'food',
      sellingPrice: 490.0,
      targetCostPercent: 30.0,
      monthlyVolume: 380,
      ingredients: [
        { ing: getIng('Salmon'), qty: 180, unit: 'g' },
        { ing: getIng('Olive Oil'), qty: 20, unit: 'ml' },
        { ing: getIng('Baby Spinach'), qty: 80, unit: 'g' },
      ],
    },
    // 2. Star: High Volume, High Margin
    {
      name: 'Truffle Cream Fettuccine (เฟตตูชินีครีมทรัฟเฟิล)',
      category: 'food',
      sellingPrice: 380.0,
      targetCostPercent: 25.0,
      monthlyVolume: 430,
      ingredients: [
        { ing: getIng('Truffle Paste'), qty: 15, unit: 'g' },
        { ing: getIng('Heavy Cream'), qty: 120, unit: 'ml' },
        { ing: getIng('Parmigiano'), qty: 30, unit: 'g' },
        { ing: getIng('Spaghetti'), qty: 120, unit: 'g' },
      ],
    },
    // 3. Puzzle: Low Volume, High Margin
    {
      name: 'Wagyu Ribeye MB4/5 Steak (สเต๊กวากิวริบอาย)',
      category: 'food',
      sellingPrice: 1450.0,
      targetCostPercent: 28.0,
      monthlyVolume: 85,
      ingredients: [
        { ing: getIng('Wagyu'), qty: 250, unit: 'g' },
        { ing: getIng('Olive Oil'), qty: 20, unit: 'ml' },
        { ing: getIng('Garlic & French Rosemary'), qty: 15, unit: 'g' },
        { ing: getIng('Anchor Butter'), qty: 20, unit: 'g' },
      ],
    },
    // 4. Plowhorse: High Volume, Low Margin
    {
      name: 'Tiger Prawn Garlic Butter (กุ้งลายเสือผัดเนยกระเทียม)',
      category: 'food',
      sellingPrice: 280.0,
      targetCostPercent: 45.0,
      monthlyVolume: 490,
      ingredients: [
        { ing: getIng('Tiger Prawns'), qty: 200, unit: 'g' },
        { ing: getIng('Olive Oil'), qty: 30, unit: 'ml' },
        { ing: getIng('Garlic & French Rosemary'), qty: 15, unit: 'g' },
      ],
    },
    // 5. Star: Creamy Spinach Gratin
    {
      name: 'Creamy Spinach Gratin (ผักโขมอบชีสยืด)',
      category: 'food',
      sellingPrice: 190.0,
      targetCostPercent: 32.0,
      monthlyVolume: 210,
      ingredients: [
        { ing: getIng('Baby Spinach'), qty: 150, unit: 'g' },
        { ing: getIng('Heavy Cream'), qty: 80, unit: 'ml' },
        { ing: getIng('Parmigiano'), qty: 40, unit: 'g' },
      ],
    },
    // 6. Dog: Low Volume, Low Margin
    {
      name: 'Seafood Saffron Risotto (รีซอตโต้ซีฟู้ด)',
      category: 'food',
      sellingPrice: 360.0,
      targetCostPercent: 40.0,
      monthlyVolume: 55,
      ingredients: [
        { ing: getIng('Tiger Prawns'), qty: 150, unit: 'g' },
        { ing: getIng('Jasmine Rice'), qty: 100, unit: 'g' },
        { ing: getIng('Heavy Cream'), qty: 50, unit: 'ml' },
        { ing: getIng('Parmigiano'), qty: 30, unit: 'g' },
      ],
    },
    // 7. Star: Kurobuta Pork Chop
    {
      name: 'Kurobuta Pork Chop with Rosemary (สเต๊กพอร์คชอปคุโรบูตะ)',
      category: 'food',
      sellingPrice: 390.0,
      targetCostPercent: 28.0,
      monthlyVolume: 360,
      ingredients: [
        { ing: getIng('Kurobuta'), qty: 250, unit: 'g' },
        { ing: getIng('Anchor Butter'), qty: 25, unit: 'g' },
        { ing: getIng('Garlic & French Rosemary'), qty: 15, unit: 'g' },
        { ing: getIng('Salad Greens'), qty: 50, unit: 'g' },
      ],
    },
    // 8. Plowhorse: Wagyu Basil Rice
    {
      name: 'Wagyu Basil Rice with Cured Yolk (ข้าวผัดกะเพราเนื้อวากิวไข่ดอง)',
      category: 'food',
      sellingPrice: 220.0,
      targetCostPercent: 42.0,
      monthlyVolume: 540,
      ingredients: [
        { ing: getIng('Wagyu'), qty: 60, unit: 'g' },
        { ing: getIng('Jasmine Rice'), qty: 180, unit: 'g' },
        { ing: getIng('Hen Eggs'), qty: 1, unit: 'ฟอง' },
        { ing: getIng('Holy Basil'), qty: 25, unit: 'g' },
        { ing: getIng('Olive Oil'), qty: 15, unit: 'ml' },
      ],
    },
    // 9. Plowhorse: Spaghetti Aglio Olio Tiger Prawn
    {
      name: 'Spaghetti Aglio Olio Tiger Prawn (สปาเก็ตตี้พริกแห้งกุ้งลายเสือ)',
      category: 'food',
      sellingPrice: 260.0,
      targetCostPercent: 42.0,
      monthlyVolume: 460,
      ingredients: [
        { ing: getIng('Spaghetti'), qty: 110, unit: 'g' },
        { ing: getIng('Tiger Prawns'), qty: 120, unit: 'g' },
        { ing: getIng('Olive Oil'), qty: 25, unit: 'ml' },
        { ing: getIng('Garlic & French Rosemary'), qty: 15, unit: 'g' },
      ],
    },
    // 10. Puzzle: Truffle Champignon Soup
    {
      name: 'Truffle Champignon Cream Soup (ซุปเห็ดแชมปิญองทรัฟเฟิล)',
      category: 'food',
      sellingPrice: 220.0,
      targetCostPercent: 24.0,
      monthlyVolume: 90,
      ingredients: [
        { ing: getIng('Champignon'), qty: 120, unit: 'g' },
        { ing: getIng('Heavy Cream'), qty: 100, unit: 'ml' },
        { ing: getIng('Truffle Paste'), qty: 10, unit: 'g' },
        { ing: getIng('Anchor Butter'), qty: 20, unit: 'g' },
      ],
    },
    // 11. Star: Smoked Salmon Salad
    {
      name: 'Smoked Salmon Garden Salad (สลัดแซลมอนรมควันฮันนี่มัสตาร์ด)',
      category: 'food',
      sellingPrice: 260.0,
      targetCostPercent: 30.0,
      monthlyVolume: 310,
      ingredients: [
        { ing: getIng('Salmon'), qty: 80, unit: 'g' },
        { ing: getIng('Salad Greens'), qty: 150, unit: 'g' },
        { ing: getIng('Avocado'), qty: 60, unit: 'g' },
        { ing: getIng('Olive Oil'), qty: 20, unit: 'ml' },
      ],
    },
    // 12. Star: Ceremonial Matcha Latte
    {
      name: 'Iced Ceremonial Uji Matcha Latte (มัทฉะลาเต้พรีเมียมเย็น)',
      category: 'drink',
      sellingPrice: 155.0,
      targetCostPercent: 22.0,
      monthlyVolume: 620,
      ingredients: [
        { ing: getIng('Uji Matcha'), qty: 4, unit: 'g' },
        { ing: getIng('Fresh Milk'), qty: 180, unit: 'ml' },
      ],
    },
    // 13. Star: Yuzu Sparkling Americano
    {
      name: 'Sparkling Yuzu Cold Brew (โคลด์บรูว์ส้มยูซุซ่า)',
      category: 'drink',
      sellingPrice: 165.0,
      targetCostPercent: 24.0,
      monthlyVolume: 480,
      ingredients: [
        { ing: getIng('Arabica Beans'), qty: 22, unit: 'g' },
        { ing: getIng('Yuzu'), qty: 35, unit: 'ml' },
      ],
    },
    // 14. Star: Dirty Coffee
    {
      name: 'Signature Velvet Dirty Coffee (เดอร์ตี้คอฟฟี่นมเย็นจัด)',
      category: 'drink',
      sellingPrice: 145.0,
      targetCostPercent: 20.0,
      monthlyVolume: 530,
      ingredients: [
        { ing: getIng('Arabica Beans'), qty: 20, unit: 'g' },
        { ing: getIng('Fresh Milk'), qty: 120, unit: 'ml' },
        { ing: getIng('Heavy Cream'), qty: 30, unit: 'ml' },
      ],
    },
    // 15. Star: French Butter Croissant
    {
      name: 'Golden French Butter Croissant (ครัวซองต์เนยสดฝรั่งเศส)',
      category: 'bakery',
      sellingPrice: 120.0,
      targetCostPercent: 32.0,
      monthlyVolume: 490,
      ingredients: [
        { ing: getIng('Croissant Dough'), qty: 1, unit: 'pcs' },
        { ing: getIng('Anchor Butter'), qty: 10, unit: 'g' },
      ],
    },
    // 16. Star: Truffle Parmesan Fries
    {
      name: 'Parmesan Truffle Shoestring Fries (เฟรนช์ฟรายส์ทรัฟเฟิลพาร์เมซาน)',
      category: 'food',
      sellingPrice: 165.0,
      targetCostPercent: 26.0,
      monthlyVolume: 610,
      ingredients: [
        { ing: getIng('Potato Fries'), qty: 180, unit: 'g' },
        { ing: getIng('Truffle Olive Oil'), qty: 10, unit: 'ml' },
        { ing: getIng('Parmigiano'), qty: 20, unit: 'g' },
      ],
    },
    // 17. New Star: Japanese Hotate Butter Truffle
    {
      name: 'Pan-Seared Hotate Scallops (หอยเชลล์โฮตาเตะย่างเนยทรัฟเฟิล)',
      category: 'food',
      sellingPrice: 590.0,
      targetCostPercent: 29.0,
      monthlyVolume: 240,
      ingredients: [
        { ing: getIng('Hotate Scallops'), qty: 120, unit: 'g' },
        { ing: getIng('Anchor Butter'), qty: 20, unit: 'g' },
        { ing: getIng('Truffle Olive Oil'), qty: 10, unit: 'ml' },
      ],
    },
    // 18. New Star: Lump Crab Meat Fried Rice
    {
      name: 'Supreme Blue Crab Fried Rice (ข้าวผัดปูม้าก้อนพรีเมียม)',
      category: 'food',
      sellingPrice: 380.0,
      targetCostPercent: 32.0,
      monthlyVolume: 410,
      ingredients: [
        { ing: getIng('Lump Blue Crab'), qty: 80, unit: 'g' },
        { ing: getIng('Jasmine Rice'), qty: 180, unit: 'g' },
        { ing: getIng('Hen Eggs'), qty: 1, unit: 'ฟอง' },
        { ing: getIng('Anchor Butter'), qty: 15, unit: 'g' },
      ],
    },
    // 19. New Dog: Creamy Chicken Carbonara
    {
      name: 'Classic Chicken Spaghetti (สปาเก็ตตี้ไก่ครีมซอส)',
      category: 'food',
      sellingPrice: 180.0,
      targetCostPercent: 38.0,
      monthlyVolume: 40,
      ingredients: [
        { ing: getIng('Chicken Breast'), qty: 120, unit: 'g' },
        { ing: getIng('Spaghetti'), qty: 100, unit: 'g' },
        { ing: getIng('Fresh Milk'), qty: 80, unit: 'ml' },
      ],
    },
    // 20. New Puzzle: 70.5% Belgian Lava Cake
    {
      name: 'Molten Belgian Dark Chocolate Cake (เค้กลาวาช็อกโกแลตเบลเยียม)',
      category: 'bakery',
      sellingPrice: 195.0,
      targetCostPercent: 24.0,
      monthlyVolume: 75,
      ingredients: [
        { ing: getIng('Dark Chocolate'), qty: 60, unit: 'g' },
        { ing: getIng('Anchor Butter'), qty: 30, unit: 'g' },
        { ing: getIng('Hen Eggs'), qty: 1, unit: 'ฟอง' },
      ],
    },
  ];

  const createdRecipes: any[] = [];
  const recipeCostMap = new Map<string, number>();

  for (const r of recipesData) {
    let bomCost = 0;
    for (const item of r.ingredients) {
      bomCost += Number(item.ing.costPerBaseUnit) * item.qty;
    }

    const rec = await prisma.recipe.create({
      data: {
        name: r.name,
        category: r.category,
        sellingPrice: r.sellingPrice,
        targetCostPercent: r.targetCostPercent,
        ingredients: {
          create: r.ingredients.map((item) => ({
            ingredientId: item.ing.id,
            quantityUsed: item.qty,
            unit: item.unit,
          })),
        },
      },
    });

    createdRecipes.push({
      id: rec.id,
      name: rec.name,
      sellingPrice: Number(r.sellingPrice),
      bomCost: Number(bomCost.toFixed(2)),
      monthlyVolume: r.monthlyVolume,
    });
    recipeCostMap.set(rec.id, Number(bomCost.toFixed(2)));
  }
  console.log(`✅ Created ${createdRecipes.length} recipes across all 4 quadrants.`);

  // 4. Create Monthly Sales Logs for Menu Engineering Matrix
  const now = new Date();
  const lastMonth = new Date();
  lastMonth.setMonth(now.getMonth() - 1);

  for (const r of createdRecipes) {
    await prisma.salesLog.create({
      data: {
        recipeId: r.id,
        quantitySold: r.monthlyVolume,
        period: now,
      },
    });
    await prisma.salesLog.create({
      data: {
        recipeId: r.id,
        quantitySold: Math.round(r.monthlyVolume * (0.85 + Math.random() * 0.3)),
        period: lastMonth,
      },
    });
  }
  console.log('✅ Created SalesLog records for the last 2 months.');

  // 5. Generate Rich Historical POS Orders Spanning the Last 60 Days
  console.log('⏳ Generating 60 days of historical POS orders...');
  let totalOrdersCreated = 0;

  // Meal rush hours distribution
  const rushHours = [
    { hour: 11, minute: 45 },
    { hour: 12, minute: 15 },
    { hour: 12, minute: 40 },
    { hour: 13, minute: 20 },
    { hour: 15, minute: 10 },
    { hour: 17, minute: 45 },
    { hour: 18, minute: 30 },
    { hour: 19, minute: 15 },
    { hour: 20, minute: 0 },
  ];

  for (let daysAgo = 60; daysAgo >= 0; daysAgo--) {
    // 3 to 6 orders per day
    const ordersTodayCount = 3 + Math.floor(Math.random() * 4);

    for (let oIdx = 0; oIdx < ordersTodayCount; oIdx++) {
      const rush = rushHours[(oIdx * 2 + Math.floor(Math.random() * 2)) % rushHours.length];
      const orderDate = getDateDaysAgo(daysAgo, rush.hour, rush.minute);

      // Pick 1 to 3 random recipes
      const numItems = 1 + Math.floor(Math.random() * 3);
      const chosenRecipes = [...createdRecipes]
        .sort(() => 0.5 - Math.random())
        .slice(0, numItems);

      let orderTotalAmount = 0;
      let orderTotalCost = 0;
      const orderItemsData: any[] = [];

      for (const recipe of chosenRecipes) {
        // High volume recipes get ordered more frequently in quantities 1-3
        const qty = 1 + Math.floor(Math.random() * 2);
        const itemPrice = recipe.sellingPrice;
        const itemCost = recipe.bomCost;

        orderTotalAmount += itemPrice * qty;
        orderTotalCost += itemCost * qty;

        orderItemsData.push({
          recipeId: recipe.id,
          quantity: qty,
          pricePerUnit: itemPrice,
          costPerUnit: itemCost,
          createdAt: orderDate,
        });
      }

      // Status: 92% COMPLETED, on day 0 some PENDING
      let status: OrderStatus = OrderStatus.COMPLETED;
      if (daysAgo === 0 && oIdx >= ordersTodayCount - 2) {
        status = OrderStatus.PENDING;
      } else if (Math.random() < 0.04) {
        status = OrderStatus.CANCELLED;
      }

      await prisma.order.create({
        data: {
          totalAmount: Number(orderTotalAmount.toFixed(2)),
          totalCost: Number(orderTotalCost.toFixed(2)),
          status,
          createdAt: orderDate,
          updatedAt: orderDate,
          items: {
            create: orderItemsData,
          },
        },
      });

      totalOrdersCreated++;
    }
  }

  console.log(`✅ Seeded ${totalOrdersCreated} completed POS orders spanning the last 60 days!`);
  console.log('🎉 60-day database seed finished successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
