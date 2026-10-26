import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../models/recipe.dart';
import '../providers/recipes_provider.dart';
import '../widgets/recipe_card.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final recipes = ref.watch(recipesProvider);

    final filtered = recipes.where((r) {
      final matchesSearch = r.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == null || r.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    final categories = {'All', ...recipes.map((e) => e.category)}.toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สูตรอาหาร & การคิดต้นทุน (Recipes & Food Costing)',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'คำนวณ Food Cost %, กำไรขั้นต้นต่อจาน (Contribution Margin) และยอดขายจริง',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => context.go('/recipes/builder'),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('สร้างสูตรอาหารใหม่ (Recipe Builder)'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search & Filter
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 650;
                    final searchField = TextField(
                      decoration: const InputDecoration(
                        hintText: 'ค้นหาชื่อเมนูอาหาร...',
                        prefixIcon: Icon(Icons.search_rounded, size: 20),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    );

                    final dropdown = Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory ?? 'All',
                          items: categories.map((cat) {
                            return DropdownMenuItem<String>(
                              value: cat,
                              child: Text(
                                cat,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedCategory = val == 'All' ? null : val;
                            });
                          },
                        ),
                      ),
                    );

                    final countText = Text(
                      'พบ ${filtered.length} เมนู',
                      style: Theme.of(context).textTheme.bodySmall,
                    );

                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(flex: 2, child: searchField),
                          const SizedBox(width: 16),
                          dropdown,
                          const SizedBox(width: 16),
                          countText,
                        ],
                      );
                    }

                    return Column(
                      children: [
                        searchField,
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            dropdown,
                            const Spacer(),
                            countText,
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recipes Grid
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 1200
                      ? 2
                      : (constraints.maxWidth > 700 ? 1 : 1);

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 250,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final recipe = filtered[index];
                      return RecipeCard(
                        recipe: recipe,
                        onTap: () => _showRecipeDetailsDialog(context, recipe),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipeDetailsDialog(BuildContext context, Recipe recipe) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Text(recipe.name, style: Theme.of(context).textTheme.titleLarge),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'ราคาขาย: ${Formatters.currency(recipe.sellingPrice)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ส่วนประกอบในจาน (Sub-recipes & Ingredients breakdown):',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(2),
                  },
                  border: TableBorder.all(color: AppTheme.border, borderRadius: BorderRadius.circular(8)),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: AppTheme.surfaceMuted),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Text('วัตถุดิบ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Text('ปริมาณใช้', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Text('ต้นทุน (฿)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                    ...recipe.ingredients.map(
                      (item) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(item.ingredient.name, style: const TextStyle(fontSize: 13)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              '${item.quantityUsed} ${item.unitUsed}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              Formatters.currency(item.cost),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ต้นทุนอาหารรวม (Total Food Cost):',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        Formatters.currency(recipe.totalFoodCost),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/recipes/builder', extra: recipe);
            },
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('แก้ไขสูตรใน Recipe Builder'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }
}
