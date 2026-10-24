import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/unit_converter.dart';
import '../models/ingredient.dart';
import '../providers/ingredients_provider.dart';

/// Modal dialog for adding or editing an ingredient with real-time live unit cost calculation.
class IngredientFormDialog extends ConsumerStatefulWidget {
  final Ingredient? initialIngredient;

  const IngredientFormDialog({super.key, this.initialIngredient});

  static Future<void> show(BuildContext context, {Ingredient? ingredient}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => IngredientFormDialog(initialIngredient: ingredient),
    );
  }

  @override
  ConsumerState<IngredientFormDialog> createState() => _IngredientFormDialogState();
}

class _IngredientFormDialogState extends ConsumerState<IngredientFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _yieldController;
  late TextEditingController _stockController;
  late TextEditingController _supplierController;

  final List<String> _commonUnits = ['kg', 'g', 'L', 'ml', 'pcs', 'can', 'bottle'];
  final List<String> _categories = [
    'Meat',
    'Seafood',
    'Produce',
    'Dairy',
    'Oil & Condiments',
    'Specialty',
    'Dry Goods',
    'Beverage',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.initialIngredient;

    _nameController = TextEditingController(text: item?.name ?? '');
    _categoryController = TextEditingController(text: item?.category ?? 'Meat');
    _priceController = TextEditingController(
      text: item != null ? item.purchaseCost.toStringAsFixed(2) : '',
    );
    _quantityController = TextEditingController(
      text: item != null ? item.purchaseQuantity.toString() : '1.0',
    );
    _unitController = TextEditingController(text: item?.purchaseUnit ?? 'kg');
    _yieldController = TextEditingController(
      text: item != null ? item.yieldPercentage.toString() : '100.0',
    );
    _stockController = TextEditingController(
      text: item != null ? item.currentStock.toString() : '10.0',
    );
    _supplierController = TextEditingController(text: item?.supplier ?? 'ทั่วไป');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _yieldController.dispose();
    _stockController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  // Live calculation values
  double get _currentPrice => double.tryParse(_priceController.text) ?? 0.0;
  double get _currentQty => double.tryParse(_quantityController.text) ?? 1.0;
  String get _currentUnit => _unitController.text.trim();
  double get _currentYield => double.tryParse(_yieldController.text) ?? 100.0;

  double get _calculatedCostPerBaseUnit {
    if (_currentPrice <= 0 || _currentQty <= 0 || _currentYield <= 0) return 0.0;
    final baseQty = UnitConverter.toBaseUnit(_currentQty, _currentUnit);
    final effectiveBaseQty = baseQty * (_currentYield / 100.0);
    return effectiveBaseQty > 0 ? (_currentPrice / effectiveBaseQty) : 0.0;
  }

  double get _calculatedUsableUnitCost {
    final baseInOneUnit = UnitConverter.toBaseUnit(1.0, _currentUnit);
    return _calculatedCostPerBaseUnit * baseInOneUnit;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialIngredient != null;
    final baseUnitName = UnitConverter.getBaseUnitName(_currentUnit);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                            color: AppTheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'แก้ไขข้อมูลวัตถุดิบ' : 'เพิ่มวัตถุดิบใหม่',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'คำนวณต้นทุนต่อหน่วยและส่วนสูญเสีย (Yield %) อัตโนมัติ',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Live Cost Calculation Banner (Reactive)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.08),
                        AppTheme.accent.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calculate_outlined, size: 16, color: AppTheme.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'ต้นทุนต่อหน่วยฐาน (Base Unit Cost):',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primary,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${Formatters.currency(_calculatedCostPerBaseUnit)} / $baseUnitName',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                              ),
                            ),
                            Text(
                              'ต้นทุนสุทธิหลังตัดแต่ง: ${Formatters.currency(_calculatedUsableUnitCost)} / ${_currentUnit.isEmpty ? 'หน่วย' : _currentUnit}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _currentYield >= 90
                              ? AppTheme.success.withValues(alpha: 0.15)
                              : (_currentYield >= 75 ? AppTheme.warning.withValues(alpha: 0.15) : AppTheme.danger.withValues(alpha: 0.15)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Yield ${_currentYield.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _currentYield >= 90
                                    ? AppTheme.success
                                    : (_currentYield >= 75 ? AppTheme.warning : AppTheme.danger),
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'สูญเสีย ${(100 - _currentYield).clamp(0, 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Form Fields (Scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'ชื่อวัตถุดิบ *',
                            hintText: 'เช่น Norwegian Salmon Fillet, Wagyu Beef',
                            prefixIcon: Icon(Icons.fastfood_outlined, size: 20),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'กรุณาระบุชื่อวัตถุดิบ' : null,
                        ),
                        const SizedBox(height: 14),

                        // Category & Unit Row
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                initialValue: _categories.contains(_categoryController.text)
                                    ? _categoryController.text
                                    : _categories.first,
                                decoration: const InputDecoration(labelText: 'หมวดหมู่วัตถุดิบ'),
                                items: _categories
                                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _categoryController.text = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                initialValue: _commonUnits.contains(_unitController.text)
                                    ? _unitController.text
                                    : _commonUnits.first,
                                decoration: const InputDecoration(labelText: 'หน่วยซื้อ (Unit) *'),
                                items: _commonUnits
                                    .map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13))))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _unitController.text = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Purchase Price & Purchase Quantity
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'ราคาซื้อต่อแพ็ก (฿) *',
                                  hintText: 'เช่น 650',
                                  prefixIcon: Icon(Icons.attach_money_rounded, size: 20),
                                ),
                                onChanged: (_) => setState(() {}),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'กรุณากรอกราคาซื้อ';
                                  if (double.tryParse(val) == null) return 'ต้องเป็นตัวเลข';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: _quantityController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'ปริมาณต่อแพ็ก *',
                                  hintText: 'เช่น 1.0 หรือ 500',
                                  suffixText: _currentUnit,
                                ),
                                onChanged: (_) => setState(() {}),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'กรุณากรอกปริมาณ';
                                  if (double.tryParse(val) == null || double.parse(val) <= 0) return 'ต้องมากกว่า 0';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Yield % & Stock
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _yieldController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Edible Yield % (เนื้อที่ใช้ได้) *',
                                  hintText: '100% หรือ 85%',
                                  suffixText: '%',
                                ),
                                onChanged: (_) => setState(() {}),
                                validator: (val) {
                                  final numVal = double.tryParse(val ?? '');
                                  if (numVal == null || numVal <= 0 || numVal > 100) {
                                    return 'ค่าต้องอยู่ระหว่าง 1 - 100%';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: _stockController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'สต็อกคงเหลือปัจจุบัน',
                                  suffixText: _currentUnit,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Supplier
                        TextFormField(
                          controller: _supplierController,
                          decoration: const InputDecoration(
                            labelText: 'ผู้จัดจำหน่าย / ซัพพลายเออร์',
                            hintText: 'เช่น Ocean Fresh Co., Makro, ตลาดสด',
                            prefixIcon: Icon(Icons.local_shipping_outlined, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ยกเลิก'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _saveIngredient,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(isEditing ? 'บันทึกการแก้ไข' : 'เพิ่มวัตถุดิบ'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveIngredient() {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.initialIngredient?.id ?? 'ing_${DateTime.now().millisecondsSinceEpoch}';
    final ingredient = Ingredient(
      id: id,
      name: _nameController.text.trim(),
      category: _categoryController.text.trim(),
      purchaseCost: _currentPrice,
      purchaseQuantity: _currentQty,
      purchaseUnit: _currentUnit,
      costPerBaseUnit: _calculatedCostPerBaseUnit,
      yieldPercentage: _currentYield,
      currentStock: double.tryParse(_stockController.text) ?? 0.0,
      supplier: _supplierController.text.trim().isEmpty ? 'ทั่วไป' : _supplierController.text.trim(),
    );

    if (widget.initialIngredient != null) {
      ref.read(ingredientsProvider.notifier).updateIngredient(ingredient);
    } else {
      ref.read(ingredientsProvider.notifier).addIngredient(ingredient);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.initialIngredient != null
              ? 'อัปเดตข้อมูล ${ingredient.name} เรียบร้อยแล้ว'
              : 'เพิ่มวัตถุดิบ ${ingredient.name} เข้าสู่ระบบสำเร็จ',
        ),
        backgroundColor: AppTheme.success,
      ),
    );
  }
}
