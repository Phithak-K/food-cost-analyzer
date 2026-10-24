import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/core/theme/app_theme.dart';
import 'package:my_first_app/features/recipes/screens/recipe_builder_screen.dart';

void main() {
  testWidgets('RecipeBuilderScreen renders and adds dynamic ingredient row', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RecipeBuilderScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title and live costing card exist
    expect(find.text('สร้างสูตรอาหาร & คำนวณต้นทุน (Recipe Builder)'), findsOneWidget);
    expect(find.text('คำนวณต้นทุนสด (Live Costing)'), findsOneWidget);
    expect(find.text('Food Cost Percentage'), findsOneWidget);

    // Tap "เพิ่มวัตถุดิบ" to add dynamic row
    final addButton = find.widgetWithText(ElevatedButton, 'เพิ่มวัตถุดิบ');
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Verify that now we have 2 ingredient rows (badges '1' and '2')
    expect(find.text('2'), findsOneWidget);
  });
}
