import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/kds_websocket_service.dart';
import '../../core/utils/audio_chime.dart';
import '../../core/widgets/capsule_toast.dart';
import '../pos/models/kitchen_ticket.dart';
import '../pos/providers/kds_provider.dart';

class BigScreenDisplayScreen extends ConsumerStatefulWidget {
  const BigScreenDisplayScreen({super.key});

  @override
  ConsumerState<BigScreenDisplayScreen> createState() => _BigScreenDisplayScreenState();
}

class _BigScreenDisplayScreenState extends ConsumerState<BigScreenDisplayScreen> {
  // 0 = Customer Queue Board, 1 = Server Runner Board, 2 = Hybrid Split Board
  int _viewMode = 0;
  bool _soundEnabled = true;
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();
  int _prevReadyCount = 0;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _checkAndPlayChime(int currentReadyCount) {
    if (_soundEnabled && currentReadyCount > _prevReadyCount) {
      AudioChime.play();
    }
    _prevReadyCount = currentReadyCount;
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(kdsProvider);
    final cookingTickets = tickets.where((t) => t.isCooking).toList();
    final readyTickets = tickets.where((t) => t.isReady).toList();
    final servedTickets = tickets.where((t) => t.isServed).toList();

    // Trigger chime on new ready tickets
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPlayChime(readyTickets.length);
    });

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTvHeader(context, cookingTickets.length, readyTickets.length),

            // Main Display Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildBody(cookingTickets, readyTickets, servedTickets),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    List<KitchenTicket> cookingTickets,
    List<KitchenTicket> readyTickets,
    List<KitchenTicket> servedTickets,
  ) {
    switch (_viewMode) {
      case 1:
        return _buildServerRunnerView(readyTickets, servedTickets);
      case 2:
        return _buildHybridSplitView(cookingTickets, readyTickets, servedTickets);
      case 0:
      default:
        return _buildCustomerQueueView(cookingTickets, readyTickets);
    }
  }

  // ==========================================
  // TOP TV HEADER
  // ==========================================
  Widget _buildTvHeader(BuildContext context, int cookingCount, int readyCount) {
    final timeFormatted =
        '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}:${_currentTime.second.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1424),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1.5)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          final brandAndClock = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tv_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'MenuEng TV Live Display',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 4),
                      Text(
                        timeFormatted,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF38BDF8),
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );

          final modeTabs = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF070B14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildModeTab(
                    0,
                    '🔔 เรียกคิวลูกค้า ($readyCount)',
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 4),
                  _buildModeTab(
                    1,
                    '🍽️ จุดเสิร์ฟพนักงาน ($readyCount)',
                    const Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 4),
                  _buildModeTab(
                    2,
                    '⚡ จอคู่ไฮบริด',
                    const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ),
          );

          final controls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live Sync Pill
              Builder(
                builder: (context) {
                  final wsState = ref.watch(kdsWebSocketProvider);
                  final isConnected = wsState.status == WebSocketConnectionStatus.connected;
                  final isConnecting = wsState.status == WebSocketConnectionStatus.connecting;
                  final color = isConnected
                      ? const Color(0xFF10B981)
                      : (isConnecting ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isConnected ? 'LIVE' : (isConnecting ? 'CONNECTING' : 'OFFLINE'),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),

              // Sound toggle
              IconButton(
                tooltip: _soundEnabled ? 'ปิดเสียงแจ้งเตือน' : 'เปิดเสียงแจ้งเตือน',
                icon: Icon(
                  _soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: _soundEnabled ? const Color(0xFF10B981) : Colors.grey,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _soundEnabled = !_soundEnabled);
                  CapsuleToast.showInfo(
                    context,
                    _soundEnabled ? '🔔 เปิดเสียงเตือนกระดิ่งแล้ว' : '🔕 ปิดเสียงเตือนแล้ว',
                  );
                },
              ),

              // Bell Chime Test
              IconButton(
                tooltip: 'ทดสอบเสียงกระดิ่ง (Ding!)',
                icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFFF59E0B), size: 20),
                onPressed: () {
                  AudioChime.play();
                  CapsuleToast.showSuccess(context, '🔔 ทดสอบเสียงกระดิ่ง (Ding!)');
                },
              ),

              const SizedBox(width: 6),

              // Exit TV Mode Button
              ElevatedButton.icon(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/pos');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.fullscreen_exit_rounded, size: 18),
                label: const Text('ปิดจอใหญ่', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          );

          if (isWide) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                brandAndClock,
                modeTabs,
                controls,
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    brandAndClock,
                    controls,
                  ],
                ),
                const SizedBox(height: 10),
                Center(child: modeTabs),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildModeTab(int mode, String label, Color accentColor) {
    final isSelected = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MODE 0: CUSTOMER QUEUE BOARD
  // ==========================================
  Widget _buildCustomerQueueView(
    List<KitchenTicket> cookingTickets,
    List<KitchenTicket> readyTickets,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;

        if (isNarrow) {
          return Column(
            children: [
              Expanded(
                flex: 40,
                child: _buildQueueColumn(
                  title: '⏳ กำลังปรุงอาหาร (PREPARING)',
                  count: cookingTickets.length,
                  accentColor: const Color(0xFFF59E0B),
                  tickets: cookingTickets,
                  isReadyState: false,
                ),
              ),
              const Divider(color: Color(0xFF1E293B), height: 1),
              Expanded(
                flex: 60,
                child: _buildQueueColumn(
                  title: '🔔 เชิญรับอาหาร (READY FOR PICKUP)',
                  count: readyTickets.length,
                  accentColor: const Color(0xFF10B981),
                  tickets: readyTickets,
                  isReadyState: true,
                ),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Column: Preparing
            Expanded(
              flex: 45,
              child: _buildQueueColumn(
                title: '⏳ กำลังปรุงอาหาร (PREPARING)',
                count: cookingTickets.length,
                accentColor: const Color(0xFFF59E0B),
                tickets: cookingTickets,
                isReadyState: false,
              ),
            ),

            // Divider Line
            Container(width: 2, color: const Color(0xFF1E293B)),

            // Right Column: Ready
            Expanded(
              flex: 55,
              child: _buildQueueColumn(
                title: '🔔 เชิญรับอาหาร (READY FOR PICKUP)',
                count: readyTickets.length,
                accentColor: const Color(0xFF10B981),
                tickets: readyTickets,
                isReadyState: true,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQueueColumn({
    required String title,
    required int count,
    required Color accentColor,
    required List<KitchenTicket> tickets,
    required bool isReadyState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Column Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            border: Border(bottom: BorderSide(color: accentColor.withValues(alpha: 0.3), width: 2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF070B14),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Cards Grid
        Expanded(
          child: tickets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isReadyState ? Icons.check_circle_outline_rounded : Icons.soup_kitchen_outlined,
                        size: 56,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isReadyState ? 'ยังไม่มีอาหารที่พร้อมรับ' : 'ไม่มีรายการกำลังปรุง',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isReadyState ? 2 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: isReadyState ? 140 : 110,
                  ),
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    return _buildCustomerQueueCard(ticket, isReadyState, accentColor);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCustomerQueueCard(KitchenTicket ticket, bool isReady, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: isReady ? 0.7 : 0.35),
          width: isReady ? 2.5 : 1.5,
        ),
        boxShadow: isReady
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Order Queue Number (Giant Font for Ready tickets)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '#${ticket.orderNumber}',
              style: TextStyle(
                fontSize: isReady ? 38 : 26,
                fontWeight: FontWeight.w900,
                color: isReady ? const Color(0xFF34D399) : Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Table / Order Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ticket.isTakeaway
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
                  : const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ticket.isTakeaway
                    ? const Color(0xFF38BDF8).withValues(alpha: 0.4)
                    : const Color(0xFF10B981).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ticket.isTakeaway ? '🛍️' : '🍽️', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  ticket.isTakeaway ? 'กลับบ้าน (Takeaway)' : ticket.tableNumber,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: ticket.isTakeaway ? const Color(0xFF38BDF8) : const Color(0xFF34D399),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODE 1: SERVER / FOOD RUNNER DISPATCH BOARD
  // ==========================================
  Widget _buildServerRunnerView(
    List<KitchenTicket> readyTickets,
    List<KitchenTicket> servedTickets,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Runner Header Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
            border: const Border(bottom: BorderSide(color: Color(0xFF0284C7), width: 2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Text('🍽️', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'จุดรับส่งอาหารพนักงาน (Food Runner Dispatch)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF38BDF8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'รอเสิร์ฟ: ${readyTickets.length} ออเดอร์',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Active Ready Orders List
        Expanded(
          child: readyTickets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('✨', style: TextStyle(fontSize: 38)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'เสิร์ฟครบทุกโต๊ะแล้ว!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'ไม่มีอาหารที่ค้างเสิร์ฟในช่องวางอาหารหน้าร้าน',
                        style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = 3;
                    if (constraints.maxWidth < 900) {
                      crossAxisCount = 1;
                    } else if (constraints.maxWidth < 1350) {
                      crossAxisCount = 2;
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 310,
                      ),
                      itemCount: readyTickets.length,
                      itemBuilder: (context, index) {
                        final ticket = readyTickets[index];
                        return _buildServerDispatchCard(context, ticket);
                      },
                    );
                  },
                ),
        ),

        // Recently Served Bar (Footer)
        if (servedTickets.isNotEmpty) _buildRecentlyServedFooter(servedTickets),
      ],
    );
  }

  Widget _buildServerDispatchCard(BuildContext context, KitchenTicket ticket) {
    final minutesElapsed = ticket.minutesElapsed;
    final isUrgent = minutesElapsed >= 8;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          width: isUrgent ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isUrgent ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Table Number & Wait Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: (isUrgent ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(ticket.isTakeaway ? '🛍️' : '🍽️', style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          ticket.isTakeaway ? 'กลับบ้าน (Takeaway)' : ticket.tableNumber,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: isUrgent ? Colors.white : const Color(0xFF38BDF8)),
                      const SizedBox(width: 4),
                      Text(
                        '$minutesElapsed นาที',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isUrgent ? Colors.white : const Color(0xFF38BDF8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Order Code Subhead
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'คิวออเดอร์ #${ticket.orderNumber}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                ),
                const Text(
                  'พร้อมเสิร์ฟ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF1E293B), height: 1),

          // Items List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: ticket.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, idx) {
                final item = ticket.items[idx];
                return Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.quantity}x',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF34D399)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.recipe.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Mark As Served Big Action Button
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(kdsProvider.notifier).markAsServed(ticket.id);
                  AudioChime.play();
                  CapsuleToast.showSuccess(
                    context,
                    '✔ เสิร์ฟ ${ticket.isTakeaway ? "ออเดอร์กลับบ้าน" : ticket.tableNumber} เรียบร้อยแล้ว!',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: const Color(0xFF070B14),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.room_service_rounded, size: 20),
                label: const Text(
                  '✔ เสิร์ฟแล้ว (Mark as Served)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyServedFooter(List<KitchenTicket> servedTickets) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1424),
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, size: 16, color: Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          const Text(
            'เสิร์ฟแล้วล่าสุด:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: servedTickets.take(5).map((t) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${t.isTakeaway ? "กลับบ้าน" : t.tableNumber} (#${t.orderNumber})',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODE 2: HYBRID SPLIT BOARD
  // ==========================================
  Widget _buildHybridSplitView(
    List<KitchenTicket> cookingTickets,
    List<KitchenTicket> readyTickets,
    List<KitchenTicket> servedTickets,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 950;

        if (isNarrow) {
          return Column(
            children: [
              Expanded(
                flex: 45,
                child: _buildCustomerQueueView(cookingTickets, readyTickets),
              ),
              const Divider(color: Color(0xFF1E293B), height: 2),
              Expanded(
                flex: 55,
                child: _buildServerRunnerView(readyTickets, servedTickets),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left half: Customer Queue Board
            Expanded(
              flex: 50,
              child: _buildCustomerQueueView(cookingTickets, readyTickets),
            ),

            Container(width: 3, color: const Color(0xFF1E293B)),

            // Right half: Server Runner Dispatch
            Expanded(
              flex: 50,
              child: _buildServerRunnerView(readyTickets, servedTickets),
            ),
          ],
        );
      },
    );
  }
}
