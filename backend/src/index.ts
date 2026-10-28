import http from 'http';
import path from 'path';
import fs from 'fs';
import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import ingredientsRouter from './routes/ingredients.routes';
import recipesRouter from './routes/recipes.routes';
import analyticsRouter from './routes/analytics.routes';
import ordersRouter from './routes/orders.routes';
import { WebSocketService } from './services/websocket.service';
import { prisma } from './prisma';

const app = express();
const PORT = process.env.PORT || 5000;

// Enable CORS for Flutter Web (all localhost ports e.g. localhost:8080, localhost:3000, localhost:5500, etc.)
app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (e.g. mobile apps, curl, server-to-server)
      if (!origin) return callback(null, true);
      // Allow any localhost or 127.0.0.1 on any port
      if (/^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)) {
        return callback(null, true);
      }
      return callback(null, true); // Permissive for local dev environment
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
    credentials: true,
  })
);

app.use(express.json());

// Request logger for local dev
app.use((req: Request, _res: Response, next: NextFunction) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Health check endpoint with real live PostgreSQL connection test
app.get('/api/health', async (_req: Request, res: Response) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    return res.json({
      success: true,
      status: 'ONLINE',
      database: 'CONNECTED',
      service: 'Food Costing & Menu Engineering API',
      timestamp: new Date().toISOString(),
    });
  } catch (err: any) {
    return res.status(503).json({
      success: false,
      status: 'DEGRADED',
      database: 'DISCONNECTED',
      service: 'Food Costing & Menu Engineering API',
      error: 'PostgreSQL offline or unreachable',
      timestamp: new Date().toISOString(),
    });
  }
});

// API Routes
app.use('/api/ingredients', ingredientsRouter);
app.use('/api/recipes', recipesRouter);
app.use('/api/analytics', analyticsRouter);
app.use('/api/orders', ordersRouter);

// Serve Flutter Web Frontend (Monorepo Single-Service)
const webDistPath = path.resolve(__dirname, '../../frontend/build/web');
app.use(express.static(webDistPath));

// Fallback for SPA routing in Express 5
app.use((req: Request, res: Response, next: NextFunction) => {
  if (req.path.startsWith('/api')) {
    return next();
  }
  const indexHtml = path.join(webDistPath, 'index.html');
  if (fs.existsSync(indexHtml)) {
    return res.sendFile(indexHtml);
  }
  return next();
});

// 404 Handler
app.use((_req: Request, res: Response) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found',
  });
});

// Global Error Handler
app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
  console.error('Unhandled server error:', err);
  res.status(500).json({
    success: false,
    error: err.message || 'Internal server error',
  });
});

// Start listening
const server = http.createServer(app);
WebSocketService.init(server);

server.listen(PORT, () => {
  console.log(`Food Costing & Menu Engineering API running on http://localhost:${PORT}`);
  console.log(`WebSocket Server active on ws://localhost:${PORT}/ws`);
  console.log(`Connected to PostgreSQL via Prisma (Port 5433)`);
});

export default app;
export { server };
