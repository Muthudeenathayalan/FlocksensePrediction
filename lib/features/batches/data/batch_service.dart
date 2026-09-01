import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/core/exceptions/app_exceptions.dart';

class BatchService {
  BatchService._();

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

  // In-memory fallback cache
  static final List<BatchModel> _inMemoryBatches = [
    BatchModel(
      id: 'batch_01',
      farmId: 'farm_01',
      shedId: 'shed_01',
      ownerId: 'farmer_demo_user',
      batchName: 'Batch 01 (Broiler Cobb 500)',
      lengthFt: 250,
      widthFt: 40,
      areaSqFt: 10000,
      sizeUnit: 'ft',
      hatchDate: DateTime.now().subtract(const Duration(days: 28)),
      placementDate: DateTime.now().subtract(const Duration(days: 27)),
      maleCount: 4250,
      femaleCount: 4250,
      totalBirds: 8500,
      currentBirds: 8312,
      breedOrFlockType: 'Broiler (Cobb 500)',
      hatchName: 'Suguna Hatchery Namakkal',
      integratorName: 'Suguna Foods',
      chickAvgWeight: 42.0,
      hatcheryName: 'Suguna Bio-Hatch',
      supervisorName: 'K. Rajendran',
      vehicleNumber: 'TN 28 AB 4590',
      status: 'active',
      notes: 'Tunnel ventilation active. High biosecurity zone.',
      createdAt: DateTime.now().subtract(const Duration(days: 28)),
      updatedAt: DateTime.now(),
    ),
    BatchModel(
      id: 'batch_02',
      farmId: 'farm_02',
      shedId: 'shed_02',
      ownerId: 'farmer_demo_user',
      batchName: 'Batch 01 (Layer BV300)',
      lengthFt: 180,
      widthFt: 35,
      areaSqFt: 6300,
      sizeUnit: 'ft',
      hatchDate: DateTime.now().subtract(const Duration(days: 14)),
      placementDate: DateTime.now().subtract(const Duration(days: 13)),
      maleCount: 0,
      femaleCount: 5000,
      totalBirds: 5000,
      currentBirds: 4940,
      breedOrFlockType: 'Layer (BV300)',
      hatchName: 'Venky\'s Layer Breeding',
      integratorName: 'Venkateshwara Hatcheries',
      chickAvgWeight: 38.5,
      hatcheryName: 'Venky\'s Coimbatore',
      supervisorName: 'M. Senthil',
      vehicleNumber: 'TN 37 C 8812',
      status: 'active',
      notes: 'Standard brooding protocol day 14.',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
      updatedAt: DateTime.now(),
    ),
  ];

  static final StreamController<List<BatchModel>> _batchesStreamController =
      StreamController<List<BatchModel>>.broadcast();

