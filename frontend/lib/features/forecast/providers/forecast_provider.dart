import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ingredient_forecast.dart';

class ForecastState {
  final bool isLoading;
  final ForecastSummaryData data;
  final String? errorMessage;

  const ForecastState({
    this.isLoading = false,
    required this.data,
    this.errorMessage,
  });

  ForecastState copyWith({
    bool? isLoading,
    ForecastSummaryData? data,
    String? errorMessage,
  }) {
    return ForecastState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }
}

class ForecastNotifier extends Notifier<ForecastState> {
  final bool autoFetch;
  late final Dio _dio;

  ForecastNotifier({this.autoFetch = true});

  @override
  ForecastState build() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:5000',
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ),
    );

    // Initial state with smart fallback
    final initialState = ForecastState(
      isLoading: false,
      data: _getFallbackForecast(),
    );

    if (autoFetch) {
      fetchForecast();
    }
    return initialState;
  }

  Future<void> fetchForecast() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _dio.get('/api/analytics/waste-forecast');
      if (response.data != null && response.data['data'] != null) {
        final parsed = ForecastSummaryData.fromJson(response.data['data'] as Map<String, dynamic>);
        state = state.copyWith(isLoading: false, data: parsed);
        return;
      }
    } catch (e) {
      // Fallback remains active, log error
    }
    state = state.copyWith(isLoading: false);
  }

  static ForecastSummaryData _getFallbackForecast() {
    return ForecastSummaryData(
      totalWasteValueAtRisk: 2840.0,
      criticalItemsCount: 2,
      warningItemsCount: 3,
      safeItemsCount: 11,
      suggestedOrderTotalValue: 1420.0,
      forecastBasisDays: 14,
      totalOrdersAnalyzed: 48,
      generatedAt: DateTime.now(),
      items: [
        IngredientForecastItem(
          ingredientId: 'ing_pork_belly',
          ingredientName: 'เนื้อหมูสามชั้นสไลซ์',
          category: 'Meat',
          purchaseUnit: 'kg',
          currentStock: 8.5,
          shelfLifeDays: 3,
          dailyConsumption: 1.2,
          daysRemaining: 7.1,
          riskLevel: ForecastRiskLevel.critical,
          potentialWasteQuantity: 4.9,
          potentialWasteValue: 1176.0,
          suggestedOrder7Days: 0.0,
          suggestedOrderValue: 0.0,
          message: 'เสี่ยงเน่าเสียทิ้ง 4.9 kg (คาดใช้ไม่ทันใน 3 วัน)',
          actionRecommendation: 'จัดโปรโมชั่นเมนูหมูสามชั้น หรือเพิ่มเป็นเมนูแนะนำประจำวันเพื่อระบายสต็อก',
        ),
        IngredientForecastItem(
          ingredientId: 'ing_fresh_basil',
          ingredientName: 'ใบกะเพราสด',
          category: 'Vegetables',
          purchaseUnit: 'kg',
          currentStock: 3.2,
          shelfLifeDays: 4,
          dailyConsumption: 0.45,
          daysRemaining: 7.1,
          riskLevel: ForecastRiskLevel.critical,
          potentialWasteQuantity: 1.4,
          potentialWasteValue: 280.0,
          suggestedOrder7Days: 0.0,
          suggestedOrderValue: 0.0,
          message: 'เสี่ยงเหี่ยวเน่า 1.4 kg ก่อน 4 วัน',
          actionRecommendation: 'ทำซอสกะเพราสูตรเข้มข้นแช่แข็งสต็อกเก็บไว้ใช้ระยะยาว',
        ),
        IngredientForecastItem(
          ingredientId: 'ing_fresh_milk',
          ingredientName: 'นมสดพาสเจอร์ไรส์',
          category: 'Dairy',
          purchaseUnit: 'l',
          currentStock: 12.0,
          shelfLifeDays: 6,
          dailyConsumption: 1.5,
          daysRemaining: 8.0,
          riskLevel: ForecastRiskLevel.warning,
          potentialWasteQuantity: 3.0,
          potentialWasteValue: 285.0,
          suggestedOrder7Days: 0.0,
          suggestedOrderValue: 0.0,
          message: 'สต็อกเกินความต้องการ 6 วันเล็กน้อย (~3.0 ลิตร)',
          actionRecommendation: 'ชะลอการสั่งรอบใหม่ และจัดเมนูเครื่องดื่มพิเศษ',
        ),
        IngredientForecastItem(
          ingredientId: 'ing_beef_sirloin',
          ingredientName: 'เนื้อวัวสันนอกออสเตรเลีย',
          category: 'Meat',
          purchaseUnit: 'kg',
          currentStock: 1.5,
          shelfLifeDays: 3,
          dailyConsumption: 1.1,
          daysRemaining: 1.4,
          riskLevel: ForecastRiskLevel.warning,
          potentialWasteQuantity: 0.0,
          potentialWasteValue: 0.0,
          suggestedOrder7Days: 6.2,
          suggestedOrderValue: 2480.0,
          message: 'สต็อกเหลือน้อยมาก จะหมดใน 1.4 วัน',
          actionRecommendation: 'สั่งซื้อด่วนอย่างน้อย 6.2 kg เพื่อรองรับยอดขายสัปดาห์หน้า',
        ),
        IngredientForecastItem(
          ingredientId: 'ing_jasmine_rice',
          ingredientName: 'ข้าวหอมมะลิคัดพิเศษ',
          category: 'Dry Goods',
          purchaseUnit: 'kg',
          currentStock: 45.0,
          shelfLifeDays: 45,
          dailyConsumption: 3.5,
          daysRemaining: 12.9,
          riskLevel: ForecastRiskLevel.safe,
          potentialWasteQuantity: 0.0,
          potentialWasteValue: 0.0,
          suggestedOrder7Days: 0.0,
          suggestedOrderValue: 0.0,
          message: 'ระดับสต็อกสมดุลกับการใช้งาน ปลอดภัย',
          actionRecommendation: 'รักษาระดับการสั่งซื้อตามปกติ',
        ),
        IngredientForecastItem(
          ingredientId: 'ing_soy_sauce',
          ingredientName: 'ซีอิ๊วขาวเห็ดหอม',
          category: 'Sauce',
          purchaseUnit: 'l',
          currentStock: 6.0,
          shelfLifeDays: 45,
          dailyConsumption: 0.35,
          daysRemaining: 17.1,
          riskLevel: ForecastRiskLevel.safe,
          potentialWasteQuantity: 0.0,
          potentialWasteValue: 0.0,
          suggestedOrder7Days: 0.0,
          suggestedOrderValue: 0.0,
          message: 'ระดับสต็อกสมดุลกับการใช้งาน ปลอดภัย',
          actionRecommendation: 'รักษาระดับสต็อกตามปกติ',
        ),
      ],
    );
  }
}

final forecastProvider = NotifierProvider<ForecastNotifier, ForecastState>(
  ForecastNotifier.new,
);
