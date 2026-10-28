import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../core/widgets/capsule_toast.dart';
import '../../../core/widgets/glass_container.dart';
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
  String _ingredientFilterQuery = '';
  String? _selectedIngredientCategory;

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
      CapsuleToast.showError(
        context,
        'ต้องมีวัตถุดิบอย่างน้อย 1 รายการในสูตรอาหาร',
        title: 'ไม่สามารถลบได้',
      );
      return;
    }

    setState(() {
      final removed = _ingredientRows.removeAt(index);
      removed.dispose();
    });
    CapsuleToast.showInfo(context, 'ลบรายการวัตถุดิบเรียบร้อยแล้ว');
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
        child: isDesktop
            ? Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Recipe Information & Dynamic Ingredient Rows (Scrollable)
                    Expanded(
                      flex: 7,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRecipeInfoCard(),
                            const SizedBox(height: 20),
                            _buildIngredientsBuilderCard(allIngredients, ingMap),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right: Sticky Live Reactive Cost Calculation Card
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        child: _buildLiveCostCard(
                          totalFoodCost: totalFoodCost,
                          foodCostPct: foodCostPct,
                          margin: margin,
                          suggestedPrice: suggestedPrice,
                          itemsCount: currentItems.length,
                          onSave: () => _saveRecipe(currentItems),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  children: [
                    // Live Calculation Card first on mobile
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
    return GlassContainer(
      padding: const EdgeInsets.all(AppConstants.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restaurant_rounded, color: AppTheme.primaryNeon, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ข้อมูลเมนูอาหาร (General Information)',
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 550;

              final nameField = TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อเมนูอาหาร *',
                  hintText: 'เช่น สเต๊กแซลมอนซอสเนยมะนาว',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'กรุณาระบุชื่อเมนู' : null,
              );

              final categoryField = DropdownButtonFormField<String>(
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
              );

              final priceField = TextFormField(
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
              );

              final volumeField = TextFormField(
                controller: _volumeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ประมาณการยอดขาย (จาน/เดือน)',
                  prefixIcon: Icon(Icons.trending_up_rounded, size: 20),
                  hintText: 'เช่น 150',
                ),
                onChanged: (_) => setState(() {}),
              );

              if (isWide) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(flex: 3, child: nameField),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: categoryField),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: priceField),
                        const SizedBox(width: 16),
                        Expanded(child: volumeField),
                      ],
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  nameField,
                  const SizedBox(height: 14),
                  categoryField,
                  const SizedBox(height: 14),
                  priceField,
                  const SizedBox(height: 14),
                  volumeField,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Card 2: Dynamic Ingredient Rows with Quick Search & Category Filter
  Widget _buildIngredientsBuilderCard(
    List<Ingredient> allIngredients,
    Map<String, Ingredient> ingMap,
  ) {
    final availableCategories = {'All', ...allIngredients.map((e) => e.category)}.toList();

    // Filter ingredients for dropdown suggestions
    final filteredIngredients = allIngredients.where((ing) {
      final matchesSearch = _ingredientFilterQuery.isEmpty ||
          ing.name.toLowerCase().contains(_ingredientFilterQuery.toLowerCase());
      final matchesCategory = _selectedIngredientCategory == null ||
          _selectedIngredientCategory == 'All' ||
          ing.category == _selectedIngredientCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return GlassContainer(
      padding: const EdgeInsets.all(AppConstants.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.egg_outlined, color: AppTheme.secondary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'รายการวัตถุดิบในจาน (Recipe Items)',
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _addIngredientRow(allIngredients),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('เพิ่มวัตถุดิบ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: const Color(0xFF0B0F19),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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

          // Quick Search & Category Filter Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'ค้นหาวัตถุดิบเพื่อเลือกในสูตร (Quick Search)...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          fillColor: Colors.white.withValues(alpha: 0.03),
                        ),
                        onChanged: (val) => setState(() => _ingredientFilterQuery = val.trim()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedIngredientCategory ?? 'All',
                          dropdownColor: AppTheme.surface,
                          items: availableCategories.map((cat) {
                            return DropdownMenuItem<String>(
                              value: cat,
                              child: Text(cat, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedIngredientCategory = val == 'All' ? null : val;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                if (_ingredientFilterQuery.isNotEmpty || (_selectedIngredientCategory != null && _selectedIngredientCategory != 'All')) ...[
                  const SizedBox(height: 8),
                  Text(
                    'กรองพบ ${filteredIngredients.length} วัตถุดิบในคลัง',
                    style: const TextStyle(fontSize: 11, color: AppTheme.primaryNeon, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Compact Ingredient Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _ingredientRows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
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

              // Dropdown items prioritize filtered search results while always keeping current selection
              final rowItems = (filteredIngredients.isNotEmpty ? filteredIngredients : allIngredients).toList();
              if (selectedIng != null && !rowItems.any((i) => i.id == selectedIng.id)) {
                rowItems.insert(0, selectedIng);
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 720;

                    final indexBadge = Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryNeon,
                        ),
                      ),
                    );

                    final ingredientSelector = DropdownButtonFormField<String>(
                      initialValue: row.ingredientId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      ),
                      hint: const Text('เลือกวัตถุดิบ', style: TextStyle(fontSize: 13)),
                      items: rowItems.map((ing) {
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
                    );

                    final quantityInput = TextFormField(
                      controller: row.quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'ปริมาณ',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      ),
                      onChanged: (_) => setState(() {}),
                    );

                    final unitDropdown = DropdownButtonFormField<String>(
                      initialValue: _commonUnits.contains(row.unit) ? row.unit : _commonUnits.first,
                      isDense: true,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
                    );

                    final lineCostWidget = SizedBox(
                      width: isWide ? 90 : 85,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.currency(lineCost),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Text('ต้นทุน', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                        ],
                      ),
                    );

                    final deleteButton = IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 20),
                      tooltip: 'ลบรายการนี้',
                      onPressed: () => _removeIngredientRow(index),
                    );

                    if (isWide) {
                      return Row(
                        children: [
                          indexBadge,
                          const SizedBox(width: 10),
                          Expanded(flex: 4, child: ingredientSelector),
                          const SizedBox(width: 10),
                          Expanded(flex: 2, child: quantityInput),
                          const SizedBox(width: 10),
                          Expanded(flex: 2, child: unitDropdown),
                          const SizedBox(width: 12),
                          lineCostWidget,
                          deleteButton,
                        ],
                      );
                    }

                    // Mobile / Narrow window 2-tier layout
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            indexBadge,
                            const SizedBox(width: 8),
                            Expanded(child: ingredientSelector),
                            deleteButton,
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const SizedBox(width: 32),
                            Expanded(flex: 3, child: quantityInput),
                            const SizedBox(width: 8),
                            Expanded(flex: 2, child: unitDropdown),
                            const SizedBox(width: 10),
                            lineCostWidget,
                          ],
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Card 3: Sticky Live Reactive Cost Preview Card with Smooth Gradient Progress Bar
  Widget _buildLiveCostCard({
    required double totalFoodCost,
    required double foodCostPct,
    required double margin,
    required double suggestedPrice,
    required int itemsCount,
    required VoidCallback onSave,
  }) {
    // Threshold Criteria:
    // < 30%: Vibrant Green (Healthy Margin)
    // 30 - 35%: Amber Orange (Caution Margin)
    // > 35%: Red Alert (High Food Cost Alert)
    final bool isHealthy = foodCostPct <= 30.0;
    final bool isCaution = foodCostPct > 30.0 && foodCostPct <= 35.0;

    final Color statusColor;
    final String statusBadge;
    final IconData statusIcon;
    final String statusDesc;
    final List<Color> gradientColors;

    if (isHealthy) {
      statusColor = AppTheme.starGreen;
      statusBadge = 'Healthy Margin';
      statusIcon = Icons.check_circle_rounded;
      statusDesc = 'ต้นทุนอยู่ในเกณฑ์ดีเยี่ยม (< 30%) อัตรากำไรขั้นต้นปลอดภัยสูง';
      gradientColors = const [Color(0xFF10B981), Color(0xFF00F5A0)];
    } else if (isCaution) {
      statusColor = AppTheme.plowhorseAmber;
      statusBadge = 'Caution Margin';
      statusIcon = Icons.info_outline_rounded;
      statusDesc = 'ต้นทุนเริ่มแตะกรอบระวัง (30-35%) ควรควบคุม portion หรือยอดสูญเสีย';
      gradientColors = const [Color(0xFFF59E0B), Color(0xFFFBBF24)];
    } else {
      statusColor = AppTheme.dogRose;
      statusBadge = 'High Food Cost Alert';
      statusIcon = Icons.warning_amber_rounded;
      statusDesc = 'ต้นทุนพุ่งสูงเกินเกณฑ์เป้าหมาย (> 35%) แนะนำปรับราคาขายหรือลดสัดส่วน';
      gradientColors = const [Color(0xFFEF4444), Color(0xFFF43F5E)];
    }

    return GlassContainer(
      glowColor: statusColor,
      glowOpacity: 0.14,
      glowBlur: 24,
      padding: const EdgeInsets.all(AppConstants.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                ),
                child: Icon(Icons.analytics_rounded, color: statusColor, size: 20),
              ),
              const SizedBox(width: 10),
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

          // Reactive Alert Badge with Glow
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusBadge,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                                fontSize: 12,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusDesc,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor.withValues(alpha: 0.9),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Big Food Cost % Gauge & Smooth Gradient Progress Bar
          Center(
            child: Column(
              children: [
                Text(
                  'Food Cost Percentage',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.percentage(foodCostPct),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 10),

                // Smooth Gradient Progress Bar
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: (foodCostPct / 100).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            gradient: LinearGradient(colors: gradientColors),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
          const SizedBox(height: 10),
          _buildCostLine(
            title: 'ราคาแนะนำ (Target 30% Food Cost):',
            value: Formatters.currency(suggestedPrice),
            valueColor: AppTheme.primaryNeon,
          ),
          const SizedBox(height: 10),
          _buildCostLine(
            title: 'จำนวนวัตถุดิบที่ใช้:',
            value: '$itemsCount รายการ',
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: const Text('บันทึกสูตรอาหารนี้'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: const Color(0xFF0B0F19),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
        ],
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
      CapsuleToast.showError(
        context,
        'กรุณาเลือกและระบุปริมาณวัตถุดิบอย่างน้อย 1 ชนิด',
        title: 'ข้อมูลไม่ครบถ้วน',
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

    CapsuleToast.showSuccess(
      context,
      'บันทึกสูตรอาหาร "${newRecipe.name}" เรียบร้อยแล้ว',
      title: 'บันทึกสำเร็จ',
    );

    context.go('/recipes');
  }
}