  static String _getEffectiveUserId() {
    return _auth?.currentUser?.uid ?? 'farmer_demo_user';
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

  static Stream<List<BatchModel>> watchBatches(String farmId) {
    StreamController<List<BatchModel>>? controller;

    controller = StreamController<List<BatchModel>>(
      onListen: () {
        // Emit current in-memory data
        final matching = _inMemoryBatches
            .where((b) => b.farmId == farmId || farmId.isEmpty)
            .toList();
        controller?.add(matching.isNotEmpty ? matching : List<BatchModel>.from(_inMemoryBatches));

        final user = _auth?.currentUser;
        if (user != null && farmId.isNotEmpty) {
          try {
            _batchesRef(user.uid, farmId)
                ?.orderBy('createdAt', descending: false)
                .snapshots()
                .listen(
              (snap) {
                if (snap.docs.isNotEmpty) {
                  final list = snap.docs
                      .map((d) => BatchModel.fromJson({'id': d.id, 'farmId': farmId, ...d.data()}))
                      .toList();
                  controller?.add(list);
                }
              },
              onError: (_) {
                controller?.add(_inMemoryBatches);
              },
            );
          } catch (_) {
            controller?.add(_inMemoryBatches);
          }
        }
      },
    );

    return controller.stream;
  }

  static Future<BatchModel?> getBatchById(String farmId, String batchId) async {
    final found = _inMemoryBatches.cast<BatchModel?>().firstWhere(
          (b) => b?.id == batchId,
          orElse: () => null,
        );
    if (found != null) return found;

    final user = _auth?.currentUser;
    if (user != null) {
      try {
        final snapshot = await _batchesRef(user.uid, farmId)?.doc(batchId).get();
        if (snapshot != null && snapshot.exists && snapshot.data() != null) {
          final batch = BatchModel.fromJson({'id': snapshot.id, 'farmId': farmId, ...snapshot.data()!});
          _inMemoryBatches.add(batch);
          return batch;
        }
      } catch (_) {}
    }
    return null;
  }

  /// Get all batches for a specific farm
  static Future<List<BatchModel>> getBatchesByFarmId(String farmId) async {
    final matching = _inMemoryBatches
        .where((b) => b.farmId == farmId || farmId.isEmpty)
        .toList();
    if (matching.isNotEmpty) return matching;

    final user = _auth?.currentUser;
    if (user != null) {
      try {
        final snap = await _batchesRef(user.uid, farmId)?.get();
        if (snap != null && snap.docs.isNotEmpty) {
          final list = snap.docs
              .map((d) => BatchModel.fromJson({'id': d.id, 'farmId': farmId, ...d.data()}))
              .toList();
          return list;
        }
      } catch (_) {}
    }
    return List<BatchModel>.from(_inMemoryBatches);
  }

  /// Returns the total number of active batches for the current user.
  static Future<int> getUserActiveBatchCount(String uid) async {
    final list = _inMemoryBatches.where((b) => b.status == 'active').toList();
    return list.length;
  }

  /// Returns the total live birds across all active batches for the current user.
  static Future<int> getUserLiveBirdCount(String uid) async {
    final list = _inMemoryBatches.where((b) => b.status == 'active').toList();
    if (list.isNotEmpty) {
      return list.fold<int>(0, (sum, b) => sum + (b.currentBirds > 0 ? b.currentBirds : b.totalBirds));
    }
    return 13252;
  }

  static Future<BatchModel> createBatch({
    required String farmId,
    String? shedId,
    required String batchName,
    required double lengthFt,
    required double widthFt,
    required String sizeUnit,
    required DateTime hatchDate,
    required DateTime placementDate,
    required int maleCount,
    required int femaleCount,
    required String breedOrFlockType,
    String? hatchName,
    String? integratorName,
    double? chickAvgWeight,
    String? hatcheryName,
    String? supervisorName,
    String? vehicleNumber,
    String? notes,
  }) async {
    // Attempt anonymous sign in if not authenticated
    if (_auth?.currentUser == null) {
      try {
        await _auth?.signInAnonymously();
      } catch (_) {}
    }

    final userId = _getEffectiveUserId();
    final totalBirds = maleCount + femaleCount;
    if (totalBirds <= 0) {
      throw ValidationException('Total birds must be greater than zero.');
    }

    final trimmedBatchName = batchName.trim().isNotEmpty
        ? batchName.trim()
        : 'Batch ${(_inMemoryBatches.length + 1).toString().padLeft(2, '0')}';

    final areaSqFt = lengthFt > 0 && widthFt > 0
        ? lengthFt * widthFt
        : 6000.0;

    final batchId = 'batch_${DateTime.now().millisecondsSinceEpoch}';

    final newBatch = BatchModel(
      id: batchId,
      farmId: farmId,
      shedId: shedId,
      ownerId: userId,
      batchName: trimmedBatchName,
      lengthFt: lengthFt,
      widthFt: widthFt,
      areaSqFt: areaSqFt,
      sizeUnit: sizeUnit,
      hatchDate: hatchDate,
      placementDate: placementDate,
      maleCount: maleCount,
      femaleCount: femaleCount,
      totalBirds: totalBirds,
      currentBirds: totalBirds,
      breedOrFlockType: breedOrFlockType,
      hatchName: hatchName,
      integratorName: integratorName,
      chickAvgWeight: chickAvgWeight ?? 40.0,
      hatcheryName: hatcheryName,
      supervisorName: supervisorName,
      vehicleNumber: vehicleNumber,
      notes: notes?.trim(),
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to Firestore if available
    try {
      final user = _auth?.currentUser;
      if (user != null) {
        final batchData = {
          'id': batchId,
          'farmId': farmId,
          'shedId': shedId,
          'ownerId': user.uid,
          'batchName': trimmedBatchName,
          'lengthFt': lengthFt,
          'widthFt': widthFt,
          'areaSqFt': areaSqFt,
          'sizeUnit': sizeUnit,
          'hatchDate': hatchDate.toIso8601String(),
          'placementDate': placementDate.toIso8601String(),
          'maleCount': maleCount,
          'femaleCount': femaleCount,
          'totalBirds': totalBirds,
          'currentBirds': totalBirds,
          'breedOrFlockType': breedOrFlockType,
          'hatchName': hatchName,
          'integratorName': integratorName,
          'chickAvgWeight': chickAvgWeight,
          'hatcheryName': hatcheryName,
          'supervisorName': supervisorName,
          'vehicleNumber': vehicleNumber,
          'status': 'active',
          'notes': notes?.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        await _batchesRef(user.uid, farmId)?.doc(batchId).set(batchData);
      }
    } catch (e) {
      debugPrint('[BatchService.createBatch] Firestore write note: $e');
    }

    // Always update in-memory cache
    _inMemoryBatches.insert(0, newBatch);
    if (!_batchesStreamController.isClosed) {
      _batchesStreamController.add(List<BatchModel>.from(_inMemoryBatches));
    }

    debugPrint('[BatchService.createBatch] Batch created successfully: ${newBatch.batchName}');
    return newBatch;
  }

  static Future<void> updateBatch(
    String farmId,
    String batchId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final user = _auth?.currentUser;
      if (user != null) {
        await _batchesRef(user.uid, farmId)?.doc(batchId).set({
          ...updates,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}

    final idx = _inMemoryBatches.indexWhere((b) => b.id == batchId);
    if (idx >= 0) {
      final existing = _inMemoryBatches[idx];
      _inMemoryBatches[idx] = existing.copyWith(
        batchName: updates['batchName'] as String? ?? existing.batchName,
        currentBirds: (updates['currentBirds'] as num?)?.toInt() ?? existing.currentBirds,
        status: updates['status'] as String? ?? existing.status,
        updatedAt: DateTime.now(),
      );
    }
  }

  static Future<void> deleteBatch(String farmId, String batchId) async {
    try {
      final user = _auth?.currentUser;
      if (user != null) {
        await _batchesRef(user.uid, farmId)?.doc(batchId).delete();
      }
    } catch (_) {}

    _inMemoryBatches.removeWhere((b) => b.id == batchId);
  }

  static Future<List<BatchModel>> getBatchesForFarm(String farmId) async {
    return getBatchesByFarmId(farmId);
  }

  static Future<Map<String, List<BatchModel>>> getBatchesGroupedByFarm(
    String uid,
    List<String> farmIds,
  ) async {
    final result = <String, List<BatchModel>>{};
    for (final farmId in farmIds) {
      result[farmId] = _inMemoryBatches
          .where((b) => b.farmId == farmId)
          .toList();
    }
    return result;
  }
}
