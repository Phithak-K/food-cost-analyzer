import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../recipes/models/recipe.dart';
import '../services/report_export_service.dart';

class ExportReportDialog extends StatefulWidget {
  final DashboardMetrics metrics;
  final List<Recipe> recipes;

  const ExportReportDialog({
    super.key,
    required this.metrics,
    required this.recipes,
  });

  static Future<void> show(
    BuildContext context, {
    required DashboardMetrics metrics,
    required List<Recipe> recipes,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ExportReportDialog(
        metrics: metrics,
        recipes: recipes,
      ),
    );
  }

  @override
  State<ExportReportDialog> createState() => _ExportReportDialogState();
}

class _ExportReportDialogState extends State<ExportReportDialog> {
  bool _isExportingPdf = false;
  String? _successMessage;

  Future<void> _handleExportCsv() async {
    try {
      ReportExportService.exportCsv(
        metrics: widget.metrics,
        recipes: widget.recipes,
      );
      setState(() {
        _successMessage = 'ดาวน์โหลดไฟล์ Excel/CSV เรียบร้อยแล้ว!';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการดาวน์โหลด CSV: $e')),
        );
      }
    }
  }

  Future<void> _handleExportPdf() async {
    setState(() {
      _isExportingPdf = true;
      _successMessage = null;
    });

    try {
      await ReportExportService.exportPdf(
        metrics: widget.metrics,
        recipes: widget.recipes,
      );
      if (mounted) {
        setState(() {
          _isExportingPdf = false;
          _successMessage = 'ดาวน์โหลดไฟล์ PDF เรียบร้อยแล้ว!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExportingPdf = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการดาวน์โหลด PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = widget.metrics;
    final recipes = widget.recipes;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      ),
      backgroundColor: AppTheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.cardPadding + 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.download_for_offline_rounded, color: AppTheme.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ดาวน์โหลดรายงานการวิเคราะห์',
                                style: Theme.of(context).textTheme.titleLarge,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Menu Engineering & Costing Report',
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Summary Highlights
              Text(
                'ข้อมูลสำคัญที่รวมอยู่ในรายงาน (Executive Report Overview):',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    _buildReportItem(
                      icon: Icons.analytics_outlined,
                      color: AppTheme.primary,
                      title: 'สรุปภาพรวมต้นทุนเฉลี่ยของร้าน',
                      detail:
                          'ยอดขายรวม ${Formatters.compactCurrency(metrics.totalRevenue)} | กำไร ${Formatters.compactCurrency(metrics.totalProfit)} | Food Cost เฉลี่ย ${Formatters.percentage(metrics.overallFoodCostPct)}',
                    ),
                    const SizedBox(height: 8),
                    _buildReportItem(
                      icon: Icons.trending_up_rounded,
                      color: AppTheme.secondary,
                      title: 'รายการเมนูที่ควรปรับสูตร/ขึ้นราคา (Plowhorses)',
                      detail: '${metrics.plowhorses.length} เมนู (ขายดีแต่กำไรน้อย แนะนำลดสัดส่วนหรือขึ้นราคา)',
                    ),
                    const SizedBox(height: 8),
                    _buildReportItem(
                      icon: Icons.warning_amber_rounded,
                      color: AppTheme.danger,
                      title: 'รายการเมนูที่แนะนำให้ตัดออก (Dogs)',
                      detail: '${metrics.dogs.length} เมนู (ขายไม่ออกและกำไรต่ำ แนะนำพิจารณาตัดออกจากเมนู)',
                    ),
                    const SizedBox(height: 8),
                    _buildReportItem(
                      icon: Icons.inventory_2_outlined,
                      color: AppTheme.success,
                      title: 'ตารางต้นทุนวัตถุดิบละเอียด (Bill of Materials - BOM)',
                      detail: '${recipes.length} เมนู พร้อมแจกแจงวัตถุดิบ ปริมาณ ต้นทุน และ % สัดส่วนในจาน',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Success Notification Banner
              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Download Buttons
              Text(
                'เลือกรูปแบบไฟล์สำหรับดาวน์โหลดผ่านเบราว์เซอร์:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  // Excel/CSV Option
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        side: const BorderSide(color: Color(0xFF107C41), width: 1.5), // Excel Green
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: const Color(0xFF107C41).withValues(alpha: 0.04),
                      ),
                      onPressed: _handleExportCsv,
                      child: Column(
                        children: [
                          const Icon(Icons.table_chart_rounded, color: Color(0xFF107C41), size: 28),
                          const SizedBox(height: 8),
                          const Text(
                            'Excel / CSV (.csv)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF107C41),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'UTF-8 BOM ภาษาไทย 100%',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // PDF Option
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        backgroundColor: const Color(0xFFDC2626), // PDF Red
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 1,
                      ),
                      onPressed: _isExportingPdf ? null : _handleExportPdf,
                      child: _isExportingPdf
                          ? const Column(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                ),
                                SizedBox(height: 8),
                                Text('กำลังสร้าง PDF...', style: TextStyle(fontSize: 12)),
                              ],
                            )
                          : const Column(
                              children: [
                                Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 28),
                                SizedBox(height: 8),
                                Text(
                                  'PDF Report (.pdf)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'เอกสารรายงานทางการ A4',
                                  style: TextStyle(fontSize: 11, color: Colors.white70),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportItem({
    required IconData icon,
    required Color color,
    required String title,
    required String detail,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              Text(
                detail,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
