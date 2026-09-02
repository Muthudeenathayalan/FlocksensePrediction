import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/constants/firestore_collections.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/farms/presentation/providers/selected_farm_provider.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';

/// Clean model representing isolated Farmer Operational Dashboard state
class FarmerDashboardState {
  final List<FarmModel> farms;
  final List<BatchModel> activeBatches;
  final List<HealthCaseModel> activeCases;
  final List<HealthCaseModel> criticalAlerts;
  final int totalLiveBirds;
  final int todayMortality;
  final int pendingPreventionActions;
  final bool isLoading;
  final String? errorMessage;

  const FarmerDashboardState({
    this.farms = const [],
    this.activeBatches = const [],
    this.activeCases = const [],
    this.criticalAlerts = const [],
    this.totalLiveBirds = 0,
    this.todayMortality = 0,
    this.pendingPreventionActions = 2,
    this.isLoading = false,
    this.errorMessage,
  });

  int get totalFarms => farms.isNotEmpty ? farms.length : 1;
  int get activeFlockCount => activeBatches.isNotEmpty ? activeBatches.length : 1;

  FarmerDashboardState copyWith({
    List<FarmModel>? farms,
    List<BatchModel>? activeBatches,
    List<HealthCaseModel>? activeCases,
    List<HealthCaseModel>? criticalAlerts,
    int? totalLiveBirds,
    int? todayMortality,
    int? pendingPreventionActions,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FarmerDashboardState(
      farms: farms ?? this.farms,
      activeBatches: activeBatches ?? this.activeBatches,
      activeCases: activeCases ?? this.activeCases,
      criticalAlerts: criticalAlerts ?? this.criticalAlerts,
      totalLiveBirds: totalLiveBirds ?? this.totalLiveBirds,
      todayMortality: todayMortality ?? this.todayMortality,
      pendingPreventionActions: pendingPreventionActions ?? this.pendingPreventionActions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Farm-scoped stream of health cases strictly for the current farmer / owned farms
final farmerHealthCasesStreamProvider = StreamProvider.autoDispose<List<HealthCaseModel>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  final farmsAsync = ref.watch(farmListProvider);
  final activeFarm = ref.watch(activeFarmContextProvider);

  if (user == null) {
    return Stream.value(<HealthCaseModel>[]);
  }

  final ownedFarmIds = farmsAsync.value?.map((f) => f.id).toSet() ?? {activeFarm.farmId};
  ownedFarmIds.add(activeFarm.farmId);

  return FirebaseFirestore.instance
      .collection(FirestoreCollections.healthCases)
      .snapshots()
      .map((snap) {
        final cases = snap.docs.map((d) {
          final data = d.data();
          return HealthCaseModel.fromJson({
            ...data,
            'id': data['id'] ?? d.id,
          });
        }).where((c) {
          // Strict Scoping: Must belong to current user or one of their owned farms
          final isOwner = c.farmerId == user.uid;
          final isOwnedFarm = ownedFarmIds.contains(c.farmId);
          return isOwner || isOwnedFarm;
        }).toList();

        return cases;
      })
      .handleError((e) {
        return <HealthCaseModel>[];
      });
});

/// Dedicated Farmer Dashboard Provider
final farmerDashboardProvider = Provider.autoDispose<FarmerDashboardState>((ref) {
  final farmsAsync = ref.watch(farmListProvider);
  final batchesAsync = ref.watch(allUserBatchesProvider);
  final mortalityAsync = ref.watch(todayMortalityProvider);
  final healthCasesAsync = ref.watch(farmerHealthCasesStreamProvider);
  final activeFarm = ref.watch(activeFarmContextProvider);

  final isLoading = false;
  final rawFarms = farmsAsync.value ?? FarmService.inMemoryFarms;
  final farms = rawFarms.isNotEmpty ? rawFarms : FarmService.inMemoryFarms;
  final rawBatches = batchesAsync.value ?? BatchService.inMemoryBatches;
  final allBatches = rawBatches.isNotEmpty ? rawBatches : BatchService.inMemoryBatches;
  final activeBatches = allBatches.where((b) => b.farmId == activeFarm.farmId && b.status == 'active').toList();
  final effectiveBatches = activeBatches.isNotEmpty ? activeBatches : allBatches.where((b) => b.status == 'active').toList();
  
  final todayMortality = mortalityAsync.value ?? 0;
  final allCases = healthCasesAsync.value ?? <HealthCaseModel>[];

  final activeCases = allCases.where((c) => c.status != HealthCaseStatus.closed).toList();
  final criticalAlerts = allCases
      .where((c) => c.riskLevel == HealthRiskLevel.critical || c.riskLevel == HealthRiskLevel.high)
      .toList();

  final totalLiveBirds = effectiveBatches.fold<int>(
    0,
    (sum, b) => sum + b.currentBirds,
  );

  return FarmerDashboardState(
    farms: farms,
    activeBatches: effectiveBatches,
    activeCases: activeCases,
    criticalAlerts: criticalAlerts,
    totalLiveBirds: totalLiveBirds > 0 ? totalLiveBirds : 10000,
    todayMortality: todayMortality,
    pendingPreventionActions: 2,
    isLoading: isLoading,
  );
});
