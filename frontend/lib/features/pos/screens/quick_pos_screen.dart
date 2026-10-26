import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../ingredients/providers/ingredients_provider.dart';
import '../../recipes/models/recipe.dart';
import '../../recipes/providers/recipes_provider.dart';
import '../models/cart_item.dart';
import '../providers/orders_provider.dart';
import '../widgets/insufficient_stock_dialog.dart';

class QuickPosScreen extends ConsumerStatefulWidget {
  const QuickPosScreen({super.key});

  @override
  ConsumerState<QuickPosScreen> createState() => _QuickPosScreenState();
}

class _QuickPosScreenState extends ConsumerState<QuickPosScreen> {
  String _selectedCategory = 'ทั้งหมด';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipes = ref.watch(recipesProvider);
    final orderState = ref.watch(ordersProvider);
    final isDesktop = Responsive.isDesktop(context);

    // Extract unique categories
    final categories = [
      'ทั้งหมด',
      ...{for (final r in recipes) r.category},
    ];

    // Filter recipes
    final filteredRecipes = recipes.where((r) {
      final matchesCategory = _selectedCategory == 'ทั้งหมด' || r.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Search & Category Filters
            _buildTopFilterBar(categories),

            // Main Content Area
            Expanded(
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Menu Grid
                        Expanded(
                          flex: 7,
                          child: _buildMenuGrid(filteredRecipes, orderState),
                        ),

                        // Right: Order Summary Panel
                        Container(
                          width: 390,
                          decoration: const BoxDecoration(
                            color: AppTheme.backgroundElevated,
                            border: Border(
                              left: BorderSide(color: AppTheme.border, width: 1),
                            ),
                          ),
                          child: _buildCartPanel(orderState),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        _buildMenuGrid(filteredRecipes, orderState),
                        if (orderState.items.isNotEmpty)
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: _buildMobileCartBar(orderState),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopFilterBar(List<String> categories) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        final searchInput = SizedBox(
          width: isWide ? 260 : double.infinity,
          height: 38,
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'ค้นหาเมนูอาหาร...',
              hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.primary),
              ),
            ),
          ),
        );

