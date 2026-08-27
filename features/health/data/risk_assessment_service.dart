import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/core/services/audit_service.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/daily_records/data/daily_record_service.dart';
import 'package:flock_sense/features/health/data/risk_config.dart';
import 'package:flock_sense/features/health/data/risk_engine.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/risk_assessment_model.dart';
import 'package:flock_sense/features/vaccine/data/vaccine_service.dart';

/// Primary Service for Risk Assessments & Orchestration (SIH26128)
class RiskAssessmentService {
  RiskAssessmentService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _auditService = AuditService();

  static CollectionReference<Map<String, dynamic>> get _riskRef =>
      _firestore.collection('risk_assessments');
  static CollectionReference<Map<String, dynamic>> get _casesRef =>
      _firestore.collection('health_cases');

  /// Evaluate health risk authoritatively, persist assessment, and update HealthCase
  static Future<RiskAssessmentModel?> evaluateAndPersistRisk({
    required HealthCaseModel healthCase,
    bool forceRecalculate = false,
  }) async {
    try {
      final user = _auth.currentUser;
      final uid = healthCase.farmerId ?? user?.uid ?? 'local_user';

      // 1. Fetch relevant historical daily records (previous 7-14 days)
      final recentRecords = await DailyRecordService.getAllDailyRecords(
        farmId: healthCase.farmId,
        batchId: healthCase.flockId,
      );

      // 2. Fetch batch info for population normalization
      int currentBirdCount = 1000;
      try {
        final batch = await BatchService.getBatchById(
          healthCase.farmId,
          healthCase.flockId,
        );
        if (batch != null && batch.currentBirds > 0) {
          currentBirdCount = batch.currentBirds;
        }
      } catch (e) {
        debugPrint('[RiskAssessmentService] Batch fetch fallback: $e');
      }

      // 3. Fetch vaccination records for compliance signal
      final vaccineRecords = await VaccineService.getVaccineRecords(
        farmId: healthCase.farmId,
        batchId: healthCase.flockId,
      );

      // 4. Fetch recent active health cases on this farm (last 14 days)
      final recentCasesSnapshot = await _casesRef
          .where('farmId', isEqualTo: healthCase.farmId)
          .where('reportedAt', isGreaterThan: DateTime.now().subtract(const Duration(days: 14)))
          .limit(10)
          .get();

      final recentHealthCases = recentCasesSnapshot.docs
          .map((d) => HealthCaseModel.fromJson({...d.data(), 'id': d.id}))
          .where((c) => c.id != healthCase.id)
          .toList();

      // 5. Build Engine Input
      final input = RiskEngineInput(
        caseId: healthCase.id,
        farmId: healthCase.farmId,
        batchId: healthCase.flockId,
        currentMortality: healthCase.mortalityCount,
        affectedCount: healthCase.affectedCount,
        symptoms: healthCase.symptoms,
        feedReductionPercent: healthCase.feedReductionPercent,
        waterReductionPercent: healthCase.waterReductionPercent,
        temperature: healthCase.temperature,
        humidity: healthCase.humidity,
        incidentDate: healthCase.reportedAt,
        currentBirdCount: currentBirdCount,
        recentDailyRecords: recentRecords,
        vaccinationRecords: vaccineRecords,
        recentHealthCases: recentHealthCases,
      );

      final inputHash = input.computeInputHash();

      // 6. Check Idempotency & Trigger-Loop Prevention
      final existingDoc = await _riskRef.doc('${healthCase.id}_${RiskConfig.engineVersion}').get();
      if (existingDoc.exists && !forceRecalculate) {
        final existingData = existingDoc.data();
        if (existingData != null && existingData['inputHash'] == inputHash) {
          debugPrint('[RiskAssessmentService] Assessment is up to date (hash matches), skipping recalculation.');
          return RiskAssessmentModel.fromJson({...existingData, 'id': existingDoc.id});
        }
      }

      // 7. Calculate Risk via Rule + Historical Anomaly Engine
      final assessment = RiskEngine.calculateHealthRisk(input);

      // 8. Save Assessment to 'risk_assessments' with Deterministic ID
      final assessmentRef = _riskRef.doc(assessment.id);
      await assessmentRef.set(assessment.toJson(), SetOptions(merge: true));

      // 9. Update related HealthCase with Official Server Risk Results
      final updatedStatus = (assessment.riskLevel == HealthRiskLevel.high ||
              assessment.riskLevel == HealthRiskLevel.critical)
          ? HealthCaseStatus.vet_required
          : (healthCase.status == HealthCaseStatus.reported
              ? HealthCaseStatus.risk_assessed
              : healthCase.status);

      await _casesRef.doc(healthCase.id).set({
        'riskScore': assessment.score,
        'riskLevel': assessment.riskLevel.name,
        'riskReasons': assessment.reasons,
        'status': updatedStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 10. Write Audit Log
      await _auditService.logOperation(
        operation: AuditOperation.dataSync,
        resourceType: 'RiskAssessment',
        resourceId: assessment.id,
        changes: {
          'action': 'RISK_ASSESSED',
          'caseId': healthCase.id,
          'farmId': healthCase.farmId,
          'score': assessment.score,
          'riskLevel': assessment.riskLevel.name,
          'engineVersion': assessment.engineVersion,
          'baselineStatus': assessment.baselineStatus,
          'reasonsCount': assessment.structuredReasons.length,
        },
      );

      return assessment;
    } catch (e, stack) {
      debugPrint('[RiskAssessmentService.evaluateAndPersistRisk] Error: $e\n$stack');
      return null;
    }
  }

  /// Get assessment by Case ID
  static Future<RiskAssessmentModel?> getAssessmentByCaseId(String caseId) async {
    try {
      // 1. Try deterministic primary document ID
      final directDoc = await _riskRef.doc('${caseId}_${RiskConfig.engineVersion}').get();
      if (directDoc.exists && directDoc.data() != null) {
        return RiskAssessmentModel.fromJson({
          ...directDoc.data()!,
          'id': directDoc.id,
        });
      }

      // 2. Query fallback
      final snap = await _riskRef.where('caseId', isEqualTo: caseId).limit(1).get();
      if (snap.docs.isNotEmpty) {
        return RiskAssessmentModel.fromJson({
          ...snap.docs.first.data(),
          'id': snap.docs.first.id,
        });
      }
    } catch (e) {
      debugPrint('[RiskAssessmentService.getAssessmentByCaseId] Error: $e');
    }
    return null;
  }

  /// Real-time stream of assessment by Case ID
  static Stream<RiskAssessmentModel?> streamAssessmentForCase(String caseId) {
    return _riskRef
        .doc('${caseId}_${RiskConfig.engineVersion}')
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return RiskAssessmentModel.fromJson({
          ...doc.data()!,
          'id': doc.id,
        });
      }
      return null;
    }).handleError((e) {
      debugPrint('[RiskAssessmentService.streamAssessmentForCase] Error: $e');
      return null;
    });
  }

  /// Stream assessments for a farm
  static Stream<List<RiskAssessmentModel>> streamAssessmentsForFarm(String farmId) {
    return _riskRef
        .where('farmId', isEqualTo: farmId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RiskAssessmentModel.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList())
        .handleError((e) {
      debugPrint('[RiskAssessmentService.streamAssessmentsForFarm] Error: $e');
      return <RiskAssessmentModel>[];
    });
  }
}
