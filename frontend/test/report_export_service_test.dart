import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:my_first_app/features/ingredients/models/ingredient.dart';
import 'package:my_first_app/features/recipes/models/recipe.dart';
import 'package:my_first_app/features/recipes/models/recipe_item.dart';
import 'package:my_first_app/features/reports/services/report_export_service.dart';
import 'package:my_first_app/features/reports/widgets/export_report_dialog.dart';

void main() {
  final sampleIngredient1 = Ingredient(
    id: 'ing_1',
    name: 'ผงมัทฉะเกรดพิธีการ',
    category: 'drink',
    purchaseCost: 950.0,
    purchaseQuantity: 100.0,
    purchaseUnit: 'g',
    costPerBaseUnit: 9.5,
  );

  final sampleIngredient2 = Ingredient(
    id: 'ing_2',
    name: 'นมสดพาสเจอร์ไรส์',
    category: 'dairy',
    purchaseCost: 98.0,
    purchaseQuantity: 2000.0,
    purchaseUnit: 'l',
    costPerBaseUnit: 0.049,
  );

  final sampleRecipes = [
    Recipe(
      id: 'rec_1',
      name: 'Iced Ceremonial Matcha Latte',
      category: 'drink',
      sellingPrice: 145.0,
      unitsSoldMonthly: 430,
      items: [
        RecipeItem(ingredient: sampleIngredient1, quantityUsed: 4.0, unitUsed: 'g'),
        RecipeItem(ingredient: sampleIngredient2, quantityUsed: 150.0, unitUsed: 'ml'),
      ],
    ),
    Recipe(
      id: 'rec_2',
      name: 'ข้าวกะเพราหมูสับไข่ดาวกรอบ',
      category: 'food',
      sellingPrice: 89.0,
      unitsSoldMonthly: 510,
      items: [
        RecipeItem(ingredient: sampleIngredient1, quantityUsed: 1.0, unitUsed: 'g'),
      ],
    ),
    Recipe(
      id: 'rec_3',
      name: 'สปาเก็ตตี้เนยกระเทียมไข่ดาว',
      category: 'food',
      sellingPrice: 95.0,
      unitsSoldMonthly: 45,
      items: [
        RecipeItem(ingredient: sampleIngredient2, quantityUsed: 50.0, unitUsed: 'ml'),
      ],
    ),
  ];

  test('ReportExportService generates CSV with UTF-8 BOM, Executive Summary, Plowhorses, Dogs, and BOM', () {
    final metrics = DashboardMetrics.fromRecipes(sampleRecipes);
    final csv = ReportExportService.generateCsvContent(metrics: metrics, recipes: sampleRecipes);

    // 1. Must start with UTF-8 BOM
    expect(csv.startsWith('\uFEFF'), isTrue);

    // 2. Contains Executive Summary
    expect(csv.contains('ยอดขายรวมทั้งร้าน (Total Revenue)'), isTrue);
    expect(csv.contains('กำไรขั้นต้นรวม (Gross Profit)'), isTrue);
    expect(csv.contains('Food Cost % เฉลี่ยรวมทั้งร้าน'), isTrue);

    // 3. Contains Section 2: Plowhorses
    expect(csv.contains('กลุ่ม Plowhorses: ขายดีแต่กำไรน้อย'), isTrue);
    expect(csv.contains('ขายดีแต่กำไรน้อย แนะนำลดสัดส่วนวัตถุดิบบางตัวหรือขึ้นราคา'), isTrue);

    // 4. Contains Section 3: Dogs
    expect(csv.contains('กลุ่ม Dogs: ขายไม่ออกและกำไรต่ำ'), isTrue);
    expect(csv.contains('ขายไม่ออกและกำไรต่ำ แนะนำพิจารณาตัดออกจากเมนู'), isTrue);

    // 5. Contains Section 4: Bill of Materials (BOM)
    expect(csv.contains('BOM - Bill of Materials Breakdown'), isTrue);
    expect(csv.contains('Iced Ceremonial Matcha Latte'), isTrue);
    expect(csv.contains('ผงมัทฉะเกรดพิธีการ'), isTrue);
  });

  test('ReportExportService generates valid PDF byte stream with %PDF header', () async {
    final metrics = DashboardMetrics.fromRecipes(sampleRecipes);
    final bytes = await ReportExportService.generatePdfBytes(metrics: metrics, recipes: sampleRecipes);

    expect(bytes.isNotEmpty, isTrue);
    // PDF magic bytes: %PDF (0x25, 0x50, 0x44, 0x46)
    final header = utf8.decode(bytes.sublist(0, 4));
    expect(header, equals('%PDF'));
  });

  testWidgets('ExportReportDialog renders and handles CSV export click', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final metrics = DashboardMetrics.fromRecipes(sampleRecipes);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExportReportDialog(
            metrics: metrics,
            recipes: sampleRecipes,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('ดาวน์โหลดรายงานการวิเคราะห์'), findsOneWidget);
    expect(find.text('Menu Engineering & Costing Report'), findsOneWidget);
    expect(find.text('Excel / CSV (.csv)'), findsOneWidget);
    expect(find.text('PDF Report (.pdf)'), findsOneWidget);
    expect(find.textContaining('ตารางต้นทุนวัตถุดิบละเอียด (Bill of Materials - BOM)'), findsOneWidget);

    // Tap CSV download button
    await tester.tap(find.text('Excel / CSV (.csv)'));
    await tester.pumpAndSettle();

    // Verify success banner appears
    expect(find.text('ดาวน์โหลดไฟล์ Excel/CSV เรียบร้อยแล้ว!'), findsOneWidget);
  });
}
