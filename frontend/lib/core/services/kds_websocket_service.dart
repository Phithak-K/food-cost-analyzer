import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../features/pos/models/kitchen_ticket.dart';
import '../../features/pos/providers/kds_provider.dart';
import '../../features/recipes/models/recipe.dart';
import '../../features/recipes/providers/recipes_provider.dart';
import '../utils/audio_chime.dart';

enum WebSocketConnectionStatus {
  connecting,
  connected,
  disconnected,
}

class KdsWebSocketState {
  final WebSocketConnectionStatus status;
  final String? lastMessage;
  final DateTime? lastHeartbeat;
  final int orderReceivedCount;

  const KdsWebSocketState({
    this.status = WebSocketConnectionStatus.disconnected,
    this.lastMessage,
    this.lastHeartbeat,
    this.orderReceivedCount = 0,
  });

  KdsWebSocketState copyWith({
    WebSocketConnectionStatus? status,
    String? lastMessage,
    DateTime? lastHeartbeat,
    int? orderReceivedCount,
  }) {
    return KdsWebSocketState(
      status: status ?? this.status,
      lastMessage: lastMessage ?? this.lastMessage,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
      orderReceivedCount: orderReceivedCount ?? this.orderReceivedCount,
    );
  }
}

class KdsWebSocketNotifier extends Notifier<KdsWebSocketState> {
  static bool enableInTests = false;
  final bool autoConnect;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _isDisposed = false;

  final String _wsUrl = 'ws://localhost:5000/ws';

  KdsWebSocketNotifier({this.autoConnect = true});

  bool get _isTestEnvironment {
    if (enableInTests) return false;
    final binding = WidgetsBinding.instance.runtimeType.toString();
    return binding.contains('Test');
  }

  @override
  KdsWebSocketState build() {
    ref.onDispose(() {
      _isDisposed = true;
      _disconnect();
    });

    if (autoConnect && !_isTestEnvironment) {
      // Defer auto-connect to microtask so build() returns initial state safely
      Future.microtask(() {
        if (!_isDisposed) {
          _connect();
        }
      });
    }

    return const KdsWebSocketState(status: WebSocketConnectionStatus.disconnected);
  }

  void connect() {
    _connect();
  }

  void _connect() {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();

    state = state.copyWith(status: WebSocketConnectionStatus.connecting);

    try {
      final uri = Uri.parse(_wsUrl);
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;

      // Catch channel.ready future gracefully to prevent uncaught zone error in console
      channel.ready.catchError((err) {
        // Expected when backend server is offline; handle gracefully
        if (!_isDisposed) {
          state = state.copyWith(status: WebSocketConnectionStatus.disconnected);
          _scheduleReconnect();
        }
      });

      _subscription = channel.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onDone: () {
          if (!_isDisposed) {
            state = state.copyWith(status: WebSocketConnectionStatus.disconnected);
            _scheduleReconnect();
          }
        },
        onError: (err) {
          if (!_isDisposed) {
            state = state.copyWith(status: WebSocketConnectionStatus.disconnected);
            _scheduleReconnect();
          }
        },
        cancelOnError: true,
      );

      // Start ping heartbeat every 15s to keep connection alive
      _pingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (state.status == WebSocketConnectionStatus.connected) {
          try {
            _channel?.sink.add(jsonEncode({'type': 'PING'}));
          } catch (_) {}
        }
      });
    } catch (_) {
      state = state.copyWith(status: WebSocketConnectionStatus.disconnected);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isDisposed && state.status != WebSocketConnectionStatus.connected) {
        _connect();
      }
    });
  }

  void _disconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void _handleMessage(dynamic data) {
    try {
      final text = data is String ? data : utf8.decode(data as List<int>);
      final payload = jsonDecode(text) as Map<String, dynamic>;
      final event = payload['event'] as String?;

      if (event == 'CONNECTED') {
        state = state.copyWith(
          status: WebSocketConnectionStatus.connected,
          lastHeartbeat: DateTime.now(),
        );
        debugPrint('[WebSocket] Gateway Connected');
      } else if (event == 'PONG') {
        state = state.copyWith(lastHeartbeat: DateTime.now());
      } else if (event == 'NEW_ORDER') {
        _processNewOrder(payload['data'] as Map<String, dynamic>);
      } else if (event == 'ORDER_STATUS_CHANGED') {
        _processOrderStatusChange(payload['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[WebSocket] Error processing message: $e');
    }
  }

  void _processNewOrder(Map<String, dynamic> orderData) {
    final orderId = (orderData['id'] ?? '').toString();
    final rawOrderNumber = orderId.length >= 6
        ? 'ORD-${orderId.substring(0, 6).toUpperCase()}'
        : 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    final recipes = ref.read(recipesProvider);
    final rawItems = orderData['items'] as List<dynamic>? ?? [];

    final List<KitchenOrderItem> ticketItems = [];

    for (final rawItem in rawItems) {
      final recipeId = (rawItem['recipeId'] ?? '').toString();
      final qty = (rawItem['quantity'] as num?)?.toInt() ?? 1;

      // Find recipe in repository or fallback
      Recipe? recipe;
      try {
        recipe = recipes.firstWhere((r) => r.id == recipeId);
      } catch (_) {
        final rawRecipe = rawItem['recipe'] as Map<String, dynamic>?;
        recipe = Recipe(
          id: recipeId,
          name: rawRecipe?['name']?.toString() ?? 'เมนูสั่งด่วน',
          category: rawRecipe?['category']?.toString() ?? 'Main Course',
          sellingPrice: (rawItem['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
          items: const [],
        );
      }

      ticketItems.add(KitchenOrderItem(recipe: recipe, quantity: qty));
    }

    if (ticketItems.isNotEmpty) {
      final newTicket = KitchenTicket(
        id: orderId.isNotEmpty ? orderId : 'kds_${DateTime.now().millisecondsSinceEpoch}',
        orderNumber: rawOrderNumber,
        tableNumber: 'โต๊ะ ${(state.orderReceivedCount % 8) + 1}',
        orderType: 'ทานที่ร้าน (Dine-In)',
        createdAt: DateTime.now(),
        items: ticketItems,
        status: KitchenOrderStatus.cooking,
      );

      // Add to KDS and sound the bell chime
      ref.read(kdsProvider.notifier).addTicketFromWebSocket(newTicket);

      state = state.copyWith(
        orderReceivedCount: state.orderReceivedCount + 1,
        lastMessage: 'ออเดอร์ใหม่ #$rawOrderNumber เข้ามาแล้ว',
        lastHeartbeat: DateTime.now(),
      );
    }
  }

  void _processOrderStatusChange(Map<String, dynamic> orderData) {
    final orderId = (orderData['id'] ?? '').toString();
    final statusStr = (orderData['status'] ?? '').toString();

    KitchenOrderStatus status = KitchenOrderStatus.cooking;
    if (statusStr == 'READY') {
      status = KitchenOrderStatus.ready;
    } else if (statusStr == 'SERVED' || statusStr == 'COMPLETED') {
      status = KitchenOrderStatus.served;
    }

    ref.read(kdsProvider.notifier).updateTicketStatus(orderId, status);
  }

  /// Triggers a manual test chime for kitchen staff
  void testChime() {
    AudioChime.play();
  }
}

final kdsWebSocketProvider =
    NotifierProvider<KdsWebSocketNotifier, KdsWebSocketState>(
  KdsWebSocketNotifier.new,
);