        final titleWidget = Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.point_of_sale_rounded,
                color: AppTheme.primaryNeon,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick POS / รับออเดอร์หน้าร้าน',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'เลือกเมนูเพื่อจำลองการขาย ระบบจะตัดสต็อกวัตถุดิบตามสูตร (BOM) และอัปเดต Dashboard ทันที',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          decoration: const BoxDecoration(
            color: AppTheme.backgroundElevated,
            border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isWide)
                Row(
                  children: [
                    Expanded(child: titleWidget),
                    const SizedBox(width: 16),
                    searchInput,
                  ],
                )
              else ...[
                titleWidget,
                const SizedBox(height: 12),
                searchInput,
              ],
              const SizedBox(height: 12),
              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? const Color(0xFF0B0F19) : AppTheme.textSecondary,
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.04),
                        selectedColor: AppTheme.primary,
                        checkmarkColor: const Color(0xFF0B0F19),
                        side: BorderSide(
                          color: isSelected ? AppTheme.primary : AppTheme.border,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildMenuGrid(List<Recipe> recipes, OrderState orderState) {
    if (recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 54, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            const Text(
              'ไม่พบเมนูอาหารที่ค้นหา',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 3;
        if (constraints.maxWidth < 650) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 950) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 195,
          ),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return _buildRecipeCard(recipe, orderState);
          },
        );
      },
    );
  }

  Widget _buildRecipeCard(Recipe recipe, OrderState orderState) {
    final ingredientsNotifier = ref.read(ingredientsProvider.notifier);
    final canCook = ingredientsNotifier.canCookRecipe(recipe);
    final missingList = !canCook ? ingredientsNotifier.getMissingIngredients(recipe) : <String>[];
    final cartQty = orderState.getQuantityForRecipe(recipe.id);

    return InkWell(
      onTap: () {
        if (!canCook) {
          showInsufficientStockDialog(context, insufficientItems: missingList);
        } else {
          ref.read(ordersProvider.notifier).addToCart(recipe);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: canCook
              ? AppTheme.surfaceMuted.withValues(alpha: 0.8)
              : AppTheme.surfaceMuted.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cartQty > 0
                ? AppTheme.primary
                : (canCook ? AppTheme.border : AppTheme.danger.withValues(alpha: 0.3)),
            width: cartQty > 0 ? 1.5 : 1,
          ),
          boxShadow: [
            if (cartQty > 0)
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category + Stock / Cart Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    recipe.category,
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                if (!canCook)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.danger.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 12, color: AppTheme.danger),
                        SizedBox(width: 4),
                        Text(
                          'Out of Stock',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.danger),
                        ),
                      ],
                    ),
                  )
                else if (cartQty > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ในตะกร้า x$cartQty',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0B0F19),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Recipe Name
            Text(
              recipe.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: canCook ? AppTheme.textPrimary : AppTheme.textMuted,
                letterSpacing: -0.2,
                height: 1.25,
              ),
            ),

            const Spacer(),

            // Ingredient count indicator
            Text(
              '${recipe.items.length} วัตถุดิบตามสูตร',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),

            const SizedBox(height: 6),
            const Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 8),

            // Price & Profit Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '฿${recipe.sellingPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: canCook ? AppTheme.primaryNeon : AppTheme.textMuted,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'กำไร ฿${recipe.contributionMargin.toStringAsFixed(0)} (${(100 - recipe.foodCostPercentage).toStringAsFixed(0)}%)',
                      style: TextStyle(
                        fontSize: 11,
                        color: canCook ? AppTheme.textSecondary : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: canCook
                        ? (cartQty > 0 ? AppTheme.primary : Colors.white.withValues(alpha: 0.08))
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: cartQty > 0 ? AppTheme.primary : AppTheme.border,
                    ),
                  ),
                  child: Icon(
                    canCook ? (cartQty > 0 ? Icons.check_rounded : Icons.add_rounded) : Icons.block_rounded,
                    size: 18,
                    color: canCook ? (cartQty > 0 ? const Color(0xFF0B0F19) : AppTheme.textPrimary) : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartPanel(OrderState orderState) {
    return Column(
      children: [
        // Cart Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.shopping_bag_outlined, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'รายการสั่งซื้อ (Cart)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (orderState.items.isNotEmpty)
                TextButton.icon(
                  onPressed: () => ref.read(ordersProvider.notifier).clearCart(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('ล้างตะกร้า', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),

        const Divider(color: AppTheme.border, height: 1),

        // Cart Items List
        Expanded(
          child: orderState.items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_shopping_cart_rounded, size: 30, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'ยังไม่มีรายการอาหาร',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'แตะเลือกการ์ดเมนูอาหารจากฝั่งซ้าย\nเพื่อเพิ่มลงในตะกร้าสั่งซื้อ',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: orderState.items.length,
                  separatorBuilder: (_, _) => const Divider(color: AppTheme.border, height: 12),
                  itemBuilder: (context, index) {
                    final item = orderState.items[index];
                    return _buildCartItemRow(item);
                  },
                ),
        ),

        // Checkout Summary
        _buildCheckoutFooter(orderState),
      ],
    );
  }

  Widget _buildCartItemRow(CartItem item) {
    final ordersNotifier = ref.read(ordersProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Recipe Name & Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.recipe.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '฿${item.recipe.sellingPrice.toStringAsFixed(0)} / จาน',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),

          // Stepper Buttons: [-] [qty] [+]
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => ordersNotifier.decrementQuantity(item.recipe.id),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.remove_rounded, size: 14, color: AppTheme.textSecondary),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                ),
                InkWell(
                  onTap: () => ordersNotifier.incrementQuantity(item.recipe.id),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.add_rounded, size: 14, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Subtotal
          SizedBox(
            width: 70,
            child: Text(
              '฿${item.subtotal.toStringAsFixed(0)}',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryNeon,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutFooter(OrderState orderState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundElevated,
        border: const Border(top: BorderSide(color: AppTheme.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Order summary figures
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'จำนวนรวม (${orderState.totalQuantity} รายการ)',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'ต้นทุน est. ฿${orderState.totalCost.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ยอดชำระสุทธิ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              Text(
                '฿${orderState.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryNeon,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Confirm and Deduct Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: orderState.isEmpty || orderState.isSubmitting
                  ? null
                  : () => ref.read(ordersProvider.notifier).confirmAndDeductOrder(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: const Color(0xFF0B0F19),
                elevation: 4,
                shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: orderState.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0B0F19)),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 20),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  orderState.isSubmitting ? 'กำลังตัดสต็อก...' : 'ยืนยันออเดอร์ & ตัดสต็อก (Confirm & Deduct)',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCartBar(OrderState orderState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
            child: Text(
              '${orderState.totalQuantity}',
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0B0F19), fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ยอดสั่งซื้อปัจจุบัน', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              Text(
                '฿${orderState.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primaryNeon),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (ctx) => Container(
                  height: MediaQuery.of(ctx).size.height * 0.75,
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundElevated,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: _buildCartPanel(orderState),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: const Color(0xFF0B0F19),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('ดูตะกร้า & ยืนยัน', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
