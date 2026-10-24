import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/file_downloader.dart';
import '../../../core/utils/formatters.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../recipes/models/recipe.dart';

class ReportExportService {
  /// Generates the full CSV content formatted with UTF-8 BOM for Microsoft Excel compatibility.
  static String generateCsvContent({
    required DashboardMetrics metrics,
    required List<Recipe> recipes,
  }) {
    final buffer = StringBuffer();
    // Prepend UTF-8 BOM (\uFEFF) so Excel on Windows/Mac renders Thai without mojibake
    buffer.write('\uFEFF');

    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    // ==========================================
    // SECTION 1: ภาพรวมต้นทุนเฉลี่ยของร้าน (Executive Summary)
    // ==========================================
    buffer.writeln('========================================================================================');
    buffer.writeln('"รายงานสรุปผลการวิเคราะห์ Menu Engineering & ต้นทุนอาหาร (Food Costing & Menu Matrix Report)"');
    buffer.writeln('"วันที่จัดทำรายงาน: $now"');
    buffer.writeln('"รอบการขาย: 30 วันล่าสุด"');
    buffer.writeln('========================================================================================');
    buffer.writeln();

    buffer.writeln('"--- 1. สรุปภาพรวมต้นทุนและผลประกอบการของร้าน (Executive Financial Summary) ---"');
    buffer.writeln('"ตัวชี้วัด (KPI)","มูลค่า","หน่วย / หมายเหตุ"');
    buffer.writeln('"ยอดขายรวมทั้งร้าน (Total Revenue)","${metrics.totalRevenue.toStringAsFixed(2)}","บาท"');
    buffer.writeln('"กำไรขั้นต้นรวม (Gross Profit)","${metrics.totalProfit.toStringAsFixed(2)}","บาท"');
    buffer.writeln('"ต้นทุนอาหารรวม (Total Food Cost)","${metrics.totalFoodCost.toStringAsFixed(2)}","บาท"');
    buffer.writeln(
      '"Food Cost % เฉลี่ยรวมทั้งร้าน","${metrics.overallFoodCostPct.toStringAsFixed(2)}%","${metrics.overallFoodCostPct <= 35 ? "อยู่ในเกณฑ์เป้าหมายมาตรฐาน (<=35%)" : "สูงกว่าเกณฑ์เป้าหมาย แนะนำปรับปรุง"}"',
    );
    buffer.writeln('"ยอดขายเฉลี่ยต่อเมนู (Average Volume)","${metrics.averageUnitsSold.toStringAsFixed(1)}","จาน/เดือน"');
    buffer.writeln(
      '"กำไรส่วนเกินเฉลี่ยต่อจาน (Average Margin)","${metrics.averageContributionMargin.toStringAsFixed(2)}","บาท/จาน"',
    );
    buffer.writeln('"จำนวนเมนูทั้งหมดในระบบ","${metrics.classifiedItems.length}","รายการ"');
    buffer.writeln('"เมนูดาวเด่น (Stars)","${metrics.stars.length}","รายการ (กำไรสูง / ขายดี)"');
    buffer.writeln('"เมนูม้างาน (Plowhorses)","${metrics.plowhorses.length}","รายการ (กำไรต่ำ / ขายดี)"');
    buffer.writeln('"เมนูปริศนา (Puzzles)","${metrics.puzzles.length}","รายการ (กำไรสูง / ขายได้น้อย)"');
    buffer.writeln('"เมนูตัดทิ้ง (Dogs)","${metrics.dogs.length}","รายการ (กำไรต่ำ / ขายได้น้อย)"');
    buffer.writeln();

    // ==========================================
    // SECTION 2: รายการเมนูที่ควรปรับสูตร/ขึ้นราคา (กลุ่ม Plowhorses)
    // ==========================================
    buffer.writeln('"--- 2. รายการเมนูที่ควรปรับสูตรหรือขึ้นราคา (กลุ่ม Plowhorses: ขายดีแต่กำไรน้อย) ---"');
    buffer.writeln(
      '"คำแนะนำเชิงกลยุทธ์: ${MenuQuadrant.plowhorse.actionStrategy}"',
    );
    buffer.writeln(
      '"ชื่อเมนู","หมวดหมู่","ราคาขาย (฿)","ต้นทุนต่อจาน (฿)","กำไรส่วนเกิน (฿)","Food Cost %","ยอดขาย (จาน)","กำไรรวม (฿)","คำแนะนำ"',
    );

    if (metrics.plowhorses.isEmpty) {
      buffer.writeln('"ไม่มีรายการเมนูในกลุ่มนี้","-","-","-","-","-","-","-","-"');
    } else {
      for (final item in metrics.plowhorses) {
        final r = item.recipe;
        final profitTotal = r.contributionMargin * r.unitsSoldMonthly;
        buffer.writeln(
          '"${_escape(r.name)}","${_escape(r.category)}",${r.sellingPrice.toStringAsFixed(2)},${r.totalCost.toStringAsFixed(2)},${r.contributionMargin.toStringAsFixed(2)},${r.foodCostPercentage.toStringAsFixed(1)}%,${r.unitsSoldMonthly},${profitTotal.toStringAsFixed(2)},"${_escape(MenuQuadrant.plowhorse.actionStrategy)}"',
        );
      }
    }
    buffer.writeln();

    // ==========================================
    // SECTION 3: รายการเมนูที่แนะนำให้ตัดออก (กลุ่ม Dogs)
    // ==========================================
    buffer.writeln('"--- 3. รายการเมนูที่แนะนำให้พิจารณาตัดออกจากเมนู (กลุ่ม Dogs: ขายไม่ออกและกำไรต่ำ) ---"');
    buffer.writeln(
      '"คำแนะนำเชิงกลยุทธ์: ${MenuQuadrant.dog.actionStrategy}"',
    );
    buffer.writeln(
      '"ชื่อเมนู","หมวดหมู่","ราคาขาย (฿)","ต้นทุนต่อจาน (฿)","กำไรส่วนเกิน (฿)","Food Cost %","ยอดขาย (จาน)","กำไรรวม (฿)","คำแนะนำ"',
    );

    if (metrics.dogs.isEmpty) {
      buffer.writeln('"ไม่มีรายการเมนูในกลุ่มนี้","-","-","-","-","-","-","-","-"');
    } else {
      for (final item in metrics.dogs) {
        final r = item.recipe;
        final profitTotal = r.contributionMargin * r.unitsSoldMonthly;
        buffer.writeln(
          '"${_escape(r.name)}","${_escape(r.category)}",${r.sellingPrice.toStringAsFixed(2)},${r.totalCost.toStringAsFixed(2)},${r.contributionMargin.toStringAsFixed(2)},${r.foodCostPercentage.toStringAsFixed(1)}%,${r.unitsSoldMonthly},${profitTotal.toStringAsFixed(2)},"${_escape(MenuQuadrant.dog.actionStrategy)}"',
        );
      }
    }
    buffer.writeln();

    // ==========================================
    // SECTION 4: ตารางต้นทุนวัตถุดิบแบบละเอียด (BOM - Bill of Materials)
    // ==========================================
    buffer.writeln('"--- 4. ตารางต้นทุนวัตถุดิบแบบละเอียดทุกจาน (BOM - Bill of Materials Breakdown) ---"');
    buffer.writeln(
      '"ชื่อเมนู","หมวดเมนู","ราคาขาย (฿)","ต้นทุนรวม (฿)","Food Cost %","วัตถุดิบที่ใช้","หมวดวัตถุดิบ","ปริมาณที่ใช้","หน่วย","ต้นทุนวัตถุดิบในจาน (฿)","สัดส่วนต้นทุน (%)"',
    );

    for (final recipe in recipes) {
      final totalCost = recipe.totalCost;
      if (recipe.items.isEmpty) {
        buffer.writeln(
          '"${_escape(recipe.name)}","${_escape(recipe.category)}",${recipe.sellingPrice.toStringAsFixed(2)},${totalCost.toStringAsFixed(2)},${recipe.foodCostPercentage.toStringAsFixed(1)}%,"ไม่มีวัตถุดิบในสูตร","-","-","-",0.00,0.0%',
        );
      } else {
        for (final item in recipe.items) {
          final sharePct = totalCost > 0 ? (item.itemCost / totalCost) * 100 : 0.0;
          buffer.writeln(
            '"${_escape(recipe.name)}","${_escape(recipe.category)}",${recipe.sellingPrice.toStringAsFixed(2)},${totalCost.toStringAsFixed(2)},${recipe.foodCostPercentage.toStringAsFixed(1)}%,"${_escape(item.ingredient.name)}","${_escape(item.ingredient.category)}",${item.quantityUsed},"${_escape(item.unitUsed)}",${item.itemCost.toStringAsFixed(2)},${sharePct.toStringAsFixed(1)}%',
          );
        }
      }
    }

    return buffer.toString();
  }

