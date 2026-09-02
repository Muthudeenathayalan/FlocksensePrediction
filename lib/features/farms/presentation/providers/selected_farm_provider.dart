import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';

/// Active Farm Context holding the currently active farm and flock selection.
/// Eliminates hardcoded 'farm_01' or 'flock_01' across operational screens.
class ActiveFarmContext {
  final String farmId;
  final String farmName;
  final String? batchId;
  final String? batchName;
  final String district;
  final String state;
  final double latitude;
  final double longitude;

  const ActiveFarmContext({
    required this.farmId,
    required this.farmName,
    this.batchId,
    this.batchName,
    this.district = 'Nashik',
    this.state = 'Maharashtra',
    this.latitude = 19.9975,
    this.longitude = 73.7898,
  });

  ActiveFarmContext copyWith({
    String? farmId,
    String? farmName,
    String? batchId,
    String? batchName,
    String? district,
    String? state,
    double? latitude,
    double? longitude,
  }) {
    return ActiveFarmContext(
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      batchId: batchId ?? this.batchId,
      batchName: batchName ?? this.batchName,
      district: district ?? this.district,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  static const defaultContext = ActiveFarmContext(
    farmId: 'farm_demo_001',
    farmName: 'Green Valley Poultry Farm',
    batchId: 'batch_demo_001',
    batchName: 'Broiler Batch 01',
    district: 'Nashik',
    state: 'Maharashtra',
    latitude: 19.9975,
    longitude: 73.7898,
  );
}

/// State notifier managing the active farm context across the application
class ActiveFarmContextNotifier extends StateNotifier<ActiveFarmContext> {
  ActiveFarmContextNotifier() : super(ActiveFarmContext.defaultContext);

  void selectFarm({
    required String farmId,
    required String farmName,
    String? district,
    String? stateName,
    double? latitude,
    double? longitude,
  }) {
    final current = state;
    state = current.copyWith(
      farmId: farmId,
      farmName: farmName,
      district: district ?? current.district,
      state: stateName ?? current.state,
      latitude: latitude ?? current.latitude,
      longitude: longitude ?? current.longitude,
      batchId: null,
      batchName: null,
    );
  }

  void selectFarmModel(FarmModel farm) {
    state = state.copyWith(
      farmId: farm.id,
      farmName: farm.farmName,
      district: farm.district ?? 'Nashik',
      state: farm.state ?? 'Maharashtra',
      latitude: farm.latitude ?? 19.9975,
      longitude: farm.longitude ?? 73.7898,
    );
  }

  void selectBatch({required String batchId, required String batchName}) {
    state = state.copyWith(
      batchId: batchId,
      batchName: batchName,
    );
  }
}

/// Primary provider for the active farm context
final activeFarmContextProvider =
    StateNotifierProvider<ActiveFarmContextNotifier, ActiveFarmContext>((ref) {
  final notifier = ActiveFarmContextNotifier();
  
  // Auto-sync with first farm when farm list loads if default is not loaded
  final farmsAsync = ref.watch(farmListProvider);
  farmsAsync.whenData((farms) {
    if (farms.isNotEmpty && notifier.state == ActiveFarmContext.defaultContext) {
      final first = farms.first;
      notifier.selectFarmModel(first);
    }
  });

  return notifier;
});
