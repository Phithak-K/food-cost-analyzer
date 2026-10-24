import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ingredients/providers/ingredients_provider.dart';
import '../../recipes/providers/recipes_provider.dart';
import '../models/simulation_models.dart';
import '../services/simulation_engine.dart';

class SimulationState {
  final Map<String, double> percentAdjustments; // ingredientId -> % change
  final double threshold;
  final String searchQuery;
  final String? activePreset;
  final SimulationResult result;

  const SimulationState({
    required this.percentAdjustments,
    required this.threshold,
    required this.searchQuery,
    this.activePreset,
    required this.result,
  });

  SimulationState copyWith({
    Map<String, double>? percentAdjustments,
    double? threshold,
    String? searchQuery,
    String? activePreset,
    SimulationResult? result,
  }) {
    return SimulationState(
      percentAdjustments: percentAdjustments ?? this.percentAdjustments,
      threshold: threshold ?? this.threshold,
      searchQuery: searchQuery ?? this.searchQuery,
      activePreset: activePreset ?? this.activePreset,
      result: result ?? this.result,
    );
  }
}

class SimulationNotifier extends Notifier<SimulationState> {
  @override
  SimulationState build() {
    final recipes = ref.watch(recipesProvider);
    final ingredients = ref.watch(ingredientsProvider);

    final initialAdjustments = <String, double>{};
    final initialResult = SimulationEngine.calculate(
      recipes: recipes,
      ingredients: ingredients,
      percentAdjustments: initialAdjustments,
      targetCostThreshold: 35.0,
    );

    return SimulationState(
      percentAdjustments: initialAdjustments,
      threshold: 35.0,
      searchQuery: '',
      result: initialResult,
    );
  }

  void _recalculate() {
    final recipes = ref.read(recipesProvider);
    final ingredients = ref.read(ingredientsProvider);

    final newResult = SimulationEngine.calculate(
      recipes: recipes,
      ingredients: ingredients,
      percentAdjustments: state.percentAdjustments,
      targetCostThreshold: state.threshold,
    );

    state = state.copyWith(result: newResult);
  }

  void setPercentAdjustment(String ingredientId, double percent) {
    final newMap = Map<String, double>.from(state.percentAdjustments);
    if (percent == 0.0) {
      newMap.remove(ingredientId);
    } else {
      newMap[ingredientId] = double.parse(percent.toStringAsFixed(1));
    }
    state = state.copyWith(
      percentAdjustments: newMap,
      activePreset: null,
    );
    _recalculate();
  }

  void adjustByStep(String ingredientId, double deltaPercent) {
    final current = state.percentAdjustments[ingredientId] ?? 0.0;
    setPercentAdjustment(ingredientId, current + deltaPercent);
  }

  void setThreshold(double threshold) {
    state = state.copyWith(threshold: threshold);
    _recalculate();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void resetAll() {
    state = state.copyWith(
      percentAdjustments: {},
      activePreset: null,
    );
    _recalculate();
  }

  /// Preset Scenarios:
  void applyPreset(String presetName) {
    final ingredients = ref.read(ingredientsProvider);
    final newMap = <String, double>{};

    switch (presetName) {
      case 'general_inflation': // +10% all ingredients
        for (final ing in ingredients) {
          newMap[ing.id] = 10.0;
        }
        break;

      case 'dairy_spike': // +20% dairy & eggs
        for (final ing in ingredients) {
          final cat = ing.category.toLowerCase();
          final name = ing.name.toLowerCase();
          if (cat.contains('dairy') ||
              cat.contains('นม') ||
              name.contains('cream') ||
              name.contains('นม') ||
              name.contains('ชีส') ||
              name.contains('butter') ||
              name.contains('เนย')) {
            newMap[ing.id] = 20.0;
          }
        }
        break;

      case 'meat_seafood_spike': // +15% meat & seafood
        for (final ing in ingredients) {
          final cat = ing.category.toLowerCase();
          final name = ing.name.toLowerCase();
          if (cat.contains('meat') ||
              cat.contains('seafood') ||
              name.contains('เนื้อ') ||
              name.contains('กุ้ง') ||
              name.contains('ปลา') ||
              name.contains('แซลมอน') ||
              name.contains('salmon') ||
              name.contains('wagyu') ||
              name.contains('beef')) {
            newMap[ing.id] = 15.0;
          }
        }
        break;
    }

    state = state.copyWith(
      percentAdjustments: newMap,
      activePreset: presetName,
    );
    _recalculate();
  }
}

final simulationProvider =
    NotifierProvider<SimulationNotifier, SimulationState>(SimulationNotifier.new);
