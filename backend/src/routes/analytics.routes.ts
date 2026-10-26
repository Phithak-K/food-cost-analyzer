import { Router, Request, Response } from 'express';
import { CalculatorService } from '../services/calculator.service';
import { SimulationService, SimulationRequest } from '../services/simulation.service';
import { ForecastService } from '../services/forecast.service';

const router = Router();

// GET /api/analytics/menu-matrix - 4-Quadrant Menu Engineering Analytics
router.get('/menu-matrix', async (_req: Request, res: Response) => {
  try {
    const analytics = await CalculatorService.getMenuMatrixAnalytics();
    return res.json({
      success: true,
      data: analytics,
    });
  } catch (error) {
    console.error('Error computing menu matrix analytics:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to compute menu matrix analytics',
    });
  }
});

// GET /api/analytics/waste-forecast - Demand Forecasting & Waste Risk Prediction
router.get('/waste-forecast', async (_req: Request, res: Response) => {
  try {
    const forecast = await ForecastService.getDemandAndWasteForecast();
    return res.json({
      success: true,
      data: forecast,
    });
  } catch (error) {
    console.error('Error generating waste forecast:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to compute waste and demand forecast',
    });
  }
});

// POST /api/analytics/simulate-cost - What-If Cost Impact Simulation
router.post('/simulate-cost', async (req: Request, res: Response) => {
  try {
    const body: SimulationRequest = req.body;

    if (!body || !body.adjustments || !Array.isArray(body.adjustments)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid payload: adjustments must be an array of { ingredientId, percentChange?, absolutePriceChange?, newPrice? }',
      });
    }

    const simulation = await SimulationService.simulateCostImpact(body);

    return res.json({
      success: true,
      data: simulation,
    });
  } catch (error) {
    console.error('Error running cost simulation:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to execute cost simulation',
    });
  }
});

export default router;
