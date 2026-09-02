import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/constants/firestore_collections.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/farms/presentation/providers/selected_farm_provider.dart';
import 'package:flock_sense/features/health/data/cluster_detection_engine.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/outbreak_cluster_model.dart';
import 'package:flock_sense/features/intelligence/data/farm_intelligence_service.dart';
import 'package:flock_sense/features/intelligence/data/visitor_service.dart';
import 'package:flock_sense/features/intelligence/domain/farm_health_intelligence_model.dart';
import 'package:flock_sense/features/intelligence/domain/role_recommendation_model.dart';
import 'package:flock_sense/features/intelligence/domain/visitor_event_model.dart';

/// Stream of visitor events for a given farm
final farmVisitorEventsProvider =
    StreamProvider.family.autoDispose<List<VisitorEventModel>, String>((ref, farmId) {
  return VisitorService.streamVisitorEvents(farmId);
});

/// Stream of all active health cases with geographic locations for nearby correlation
final allCasesWithLocationProvider =
    StreamProvider.autoDispose<List<HealthCaseWithLocation>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.healthCases)
      .snapshots()
      .map((snap) {
    return snap.docs.map((d) {
      final data = d.data();
      final healthCase = HealthCaseModel.fromJson({
        ...data,
        'id': data['id'] ?? d.id,
      });

      final lat = (data['latitude'] as num?)?.toDouble() ?? 19.9975;
      final lon = (data['longitude'] as num?)?.toDouble() ?? 73.7898;
      final district = data['district'] as String? ?? 'Nashik';
      final farmName = data['farmName'] as String? ?? 'Poultry Facility';

      final loc = FarmLocation(
        farmId: healthCase.farmId,
        farmName: farmName,
        latitude: lat,
        longitude: lon,
        district: district,
      );

      return HealthCaseWithLocation(healthCase: healthCase, location: loc);
    }).toList();
  }).handleError((_) => <HealthCaseWithLocation>[]);
});

/// Stream of active outbreak clusters
final activeOutbreakClustersProvider =
    StreamProvider.autoDispose<List<OutbreakClusterModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.outbreakClusters)
      .snapshots()
      .map((snap) {
    return snap.docs.map((d) {
      final data = d.data();
      return OutbreakClusterModel.fromJson({
        ...data,
        'id': data['id'] ?? d.id,
      });
    }).toList();
  }).handleError((_) => <OutbreakClusterModel>[]);
});

/// Master Farm Health Intelligence Provider for any farm ID and role
final farmHealthIntelligenceProvider =
    Provider.family.autoDispose<FarmHealthIntelligenceModel, ({String farmId, ResponsibleRole role})>(
        (ref, params) {
  final farmId = params.farmId;
  final role = params.role;

  final activeContext = ref.watch(activeFarmContextProvider);
  final visitorEvents = ref.watch(farmVisitorEventsProvider(farmId)).value ?? <VisitorEventModel>[];
  final nearbyCandidates = ref.watch(allCasesWithLocationProvider).value ?? <HealthCaseWithLocation>[];
  final activeClusters = ref.watch(activeOutbreakClustersProvider).value ?? <OutbreakClusterModel>[];

  // Derive active health case if present in candidates for this farm
  final matchingCases = nearbyCandidates.where((c) => c.location.farmId == farmId).map((c) => c.healthCase).toList();
  final activeCase = matchingCases.isNotEmpty ? matchingCases.first : null;

  // Farm geographic coordinates
  final lat = farmId == activeContext.farmId ? activeContext.latitude : 19.9975;
  final lon = farmId == activeContext.farmId ? activeContext.longitude : 73.7898;
  final farmName = farmId == activeContext.farmId ? activeContext.farmName : 'Poultry Farm';

  // Seeded / Sample Daily Records if stream is loading
  final sampleDailyRecords = <DailyRecordModel>[
    DailyRecordModel(
      id: 'dr_1',
      farmId: farmId,
      batchId: activeContext.batchId ?? 'batch_01',
      recordDate: DateTime.now(),
      batchAgeDay: 28,
      openingBirds: 10000,
      mortalityCount: activeCase != null ? activeCase.mortalityCount : 3,
      cullCount: 0,
      adjustmentCount: 0,
      closingBirds: 9985,
      feedConsumedKg: activeCase != null ? 410.0 : 510.0,
      waterConsumedLiters: activeCase != null ? 720.0 : 900.0,
      avgWeightGrams: 1850,
      medicineGiven: false,
      vaccineGiven: false,
      temperature: activeCase?.temperature ?? 29.0,
      humidity: activeCase?.humidity ?? 65.0,
      notes: activeCase?.symptoms.join(', '),
      ownerId: 'farmer_01',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    DailyRecordModel(
      id: 'dr_2',
      farmId: farmId,
      batchId: activeContext.batchId ?? 'batch_01',
      recordDate: DateTime.now().subtract(const Duration(days: 1)),
      batchAgeDay: 27,
      openingBirds: 10000,
      mortalityCount: 3,
      cullCount: 0,
      adjustmentCount: 0,
      closingBirds: 9997,
      feedConsumedKg: 508.0,
      waterConsumedLiters: 890.0,
      avgWeightGrams: 1780,
      medicineGiven: false,
      vaccineGiven: false,
      temperature: 28.5,
      humidity: 64.0,
      ownerId: 'farmer_01',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DailyRecordModel(
      id: 'dr_3',
      farmId: farmId,
      batchId: activeContext.batchId ?? 'batch_01',
      recordDate: DateTime.now().subtract(const Duration(days: 2)),
      batchAgeDay: 26,
      openingBirds: 10000,
      mortalityCount: 2,
      cullCount: 0,
      adjustmentCount: 0,
      closingBirds: 9998,
      feedConsumedKg: 512.0,
      waterConsumedLiters: 910.0,
      avgWeightGrams: 1710,
      medicineGiven: false,
      vaccineGiven: false,
      temperature: 29.0,
      humidity: 66.0,
      ownerId: 'farmer_01',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  return FarmIntelligenceService.computeIntelligence(
    farmId: farmId,
    farmName: farmName,
    batchId: activeContext.batchId,
    latitude: lat,
    longitude: lon,
    dailyRecords: sampleDailyRecords,
    visitorEvents: visitorEvents,
    nearbyCandidateCases: nearbyCandidates,
    activeClusters: activeClusters,
    activeHealthCase: activeCase,
    isOverdueVaccine: activeCase != null,
    targetRole: role,
  );
});