  /// Generates a professional multi-page PDF document.
  static Future<Uint8List> generatePdfBytes({
    required DashboardMetrics metrics,
    required List<Recipe> recipes,
  }) async {
    final pdf = pw.Document();

    // Load Thai-compatible font via PdfGoogleFonts
    pw.Font? ttfFont;
    pw.Font? ttfBold;
    try {
      ttfFont = await PdfGoogleFonts.sarabunRegular();
      ttfBold = await PdfGoogleFonts.sarabunBold();
    } catch (_) {
      // Fallback for offline or test environments
      ttfFont = pw.Font.helvetica();
      ttfBold = pw.Font.helveticaBold();
    }

    final theme = pw.ThemeData.withFont(
      base: ttfFont,
      bold: ttfBold,
    );

    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    // Page 1: Executive Summary & Plowhorses / Dogs Action List
    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader(dateStr),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          // Section 1: Executive Summary
          pw.Text(
            '1. สรุปภาพรวมต้นทุนและผลประกอบการ (Executive Financial Summary)',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            headers: ['ตัวชี้วัดทางธุรกิจ (Key Performance Indicators)', 'มูลค่าตัวเลข', 'เกณฑ์ประเมิน / หมายเหตุ'],
            data: [
              ['ยอดขายรวมทั้งร้าน (Total Revenue)', Formatters.currency(metrics.totalRevenue), 'รอบการขาย 30 วันล่าสุด'],
              ['กำไรขั้นต้นรวม (Gross Profit)', Formatters.currency(metrics.totalProfit), 'คิดเป็นกำไรสุทธิทางตรง'],
              ['ต้นทุนอาหารรวม (Total Food Cost)', Formatters.currency(metrics.totalFoodCost), 'ค่าวัตถุดิบทั้งหมดที่ใช้'],
              [
                'Food Cost % เฉลี่ยรวม',
                Formatters.percentage(metrics.overallFoodCostPct),
                metrics.overallFoodCostPct <= AppConstants.targetFoodCostMax
                    ? 'อยู่ในเกณฑ์เป้าหมายมาตรฐาน'
                    : 'สูงกว่าเกณฑ์เป้าหมาย (35%)',
              ],
              ['ยอดขายเฉลี่ยต่อเมนู (Average Volume)', '${metrics.averageUnitsSold.toStringAsFixed(0)} จาน', 'จุดตัดแกน X'],
              [
                'กำไรส่วนเกินเฉลี่ยต่อจาน (Average Margin)',
                Formatters.currency(metrics.averageContributionMargin),
                'จุดตัดแกน Y',
              ],
              [
                'การกระจายตัว 4 กลุ่ม (Matrix)',
                'Stars: ${metrics.stars.length} | Plowhorses: ${metrics.plowhorses.length}',
                'Puzzles: ${metrics.puzzles.length} | Dogs: ${metrics.dogs.length}',
              ],
            ],
          ),
          pw.SizedBox(height: 20),

          // Section 2: Plowhorses
          pw.Text(
            '2. รายการเมนูที่ควรปรับสูตรหรือขึ้นราคา (กลุ่ม Plowhorses: ขายดีแต่กำไรน้อย)',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
          ),
          pw.Text(
            'กลยุทธ์: ${MenuQuadrant.plowhorse.actionStrategy}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo700),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            headers: ['ชื่อเมนู', 'ราคาขาย', 'ต้นทุน', 'กำไร/จาน', 'Food Cost %', 'ยอดขาย', 'กำไรรวม'],
            data: metrics.plowhorses.isEmpty
                ? [
                    ['ไม่มีเมนูในหมวดนี้', '-', '-', '-', '-', '-', '-'],
                  ]
                : metrics.plowhorses.map((item) {
                    final r = item.recipe;
                    final totalP = r.contributionMargin * r.unitsSoldMonthly;
                    return [
                      r.name,
                      Formatters.currency(r.sellingPrice),
                      Formatters.currency(r.totalCost),
                      Formatters.currency(r.contributionMargin),
                      Formatters.percentage(r.foodCostPercentage),
                      '${r.unitsSoldMonthly} จาน',
                      Formatters.currency(totalP),
                    ];
                  }).toList(),
          ),
          pw.SizedBox(height: 20),

          // Section 3: Dogs
          pw.Text(
            '3. รายการเมนูที่แนะนำให้พิจารณาตัดออก (กลุ่ม Dogs: ขายไม่ออกและกำไรต่ำ)',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
          ),
          pw.Text(
            'กลยุทธ์: ${MenuQuadrant.dog.actionStrategy}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            headers: ['ชื่อเมนู', 'ราคาขาย', 'ต้นทุน', 'กำไร/จาน', 'Food Cost %', 'ยอดขาย', 'กำไรรวม'],
            data: metrics.dogs.isEmpty
                ? [
                    ['ไม่มีเมนูในหมวดนี้', '-', '-', '-', '-', '-', '-'],
                  ]
                : metrics.dogs.map((item) {
                    final r = item.recipe;
                    final totalP = r.contributionMargin * r.unitsSoldMonthly;
                    return [
                      r.name,
                      Formatters.currency(r.sellingPrice),
                      Formatters.currency(r.totalCost),
                      Formatters.currency(r.contributionMargin),
                      Formatters.percentage(r.foodCostPercentage),
                      '${r.unitsSoldMonthly} จาน',
                      Formatters.currency(totalP),
                    ];
                  }).toList(),
          ),
          pw.SizedBox(height: 20),

          // Section 4: Bill of Materials (BOM)
          pw.Text(
            '4. ตารางแจกแจงต้นทุนวัตถุดิบอย่างละเอียด (BOM - Bill of Materials)',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
          ),
          pw.SizedBox(height: 6),
          ...recipes.map((r) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${r.name} (${r.category})',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'ขาย: ${Formatters.currency(r.sellingPrice)} | ทุน: ${Formatters.currency(r.totalCost)} (FC: ${Formatters.percentage(r.foodCostPercentage)})',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue800),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.TableHelper.fromTextArray(
                    border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    cellStyle: const pw.TextStyle(fontSize: 8),
                    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    headers: ['วัตถุดิบ', 'ปริมาณที่ใช้', 'ต้นทุนย่อย', 'สัดส่วน %'],
                    data: r.items.map((it) {
                      final share = r.totalCost > 0 ? (it.itemCost / r.totalCost) * 100 : 0.0;
                      return [
                        it.ingredient.name,
                        '${it.quantityUsed} ${it.unitUsed}',
                        Formatters.currency(it.itemCost),
                        '${share.toStringAsFixed(1)}%',
                      ];
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );

    return pdf.save();
  }

  /// Triggers a download of the CSV report directly in the browser.
  static void exportCsv({
    required DashboardMetrics metrics,
    required List<Recipe> recipes,
    String? filename,
  }) {
    final csvContent = generateCsvContent(metrics: metrics, recipes: recipes);
    final dateTag = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final name = filename ?? 'menu_engineering_report_$dateTag.csv';

    downloadFileFromString(csvContent, name, 'text/csv;charset=utf-8');
  }

  /// Triggers a download of the PDF report directly in the browser.
  static Future<void> exportPdf({
    required DashboardMetrics metrics,
    required List<Recipe> recipes,
    String? filename,
  }) async {
    final pdfBytes = await generatePdfBytes(metrics: metrics, recipes: recipes);
    final dateTag = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final name = filename ?? 'menu_engineering_report_$dateTag.pdf';

    downloadFileFromBytes(pdfBytes, name, 'application/pdf');
  }

  static pw.Widget _buildPdfHeader(String dateStr) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      margin: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue800, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Menu Engineering & Costing Report',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
              ),
              pw.Text(
                'รายงานสรุปผลการวิเคราะห์เมนูและควบคุมต้นทุนอาหาร (Kasavana & Smith)',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('พิมพ์เมื่อ: $dateStr', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              pw.Text('สถานะ: สมบูรณ์', style: const pw.TextStyle(fontSize: 9, color: PdfColors.green700)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'หน้า ${context.pageNumber} จาก ${context.pagesCount}',
        style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
      ),
    );
  }

  static String _escape(String field) {
    return field.replaceAll('"', '""');
  }
}
