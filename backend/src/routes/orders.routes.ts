import { Router, Request, Response } from 'express';
import { OrdersService, InsufficientStockError } from '../services/orders.service';
import { WebSocketService } from '../services/websocket.service';

const router = Router();

// GET /api/orders - Fetch order history
router.get('/', async (req: Request, res: Response) => {
  try {
    const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 250;
    const orders = await OrdersService.getOrders(isNaN(limit) ? 250 : limit);
    return res.json({
      success: true,
      count: orders.length,
      data: orders,
    });
  } catch (error: any) {
    console.error('Error fetching orders:', error);
    return res.status(500).json({
      success: false,
      error: error.message || 'Failed to fetch orders',
    });
  }
});

// GET /api/orders/:id - Fetch single order details
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    const order = await OrdersService.getOrderById(id);
    if (!order) {
      return res.status(404).json({
        success: false,
        error: 'Order not found',
      });
    }
    return res.json({
      success: true,
      data: order,
    });
  } catch (error: any) {
    console.error('Error fetching order by ID:', error);
    return res.status(500).json({
      success: false,
      error: error.message || 'Failed to fetch order',
    });
  }
});

// POST /api/orders - Create new order and deduct stock atomically
router.post('/', async (req: Request, res: Response) => {
  try {
    const { items, orderNumber, tableNumber, orderType } = req.body;

    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Missing or invalid "items" array in request body',
      });
    }

    const createdOrder = await OrdersService.createOrder({
      items,
      orderNumber,
      tableNumber,
      orderType,
    });

    const broadcastPayload = {
      id: createdOrder.id,
      orderNumber: orderNumber || `ORD-${createdOrder.id.substring(0, 6).toUpperCase()}`,
      tableNumber: tableNumber || 'โต๊ะ 01',
      orderType: orderType || 'ทานที่ร้าน (Dine-In)',
      status: 'COOKING',
      items: (createdOrder.items || []).map((i: any) => ({
        recipeId: i.recipeId,
        recipeName: i.recipe?.name || '',
        category: i.recipe?.category || 'Main Course',
        quantity: i.quantity,
        pricePerUnit: Number(i.pricePerUnit),
      })),
    };

    // Real-Time broadcast to Kitchen Display System (KDS) & other listeners
    try {
      WebSocketService.broadcast('NEW_ORDER', broadcastPayload);
    } catch (wsErr) {
      console.error('Failed to broadcast NEW_ORDER via WebSocket:', wsErr);
    }

    return res.status(201).json({
      success: true,
      message: 'Order created and inventory deducted successfully',
      data: createdOrder,
    });
  } catch (error: any) {
    console.error('Error creating order:', error);

    if (error instanceof InsufficientStockError) {
      return res.status(400).json({
        success: false,
        code: 'INSUFFICIENT_STOCK',
        error: error.message,
        insufficientItems: error.insufficientItems,
      });
    }

    return res.status(400).json({
      success: false,
      error: error.message || 'Failed to process order',
    });
  }
});

// PATCH /api/orders/:id/status - Update order status and broadcast via WebSocket
router.patch('/:id/status', async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id);
    const { status } = req.body;

    if (!status) {
      return res.status(400).json({
        success: false,
        error: 'Missing "status" in request body',
      });
    }

    const updatedOrder = await OrdersService.updateOrderStatus(id, status);

    // Broadcast status change to KDS and POS
    try {
      WebSocketService.broadcast('ORDER_STATUS_CHANGED', updatedOrder);
    } catch (wsErr) {
      console.error('Failed to broadcast ORDER_STATUS_CHANGED via WebSocket:', wsErr);
    }

    return res.json({
      success: true,
      message: `Order status updated to ${status}`,
      data: updatedOrder,
    });
  } catch (error: any) {
    console.error('Error updating order status:', error);
    return res.status(500).json({
      success: false,
      error: error.message || 'Failed to update order status',
    });
  }
});

export default router;
