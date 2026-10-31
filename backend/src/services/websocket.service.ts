import { WebSocketServer, WebSocket } from 'ws';
import http from 'http';

export class WebSocketService {
  private static wss: WebSocketServer | null = null;
  private static clients: Set<WebSocket> = new Set();
  private static activeTickets: Map<string, any> = new Map();

  private static initDefaultTickets() {
    if (this.activeTickets.size === 0) {
      this.activeTickets.set('ORD-7801', {
        id: 'kds_1',
        orderNumber: 'ORD-7801',
        tableNumber: 'โต๊ะ 04',
        orderType: 'ทานที่ร้าน (Dine-In)',
        createdAt: new Date(Date.now() - 6 * 60 * 1000).toISOString(),
        status: 'COOKING',
        items: [
          {
            recipeId: 'rec_1',
            recipeName: 'Pan-Seared Norwegian Salmon (สเต๊กแซลมอนย่าง)',
            quantity: 2,
            note: 'สุก Medium-Well',
          },
          {
            recipeId: 'rec_2',
            recipeName: 'Truffle Cream Fettuccine (เฟตตูชินีครีมทรัฟเฟิล)',
            quantity: 1,
            note: 'เพิ่มพริกไทยดำ',
          },
        ],
      });
      this.activeTickets.set('ORD-7802', {
        id: 'kds_2',
        orderNumber: 'ORD-7802',
        tableNumber: 'โต๊ะ 08',
        orderType: 'ทานที่ร้าน (Dine-In)',
        createdAt: new Date(Date.now() - 14 * 60 * 1000).toISOString(),
        status: 'COOKING',
        items: [
          {
            recipeId: 'rec_3',
            recipeName: 'Wagyu Ribeye MB4/5 Steak (สเต๊กวากิวริบอาย)',
            quantity: 1,
            note: 'ความสุก Medium-Rare',
          },
        ],
      });
      this.activeTickets.set('ORD-7803', {
        id: 'kds_3',
        orderNumber: 'ORD-7803',
        tableNumber: 'รับกลับบ้าน (Takeaway)',
        orderType: 'กลับบ้าน (Takeaway)',
        createdAt: new Date(Date.now() - 2 * 60 * 1000).toISOString(),
        status: 'COOKING',
        items: [
          {
            recipeId: 'rec_4',
            recipeName: 'Tiger Prawn Garlic Butter (กุ้งลายเสือผัดเนยกระเทียม)',
            quantity: 2,
          },
          {
            recipeId: 'rec_5',
            recipeName: 'Creamy Spinach Gratin (ผักโขมอบชีส)',
            quantity: 1,
            note: 'แยกซอส',
          },
        ],
      });
    }
  }

  static init(server: http.Server) {
    this.initDefaultTickets();
    this.wss = new WebSocketServer({ server, path: '/ws' });

    this.wss.on('connection', (ws: WebSocket, req) => {
      console.log(`[WebSocket] Client connected (${this.clients.size + 1} active)`);
      this.clients.add(ws);

      // Send initial connection handshake
      ws.send(
        JSON.stringify({
          event: 'CONNECTED',
          message: 'Connected to Real-Time Kitchen Display Gateway',
          timestamp: new Date().toISOString(),
        })
      );

      // Send authoritative active tickets state to synchronize newly connected/refreshed clients
      ws.send(
        JSON.stringify({
          event: 'INITIAL_STATE',
          data: Array.from(WebSocketService.activeTickets.values()),
          timestamp: new Date().toISOString(),
        })
      );

      ws.on('message', (raw) => {
        try {
          const parsed = JSON.parse(raw.toString());
          if (parsed.type === 'PING' || parsed.event === 'PING') {
            ws.send(JSON.stringify({ event: 'PONG', timestamp: new Date().toISOString() }));
          } else if (
            parsed.event === 'UPDATE_ORDER_STATUS' ||
            parsed.event === 'ORDER_STATUS_CHANGED' ||
            parsed.type === 'UPDATE_ORDER_STATUS'
          ) {
            console.log('[WebSocket] Client status change broadcast:', parsed.data);
            WebSocketService.broadcast('ORDER_STATUS_CHANGED', parsed.data);
          } else if (
            parsed.event === 'NEW_ORDER' ||
            parsed.event === 'CREATE_ORDER' ||
            parsed.type === 'NEW_ORDER'
          ) {
            console.log('[WebSocket] Client new order broadcast:', parsed.data);
            WebSocketService.broadcast('NEW_ORDER', parsed.data);
          } else if (parsed.event === 'GET_STATE' || parsed.type === 'GET_STATE') {
            ws.send(
              JSON.stringify({
                event: 'INITIAL_STATE',
                data: Array.from(WebSocketService.activeTickets.values()),
                timestamp: new Date().toISOString(),
              })
            );
          }
        } catch {
          // Ignore malformed message
        }
      });

      ws.on('close', () => {
        this.clients.delete(ws);
        console.log(`[WebSocket] Client disconnected (${this.clients.size} active)`);
      });

      ws.on('error', (err) => {
        console.error('[WebSocket] Client error:', err);
        this.clients.delete(ws);
      });
    });

    console.log('[WebSocket] Server initialized on ws://localhost:5000/ws');
  }

  private static recordNewOrder(orderData: any) {
    if (!orderData) return;
    const orderNumber = (orderData.orderNumber || '').toString();
    const id = (orderData.id || '').toString();
    const key = orderNumber || id;
    if (key) {
      this.activeTickets.set(key, {
        ...orderData,
        orderNumber: orderNumber || key,
        status: orderData.status || 'COOKING',
        createdAt: orderData.createdAt || new Date().toISOString(),
      });
    }
  }

  private static recordStatusChange(statusData: any) {
    if (!statusData) return;
    const id = (statusData.id || '').toString();
    const orderNumber = (statusData.orderNumber || '').toString();
    const status = (statusData.status || '').toString();

    let found = false;
    for (const [key, ticket] of this.activeTickets.entries()) {
      if (
        key === orderNumber ||
        key === id ||
        ticket.id === id ||
        ticket.orderNumber === orderNumber ||
        ticket.orderNumber?.replace('#', '').trim().toLowerCase() ===
          orderNumber?.replace('#', '').trim().toLowerCase()
      ) {
        ticket.status = status;
        this.activeTickets.set(key, ticket);
        found = true;
        break;
      }
    }

    if (!found && (orderNumber || id)) {
      this.activeTickets.set(orderNumber || id, {
        id,
        orderNumber: orderNumber || id,
        status,
        createdAt: new Date().toISOString(),
      });
    }
  }

  /**
   * Broadcast an event to all connected clients (KDS screens, Cashier, Dashboards)
   */
  static broadcast(event: string, data: any) {
    if (event === 'NEW_ORDER') {
      this.recordNewOrder(data);
    } else if (event === 'ORDER_STATUS_CHANGED') {
      this.recordStatusChange(data);
    }

    if (!this.wss) return;

    const payload = JSON.stringify({
      event,
      data,
      timestamp: new Date().toISOString(),
    });

    for (const client of this.clients) {
      if (client.readyState === WebSocket.OPEN) {
        try {
          client.send(payload);
        } catch (err) {
          console.error('[WebSocket] Failed to send payload:', err);
        }
      }
    }
  }

  static getConnectedCount(): number {
    return this.clients.size;
  }
}
