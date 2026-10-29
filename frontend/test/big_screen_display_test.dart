import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/core/services/kds_websocket_service.dart';
import 'package:my_first_app/features/display/big_screen_display_screen.dart';
import 'package:my_first_app/features/pos/models/kitchen_ticket.dart';
import 'package:my_first_app/features/pos/providers/kds_provider.dart';
import 'package:my_first_app/features/pos/providers/orders_provider.dart';
import 'package:my_first_app/features/recipes/models/recipe.dart';

void main() {
  group('Table & Order Type Provider Unit Tests', () {
    test('OrderState has correct defaults and copyWith for orderType and tableNumber', () {
      const state = OrderState();
      expect(state.orderType, equals('ทานที่ร้าน (Dine-In)'));
      expect(state.tableNumber, equals('โต๊ะ 01'));

      final updated = state.copyWith(
        orderType: 'กลับบ้าน (Takeaway)',
        tableNumber: 'โต๊ะ 05',
      );
      expect(updated.orderType, equals('กลับบ้าน (Takeaway)'));
      expect(updated.tableNumber, equals('โต๊ะ 05'));
    });

    test('KitchenTicket getters return expected booleans', () {
      final dineInTicket = KitchenTicket(
        id: 't_1',
        orderNumber: 'ORD-101',
        tableNumber: 'โต๊ะ 03',
        orderType: 'ทานที่ร้าน (Dine-In)',
        createdAt: DateTime.now(),
        items: const [],
        status: KitchenOrderStatus.cooking,
      );

      expect(dineInTicket.isTakeaway, isFalse);
      expect(dineInTicket.isCooking, isTrue);
      expect(dineInTicket.isReady, isFalse);
      expect(dineInTicket.isServed, isFalse);

      final takeawayTicket = dineInTicket.copyWith(
        orderType: 'กลับบ้าน (Takeaway)',
        status: KitchenOrderStatus.ready,
      );

      expect(takeawayTicket.isTakeaway, isTrue);
      expect(takeawayTicket.isCooking, isFalse);
      expect(takeawayTicket.isReady, isTrue);
      expect(takeawayTicket.isServed, isFalse);

      final servedTicket = takeawayTicket.copyWith(status: KitchenOrderStatus.served);
      expect(servedTicket.isServed, isTrue);
    });

    test('markAsServed updates status to KitchenOrderStatus.served', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final kdsNotifier = container.read(kdsProvider.notifier);
      final ticket = KitchenTicket(
        id: 'ticket_test_served',
        orderNumber: 'ORD-999',
        tableNumber: 'โต๊ะ 04',
        createdAt: DateTime.now(),
        items: const [],
        status: KitchenOrderStatus.ready,
      );

      kdsNotifier.addTicket(ticket);
      expect(container.read(kdsProvider).first.status, equals(KitchenOrderStatus.ready));

      kdsNotifier.markAsServed('ticket_test_served');
      expect(container.read(kdsProvider).first.status, equals(KitchenOrderStatus.served));
    });
  });

  group('BigScreenDisplayScreen Widget Tests', () {
    final sampleRecipe = Recipe(
      id: 'rec_pad_thai',
      name: 'ผัดไทยกุ้งสด',
      category: 'Main Course',
      sellingPrice: 120.0,
      items: const [],
    );

    final cookingTicket = KitchenTicket(
      id: 't_cook',
      orderNumber: 'ORD-001',
      tableNumber: 'โต๊ะ 02',
      orderType: 'ทานที่ร้าน (Dine-In)',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      items: [KitchenOrderItem(recipe: sampleRecipe, quantity: 2)],
      status: KitchenOrderStatus.cooking,
    );

    final readyTicket = KitchenTicket(
      id: 't_ready',
      orderNumber: 'ORD-002',
      tableNumber: 'โต๊ะ 07',
      orderType: 'ทานที่ร้าน (Dine-In)',
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      items: [KitchenOrderItem(recipe: sampleRecipe, quantity: 1)],
      status: KitchenOrderStatus.ready,
    );

    Widget createTestApp(ProviderContainer container) {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: BigScreenDisplayScreen(),
        ),
      );
    }

    testWidgets('renders TV header, customer queue board with preparing and ready orders',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          kdsProvider.overrideWith(() => _CustomKds([cookingTicket, readyTicket])),
          kdsWebSocketProvider.overrideWith(() => KdsWebSocketNotifier(autoConnect: false)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(container));
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('MenuEng TV Live Display'), findsOneWidget);
      expect(find.textContaining('เรียกคิวลูกค้า'), findsOneWidget);
      expect(find.textContaining('จุดเสิร์ฟพนักงาน'), findsOneWidget);
      expect(find.textContaining('จอคู่ไฮบริด'), findsOneWidget);

      // Verify Mode 0 Columns
      expect(find.textContaining('กำลังปรุงอาหาร'), findsOneWidget);
      expect(find.textContaining('เชิญรับอาหาร'), findsOneWidget);

      // Verify tickets shown
      expect(find.text('#ORD-001'), findsOneWidget);
      expect(find.text('#ORD-002'), findsOneWidget);
      expect(find.text('โต๊ะ 02'), findsOneWidget);
      expect(find.text('โต๊ะ 07'), findsOneWidget);
    });

    testWidgets('switching to Server Runner Board displays dispatch cards and allows marking as served',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          kdsProvider.overrideWith(() => _CustomKds([cookingTicket, readyTicket])),
          kdsWebSocketProvider.overrideWith(() => KdsWebSocketNotifier(autoConnect: false)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(container));
      await tester.pumpAndSettle();

      // Tap Mode 1 Tab (จุดเสิร์ฟพนักงาน)
      await tester.tap(find.textContaining('จุดเสิร์ฟพนักงาน'));
      await tester.pumpAndSettle();

      // Verify Food Runner Dispatch Station header is shown
      expect(find.textContaining('จุดรับส่งอาหารพนักงาน'), findsOneWidget);
      expect(find.text('โต๊ะ 07'), findsOneWidget);
      expect(find.text('ผัดไทยกุ้งสด'), findsOneWidget);
      expect(find.text('1x'), findsOneWidget);

      // Find and tap '✔ เสิร์ฟแล้ว (Mark as Served)'
      final servedButton = find.text('✔ เสิร์ฟแล้ว (Mark as Served)');
      expect(servedButton, findsOneWidget);
      await tester.tap(servedButton);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4)); // drain toast

      // Verify ticket is now served and empty state or footer appears
      expect(find.text('เสิร์ฟครบทุกโต๊ะแล้ว!'), findsOneWidget);
      expect(find.textContaining('เสิร์ฟแล้วล่าสุด:'), findsOneWidget);
    });

    testWidgets('switching to Hybrid Split view shows both Customer Queue and Server Runner panels',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          kdsProvider.overrideWith(() => _CustomKds([cookingTicket, readyTicket])),
          kdsWebSocketProvider.overrideWith(() => KdsWebSocketNotifier(autoConnect: false)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(container));
      await tester.pumpAndSettle();

      // Tap Mode 2 Tab (จอคู่ไฮบริด)
      await tester.tap(find.textContaining('จอคู่ไฮบริด'));
      await tester.pumpAndSettle();

      // Verify both sides are present
      expect(find.textContaining('กำลังปรุงอาหาร'), findsOneWidget);
      expect(find.textContaining('จุดรับส่งอาหารพนักงาน'), findsOneWidget);
    });

    testWidgets('renders cleanly without overflow at 918px snapped half-screen with takeaway badge',
        (tester) async {
      tester.view.physicalSize = const Size(918, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final takeawayTicket = KitchenTicket(
        id: 't_takeaway',
        orderNumber: 'ORD-7803',
        tableNumber: 'รับกลับบ้าน (Takeaway)',
        orderType: 'กลับบ้าน (Takeaway)',
        createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
        items: [KitchenOrderItem(recipe: sampleRecipe, quantity: 1)],
        status: KitchenOrderStatus.cooking,
      );

      final container = ProviderContainer(
        overrides: [
          kdsProvider.overrideWith(() => _CustomKds([takeawayTicket])),
          kdsWebSocketProvider.overrideWith(() => KdsWebSocketNotifier(autoConnect: false)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(container));
      await tester.pumpAndSettle();

      // Verify no RenderFlex overflow occurs on 918px
      expect(tester.takeException(), isNull);
      expect(find.text('#ORD-7803'), findsOneWidget);
      expect(find.textContaining('กลับบ้าน (Takeaway)'), findsOneWidget);
    });
  });
}

class _CustomKds extends KdsNotifier {
  final List<KitchenTicket> initial;
  _CustomKds(this.initial);

  @override
  List<KitchenTicket> build() => initial;
}

