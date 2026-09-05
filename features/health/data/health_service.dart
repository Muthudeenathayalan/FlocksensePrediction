import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/data/ai_health_assessment_service.dart';
import 'package:flock_sense/features/health/data/escalation_service.dart';
import 'package:flock_sense/features/health/data/risk_assessment_service.dart';
import 'package:flock_sense/core/services/audit_service.dart';

/// Primary Service for Health Cases & Disease Incidents (SIH26128)
class HealthService {
  static FirebaseFirestore? get _firestoreOrNull {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static FirebaseAuth? get _authOrNull {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  static final _auditService = AuditService();

  static CollectionReference<Map<String, dynamic>>? get _casesRef =>
      _firestoreOrNull?.collection('health_cases');

  /// Generate deterministic incident key for duplicate prevention
  static String generateIncidentKey(String farmId, String flockId, DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${farmId}_${flockId}_$y-$m-$d';
  }

  /// Check if an active incident already exists for this farm/flock/date
  static Future<HealthCaseModel?> findActiveIncident(String incidentKey) async {
    final ref = _casesRef;
    if (ref == null) return null;
    try {
      final snap = await ref
          .where('incidentKey', isEqualTo: incidentKey)
          .where('status', whereNotIn: [HealthCaseStatus.closed.name, HealthCaseStatus.rejected.name])
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        return HealthCaseModel.fromJson({
          ...snap.docs.first.data(),
          'id': snap.docs.first.id,
        });
      }
    } catch (e) {
      debugPrint('[HealthService.findActiveIncident] Error: $e');
    }
    return null;
  }

  /// Create or idempotently update health case
  static Future<HealthCaseModel> createOrUpdateHealthCase(HealthCaseModel healthCase) async {
    final user = _authOrNull?.currentUser;
    final incidentKey = healthCase.incidentKey ??
        generateIncidentKey(healthCase.farmId, healthCase.flockId, healthCase.reportedAt);

    final ref = _casesRef;
    if (ref == null) {
      return healthCase.copyWith(
        id: healthCase.id.isNotEmpty ? healthCase.id : 'case_offline_mock',
        farmerId: healthCase.farmerId ?? user?.uid,
        incidentKey: incidentKey,
        updatedAt: DateTime.now(),
      );
    }

    // 1. Check for existing active incident
    final existing = await findActiveIncident(incidentKey);
    final docRef = existing != null ? ref.doc(existing.id) : ref.doc();

    final toSave = healthCase.copyWith(
      id: docRef.id,
      farmerId: healthCase.farmerId ?? user?.uid,
      incidentKey: incidentKey,
      updatedAt: DateTime.now(),
    );

    try {
      await docRef.set(toSave.toJson(), SetOptions(merge: true));

      await _auditService.logOperation(
        operation: AuditOperation.dataSync,
        resourceType: 'HealthCase',
        resourceId: docRef.id,
        changes: {
          'action': existing != null ? 'HEALTH_CASE_UPDATED' : 'HEALTH_CASE_CREATED',
          'caseNumber': toSave.caseNumber,
          'farmId': toSave.farmId,
          'riskLevel': toSave.riskLevel.name,
          'status': toSave.status.name,
        },
      );

      // 1. Trigger Authoritative Backend Risk Engine
      RiskAssessmentService.evaluateAndPersistRisk(healthCase: toSave).then((riskAssessment) {
        // 2. Trigger Central Health Escalation Engine (SIH26128 Phase 5) - NEVER WAITS FOR AI
        EscalationService.evaluateAndEscalateCase(
          healthCase: toSave,
          riskAssessment: riskAssessment,
        ).catchError((e) {
          debugPrint('[HealthService] Automatic escalation error: $e');
          return null;
        });

        // 3. Trigger Multimodal AI Clinical Assessment (SIH26128 Phase 4)
        AIHealthAssessmentService.evaluateAndPersistAIAssessment(
          healthCase: toSave,
          riskAssessment: riskAssessment,
        ).catchError((e) {
          debugPrint('[HealthService] Automatic AI clinical assessment error: $e');
          return null;
        });
      }).catchError((e) {
        debugPrint('[HealthService] Automatic risk assessment error: $e');
        return null;
      });
    } catch (e) {
      debugPrint('[HealthService.createOrUpdateHealthCase] Firestore write error: $e');
    }

    return toSave;
  }

  /// Stream all active health cases (General / Government overview)
  static Stream<List<HealthCaseModel>> streamHealthCases() {
    final ref = _casesRef;
    if (ref == null) {
      return Stream.value(_getSampleHealthCases());
    }
    return ref
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _getSampleHealthCases();
      }
      return snapshot.docs
          .map((doc) => HealthCaseModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    }).handleError((e) {
      debugPrint('[HealthService] streamHealthCases error: $e');
      return _getSampleHealthCases();
    });
  }

  /// Get a single health case by ID
  static Future<HealthCaseModel?> getCaseById(String caseId) async {
    final ref = _casesRef;
    if (ref == null) {
      final sample = _getSampleHealthCases().where((c) => c.id == caseId);
      return sample.isNotEmpty ? sample.first : null;
    }
    try {
      final doc = await ref.doc(caseId).get();
      if (!doc.exists || doc.data() == null) {
        final sample = _getSampleHealthCases().where((c) => c.id == caseId);
        return sample.isNotEmpty ? sample.first : null;
      }
      return HealthCaseModel.fromJson({
        ...doc.data()!,
        'id': doc.id,
      });
    } catch (e) {
      debugPrint('[HealthService.getCaseById] Error: $e');
      final sample = _getSampleHealthCases().where((c) => c.id == caseId);
      return sample.isNotEmpty ? sample.first : null;
    }
  }

  /// Stream health cases for a specific farm
  static Stream<List<HealthCaseModel>> streamCasesForFarm(String farmId) {
    final ref = _casesRef;
    if (ref == null) {
      return Stream.value(_getSampleHealthCases().where((c) => c.farmId == farmId).toList());
    }
    return ref
        .where('farmId', isEqualTo: farmId)
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HealthCaseModel.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList())
        .handleError((e) {
      debugPrint('[HealthService] streamCasesForFarm error: $e');
      return _getSampleHealthCases().where((c) => c.farmId == farmId).toList();
    });
  }

  /// Stream health cases assigned to a veterinarian
  static Stream<List<HealthCaseModel>> streamAssignedCases(String vetId) {
    final ref = _casesRef;
    if (ref == null) {
      return Stream.value(_getSampleHealthCases());
    }
    return ref
        .where('assignedVetId', isEqualTo: vetId)
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HealthCaseModel.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList())
        .handleError((e) {
      debugPrint('[HealthService] streamAssignedCases error: $e');
      return _getSampleHealthCases();
    });
  }

  /// Stream critical surveillance cases for Government Command Center
  static Stream<List<HealthCaseModel>> streamCriticalCases() {
    final ref = _casesRef;
    if (ref == null) {
      return Stream.value(_getSampleHealthCases()
          .where((c) => c.riskLevel == HealthRiskLevel.critical || c.riskLevel == HealthRiskLevel.high)
          .toList());
    }
    return ref
        .where('riskLevel', whereIn: [HealthRiskLevel.critical.name, HealthRiskLevel.high.name])
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HealthCaseModel.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList())
        .handleError((e) {
      debugPrint('[HealthService] streamCriticalCases error: $e');
      return _getSampleHealthCases()
          .where((c) => c.riskLevel == HealthRiskLevel.critical || c.riskLevel == HealthRiskLevel.high)
          .toList();
    });
  }

  /// Stream a single case by ID
  static Stream<HealthCaseModel?> streamCaseById(String caseId) {
    final ref = _casesRef;
    if (ref == null) {
      return Stream.value(null);
    }
    return ref.doc(caseId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return HealthCaseModel.fromJson({...snap.data()!, 'id': snap.id});
    });
  }

  /// Legacy compatibility wrapper
  static Future<void> reportHealthCase(HealthCaseModel healthCase) async {
    await createOrUpdateHealthCase(healthCase);
  }

  /// Update case status and veterinary sign-off
  static Future<void> updateCaseStatus(
    String caseId,
    HealthCaseStatus newStatus, {
    String? vetNotes,
    String? diagnosis,
    String? treatmentPlanId,
  }) async {
    final ref = _casesRef;
    if (ref == null) return;
    try {
      final updates = <String, dynamic>{
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (vetNotes != null) updates['veterinarianAssessment'] = vetNotes;
      if (diagnosis != null) updates['diagnosis'] = diagnosis;
      if (treatmentPlanId != null) updates['treatmentPlanId'] = treatmentPlanId;

      await ref.doc(caseId).update(updates);
    } catch (e) {
      debugPrint('[HealthService.updateCaseStatus] Error: $e');
    }
  }

  /// Assign a veterinarian to a case
  static Future<void> assignVeterinarian(
    String caseId,
    String vetId, {
    String? notes,
  }) async {
    final ref = _casesRef;
    if (ref == null) return;
    try {
      await ref.doc(caseId).update({
        'assignedVetId': vetId,
        'status': HealthCaseStatus.vet_assigned.name,
        if (notes != null) 'veterinarianAssessment': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[HealthService.assignVeterinarian] Error: $e');
    }
  }

  /// Public access to sample health cases for immediate zero-latency UI rendering
  static List<HealthCaseModel> getSampleHealthCases() => _getSampleHealthCases();

  /// Initial sample data for SIH presentation if Firestore collection is fresh
  static List<HealthCaseModel> _getSampleHealthCases() {
    final now = DateTime.now();
    return [
      HealthCaseModel(
        id: 'hc_1042',
        caseNumber: 'HC-1042',
        farmId: 'farm_01',
        farmName: 'Green Valley Farm',
        flockId: 'flock_08',
        flockName: 'Cobb 500 — Batch 08',
        symptoms: ['Respiratory clicking', 'Reduced feed intake', 'Watery eyes'],
        affectedCount: 18,
        mortalityCount: 2,
        riskScore: 86,
        riskLevel: HealthRiskLevel.critical,
        possibleDiseases: ['Newcastle Disease', 'Infectious Bronchitis', 'Avian Influenza'],
        riskReasons: [
          'Mortality increased 4.1× over shed baseline',
          'Feed intake dropped 18% in last 24h',
          'Water consumption dropped below expected curve',
          'Audible respiratory clicking and sneezing detected',
        ],
        status: HealthCaseStatus.under_investigation,
        notes: 'Observed sudden drop in feed consumption and respiratory sounds in Shed 2.',
        veterinarianAssessment: 'Suspected acute respiratory infection. Prescribed oral antimicrobial and isolation protocol.',
        diagnosis: 'Suspected Newcastle Disease (ND) / IB Complex',
        labRequired: true,
        reportedAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      HealthCaseModel(
        id: 'hc_1041',
        caseNumber: 'HC-1041',
        farmId: 'farm_01',
        farmName: 'Green Valley Farm',
        flockId: 'flock_06',
        flockName: 'Ross 308 — Batch 06',
        symptoms: ['Lethargy', 'Ruffled feathers'],
        affectedCount: 5,
        mortalityCount: 0,
        riskScore: 48,
        riskLevel: HealthRiskLevel.moderate,
        possibleDiseases: ['Heat Stress Anomaly', 'Subclinical Coccidiosis'],
        riskReasons: ['Ambient temperature peaked at 34.2°C during midday'],
        status: HealthCaseStatus.treatment_started,
        notes: 'Birds showing signs of heat stress during afternoon peak.',
        veterinarianAssessment: 'Increase ventilation fan speed and add Vitamin C to water.',
        diagnosis: 'Acute Ambient Heat Stress',
        reportedAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 12)),
      ),
      HealthCaseModel(
        id: 'hc_1039',
        caseNumber: 'HC-1039',
        farmId: 'farm_02',
        farmName: 'Sunrise Broiler Farm',
        flockId: 'flock_03',
        flockName: 'Hubbard — Batch 03',
        symptoms: ['Mild diarrhea'],
        affectedCount: 8,
        mortalityCount: 0,
        riskScore: 22,
        riskLevel: HealthRiskLevel.low,
        possibleDiseases: ['Nutritional Enteritis'],
        status: HealthCaseStatus.closed,
        notes: 'Water drinker nipple blockage detected and cleared.',
        veterinarianAssessment: 'Resolved after water line sanitization.',
        diagnosis: 'Drinker Line Microbial Slime (Resolved)',
        reportedAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}
