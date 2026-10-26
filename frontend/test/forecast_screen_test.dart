import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/features/forecast/providers/forecast_provider.dart';
import 'package:my_first_app/features/forecast/screens/forecast_screen.dart';

void main() {
  group('AI Demand & Waste Forecast Screen Widget Tests', () {
    Widget createTestApp(ProviderContainer container) {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ForecastScreen(),
        ),
      );
    }

    testWidgets('ForecastScreen renders header, KPI metrics, and forecast cards', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          forecastProvider.overrideWith(() => ForecastNotifier(autoFetch: false)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(container));
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.textContaining('พยากรณ์วัตถุดิบ & ป้องกันของเสีย'), findsOneWidget);
      expect(find.textContaining('คำนวณใหม่'), findsOneWidget);

      // Verify KPI Metric Cards
      expect(find.text('มูลค่าเสี่ยงเน่าเสียทิ้ง'), findsOneWidget);
      expect(find.text('วัตถุดิบวิกฤตเสี่ยงหมดอายุ'), findsOneWidget);
      expect(find.text('งบประมาณสั่งซื้อแนะนำ 7 วัน'), findsOneWidget);

      // Verify Forecast Items (from fallback/mock data)
      expect(find.textContaining('เนื้อหมูสามชั้นสไลซ์'), findsOneWidget);
      expect(find.textContaining('วิกฤต'), findsWidgets);
      expect(find.textContaining('สต็อกปัจจุบัน'), findsWidgets);
    });

    testWidgets('Filtering by Critical risk shows only critical items', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          forecastProvider.overrideWith(() => ForecastNotifier(autoFetch: false)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(container));
      await tester.pumpAndSettle();

      // Tap on 'วิกฤต' filter chip
      final criticalChip = find.textContaining('วิกฤต');
      expect(criticalChip, findsWidgets);
      await tester.tap(criticalChip.first);
      await tester.pumpAndSettle();

      // Critical pork belly should be present
      expect(find.textContaining('เนื้อหมูสามชั้นสไลซ์'), findsOneWidget);
    });
  });
}
