import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/core/exceptions/app_exceptions.dart';
import 'package:flock_sense/features/vaccine/domain/vaccine_record_model.dart';

class VaccineService {
  VaccineService._();

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

  static CollectionReference<Map<String, dynamic>>? _vaccineRef(
    String uid,
    String farmId,
    String batchId,
  ) {
    return _db
        ?.collection('users')
        .doc(uid)
        .collection('farms')
        .doc(farmId)
        .collection('batches')
        .doc(batchId)
        .collection('vaccineRecords');
  }

  static Stream<List<VaccineRecordModel>> watchVaccineRecords(
    String farmId,
    String batchId,
  ) {
    try {
      final uid = _auth?.currentUser?.uid ?? 'farmer_demo_user';
      final ref = _vaccineRef(uid, farmId, batchId);
      if (ref == null) {
        return Stream.value([]);
      }

      return ref.snapshots().map((snapshot) {
        final records = snapshot.docs
            .map((doc) => VaccineRecordModel.fromJson(doc.data()))
            .toList();
        records.sort((a, b) => b.date.compareTo(a.date));
        return records;
      });
    } catch (e) {
      debugPrint('VaccineService.watchVaccineRecords failed: $e');
      return Stream.value([]);
    }
  }

  static Future<List<VaccineRecordModel>> getVaccineRecords({
    required String farmId,
    required String batchId,
  }) async {
    final user = _auth?.currentUser;
    if (user == null) return [];

    final ref = _vaccineRef(user.uid, farmId, batchId);
    if (ref == null) return [];

    final snapshot = await ref.get();
    return snapshot.docs
        .map((doc) => VaccineRecordModel.fromJson(doc.data()))
        .toList();
  }

  static Future<VaccineRecordModel> createVaccineRecord({
    required String farmId,
    required String batchId,
    required String vaccineName,
    required String vaccineType,
    required double quantity,
    required String unit,
    required DateTime date,
    required int batchAgeDay,
    String? batchNumber,
    DateTime? expiryDate,
    required String route,
    String? doneBy,
    String? notes,
  }) async {
    try {
      final uid = _auth?.currentUser?.uid ?? 'farmer_demo_user';

      if (vaccineName.trim().isEmpty) {
        throw ValidationException('Vaccine name is required.');
      }
      if (quantity <= 0) {
        throw ValidationException('Quantity must be greater than zero.');
      }
      if (unit.trim().isEmpty) {
        throw ValidationException('Unit is required.');
      }

      final now = DateTime.now();
      final record = VaccineRecordModel(
        id: 'vac_${DateTime.now().millisecondsSinceEpoch}',
        farmId: farmId,
        batchId: batchId,
        ownerId: uid,
        createdAt: now,
        updatedAt: now,
        date: date,
        batchAgeDay: batchAgeDay,
        vaccineName: vaccineName.trim(),
        vaccineType: vaccineType.trim().isEmpty ? 'Other' : vaccineType.trim(),
        batchNumber: batchNumber?.trim(),
        expiryDate: expiryDate,
        quantity: quantity,
        unit: unit.trim(),
        route: route.trim().isEmpty ? 'Injection' : route.trim(),
        doneBy: doneBy?.trim(),
        notes: notes?.trim(),
      );

      try {
        await _vaccineRef(
          uid,
          farmId,
          batchId,
        )?.doc(record.id).set(record.toJson());
      } catch (_) {}
      return record;
    } catch (e) {
      debugPrint('VaccineService.createVaccineRecord failed: $e');
      throw ExceptionMapper.mapException(e);
    }
  }

  static Future<void> deleteVaccineRecord(
    String farmId,
    String batchId,
    String recordId,
  ) async {
    try {
      final uid = _auth?.currentUser?.uid ?? 'farmer_demo_user';
      await _vaccineRef(uid, farmId, batchId)?.doc(recordId).delete();
    } catch (e) {
      debugPrint('VaccineService.deleteVaccineRecord note: $e');
    }
  }
}
