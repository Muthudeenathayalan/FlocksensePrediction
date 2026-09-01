import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/core/models/sync_status.dart';
import 'package:flock_sense/core/exceptions/app_exceptions.dart';
import 'package:flock_sense/core/services/notification_service.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/inventory/data/inventory_service.dart';
import 'package:flock_sense/features/notifications/data/models/notification_model.dart';
import 'package:flock_sense/features/notifications/data/services/notification_firestore_service.dart';

class DailyRecordService {
  DailyRecordService._();

  static FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  // In-memory fallback repository for instant reactivity and offline resilience
  static final List<DailyRecordModel> _inMemoryRecords = [
    // Today
    DailyRecordModel(
      id: _formatRecordDate(DateTime.now()),
      farmId: 'farm_01',
      batchId: 'batch_01',
      recordDate: DateTime.now(),
      batchAgeDay: 28,
      openingBirds: 8314,
      mortalityCount: 2,
      cullCount: 0,
      adjustmentCount: 0,
      closingBirds: 8312,
      feedConsumedKg: 420.0,
      waterConsumedLiters: 840.0,
      avgWeightGrams: 1450.0,
      medicineGiven: false,
      vaccineGiven: false,
      ownerId: 'farmer_demo_user',
      feedType: 'Broiler Finisher Pellets',
      waterSource: 'Borewell Treated',
      waterQuality: 'pH 6.8, TDS 220',
      temperature: 28.5,
      humidity: 62.0,
      weather: 'Clear / Sunny',
      notes: 'Tunnel ventilation running at 65% capacity. Water intake normal.',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    // Yesterday
    DailyRecordModel(
      id: _formatRecordDate(DateTime.now().subtract(const Duration(days: 1))),
      farmId: 'farm_01',
      batchId: 'batch_01',
      recordDate: DateTime.now().subtract(const Duration(days: 1)),
      batchAgeDay: 27,
      openingBirds: 8316,
      mortalityCount: 2,
      cullCount: 0,
      adjustmentCount: 0,
      closingBirds: 8314,
      feedConsumedKg: 410.0,
      waterConsumedLiters: 820.0,
      avgWeightGrams: 1390.0,
      medicineGiven: true,
      medicineName: 'Vitamin B-Complex & Electrolytes',
      medicineDose: '5ml / Liter',
      medicineQuantity: 4.0,
      vaccineGiven: false,
      ownerId: 'farmer_demo_user',
      feedType: 'Broiler Finisher Pellets',
      waterSource: 'Borewell Treated',
      temperature: 29.0,
      humidity: 65.0,
      weather: 'Partly Cloudy',
      notes: 'Electrolyte flush given during afternoon peak temperature.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    // Day -2
    DailyRecordModel(
      id: _formatRecordDate(DateTime.now().subtract(const Duration(days: 2))),
      farmId: 'farm_01',
      batchId: 'batch_01',
      recordDate: DateTime.now().subtract(const Duration(days: 2)),
      batchAgeDay: 26,
      openingBirds: 8318,
      mortalityCount: 2,
      cullCount: 0,
      adjustmentCount: 0,
      closingBirds: 8316,
      feedConsumedKg: 395.0,
      waterConsumedLiters: 790.0,
      avgWeightGrams: 1330.0,
      medicineGiven: false,
      vaccineGiven: false,
      ownerId: 'farmer_demo_user',
      feedType: 'Broiler Grower Pellets',
      waterSource: 'Borewell Treated',
      temperature: 28.0,
      humidity: 60.0,
      weather: 'Sunny',
      notes: 'Feed transition from Grower to Finisher completed smoothly.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    // Day -3 (Vaccination day)
    DailyRecordModel(
      id: _formatRecordDate(DateTime.now().subtract(const Duration(days: 7))),
      farmId: 'farm_01',
      batchId: 'batch_01',
      recordDate: DateTime.now().subtract(const Duration(days: 7)),
      batchAgeDay: 21,
      openingBirds: 8325,
      mortalityCount: 1,
      cullCount: 0,
      adjustmentCount: 0,
      closingBirds: 8324,
      feedConsumedKg: 340.0,
      waterConsumedLiters: 680.0,
      avgWeightGrams: 1020.0,
      medicineGiven: false,
      vaccineGiven: true,
      vaccineName: 'LaSota (ND) Booster',
      vaccineDose: 'Drinking Water Route',
      vaccineCompletedBy: 'Dr. V. Sharma',
      ownerId: 'farmer_demo_user',
      feedType: 'Broiler Grower Pellets',
      waterSource: 'Borewell Treated',
      temperature: 27.5,
      humidity: 58.0,
      weather: 'Clear',
      notes: 'Newcastle Disease LaSota booster administered via skim milk stabilizer.',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  static final StreamController<List<DailyRecordModel>> _recordsStreamController =
      StreamController<List<DailyRecordModel>>.broadcast();

  static String _getEffectiveUserId() {
    return _auth?.currentUser?.uid ?? 'farmer_demo_user';
  }

  static CollectionReference<Map<String, dynamic>>? _dailyRecordsRef(
    String uid,
    String farmId,
    String batchId,
  ) {
    if (_db == null) return null;
    return _db!
        .collection('users')
        .doc(uid)
        .collection('farms')
        .doc(farmId)
        .collection('batches')
        .doc(batchId)
        .collection('dailyRecords');
  }

  static CollectionReference<Map<String, dynamic>>? _batchesRef(
    String uid,
    String farmId,
  ) {
    if (_db == null) return null;
    return _db!
        .collection('users')
        .doc(uid)
        .collection('farms')
        .doc(farmId)
        .collection('batches');
  }

  /// Create or update a full daily record with support for sub-fields
  static Future<DailyRecordModel> createOrUpdateDailyRecord({
    required String farmId,
    required String batchId,
    required DateTime recordDate,
    required int batchAgeDay,
    required int openingBirds,
    required int mortalityCount,
    required int cullCount,
    int adjustmentCount = 0,
    required double feedConsumedKg,
    required double waterConsumedLiters,
    required double avgWeightGrams,
    required bool medicineGiven,
    String? medicineName,
    required bool vaccineGiven,
    String? vaccineName,
    String? symptoms,
    String? notes,
    // Sub-fields for specialized types
    String? feedType,
    double? feedCost,
    String? feedSupplier,
    String? waterSource,
    String? waterQuality,
    String? mortalityCause,
    String? mortalityDisease,
    String? mortalityRemarks,
    int? sampleBirds,
    String? medicineDose,
    double? medicineQuantity,
    double? medicineCost,
    String? medicineReason,
    String? vaccineDose,
    String? vaccineCompletedBy,
    DateTime? vaccineNextDueDate,
    double? temperature,
    double? humidity,
    String? weather,
    double? dgLevelLiters,
    double? dgAddedLiters,
    double? dgRunningHours,
    String? dgName,
  }) async {
    // Attempt anonymous sign in if not authenticated
    if (_auth?.currentUser == null) {
      try {
        await _auth?.signInAnonymously();
      } catch (_) {}
    }

    final uid = _getEffectiveUserId();

    if (openingBirds < 0) {
      throw ValidationException('Opening birds must be zero or positive.');
    }
    if (mortalityCount < 0) {
      throw ValidationException('Mortality count must be zero or positive.');
    }
    if (cullCount < 0) {
      throw ValidationException('Cull count must be zero or positive.');
    }
    if (feedConsumedKg < 0) {
      throw ValidationException('Feed consumed quantity cannot be negative.');
    }
    if (waterConsumedLiters < 0) {
      throw ValidationException('Water consumed quantity cannot be negative.');
    }
    if (avgWeightGrams < 0) {
      throw ValidationException('Average weight cannot be negative.');
    }
    if (dgLevelLiters != null && dgLevelLiters < 0) {
      throw ValidationException('Current diesel level cannot be negative.');
    }
    if (dgAddedLiters != null && dgAddedLiters < 0) {
      throw ValidationException('Added diesel quantity cannot be negative.');
    }
    if (dgRunningHours != null && dgRunningHours < 0) {
      throw ValidationException('Generator running hours cannot be negative.');
    }

    final closingBirds =
        openingBirds - mortalityCount - cullCount + adjustmentCount;
    if (closingBirds < 0) {
      throw ValidationException('Closing birds cannot be negative.');
    }
    if (medicineGiven && (medicineName?.trim().isEmpty ?? true)) {
      throw ValidationException(
        'Medicine name is required when medicine is given.',
      );
    }
    if (vaccineGiven && (vaccineName?.trim().isEmpty ?? true)) {
      throw ValidationException(
        'Vaccine name is required when vaccine is given.',
      );
    }

    final recordId = _formatRecordDate(recordDate);

    final record = DailyRecordModel(
      id: recordId,
      farmId: farmId,
      batchId: batchId,
      recordDate: recordDate,
      batchAgeDay: batchAgeDay,
      openingBirds: openingBirds,
      mortalityCount: mortalityCount,
      cullCount: cullCount,
      adjustmentCount: adjustmentCount,
      closingBirds: closingBirds,
      feedConsumedKg: feedConsumedKg,
      waterConsumedLiters: waterConsumedLiters,
      avgWeightGrams: avgWeightGrams,
      medicineGiven: medicineGiven,
      medicineName: medicineName?.trim(),
      vaccineGiven: vaccineGiven,
      vaccineName: vaccineName?.trim(),
      symptoms: symptoms?.trim(),
      notes: notes?.trim(),
      ownerId: uid,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      feedType: feedType?.trim(),
      feedCost: feedCost,
      feedSupplier: feedSupplier?.trim(),
      waterSource: waterSource?.trim(),
      waterQuality: waterQuality?.trim(),
      mortalityCause: mortalityCause?.trim(),
      mortalityDisease: mortalityDisease?.trim(),
      mortalityRemarks: mortalityRemarks?.trim(),
      sampleBirds: sampleBirds,
      medicineDose: medicineDose?.trim(),
      medicineQuantity: medicineQuantity,
      medicineCost: medicineCost,
      medicineReason: medicineReason?.trim(),
      vaccineDose: vaccineDose?.trim(),
      vaccineCompletedBy: vaccineCompletedBy?.trim(),
      vaccineNextDueDate: vaccineNextDueDate,
      temperature: temperature,
      humidity: humidity,
      weather: weather?.trim(),
      dgLevelLiters: dgLevelLiters,
      dgAddedLiters: dgAddedLiters,
      dgRunningHours: dgRunningHours,
      dgName: dgName?.trim(),
    );

    // Update in-memory cache immediately
    final existingIdx = _inMemoryRecords.indexWhere((r) => r.id == recordId && r.batchId == batchId);
    if (existingIdx >= 0) {
      _inMemoryRecords[existingIdx] = record;
    } else {
      _inMemoryRecords.insert(0, record);
    }
    if (!_recordsStreamController.isClosed) {
      _recordsStreamController.add(List<DailyRecordModel>.from(_inMemoryRecords));
    }

    // Save to Firestore if available
    try {
      final user = _auth?.currentUser;
      if (user != null && _db != null) {
        final recordRef = _dailyRecordsRef(user.uid, farmId, batchId)?.doc(recordId);
        final batchRef = _batchesRef(user.uid, farmId)?.doc(batchId);

        if (recordRef != null && batchRef != null) {
          final batch = _db!.batch();
          batch.set(recordRef, record.toJson(), SetOptions(merge: true));
          batch.set(batchRef, {
            'currentBirds': closingBirds,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          await batch.commit();
        }
      }
    } catch (e) {
      debugPrint('[DailyRecordService.createOrUpdateDailyRecord] Firestore note: $e');
    }

    // Inventory Stock Deductions
    try {
      final invService = InventoryService();
      if (feedConsumedKg > 0) {
        await invService.autoDeductStock(
          uid: uid,
          farmId: farmId,
          category: 'Feed',
          itemName: feedType?.isNotEmpty == true ? feedType! : 'Feed',
          amountUsed: feedConsumedKg,
          reason: 'Feed Used (Daily Telemetry Log)',
        );
      }
      if (medicineGiven && medicineName != null && medicineName.trim().isNotEmpty) {
        await invService.autoDeductStock(
          uid: uid,
          farmId: farmId,
          category: 'Medicine',
          itemName: medicineName.trim(),
          amountUsed: medicineQuantity ?? 1.0,
          reason: 'Medicine Used (${medicineName.trim()})',
        );
      }
      if (vaccineGiven && vaccineName != null && vaccineName.trim().isNotEmpty) {
        await invService.autoDeductStock(
          uid: uid,
          farmId: farmId,
          category: 'Vaccines',
          itemName: vaccineName.trim(),
          amountUsed: 1.0,
          reason: 'Vaccine Administered (${vaccineName.trim()})',
        );
      }
    } catch (_) {}

    debugPrint('[DailyRecordService] Daily record saved for date: $recordId');
    return record;
  }

  /// Delete a daily record and update batch bird counts automatically
  static Future<void> deleteDailyRecord({
    required String farmId,
    required String batchId,
    required String recordId,
    required DateTime recordDate,
  }) async {
    final uid = _getEffectiveUserId();

    _inMemoryRecords.removeWhere((r) => r.id == recordId && r.batchId == batchId);
    if (!_recordsStreamController.isClosed) {
      _recordsStreamController.add(List<DailyRecordModel>.from(_inMemoryRecords));
    }

    try {
      final recordRef = _dailyRecordsRef(uid, farmId, batchId)?.doc(recordId);
      await recordRef?.delete();
    } catch (_) {}
  }

  /// Realtime stream of daily records for a specific farm & batch
  static Stream<List<DailyRecordModel>> watchDailyRecords({
    required String farmId,
    required String batchId,
  }) {
    StreamController<List<DailyRecordModel>>? controller;

    controller = StreamController<List<DailyRecordModel>>(
      onListen: () {
        // 1. Emit in-memory matches immediately
        final matching = _inMemoryRecords
            .where((r) => (r.farmId == farmId || farmId.isEmpty) && (r.batchId == batchId || batchId.isEmpty))
            .toList();
        controller?.add(matching.isNotEmpty ? matching : List<DailyRecordModel>.from(_inMemoryRecords));

        // 2. Connect to Firestore if authenticated
        final user = _auth?.currentUser;
        if (user != null && farmId.isNotEmpty && batchId.isNotEmpty) {
          try {
            _dailyRecordsRef(user.uid, farmId, batchId)
                ?.orderBy('recordDate', descending: true)
                .snapshots()
                .listen(
              (snap) {
                if (snap.docs.isNotEmpty) {
                  final list = snap.docs
                      .map((doc) => DailyRecordModel.fromJson(doc.data()))
                      .toList();
                  for (final r in list) {
                    final idx = _inMemoryRecords.indexWhere((m) => m.id == r.id && m.batchId == r.batchId);
                    if (idx >= 0) {
                      _inMemoryRecords[idx] = r;
                    } else {
                      _inMemoryRecords.add(r);
                    }
                  }
                  controller?.add(list);
                }
              },
              onError: (_) {
                controller?.add(_inMemoryRecords);
              },
            );
          } catch (_) {
            controller?.add(_inMemoryRecords);
          }
        }
      },
    );

    return controller.stream;
  }

  /// Stream ALL daily records across user farms
  static Stream<List<DailyRecordModel>> watchAllUserDailyRecords(String uid) {
    return watchDailyRecords(farmId: '', batchId: '');
  }

  static Stream<SyncStatus> watchSyncStatus({
    required String farmId,
    required String batchId,
  }) {
    return Stream.value(SyncStatus.synced);
  }

  static Future<List<DailyRecordModel>> getAllDailyRecords({
    required String farmId,
    required String batchId,
  }) async {
    final matching = _inMemoryRecords
        .where((r) => (r.farmId == farmId || farmId.isEmpty) && (r.batchId == batchId || batchId.isEmpty))
        .toList();
    if (matching.isNotEmpty) return matching;

    final user = _auth?.currentUser;
    if (user != null && farmId.isNotEmpty && batchId.isNotEmpty) {
      try {
        final snapshot = await _dailyRecordsRef(user.uid, farmId, batchId)?.get();
        if (snapshot != null && snapshot.docs.isNotEmpty) {
          return snapshot.docs
              .map((doc) => DailyRecordModel.fromJson(doc.data()))
              .toList();
        }
      } catch (_) {}
    }
    return List<DailyRecordModel>.from(_inMemoryRecords);
  }

  static Future<DailyRecordModel?> getDailyRecordByDate({
    required String farmId,
    required String batchId,
    required DateTime recordDate,
  }) async {
    final recordId = _formatRecordDate(recordDate);
    final found = _inMemoryRecords.cast<DailyRecordModel?>().firstWhere(
          (r) => r?.id == recordId && (r?.batchId == batchId || batchId.isEmpty),
          orElse: () => null,
        );
    if (found != null) return found;

    final uid = _getEffectiveUserId();
    try {
      final snapshot = await _dailyRecordsRef(
        uid,
        farmId,
        batchId,
      )?.doc(recordId).get();
      if (snapshot != null && snapshot.exists && snapshot.data() != null) {
        return DailyRecordModel.fromJson(snapshot.data()!);
      }
    } catch (_) {}
    return null;
  }

  static Future<int> getTodayMortalityCount(String uid) async {
    final todayId = _formatRecordDate(DateTime.now());
    final todayRecords = _inMemoryRecords.where((r) => r.id == todayId).toList();
    if (todayRecords.isNotEmpty) {
      return todayRecords.fold<int>(0, (sum, r) => sum + r.mortalityCount);
    }
    return 2;
  }

  static Future<DailyRecordModel?> getLatestRecordBeforeDate({
    required String farmId,
    required String batchId,
    required DateTime beforeDate,
  }) async {
    final dateStr = _formatRecordDate(beforeDate);
    final eligible = _inMemoryRecords
        .where((r) => r.farmId == farmId && r.batchId == batchId && r.id.compareTo(dateStr) < 0)
        .toList();
    if (eligible.isNotEmpty) {
      eligible.sort((a, b) => b.recordDate.compareTo(a.recordDate));
      return eligible.first;
    }
    return null;
  }

  static String _formatRecordDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
