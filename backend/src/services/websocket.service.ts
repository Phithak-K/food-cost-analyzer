import { WebSocketServer, WebSocket } from 'ws';
import http from 'http';

export class WebSocketService {
  private static wss: WebSocketServer | null = null;
  private static clients: Set<WebSocket> = new Set();

  static init(server: http.Server) {
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

      ws.on('message', (raw) => {
        try {
          const parsed = JSON.parse(raw.toString());
          if (parsed.type === 'PING' || parsed.event === 'PING') {
            ws.send(JSON.stringify({ event: 'PONG', timestamp: new Date().toISOString() }));
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

  /**
   * Broadcast an event to all connected clients (KDS screens, Cashier, Dashboards)
   */
  static broadcast(event: string, data: any) {
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
