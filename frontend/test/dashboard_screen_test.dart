import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/features/dashboard/chart_widgets/menu_matrix_chart.dart';
import 'package:my_first_app/features/dashboard/chart_widgets/recipe_cost_pie_chart.dart';
import 'package:my_first_app/features/dashboard/screens/dashboard_screen.dart';

void main() {
  testWidgets('DashboardScreen renders Scatter Plot, Pie Chart, and Actionable Recommendations', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify main components rendered
    expect(find.text('แดชบอร์ดวิเคราะห์เมนู & ต้นทุนอาหาร'), findsOneWidget);
    expect(find.byType(MenuMatrixChart), findsOneWidget);
    expect(find.byType(RecipeCostPieChart), findsOneWidget);

    // Verify Actionable Recommendations
    expect(find.textContaining('Actionable Business Recommendations'), findsOneWidget);
    expect(find.textContaining('ขายดีแต่กำไรน้อย แนะนำลดสัดส่วนวัตถุดิบบางตัวหรือขึ้นราคา'), findsWidgets);
    expect(find.textContaining('ขายไม่ออกและกำไรต่ำ แนะนำพิจารณาตัดออกจากเมนู'), findsWidgets);
  });
}
