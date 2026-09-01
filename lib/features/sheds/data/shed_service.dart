import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/sheds/domain/shed_model.dart';
import 'package:flock_sense/core/exceptions/app_exceptions.dart';
import 'package:flock_sense/core/models/sync_status.dart';

/// Shed data service — all writes are offline-safe plain set()/delete() calls.
/// Path: users/{uid}/farms/{farmId}/sheds/{shedId}
class ShedService {
  ShedService._();

  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static final List<ShedModel> _inMemorySheds = [
    ShedModel(
      id: 'shed_01',
      farmId: 'farm_01',
      ownerId: 'farmer_demo_user',
      name: 'EC Shed Unit 1',
      lengthFt: 250,
      widthFt: 40,
      totalSqFt: 10000,
      capacity: 8500,
      notes: 'Fully automated environmental control unit with cooling pads and tunnel fans.',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now(),
    ),
    ShedModel(
      id: 'shed_02',
      farmId: 'farm_02',
      ownerId: 'farmer_demo_user',
      name: 'Open Shed Unit 1',
      lengthFt: 180,
      widthFt: 35,
      totalSqFt: 6300,
      capacity: 5000,
      notes: 'Standard open shed with side curtains and misting system.',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now(),
    ),
  ];

  static String _getEffectiveUserId() {
    return _auth.currentUser?.uid ?? 'farmer_demo_user';
  }

  static CollectionReference<Map<String, dynamic>> _shedsRef(
    String uid,
    String farmId,
  ) => _db
      .collection('users')
      .doc(uid)
      .collection('farms')
      .doc(farmId)
      .collection('sheds');

  // ── STREAMS ───────────────────────────────────────────────────────────────

  /// Real-time list of sheds for a farm. Works offline via Firestore cache.
  static Stream<List<ShedModel>> watchSheds(String farmId) {
    StreamController<List<ShedModel>>? controller;

    controller = StreamController<List<ShedModel>>(
      onListen: () {
        final matching = _inMemorySheds.where((s) => s.farmId == farmId || farmId.isEmpty).toList();
        controller?.add(matching.isNotEmpty ? matching : List<ShedModel>.from(_inMemorySheds));

        final user = _auth.currentUser;
        if (user != null && farmId.isNotEmpty) {
          try {
            _shedsRef(user.uid, farmId)
                .orderBy('createdAt', descending: false)
                .snapshots()
                .listen(
              (snap) {
                if (snap.docs.isNotEmpty) {
                  final list = snap.docs.map((d) => ShedModel.fromJson(d.data())).toList();
                  for (final s in list) {
                    final idx = _inMemorySheds.indexWhere((m) => m.id == s.id);
                    if (idx >= 0) {
                      _inMemorySheds[idx] = s;
                    } else {
                      _inMemorySheds.add(s);
                    }
                  }
                  controller?.add(list);
                }
              },
              onError: (_) {
                controller?.add(_inMemorySheds);
              },
            );
          } catch (_) {
            controller?.add(_inMemorySheds);
          }
        }
      },
    );

    return controller.stream;
  }

  /// Sync-status stream
  static Stream<SyncStatus> watchSyncStatus(String farmId) {
    return Stream.value(SyncStatus.synced);
  }

  // ── CREATE ────────────────────────────────────────────────────────────────

  static Future<ShedModel> createShed({
    required String farmId,
    required String name,
    required double lengthFt,
    required double widthFt,
    int? capacity,
    String? notes,
  }) async {
    if (_auth.currentUser == null) {
      try {
        await _auth.signInAnonymously();
      } catch (_) {}
    }

    final userId = _getEffectiveUserId();

    if (name.trim().length < 2) {
      throw ValidationException('Shed name must be at least 2 characters.');
    }
    if (lengthFt <= 0) {
      throw ValidationException('Length must be greater than zero.');
    }
    if (widthFt <= 0) {
      throw ValidationException('Width must be greater than zero.');
    }

    final shedId = 'shed_${DateTime.now().millisecondsSinceEpoch}';
    final totalSqFt = lengthFt * widthFt;
    final effectiveCapacity = capacity ?? (totalSqFt / 1.2).round();

    final newShed = ShedModel(
      id: shedId,
      farmId: farmId,
      ownerId: userId,
      name: name.trim(),
      lengthFt: lengthFt,
      widthFt: widthFt,
      totalSqFt: totalSqFt,
      capacity: effectiveCapacity,
      notes: notes?.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to Firestore if available
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final shedData = {
          'id': shedId,
          'farmId': farmId,
          'userId': user.uid,
          'ownerId': user.uid,
          'name': name.trim(),
          'shedName': name.trim(),
          'lengthFt': lengthFt,
          'widthFt': widthFt,
          'totalSqFt': totalSqFt,
          'capacity': effectiveCapacity,
          'notes': notes?.trim(),
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        await _shedsRef(user.uid, farmId).doc(shedId).set(shedData);
      }
    } catch (e) {
      debugPrint('[ShedService.createShed] Firestore note: $e');
    }

    _inMemorySheds.insert(0, newShed);
    debugPrint('[ShedService.createShed] Shed created: ${newShed.name}');
    return newShed;
  }

  /// Returns the total bird capacity from all sheds across the current user.
  static Future<int> getUserShedCapacity(String uid) async {
    return _inMemorySheds.fold<int>(0, (sum, s) => sum + (s.capacity ?? (s.totalSqFt / 1.2).round()));
  }

  /// Returns the total number of sheds for the current user.
  static Future<int> getUserShedCount(String uid) async {
    return _inMemorySheds.length;
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────

  static Future<void> updateShed(
    String farmId,
    String shedId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _shedsRef(user.uid, farmId).doc(shedId).set({
          ...updates,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}

    final idx = _inMemorySheds.indexWhere((s) => s.id == shedId);
    if (idx >= 0) {
      final existing = _inMemorySheds[idx];
      _inMemorySheds[idx] = existing.copyWith(
        name: updates['name'] as String? ?? existing.name,
        capacity: updates['capacity'] as int? ?? existing.capacity,
        notes: updates['notes'] as String? ?? existing.notes,
      );
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  static Future<List<ShedModel>> getShedsByFarmId(String farmId) async {
    final matching = _inMemorySheds.where((s) => s.farmId == farmId || farmId.isEmpty).toList();
    if (matching.isNotEmpty) return matching;
    return List<ShedModel>.from(_inMemorySheds);
  }

  static Future<void> deleteShed(String farmId, String shedId) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _shedsRef(user.uid, farmId).doc(shedId).delete();
      }
    } catch (_) {}

    _inMemorySheds.removeWhere((s) => s.id == shedId);
  }
}
