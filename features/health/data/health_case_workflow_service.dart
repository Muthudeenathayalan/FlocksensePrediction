import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/core/services/audit_service.dart';
import 'package:flock_sense/features/health/domain/case_follow_up_model.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/lab_test_model.dart';
import 'package:flock_sense/features/health/domain/treatment_plan_model.dart';
import 'package:flock_sense/features/health/domain/vet_assignment_model.dart';
import 'package:flock_sense/features/health/domain/vet_clinical_assessment_model.dart';
import 'package:flock_sense/features/notifications/data/models/notification_model.dart';

/// Centralized Workflow Service for Veterinarian Clinical Actions & State Transitions (SIH26128 Phase 6)
class HealthCaseWorkflowService {
  HealthCaseWorkflowService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _auditService = AuditService();

  static CollectionReference<Map<String, dynamic>> get _casesRef =>
      _firestore.collection('health_cases');
  static CollectionReference<Map<String, dynamic>> get _assignmentsRef =>
      _firestore.collection('vet_assignments');
  static CollectionReference<Map<String, dynamic>> get _assessmentsRef =>
      _firestore.collection('vet_clinical_assessments');
  static CollectionReference<Map<String, dynamic>> get _labTestsRef =>
      _firestore.collection('lab_tests');
  static CollectionReference<Map<String, dynamic>> get _treatmentPlansRef =>
      _firestore.collection('treatment_plans');
  static CollectionReference<Map<String, dynamic>> get _followUpsRef =>
      _firestore.collection('case_follow_ups');
  static CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');
  static CollectionReference<Map<String, dynamic>> get _aiFeedbackRef =>
      _firestore.collection('ai_clinical_feedback');

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. ACCEPT CASE (CONCURRENCY & TRANSACTION PROTECTED)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Accepts a pending or district-queued case atomically with concurrency protection
  static Future<({bool success, String message})> acceptCase({
    required String caseId,
    required String vetId,
    required String vetName,
  }) async {
    final assignmentDocId = 'va_${caseId}_escalation-v1';
    final assignmentDocRef = _assignmentsRef.doc(assignmentDocId);
    final caseDocRef = _casesRef.doc(caseId);

    try {
      final result = await _firestore.runTransaction<({bool success, String message})>((tx) async {
        final assignSnap = await tx.get(assignmentDocRef);
        final caseSnap = await tx.get(caseDocRef);

        if (assignSnap.exists) {
          final data = assignSnap.data()!;
          final currentStatus = data['status'] as String?;
          final currentVetId = data['vetId'] as String?;

          // Check if already claimed/accepted by another veterinarian
          if ((currentStatus == VetAssignmentStatus.accepted.name ||
                  currentStatus == VetAssignmentStatus.in_progress.name) &&
              currentVetId != null &&
              currentVetId.isNotEmpty &&
              currentVetId != vetId) {
            return (
              success: false,
              message: 'This case has already been accepted by another veterinarian (${data['vetName'] ?? "Duty Vet"}).'
            );
          }
        }

        // Apply atomic updates
        tx.set(assignmentDocRef, {
          'id': assignmentDocId,
          'caseId': caseId,
          'vetId': vetId,
          'vetName': vetName,
          'status': VetAssignmentStatus.accepted.name,
          'acceptedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        tx.set(caseDocRef, {
          'status': HealthCaseStatus.under_investigation.name,
          'assignedVetId': vetId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Dispatch Farmer in-app notification
        final farmerId = caseSnap.data()?['farmerId'] as String?;
        if (farmerId != null && farmerId.isNotEmpty) {
          final notifId = 'notif_${caseId}_vet_accepted_${DateTime.now().millisecondsSinceEpoch}';
          final notifRef = _usersRef.doc(farmerId).collection('notifications').doc(notifId);
          tx.set(notifRef, {
            'id': notifId,
            'title': '👨‍⚕️ Veterinarian Assigned & Reviewing',
            'body': '$vetName has accepted your health report (Case $caseId) and started clinical investigation.',
            'type': NotificationType.ai.name,
            'priority': NotificationPriority.high.name,
            'status': NotificationStatus.unread.name,
            'createdAt': FieldValue.serverTimestamp(),
            'actionUrl': '/health/cases/$caseId',
          });
        }

        return (success: true, message: 'Case accepted successfully. Clinical investigation initiated.');
      });

      if (result.success) {
        await _auditService.logOperation(
          operation: AuditOperation.dataSync,
          resourceType: 'VetAssignment',
          resourceId: assignmentDocId,
          changes: {
            'action': 'CASE_ACCEPTED',
            'caseId': caseId,
            'vetId': vetId,
            'vetName': vetName,
          },
        );
      }

      return result;
    } catch (e) {
      debugPrint('[HealthCaseWorkflowService.acceptCase] Error: $e');
      return (success: false, message: 'Failed to accept case: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. ADD VETERINARY CLINICAL ASSESSMENT & PRELIMINARY DIAGNOSIS
  // ─────────────────────────────────────────────────────────────────────────────

  /// Saves structured clinical assessment, preliminary diagnosis, and farmer guidance
  static Future<bool> addClinicalAssessment({
    required String caseId,
    required String vetId,
    required String vetName,
    required VetClinicalAssessmentModel assessment,
  }) async {
    try {
      final docId = '${caseId}_assessment-v1';
      final batch = _firestore.batch();

      // 1. Write VetClinicalAssessment document
      final assessmentRef = _assessmentsRef.doc(docId);
      batch.set(assessmentRef, assessment.toJson(), SetOptions(merge: true));

      // 2. Update HealthCase with clinical conclusions
      final caseRef = _casesRef.doc(caseId);
      batch.update(caseRef, {
        'veterinarianAssessment': assessment.farmerGuidance.isNotEmpty
            ? assessment.farmerGuidance
            : assessment.clinicalObservations,
        'diagnosis': '${assessment.preliminaryDiagnosis} (${assessment.diagnosisStatus.label})',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Update VetAssignment status to in_progress
      final assignRef = _assignmentsRef.doc('va_${caseId}_escalation-v1');
      batch.update(assignRef, {
        'status': VetAssignmentStatus.in_progress.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      await _auditService.logOperation(
        operation: AuditOperation.dataSync,
        resourceType: 'VetClinicalAssessment',
        resourceId: docId,
        changes: {
          'action': 'VET_ASSESSMENT_ADDED',
          'caseId': caseId,
          'vetId': vetId,
          'preliminaryDiagnosis': assessment.preliminaryDiagnosis,
          'diagnosisStatus': assessment.diagnosisStatus.name,
          'primarySyndrome': assessment.primarySyndrome.name,
        },
      );

      return true;
    } catch (e) {
      debugPrint('[HealthCaseWorkflowService.addClinicalAssessment] Error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. REQUEST LAB TEST
  // ─────────────────────────────────────────────────────────────────────────────

  /// Creates a real LabTest record and transitions case to sample_requested
  static Future<bool> requestLabTest({
    required String caseId,
    required String vetId,
    required LabTestModel labTest,
    required String? farmerId,
    required String caseNumber,
  }) async {
    try {
      final batch = _firestore.batch();

      // 1. Write LabTest document
      final testRef = _labTestsRef.doc(labTest.id);
      batch.set(testRef, labTest.toJson(), SetOptions(merge: true));

      // 2. Update HealthCase status & labRequired flag
      final caseRef = _casesRef.doc(caseId);
      batch.update(caseRef, {
        'status': HealthCaseStatus.sample_requested.name,
        'labRequired': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Dispatch Farmer Notification
      if (farmerId != null && farmerId.isNotEmpty) {
        final notifId = 'notif_${caseId}_lab_${DateTime.now().millisecondsSinceEpoch}';
        final notifRef = _usersRef.doc(farmerId).collection('notifications').doc(notifId);
        batch.set(notifRef, {
          'id': notifId,
          'title': '🧪 Diagnostic Lab Sample Requested',
          'body': 'Your veterinarian has requested a ${labTest.sampleType} diagnostic test for case $caseNumber (${labTest.labName ?? "Central Diagnostic Lab"}).',
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
        resourceId: labTest.id,
        changes: {
          'action': 'LAB_TEST_REQUESTED',
          'caseId': caseId,
          'sampleType': labTest.sampleType,
          'labName': labTest.labName,
        },
      );

      return true;
    } catch (e) {
      debugPrint('[HealthCaseWorkflowService.requestLabTest] Error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. SET NO LAB REQUIRED
  // ─────────────────────────────────────────────────────────────────────────────

  /// Marks lab not required with clinical rationale
  static Future<bool> setNoLabRequired({
    required String caseId,
    required String vetId,
    required String rationale,
  }) async {
    try {
      await _casesRef.doc(caseId).update({
        'labRequired': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _auditService.logOperation(
        operation: AuditOperation.dataSync,
        resourceType: 'HealthCase',
        resourceId: caseId,
        changes: {
          'action': 'LAB_NOT_REQUIRED',
          'caseId': caseId,
          'vetId': vetId,
          'rationale': rationale,
        },
      );

      return true;
    } catch (e) {
      debugPrint('[HealthCaseWorkflowService.setNoLabRequired] Error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. CREATE & PUBLISH TREATMENT / MANAGEMENT PLAN
  // ─────────────────────────────────────────────────────────────────────────────

  /// Publishes active management and treatment plan to farmer
  static Future<bool> publishTreatmentPlan({
    required String caseId,
    required String vetId,
    required TreatmentPlanModel plan,
    required String? farmerId,
    required String caseNumber,
  }) async {
    try {
      final batch = _firestore.batch();

      // 1. Write TreatmentPlan document (status = active)
      final planRef = _treatmentPlansRef.doc(plan.id);
      batch.set(planRef, plan.toJson(), SetOptions(merge: true));

      // 2. Update HealthCase status to treatment_started
      final caseRef = _casesRef.doc(caseId);
      batch.update(caseRef, {
        'status': HealthCaseStatus.treatment_started.name,
        'treatmentPlanId': plan.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Dispatch Farmer In-App Notification
      if (farmerId != null && farmerId.isNotEmpty) {
        final notifId = 'notif_${caseId}_guidance_${DateTime.now().millisecondsSinceEpoch}';
        final notifRef = _usersRef.doc(farmerId).collection('notifications').doc(notifId);
        batch.set(notifRef, {
          'id': notifId,
          'title': '📋 Veterinary Guidance & Management Plan Available',
          'body': 'Official clinical instructions and biosecurity management protocol published for Case $caseNumber.',
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
        resourceType: 'TreatmentPlan',
        resourceId: plan.id,
        changes: {
          'action': 'TREATMENT_PLAN_PUBLISHED',
          'caseId': caseId,
          'vetId': vetId,
          'instructionsCount': plan.instructions.length,
          'medicationsCount': plan.medications.length,
          'biosecurityCount': plan.biosecurityActions.length,
        },
      );

      return true;
    } catch (e) {
      debugPrint('[HealthCaseWorkflowService.publishTreatmentPlan] Error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. FARMER FOLLOW-UP OBSERVATIONS SUBMISSION
  // ─────────────────────────────────────────────────────────────────────────────

  /// Submits farmer follow-up observations without altering original report
  static Future<bool> submitFarmerFollowUp({
    required String caseId,
    required CaseFollowUpModel followUp,
    required String? assignedVetId,
    required String caseNumber,
  }) async {
    try {
      final batch = _firestore.batch();

      // 1. Write Follow-Up document
      final followUpRef = _followUpsRef.doc(followUp.id);
      batch.set(followUpRef, followUp.toJson(), SetOptions(merge: true));

      // 2. Update HealthCase timestamp
      final caseRef = _casesRef.doc(caseId);
      batch.update(caseRef, {
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Dispatch Vet Notification (if assigned)
      if (assignedVetId != null && assignedVetId.isNotEmpty) {
        final notifId = 'notif_${caseId}_followup_${DateTime.now().millisecondsSinceEpoch}';
        final notifRef = _usersRef.doc(assignedVetId).collection('notifications').doc(notifId);
        batch.set(notifRef, {
          'id': notifId,
          'title': '📊 Farmer Follow-Up Submitted',
          'body': 'Farmer reported ${followUp.condition.label} (Mortality: ${followUp.currentMortalityCount}, Affected: ${followUp.currentAffectedCount}) for Case $caseNumber.',
          'type': NotificationType.ai.name,
          'priority': NotificationPriority.normal.name,
          'status': NotificationStatus.unread.name,
          'createdAt': FieldValue.serverTimestamp(),
          'actionUrl': '/health/cases/$caseId',
        });
      }

      await batch.commit();

      await _auditService.logOperation(
        operation: AuditOperation.dataSync,
        resourceType: 'CaseFollowUp',
        resourceId: followUp.id,
        changes: {
          'action': 'FARMER_FOLLOWUP_ADDED',
          'caseId': caseId,
          'condition': followUp.condition.name,
          'mortality': followUp.currentMortalityCount,
          'affected': followUp.currentAffectedCount,
        },
      );

      return true;
    } catch (e) {
      debugPrint('[HealthCaseWorkflowService.submitFarmerFollowUp] Error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 7. MOVE TO MONITORING
  // ─────────────────────────────────────────────────────────────────────────────

  /// Moves case from treatment_started to monitoring
  static Future<bool> moveToMonitoring({
    required String caseId,
    required String vetId,
    String? notes,
  }) async {
    try {
      await _casesRef.doc(caseId).update({
        'status': HealthCaseStatus.monitoring.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _auditService.logOperation(
        operation: AuditOperation.dataSync,
        resourceType: 'HealthCase',
        resourceId: caseId,
        changes: {
          'action': 'CASE_MOVED_TO_MONITORING',
          'caseId': caseId,
          'vetId': vetId,
          if (notes != null) 'notes': notes,
        },
      );

      return true;
    } catch (e) {
      debugPrint('[HealthCaseWorkflowService.moveToMonitoring] Error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 8. RECORD VETERINARIAN AI FEEDBACK
  // ─────────────────────────────────────────────────────────────────────────────

  /// Saves veterinarian AI decision support feedback separately
  static Future<void> recordAIFeedback({
    required String caseId,
    required String vetId,
    required AIFeedbackRating rating,
    String? notes,
  }) async {
    try {
      await _aiFeedbackRef.doc('${caseId}_feedback').set({
        'caseId': caseId,
        'vetId': vetId,
        'rating': rating.name,
        'notes': notes ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[HealthCaseWorkflowService.recordAIFeedback] Error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 9. REAL-TIME STREAMS
  // ─────────────────────────────────────────────────────────────────────────────

  /// Stream veterinary clinical assessment for case
  static Stream<VetClinicalAssessmentModel?> streamClinicalAssessment(String caseId) {
    return _assessmentsRef.doc('${caseId}_assessment-v1').snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return VetClinicalAssessmentModel.fromJson({...snap.data()!, 'id': snap.id});
    }).handleError((e) {
      debugPrint('[HealthCaseWorkflowService.streamClinicalAssessment] Error: $e');
      return null;
    });
  }

  /// Stream published treatment plan for case
  static Stream<TreatmentPlanModel?> streamTreatmentPlan(String caseId) {
    return _treatmentPlansRef
        .where('caseId', isEqualTo: caseId)
        .where('status', isEqualTo: TreatmentPlanStatus.active.name)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return TreatmentPlanModel.fromJson({...snap.docs.first.data(), 'id': snap.docs.first.id});
    }).handleError((e) {
      debugPrint('[HealthCaseWorkflowService.streamTreatmentPlan] Error: $e');
      return null;
    });
  }

  /// Stream follow-ups for case
  static Stream<List<CaseFollowUpModel>> streamFollowUps(String caseId) {
    return _followUpsRef
        .where('caseId', isEqualTo: caseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((doc) => CaseFollowUpModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    }).handleError((e) {
      debugPrint('[HealthCaseWorkflowService.streamFollowUps] Error: $e');
      return <CaseFollowUpModel>[];
    });
  }
}
