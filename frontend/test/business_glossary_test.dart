import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/features/dashboard/widgets/business_glossary_dialog.dart';

void main() {
  group('BusinessGlossary Model & Guide Generator Tests', () {
    test('BusinessGlossary contains all essential restaurant terms', () {
      final terms = BusinessGlossary.terms;
      expect(terms.length, greaterThanOrEqualTo(10));

      final termIds = terms.map((t) => t.id).toList();
      expect(termIds, contains('food_cost_pct'));
      expect(termIds, contains('contribution_margin'));
      expect(termIds, contains('matrix_overview'));
      expect(termIds, contains('stars'));
      expect(termIds, contains('plowhorses'));
      expect(termIds, contains('puzzles'));
      expect(termIds, contains('dogs'));
      expect(termIds, contains('yield_pct'));
      expect(termIds, contains('cost_per_base_unit'));
      expect(termIds, contains('what_if_simulation'));
      expect(termIds, contains('break_even_analysis'));
    });

    test('generateMarkdownGuide generates valid markdown with full structure', () {
      final md = BusinessGlossary.generateMarkdownGuide();
      expect(md, isNotEmpty);
      expect(md, contains('# คู่มือคำศัพท์และกลยุทธ์การบริหารต้นทุนร้านอาหาร'));
      expect(md, contains('Food Cost Percentage'));
      expect(md, contains('Contribution Margin'));
      expect(md, contains('Kasavana & Smith'));
      expect(md, contains('Stars'));
      expect(md, contains('Plowhorses'));
      expect(md, contains('Puzzles'));
      expect(md, contains('Dogs'));
      expect(md, contains('Yield Percentage'));
      expect(md, contains('ตารางสรุปเกณฑ์มาตรฐานที่ร้านอาหารควรจำ'));
    });
  });

  group('BusinessGlossaryDialog Widget Tests', () {
    testWidgets('renders dialog with search bar, categories, and terms', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BusinessGlossaryDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & subtitle
      expect(find.textContaining('คู่มือคำศัพท์ธุรกิจ'), findsOneWidget);
      expect(find.textContaining('Business Glossary'), findsOneWidget);

      // Verify search field exists
      expect(find.byType(TextField), findsOneWidget);

      // Verify download button exists
      expect(find.textContaining('ดาวน์โหลดคู่มือ'), findsWidgets);

      // Verify categories exist
      expect(find.widgetWithText(FilterChip, 'ทั้งหมด'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'ต้นทุน & กำไร'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'เมทริกซ์ 4 กลุ่ม'), findsOneWidget);

      // Search filtering
      await tester.enterText(find.byType(TextField), 'ม้าศึก');
      await tester.pumpAndSettle();

      expect(find.textContaining('Plowhorses (ม้าศึก'), findsOneWidget);
      expect(find.textContaining('Stars (ดาวเด่น'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pumpAndSettle();

      expect(find.textContaining('Food Cost Percentage'), findsOneWidget);

      // Tap download guide button (invokes downloadFileFromString without crash)
      final downloadButtons = find.widgetWithText(ElevatedButton, 'ดาวน์โหลดคู่มือ (.md)');
      expect(downloadButtons, findsOneWidget);
      await tester.tap(downloadButtons);
      await tester.pumpAndSettle();
    });
  });
}
