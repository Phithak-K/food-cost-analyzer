import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/capsule_toast.dart';
import '../../../core/widgets/glass_container.dart';
import '../models/ingredient.dart';
import '../providers/ingredients_provider.dart';
import '../widgets/ingredient_form_dialog.dart';
import '../widgets/ingredient_metric_badge.dart';

class IngredientsScreen extends ConsumerStatefulWidget {
  const IngredientsScreen({super.key});

  @override
  ConsumerState<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends ConsumerState<IngredientsScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isTableView = true; // Toggle between DataTable2 and Grid Card View

  @override
  Widget build(BuildContext context) {
    final ingredients = ref.watch(ingredientsProvider);

    final filtered = ingredients.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.supplier.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == null || item.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    final categories = {'All', ...ingredients.map((e) => e.category)}.toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
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
                      'การจัดการวัตถุดิบ (Ingredient Management)',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'จัดการคลังวัตถุดิบ คำนวณเปอร์เซ็นต์ส่วนสูญเสีย (Yield %) และต้นทุนสุทธิต่อหน่วยย่อย',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => IngredientFormDialog.show(context),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('เพิ่มวัตถุดิบใหม่'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search, Category Filter & View Toggle Bar
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    // Search box
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320, minWidth: 180),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'ค้นหาชื่อวัตถุดิบ หรือผู้จัดจำหน่าย...',
                          prefixIcon: Icon(Icons.search_rounded, size: 20),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Category filter
                        Container(
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
                        ),
                        const SizedBox(width: 12),
                        // View Toggle Buttons (Table vs Grid)
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.table_chart_rounded,
                                  size: 18,
                                  color: _isTableView ? AppTheme.primary : AppTheme.textMuted,
                                ),
                                tooltip: 'ตารางข้อมูล Desktop (DataTable)',
                                onPressed: () => setState(() => _isTableView = true),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.grid_view_rounded,
                                  size: 18,
                                  color: !_isTableView ? AppTheme.primary : AppTheme.textMuted,
                                ),
                                tooltip: 'การ์ดวัตถุดิบ (Grid Cards)',
                                onPressed: () => setState(() => _isTableView = false),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${filtered.length} รายการ',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
            ),
            const SizedBox(height: 16),

            // Content Area: DataTable2 or Grid Cards
            Expanded(
              child: _isTableView
                  ? _buildDataTable(filtered)
                  : _buildGridCards(filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(List<Ingredient> items) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: DataTable2(
        columnSpacing: 16,
        horizontalMargin: 20,
        minWidth: 980,
        dataRowHeight: 76,
        headingRowColor: WidgetStateProperty.all(AppTheme.surfaceMuted),
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
          fontSize: 13,
        ),
        columns: const [
          DataColumn2(label: Text('ชื่อวัตถุดิบ'), size: ColumnSize.L),
          DataColumn2(label: Text('หมวดหมู่'), size: ColumnSize.S),
          DataColumn2(label: Text('ราคาซื้อ'), numeric: true, size: ColumnSize.S),
          DataColumn2(label: Text('Yield %'), numeric: true, size: ColumnSize.S),
          DataColumn2(label: Text('ต้นทุนต่อหน่วยย่อย (Base EP)'), numeric: true, size: ColumnSize.L),
          DataColumn2(label: Text('คงเหลือในสต็อก'), numeric: true, size: ColumnSize.S),
          DataColumn2(label: Text('ผู้จัดจำหน่าย'), size: ColumnSize.M),
          DataColumn2(label: Text('การจัดการ'), fixedWidth: 96),
        ],
        rows: items.map((item) {
          final isLowYield = item.yieldPercentage < 80;
          return DataRow2(
            cells: [
              DataCell(
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        item.name.substring(0, 1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(IngredientCategoryBadge(category: item.category)),
              DataCell(
                Text(
                  '${Formatters.currency(item.purchaseCost)} / ${item.purchaseQuantity} ${item.purchaseUnit}',
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLowYield
                        ? AppTheme.warning.withValues(alpha: 0.15)
                        : AppTheme.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.yieldPercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: isLowYield ? AppTheme.warning : AppTheme.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${Formatters.currency(item.costPerBaseUnit)} / ${item.baseUnit}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      '(${Formatters.currency(item.usableUnitCost)} / ${item.purchaseUnit})',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              DataCell(
                Text(
                  '${item.currentStock} ${item.purchaseUnit}',
                  style: TextStyle(
                    color: item.currentStock < 10 ? AppTheme.danger : AppTheme.textSecondary,
                    fontWeight: item.currentStock < 10 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              DataCell(Text(item.supplier, style: const TextStyle(color: AppTheme.textSecondary))),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
                      tooltip: 'แก้ไข',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => IngredientFormDialog.show(context, ingredient: item),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.danger),
                      tooltip: 'ลบ',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _confirmDelete(item),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGridCards(List<Ingredient> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 3
            : (constraints.maxWidth > 800 ? 2 : 1);

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 220,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return GlassContainer(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IngredientCategoryBadge(category: item.category),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ผู้จัดจำหน่าย: ${item.supplier}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ต้นทุนต่อหน่วยย่อย', style: Theme.of(context).textTheme.bodySmall),
                              Text(
                                '${Formatters.currency(item.costPerBaseUnit)} / ${item.baseUnit}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Yield %', style: Theme.of(context).textTheme.bodySmall),
                              Text(
                                '${item.yieldPercentage.toStringAsFixed(0)}%',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'คงเหลือ: ${item.currentStock} ${item.purchaseUnit}',
                          style: TextStyle(
                            fontSize: 12,
                            color: item.currentStock < 10 ? AppTheme.danger : AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
                              tooltip: 'แก้ไข',
                              onPressed: () => IngredientFormDialog.show(context, ingredient: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.danger),
                              tooltip: 'ลบ',
                              onPressed: () => _confirmDelete(item),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Ingredient item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบวัตถุดิบ'),
        content: Text('คุณแน่ใจหรือไม่ว่าต้องการลบ "${item.name}" ออกจากคลัง?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              ref.read(ingredientsProvider.notifier).deleteIngredient(item.id);
              Navigator.pop(ctx);
              CapsuleToast.showSuccess(
                context,
                'ลบ ${item.name} สำเร็จแล้ว',
                title: 'ลบวัตถุดิบเรียบร้อย',
              );
            },
            child: const Text('ลบวัตถุดิบ'),
          ),
        ],
      ),
    );
  }
}
