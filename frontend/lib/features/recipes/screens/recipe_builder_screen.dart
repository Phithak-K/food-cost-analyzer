import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/unit_converter.dart';
import '../../ingredients/models/ingredient.dart';
import '../../ingredients/providers/ingredients_provider.dart';
import '../models/recipe.dart';
import '../models/recipe_item.dart';
import '../providers/recipes_provider.dart';
import '../services/food_cost_calculator.dart';

class RecipeBuilderScreen extends ConsumerStatefulWidget {
  final Recipe? initialRecipe;

  const RecipeBuilderScreen({super.key, this.initialRecipe});

  @override
  ConsumerState<RecipeBuilderScreen> createState() => _RecipeBuilderScreenState();
}

class _IngredientRowData {
  String? ingredientId;
  final TextEditingController quantityController;
  String unit;

  _IngredientRowData({
    this.ingredientId,
    required this.quantityController,
    this.unit = 'g',
  });

  void dispose() {
    quantityController.dispose();
  }
}

class _RecipeBuilderScreenState extends ConsumerState<RecipeBuilderScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late TextEditingController _volumeController;

  final List<_IngredientRowData> _ingredientRows = [];

  final List<String> _categories = [
    'Main Course',
    'Appetizer',
    'Pasta',
    'Steak',
    'Seafood',
    'Salad',
    'Dessert',
    'Beverage',
  ];

  final List<String> _commonUnits = [
    'g',
    'kg',
    'ml',
    'L',
    'tbsp',
    'tsp',
    'pcs',
  ];

  @override
  void initState() {
    super.initState();
    final recipe = widget.initialRecipe;

    _nameController = TextEditingController(text: recipe?.name ?? '');
    _categoryController = TextEditingController(text: recipe?.category ?? 'Main Course');
    _priceController = TextEditingController(
      text: recipe != null ? recipe.sellingPrice.toStringAsFixed(0) : '350',
    );
    _volumeController = TextEditingController(
      text: recipe != null ? recipe.unitsSoldMonthly.toString() : '150',
    );

    if (recipe != null && recipe.items.isNotEmpty) {
      for (final item in recipe.items) {
        _ingredientRows.add(
          _IngredientRowData(
            ingredientId: item.ingredient.id,
            quantityController: TextEditingController(text: item.quantityUsed.toString()),
            unit: item.unitUsed,
          ),
        );
      }
    } else {
      // Add one empty ingredient row by default
      _ingredientRows.add(
        _IngredientRowData(
          quantityController: TextEditingController(text: '100'),
          unit: 'g',
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _volumeController.dispose();
    for (final row in _ingredientRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addIngredientRow(List<Ingredient> available) {
    setState(() {
      _ingredientRows.add(
        _IngredientRowData(
          ingredientId: available.isNotEmpty ? available.first.id : null,
          quantityController: TextEditingController(text: '50'),
          unit: 'g',
        ),
      );
    });
  }

  void _removeIngredientRow(int index) {
    if (_ingredientRows.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ต้องมีวัตถุดิบอย่างน้อย 1 รายการ')),
      );
      return;
    }
    setState(() {
      final removed = _ingredientRows.removeAt(index);
      removed.dispose();
    });
  }

  // --- Live Reactive Calculations ---
  double get _sellingPrice => double.tryParse(_priceController.text) ?? 0.0;
  int get _salesVolume => int.tryParse(_volumeController.text) ?? 0;

  List<RecipeItem> _buildCurrentRecipeItems(Map<String, Ingredient> ingMap) {
    final List<RecipeItem> items = [];
    for (final row in _ingredientRows) {
      if (row.ingredientId != null && ingMap.containsKey(row.ingredientId)) {
        final ingredient = ingMap[row.ingredientId]!;
        final qty = double.tryParse(row.quantityController.text) ?? 0.0;
        if (qty > 0) {
          items.add(
            RecipeItem(
              ingredient: ingredient,
              quantityUsed: qty,
              unitUsed: row.unit,
            ),
          );
        }
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final allIngredients = ref.watch(ingredientsProvider);
    final ingMap = {for (var i in allIngredients) i.id: i};

    // Auto-select first ingredient for rows that haven't picked one yet
    for (final row in _ingredientRows) {
      if (row.ingredientId == null && allIngredients.isNotEmpty) {
        row.ingredientId = allIngredients.first.id;
        row.unit = allIngredients.first.baseUnit;
      }
    }

    final currentItems = _buildCurrentRecipeItems(ingMap);
    final totalFoodCost = FoodCostCalculator.calculateTotalCost(currentItems);
    final foodCostPct = FoodCostCalculator.calculateFoodCostPercentage(
      totalCost: totalFoodCost,
      sellingPrice: _sellingPrice,
    );
    final margin = FoodCostCalculator.calculateContributionMargin(
      sellingPrice: _sellingPrice,
      totalCost: totalFoodCost,
    );
    final suggestedPrice = FoodCostCalculator.suggestSellingPrice(
      totalCost: totalFoodCost,
      targetFoodCostPercentage: 30.0,
    );

    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.initialRecipe != null ? 'แก้ไขสูตรอาหาร' : 'สร้างสูตรอาหาร & คำนวณต้นทุน (Recipe Builder)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/recipes'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _saveRecipe(currentItems),
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('บันทึกสูตรอาหาร'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Recipe Information & Dynamic Ingredient Rows
                    Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRecipeInfoCard(),
                          const SizedBox(height: 20),
                          _buildIngredientsBuilderCard(allIngredients, ingMap),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right: Live Reactive Cost Calculation Card (Sidebar)
                    Expanded(
                      flex: 4,
                      child: _buildLiveCostCard(
                        totalFoodCost: totalFoodCost,
                        foodCostPct: foodCostPct,
                        margin: margin,
                        suggestedPrice: suggestedPrice,
                        itemsCount: currentItems.length,
                        onSave: () => _saveRecipe(currentItems),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    // Top: Live Calculation Card on mobile
                    _buildLiveCostCard(
                      totalFoodCost: totalFoodCost,
                      foodCostPct: foodCostPct,
                      margin: margin,
                      suggestedPrice: suggestedPrice,
                      itemsCount: currentItems.length,
                      onSave: () => _saveRecipe(currentItems),
                    ),
                    const SizedBox(height: 20),
                    _buildRecipeInfoCard(),
                    const SizedBox(height: 20),
                    _buildIngredientsBuilderCard(allIngredients, ingMap),
                  ],
                ),
        ),
      ),
    );
  }

  // Card 1: Recipe Meta Information
  Widget _buildRecipeInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant_rounded, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ข้อมูลเมนูอาหาร (General Information)',
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อเมนูอาหาร *',
                      hintText: 'เช่น สเต๊กแซลมอนซอสเนยมะนาว',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'กรุณาระบุชื่อเมนู' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _categories.contains(_categoryController.text)
                        ? _categoryController.text
                        : _categories.first,
                    decoration: const InputDecoration(labelText: 'หมวดหมู่อาหาร'),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _categoryController.text = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'ราคาขายหน้าร้าน (Selling Price - ฿) *',
                      prefixIcon: Icon(Icons.sell_outlined, size: 20),
                      hintText: 'เช่น 450',
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'กรุณากรอกราคาขาย';
                      if (double.tryParse(val) == null || double.parse(val) <= 0) return 'ราคาต้องมากกว่า 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _volumeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ประมาณการยอดขาย (จาน/เดือน)',
                      prefixIcon: Icon(Icons.trending_up_rounded, size: 20),
                      hintText: 'เช่น 150',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Card 2: Dynamic Ingredient Rows
  Widget _buildIngredientsBuilderCard(
    List<Ingredient> allIngredients,
    Map<String, Ingredient> ingMap,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.egg_outlined, color: AppTheme.secondary, size: 20),
                    const SizedBox(width: 8),
                    Text('รายการวัตถุดิบในจาน (Recipe Items)', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _addIngredientRow(allIngredients),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('เพิ่มวัตถุดิบ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'เลือกวัตถุดิบและระบุปริมาณที่ใช้ ระบบจะแปลงหน่วยและคำนวณต้นทุนสุทธิให้อัตโนมัติ',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Rows list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ingredientRows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final row = _ingredientRows[index];
                final selectedIng = row.ingredientId != null ? ingMap[row.ingredientId] : null;

                // Line item cost
                double lineCost = 0.0;
                if (selectedIng != null) {
                  final qty = double.tryParse(row.quantityController.text) ?? 0.0;
                  lineCost = UnitConverter.calculateItemCost(
                    costPerBaseUnit: selectedIng.costPerBaseUnit,
                    quantityUsed: qty,
                    unitUsed: row.unit,
                  );
                }

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      // Number index badge
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Ingredient Dropdown
                      Expanded(
                        flex: 4,
                        child: DropdownButtonFormField<String>(
                          initialValue: row.ingredientId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          hint: const Text('เลือกวัตถุดิบ', style: TextStyle(fontSize: 13)),
                          items: allIngredients.map((ing) {
                            return DropdownMenuItem<String>(
                              value: ing.id,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      ing.name,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '(${Formatters.currency(ing.costPerBaseUnit)}/${ing.baseUnit})',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              row.ingredientId = val;
                              if (val != null && ingMap.containsKey(val)) {
                                row.unit = ingMap[val]!.baseUnit;
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Quantity input
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: row.quantityController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'ปริมาณ',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Unit dropdown
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: _commonUnits.contains(row.unit) ? row.unit : _commonUnits.first,
                          isDense: true,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          items: _commonUnits.map((u) {
                            return DropdownMenuItem<String>(
                              value: u,
                              child: Text(u, style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => row.unit = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Line Cost
                      SizedBox(
                        width: 90,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Formatters.currency(lineCost),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Text('ต้นทุน', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),

                      // Delete row
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 20),
                        tooltip: 'ลบรายการนี้',
                        onPressed: () => _removeIngredientRow(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Card 3: Live Reactive Cost Calculation Card (The Heart of Menu Costing)
  Widget _buildLiveCostCard({
    required double totalFoodCost,
    required double foodCostPct,
    required double margin,
    required double suggestedPrice,
    required int itemsCount,
    required VoidCallback onSave,
  }) {
    // Status Badge Logic:
    // Green: < 35% (Optimal)
    // Amber: 35% - 40% (Borderline / Warning)
    // Red: > 40% (High / Critical danger)
    final bool isHealthy = foodCostPct <= AppConstants.targetFoodCostMax;
    final bool isExcellent = foodCostPct <= AppConstants.targetFoodCostMin;

    final Color statusColor = isExcellent
        ? AppTheme.success
        : (isHealthy ? AppTheme.primary : (foodCostPct <= 40 ? AppTheme.warning : AppTheme.danger));

    final String statusTitle = isExcellent
        ? 'ต้นทุนดีเยี่ยม (< 28%)'
        : (isHealthy ? 'ต้นทุนตามเกณฑ์มาตรฐาน (28-35%)' : 'ต้นทุนสูงเกินเกณฑ์เป้าหมาย (> 35%)');

    final String statusDesc = isHealthy
        ? 'สัดส่วนกำไรขั้นต้นอยู่ในเกณฑ์ที่ปลอดภัยสำหรับธุรกิจร้านอาหาร'
        : 'ควรพิจารณาปรับขึ้นราคาขาย ปรับลด Portion หรือเปลี่ยนวัตถุดิบทดแทน';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_rounded, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'คำนวณต้นทุนสด (Live Costing)',
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reactive Alert Badge
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    isHealthy ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                    color: statusColor,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusTitle,
                          style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusDesc,
                          style: TextStyle(fontSize: 11, color: statusColor.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Big Food Cost % Gauge
            Center(
              child: Column(
                children: [
                  Text('Food Cost Percentage', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.percentage(foodCostPct),
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 10,
                      width: double.infinity,
                      child: Row(
                        children: [
                          Expanded(
                            flex: (foodCostPct.clamp(0, 100) * 10).round(),
                            child: Container(color: statusColor),
                          ),
                          Expanded(
                            flex: ((100 - foodCostPct).clamp(0, 100) * 10).round(),
                            child: Container(color: AppTheme.surfaceMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Breakdown Metrics
            _buildCostLine(
              title: 'ราคาขายหน้าร้าน (Selling Price):',
              value: Formatters.currency(_sellingPrice),
              isBold: true,
            ),
            const SizedBox(height: 10),
            _buildCostLine(
              title: 'ต้นทุนอาหารรวม (Total Food Cost):',
              value: Formatters.currency(totalFoodCost),
              valueColor: AppTheme.danger,
              isBold: true,
            ),
            const SizedBox(height: 10),
            _buildCostLine(
              title: 'กำไรขั้นต้นต่อจาน (Margin):',
              value: Formatters.currency(margin),
              valueColor: AppTheme.success,
              isBold: true,
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 14),

            // Suggested Price Helper
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'ราคาขายแนะนำ (Target 30% Cost):',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Formatters.currency(suggestedPrice),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'กำไรรวมคาดการณ์ ($_salesVolume จาน):',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Formatters.compactCurrency(margin * _salesVolume),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: const Text('บันทึกสูตรอาหารนี้'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostLine({
    required String title,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  void _saveRecipe(List<RecipeItem> items) {
    if (!_formKey.currentState!.validate()) return;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกและระบุปริมาณวัตถุดิบอย่างน้อย 1 ชนิด')),
      );
      return;
    }

    final id = widget.initialRecipe?.id ?? 'rec_${DateTime.now().millisecondsSinceEpoch}';
    final newRecipe = Recipe(
      id: id,
      name: _nameController.text.trim(),
      category: _categoryController.text.trim(),
      sellingPrice: _sellingPrice,
      items: items,
      unitsSoldMonthly: _salesVolume,
    );

    if (widget.initialRecipe != null) {
      ref.read(recipesProvider.notifier).updateRecipe(newRecipe);
    } else {
      ref.read(recipesProvider.notifier).addRecipe(newRecipe);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('บันทึกสูตรอาหาร "${newRecipe.name}" เรียบร้อยแล้ว!'),
        backgroundColor: AppTheme.success,
      ),
    );

    context.go('/recipes');
  }
}
