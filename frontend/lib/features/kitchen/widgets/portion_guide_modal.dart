import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../recipes/models/recipe.dart';

/// Shows a Glassmorphism modal summarizing recipe portion specs to control food cost
void showKitchenPortionGuideModal(BuildContext context, Recipe recipe) {
  showDialog<void>(
    context: context,
    builder: (ctx) => KitchenPortionGuideModal(recipe: recipe),
  );
}

class KitchenPortionGuideModal extends StatelessWidget {
  final Recipe recipe;

  const KitchenPortionGuideModal({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 540),
              decoration: BoxDecoration(
                // Frosted Glassmorphism gradient background
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF161B26).withValues(alpha: 0.88),
                    const Color(0xFF0F172A).withValues(alpha: 0.94),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.primaryNeon.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 40,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 30,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Modal Header with ⚖️ Icon
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryNeon.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryNeon.withValues(alpha: 0.2),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Text('⚖️', style: TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Flexible(
                                    child: Text(
                                      'สเปกการปรุง (Portion Guide)',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                        letterSpacing: -0.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                                    ),
                                    child: const Text(
                                      'คุมต้นทุนเชฟ',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFF59E0B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                recipe.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryNeon,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: AppTheme.border, height: 1),

                  // Food Cost % Highlight & Warning Notice
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'กรุณาชั่งตวงตามสเปก เพื่อรักษามาตรฐานรสชาติและควบคุม Food Cost % ของร้าน',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.95),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ingredients Portion Specs List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 290),
                      child: recipe.items.isEmpty
                          ? _buildSamplePortionSpecs()
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: recipe.items.length,
                              separatorBuilder: (context, index) => const Divider(color: AppTheme.border, height: 8),
                              itemBuilder: (context, index) {
                                final item = recipe.items[index];
                                return _buildIngredientSpecRow(
                                  index: index + 1,
                                  name: item.ingredient.name,
                                  portion:
                                      '${item.quantityUsed.toStringAsFixed(item.quantityUsed % 1 == 0 ? 0 : 1)} ${item.unitUsed}',
                                );
                              },
                            ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Divider(color: AppTheme.border, height: 1),

                  // Modal Footer
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: const Color(0xFF0B0F19),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'รับทราบสเปกการปรุง (เข้าใจแล้ว)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientSpecRow({
    required int index,
    required String name,
    required String portion,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 13.5, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              portion,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryNeon,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSamplePortionSpecs() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIngredientSpecRow(index: 1, name: 'เนื้อหมูสันนอกหมักนุ่ม', portion: '120 g'),
        const Divider(color: AppTheme.border, height: 8),
        _buildIngredientSpecRow(index: 2, name: 'ซอสปรุงรสกะเพราสูตรลับ', portion: '20 ml'),
        const Divider(color: AppTheme.border, height: 8),
        _buildIngredientSpecRow(index: 3, name: 'ใบกะเพราสดคัดใบ', portion: '15 g'),
      ],
    );
  }
}
