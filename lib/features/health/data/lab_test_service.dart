import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/core/services/audit_service.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/lab_test_model.dart';
import 'package:flock_sense/features/notifications/data/models/notification_model.dart';

/// Comprehensive Service for Laboratory Sample Tracking, Quality Control & Diagnostic Results (SIH26128 Phase 7)
class LabTestService {
  LabTestService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _auditService = AuditService();

  static CollectionReference<Map<String, dynamic>> get _labRef =>
      _firestore.collection('lab_tests');
  static CollectionReference<Map<String, dynamic>> get _casesRef =>
      _firestore.collection('health_cases');
  static CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  /// Generate a unique human-readable sample identifier
  static String generateSampleId(String caseNumber, int sequenceIndex) {
    final cleanNum = caseNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final paddedSeq = sequenceIndex.toString().padLeft(3, '0');
    final y = DateTime.now().year;
    return 'SMP-$y-HC$cleanNum-$paddedSeq';
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. REQUEST DIAGNOSTIC TEST
  // ─────────────────────────────────────────────────────────────────────────────

  /// Creates a new lab test record linked to a health case
  static Future<void> requestTest(LabTestModel test) async {
    try {
      final docRef = test.id.isNotEmpty ? _labRef.doc(test.id) : _labRef.doc();
      final toSave = test.copyWith(id: docRef.id);
      await docRef.set(toSave.toJson(), SetOptions(merge: true));

      await _auditService.logOperation(
        operation: AuditOperation.dataSync,
        resourceType: 'LabTest',
        resourceId: docRef.id,
        changes: {
          'action': 'LAB_TEST_REQUESTED',
          'caseId': test.caseId,
          'sampleId': test.sampleId,
          'sampleType': test.sampleType,
          'testRequested': test.testRequested,
          'priority': test.priority,
        },
      );
    } catch (e) {
      debugPrint('[LabTestService.requestTest] Error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. SAMPLE COLLECTION
  // ─────────────────────────────────────────────────────────────────────────────

  /// Marks the sample as collected on the farm
  static Future<bool> collectSample({
    required String testId,
    required String collectorName,
    required String location,
    String? sampleQuantity,
    String? packagingCondition,
    String? notes,
  }) async {
    try {
      await _labRef.doc(testId).update({
        'status': LabTestStatus.collected.name,
        'collectedBy': collectorName,
        'collectedAt': FieldValue.serverTimestamp(),
        'collectionLocation': location,
        if (sampleQuantity != null) 'sampleQuantity': sampleQuantity,
        if (packagingCondition != null) 'packagingCondition': packagingCondition,
        if (notes != null) 'collectionNotes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _auditService.logOperation(
        operation: AuditOperation.dataSync,
        resourceType: 'LabTest',
        resourceId: testId,
        changes: {
          'action': 'SAMPLE_COLLECTED',
          'collector': collectorName,
          'location': location,
        },
      );
      return true;
    } catch (e) {
      debugPrint('[LabTestService.collectSample] Error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. SAMPLE DISPATCH
  // ─────────────────────────────────────────────────────────────────────────────

  /// Marks the sample as dispatched in cold-chain transit to the diagnostic laboratory
  static Future<bool> dispatchSample({
    required String testId,
    required String destinationLab,
    String? trackingReference,
    String? transportNotes,
  }) async {
    try {
      await _labRef.doc(testId).update({
        'status': LabTestStatus.dispatched.name,
        'destinationLab': destinationLab,
        'dispatchedAt': FieldValue.serverTimestamp(),
        if (trackingReference != null) 'trackingReference': trackingReference,
        if (transportNotes != null) 'transportNotes': transportNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _auditService.logOperation(
        operation: AuditOperation.dataSync,
        resourceType: 'LabTest',
        resourceId: testId,
        changes: {
          'action': 'SAMPLE_DISPATCHED',
          'destinationLab': destinationLab,
          'tracking': trackingReference,
        },
      );
      return true;
    } catch (e) {
      debugPrint('[LabTestService.dispatchSample] Error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. SAMPLE RECEIPT & QUALITY CONTROL
  // ─────────────────────────────────────────────────────────────────────────────

  /// Records laboratory reception and sample integrity inspection
  static Future<bool> receiveSample({
    required String testId,
    required String receivedBy,
    required SampleReceiptCondition condition,
    String? rejectionReason,
  }) async {
    try {
      final isRejected = condition != SampleReceiptCondition.acceptable;
      final newStatus = isRejected ? LabTestStatus.rejected : LabTestStatus.received;

      await _labRef.doc(testId).update({
        'status': newStatus.name,
        'receivedBy': receivedBy,
        'receivedAt': FieldValue.serverTimestamp(),
        'conditionAtReceipt': condition.name,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _auditService.logOperation(
        operation: AuditOperation.dataSync,
        resourceType: 'LabTest',
        resourceId: testId,
        changes: {
          'action': isRejected ? 'SAMPLE_REJECTED' : 'SAMPLE_RECEIVED',
          'receivedBy': receivedBy,
          'condition': condition.name,
          if (rejectionReason != null) 'rejectionReason': rejectionReason,
        },
      );
      return true;
    } catch (e) {
      debugPrint('[LabTestService.receiveSample] Error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. TESTING INITIATION
  // ─────────────────────────────────────────────────────────────────────────────

  /// Logs that the diagnostic PCR or ELISA assay has commenced
  static Future<bool> startTesting({
    required String testId,
  }) async {
    try {
      await _labRef.doc(testId).update({
        'status': LabTestStatus.testing.name,
        'testingStartedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _auditService.logOperation(
        operation: AuditOperation.dataSync,
        resourceType: 'LabTest',
        resourceId: testId,
        changes: {'action': 'LAB_TEST_STARTED'},
      );
      return true;
    } catch (e) {
      debugPrint('[LabTestService.startTesting] Error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. RECORD DIAGNOSTIC RESULTS
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enters official laboratory findings, result category, and report attachments
  static Future<bool> recordResult({
    required String testId,
    required String caseId,
    required String result,
    required LabResultCategory category,
    required String notes,
    required String enteredBy,
    List<String> attachments = const [],
    String? assignedVetId,
  }) async {
    try {
      final batch = _firestore.batch();

      final testRef = _labRef.doc(testId);
      batch.update(testRef, {
        'status': LabTestStatus.result_available.name,
        'result': result,
        'resultCategory': category.name,
        'resultNotes': notes,
        'resultEnteredBy': enteredBy,
        'resultAt': FieldValue.serverTimestamp(),
        'attachments': attachments,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify Assigned Veterinarian that Lab Results are ready for clinical interpretation
      if (assignedVetId != null && assignedVetId.isNotEmpty) {
        final notifId = 'notif_${caseId}_lab_result_${DateTime.now().millisecondsSinceEpoch}';
        final notifRef = _usersRef.doc(assignedVetId).collection('notifications').doc(notifId);
        batch.set(notifRef, {
          'id': notifId,
          'title': '🧪 Diagnostic Lab Results Available',
          'body': 'Laboratory test results for Case $caseId are ready for your clinical review (${category.label}).',
          'type': NotificationType.ai.name,
          'priority': NotificationPriority.high.name,
          'status': NotificationStatus.unread.name,
          'createdAt': FieldValue.serverTimestamp(),
          'actionUrl': '/health/cases/$caseId',
        });
      }

      await batch.commit();

      await _auditService.logOperation(
        operation: AuditOperation.dataSync,
        resourceType: 'LabTest',
        resourceId: testId,
        changes: {
          'action': 'LAB_RESULT_ENTERED',
          'result': result,
          'category': category.name,
          'enteredBy': enteredBy,
        },
      );
      return true;
    } catch (e) {
      debugPrint('[LabTestService.recordResult] Error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 7. VETERINARIAN RESULT REVIEW & CLINICAL CONFIRMATION
  // ─────────────────────────────────────────────────────────────────────────────

  /// Veterinarian interprets laboratory result and establishes confirmed or ruled-out diagnosis
  static Future<bool> reviewResultByVet({
    required String testId,
    required String caseId,
    required String vetId,
    required String interpretationNotes,
    required String diagnosisDecision, // 'confirmed' | 'ruled_out' | 'provisional' | 'inconclusive'
    required String confirmationBasis,
    required bool updateCaseDiagnosis,
    String? farmerId,
    String? caseNumber,
  }) async {
    try {
      final batch = _firestore.batch();

      // 1. Update LabTest record
      final testRef = _labRef.doc(testId);
      batch.update(testRef, {
        'status': LabTestStatus.reviewed.name,
        'reviewedByVet': vetId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'vetInterpretationNotes': interpretationNotes,
        'diagnosisDecision': diagnosisDecision,
        'confirmationBasis': confirmationBasis,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update HealthCase authoritative diagnosis if clinician verified
      if (updateCaseDiagnosis) {
        final caseRef = _casesRef.doc(caseId);
        final statusLabel = diagnosisDecision == 'confirmed'
            ? 'Clinically & Lab Confirmed'
            : (diagnosisDecision == 'ruled_out' ? 'Ruled Out by Lab' : 'Provisional');

        batch.update(caseRef, {
          'diagnosis': '$confirmationBasis ($statusLabel)',
          'status': HealthCaseStatus.diagnosis_recorded.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Dispatch Farmer Notification with veterinary confirmed guidance
      if (farmerId != null && farmerId.isNotEmpty) {
        final notifId = 'notif_${caseId}_lab_reviewed_${DateTime.now().millisecondsSinceEpoch}';
        final notifRef = _usersRef.doc(farmerId).collection('notifications').doc(notifId);
        batch.set(notifRef, {
          'id': notifId,
          'title': '📋 Laboratory Diagnostic Findings Reviewed',
          'body': 'Your veterinarian has reviewed laboratory test findings for Case ${caseNumber ?? caseId}: $confirmationBasis ($diagnosisDecision).',
          'type': NotificationType.ai.name,
          'priority': NotificationPriority.high.name,
          'status': NotificationStatus.unread.name,
          'createdAt': FieldValue.serverTimestamp(),
          'actionUrl': '/health/cases/$caseId',
        });
      }

      await batch.commit();

      await _auditService.logOperation(
        operation: AuditOperation.dataSync,
        resourceType: 'LabTest',
        resourceId: testId,
        changes: {
          'action': diagnosisDecision == 'confirmed' ? 'DIAGNOSIS_CONFIRMED' : 'DIAGNOSIS_RULED_OUT',
          'caseId': caseId,
          'vetId': vetId,
          'decision': diagnosisDecision,
          'basis': confirmationBasis,
        },
      );
      return true;
    } catch (e) {
      debugPrint('[LabTestService.reviewResultByVet] Error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 8. REQUEST REPEAT TEST
  // ─────────────────────────────────────────────────────────────────────────────

  /// Requests a repeat sample for an inconclusive or rejected test
  static Future<bool> requestRepeatTest({
    required String previousTestId,
    required LabTestModel newTest,
  }) async {
    try {
      final batch = _firestore.batch();

      final prevRef = _labRef.doc(previousTestId);
      batch.update(prevRef, {
        'status': LabTestStatus.inconclusive.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final newRef = _labRef.doc(newTest.id);
      batch.set(newRef, newTest.toJson(), SetOptions(merge: true));

      await batch.commit();

      await _auditService.logOperation(
        operation: AuditOperation.dataSync,
        resourceType: 'LabTest',
        resourceId: newTest.id,
        changes: {
          'action': 'REPEAT_TEST_REQUESTED',
          'previousTestId': previousTestId,
          'newSampleId': newTest.sampleId,
        },
      );
      return true;
    } catch (e) {
      debugPrint('[LabTestService.requestRepeatTest] Error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 9. STREAMS
  // ─────────────────────────────────────────────────────────────────────────────

  /// Stream all tests for a specific health case
  static Stream<List<LabTestModel>> streamTestsForCase(String caseId) {
    return _labRef
        .where('caseId', isEqualTo: caseId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _getSampleTests(caseId);
      }
      return snapshot.docs
          .map((doc) => LabTestModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    }).handleError((e) {
      debugPrint('[LabTestService.streamTestsForCase] Error: $e');
      return _getSampleTests(caseId);
    });
  }

  /// Stream all laboratory requests for Central Lab Queue
  static Stream<List<LabTestModel>> streamAllLabRequests() {
    return _labRef
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _getSampleTests('hc_demo_128');
      }
      return snapshot.docs
          .map((doc) => LabTestModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    }).handleError((e) {
      debugPrint('[LabTestService.streamAllLabRequests] Error: $e');
      return _getSampleTests('hc_demo_128');
    });
  }

  static List<LabTestModel> _getSampleTests(String caseId) {
    final now = DateTime.now();
    return [
      LabTestModel(
        id: 'lt_101',
        sampleId: 'SMP-2026-HC128-001',
        caseId: caseId,
        sampleType: 'Tracheal & Cloacal Swabs',
        testRequested: 'RT-PCR Viral Panel (NDV / AIV)',
        priority: 'urgent',
        requestedBy: 'Dr. Ramesh Patil (District Vet)',
        requestedAt: now.subtract(const Duration(hours: 4)),
        collectedBy: 'Field Officer A. Deshmukh',
        collectedAt: now.subtract(const Duration(hours: 3)),
        collectionLocation: 'Shed 2, Green Valley Farm',
        sampleQuantity: '4 Swab Vials in Viral Transport Medium (VTM)',
        packagingCondition: 'Cold-chain ice pack insulated box',
        dispatchedAt: now.subtract(const Duration(hours: 2)),
        destinationLab: 'Central Poultry Disease Diagnostic Lab, Pune',
        receivedAt: now.subtract(const Duration(hours: 1)),
        receivedBy: 'Lab Officer M. Kulkarni',
        conditionAtReceipt: SampleReceiptCondition.acceptable,
        testingStartedAt: now.subtract(const Duration(minutes: 45)),
        status: LabTestStatus.testing,
        labName: 'Central Poultry Disease Diagnostic Lab, Pune',
        resultNotes: 'Testing for Newcastle Disease Virus (NDV) & Avian Influenza Matrix Gene.',
      ),
    ];
  }
}
