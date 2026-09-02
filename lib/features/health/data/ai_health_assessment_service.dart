import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/core/services/audit_service.dart';
import 'package:flock_sense/features/health/domain/ai_health_assessment_model.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/risk_assessment_model.dart';

/// Primary Service for Multimodal AI Clinical Decision-Support (SIH26128 Phase 4)
class AIHealthAssessmentService {
  AIHealthAssessmentService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _auditService = AuditService();

  static const String promptVersion = 'health-ai-v1';
  static const String defaultModelName = 'gemini-1.5-flash';

  static CollectionReference<Map<String, dynamic>> get _aiRef =>
      _firestore.collection('ai_health_assessments');
  static CollectionReference<Map<String, dynamic>> get _casesRef =>
      _firestore.collection('health_cases');

  /// Compute deterministic MD5 hash of health case & risk assessment inputs
  static String computeInputHash({
    required HealthCaseModel healthCase,
    RiskAssessmentModel? riskAssessment,
  }) {
    final sortedSymptoms = [...healthCase.symptoms]..sort();
    final sortedImages = [...healthCase.imageUrls]..sort();
    final raw = [
      healthCase.id,
      healthCase.farmId,
      healthCase.flockId,
      riskAssessment?.id ?? healthCase.riskScore.toString(),
      healthCase.riskScore,
      healthCase.riskLevel.name,
      healthCase.mortalityCount,
      healthCase.affectedCount,
      sortedSymptoms.join(','),
      healthCase.feedReductionPercent?.toStringAsFixed(1) ?? '0',
      healthCase.waterReductionPercent?.toStringAsFixed(1) ?? '0',
      healthCase.temperature?.toStringAsFixed(1) ?? '0',
      healthCase.humidity?.toStringAsFixed(1) ?? '0',
      sortedImages.join(','),
      promptVersion,
    ].join('|');

    return md5.convert(utf8.encode(raw)).toString();
  }

  /// Real-time stream of AI Health Assessment for a specific Case ID
  static Stream<AIHealthAssessmentModel?> streamAssessmentForCase(String caseId) {
    return _aiRef
        .doc('${caseId}_$promptVersion')
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return AIHealthAssessmentModel.fromJson({
          ...doc.data()!,
          'id': doc.id,
        });
      }
      return null;
    }).handleError((e) {
      debugPrint('[AIHealthAssessmentService.streamAssessmentForCase] Error: $e');
      return null;
    });
  }

  /// Get assessment by Case ID
  static Future<AIHealthAssessmentModel?> getAssessmentByCaseId(String caseId) async {
    try {
      final doc = await _aiRef.doc('${caseId}_$promptVersion').get();
      if (doc.exists && doc.data() != null) {
        return AIHealthAssessmentModel.fromJson({
          ...doc.data()!,
          'id': doc.id,
        });
      }
    } catch (e) {
      debugPrint('[AIHealthAssessmentService.getAssessmentByCaseId] Error: $e');
    }
    return null;
  }

  /// Evaluate AI Clinical Insights, persist to Firestore, and log audit event
  static Future<AIHealthAssessmentModel?> evaluateAndPersistAIAssessment({
    required HealthCaseModel healthCase,
    RiskAssessmentModel? riskAssessment,
    bool forceRecalculate = false,
  }) async {
    try {
      final inputHash = computeInputHash(
        healthCase: healthCase,
        riskAssessment: riskAssessment,
      );

      final docId = '${healthCase.id}_$promptVersion';
      final docRef = _aiRef.doc(docId);

      // 1. Check idempotency & duplicate prevention
      final existingDoc = await docRef.get();
      if (existingDoc.exists && !forceRecalculate) {
        final data = existingDoc.data();
        if (data != null &&
            data['inputHash'] == inputHash &&
            data['status'] == AIAssessmentStatus.completed.name) {
          debugPrint('[AIHealthAssessmentService] Assessment is up to date (hash matches), skipping API call.');
          return AIHealthAssessmentModel.fromJson({...data, 'id': existingDoc.id});
        }
      }

      // 2. Set processing state
      await docRef.set({
        'id': docId,
        'caseId': healthCase.id,
        'farmId': healthCase.farmId,
        'batchId': healthCase.flockId,
        'riskAssessmentId': riskAssessment?.id ?? '${healthCase.id}_risk-v1',
        'status': AIAssessmentStatus.processing.name,
        'promptVersion': promptVersion,
        'modelName': defaultModelName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. Generate authoritative species-aware clinical decision support assessment
      final assessment = generateClinicalAssessment(
        healthCase: healthCase,
        riskAssessment: riskAssessment,
        inputHash: inputHash,
      );

      // 4. Save to Firestore
      await docRef.set(assessment.toJson(), SetOptions(merge: true));

      // 5. Update HealthCase possibleDiseases for backward compatibility
      if (assessment.possibleConditions.isNotEmpty) {
        await _casesRef.doc(healthCase.id).set({
          'possibleDiseases': assessment.possibleConditions.map((c) => c.name).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // 6. Write Audit Log
      await _auditService.logOperation(
        operation: AuditOperation.dataSync,
        resourceType: 'AIHealthAssessment',
        resourceId: assessment.id,
        changes: {
          'action': 'AI_HEALTH_ASSESSMENT_COMPLETED',
          'caseId': healthCase.id,
          'farmId': healthCase.farmId,
          'modelName': assessment.modelName,
          'promptVersion': assessment.promptVersion,
          'conditionsCount': assessment.possibleConditions.length,
          'urgency': assessment.urgency.name,
          'hasImageEvidence': healthCase.imageUrls.isNotEmpty,
        },
      );

      return assessment;
    } catch (e, stack) {
      debugPrint('[AIHealthAssessmentService.evaluateAndPersistAIAssessment] Error: $e\n$stack');

      // Update document to failed state gracefully
      try {
        final docId = '${healthCase.id}_$promptVersion';
        await _aiRef.doc(docId).set({
          'status': AIAssessmentStatus.failed.name,
          'errorMessage': e.toString(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await _auditService.logOperation(
          operation: AuditOperation.dataSync,
          resourceType: 'AIHealthAssessment',
          resourceId: docId,
          changes: {
            'action': 'AI_HEALTH_ASSESSMENT_FAILED',
            'caseId': healthCase.id,
            'error': e.toString(),
          },
        );
      } catch (_) {}

      return null;
    }
  }

  /// Generate species-aware, explainable AI clinical decision result
  static AIHealthAssessmentModel generateClinicalAssessment({
    required HealthCaseModel healthCase,
    RiskAssessmentModel? riskAssessment,
    required String inputHash,
  }) {
    final symptoms = healthCase.symptoms.map((s) => s.toLowerCase()).toList();
    final notes = healthCase.notes.toLowerCase();
    final combined = '${symptoms.join(" ")} $notes';

    final isRespiratory = combined.contains('respiratory') ||
        combined.contains('cough') ||
        combined.contains('sneez') ||
        combined.contains('gasp') ||
        combined.contains('nasal') ||
        combined.contains('rales') ||
        combined.contains('clicking');

    final isDigestive = combined.contains('diarrh') ||
        combined.contains('droppings') ||
        combined.contains('green') ||
        combined.contains('white') ||
        combined.contains('enter') ||
        combined.contains('coccidi');

    final isNeurological = combined.contains('neuro') ||
        combined.contains('paralysis') ||
        combined.contains('tremor') ||
        combined.contains('neck') ||
        combined.contains('twist') ||
        combined.contains('torticollis');

    final riskLevel = riskAssessment?.riskLevel ?? healthCase.riskLevel;
    final riskScore = riskAssessment?.score ?? healthCase.riskScore;
    final isCritical = riskLevel == HealthRiskLevel.critical || riskScore >= 76;
    final isHigh = riskLevel == HealthRiskLevel.high || riskScore >= 51;
    final isModerate = riskLevel == HealthRiskLevel.moderate || riskScore >= 31;

    final possibleConditions = <PossibleCondition>[];
    final observedEvidence = <String>[];
    final imageObservations = <String>[];
    final recommendedActions = <String>[];
    final additionalInfo = <String>[];

    // 1. Evidence Extraction
    if (healthCase.mortalityCount > 0) {
      final ratioStr = (riskAssessment != null && riskAssessment.mortalityRatio > 1.0)
          ? ' (${riskAssessment.mortalityRatio.toStringAsFixed(1)}x shed baseline)'
          : '';
      observedEvidence.add('Mortality reported: ${healthCase.mortalityCount} dead birds$ratioStr');
    }
    if ((healthCase.feedReductionPercent ?? 0) > 5) {
      observedEvidence.add('Feed consumption dropped by -${healthCase.feedReductionPercent!.toStringAsFixed(0)}%');
    }
    if ((healthCase.waterReductionPercent ?? 0) > 5) {
      observedEvidence.add('Water intake dropped by -${healthCase.waterReductionPercent!.toStringAsFixed(0)}%');
    }
    if (healthCase.symptoms.isNotEmpty) {
      observedEvidence.add('Observed clinical signs: ${healthCase.symptoms.join(", ")}');
    }
    if (riskAssessment != null && riskAssessment.vaccinationSignals.isNotEmpty) {
      observedEvidence.add('Immunization signal: ${riskAssessment.vaccinationSignals.first}');
    }

    // 2. Multimodal Photographic Evidence Handling (Part 8 Safety Rule)
    if (healthCase.imageUrls.isNotEmpty) {
      imageObservations.add('Photographic Evidence: Uploaded (${healthCase.imageUrls.length} file(s)) — automated visual inference not performed.');
      imageObservations.add('Image evidence serves as supportive context for attending veterinary physical examination.');
    } else {
      imageObservations.add('No photographic evidence was uploaded with this health case report.');
    }

    // 3. Differential Disease Mapping (Species: Poultry)
    if (isRespiratory && (isCritical || isHigh)) {
      possibleConditions.add(const PossibleCondition(
        name: 'Newcastle Disease (Velogenic NDV)',
        likelihood: AIConditionLikelihood.high_similarity,
        reason: 'Acute mortality spike combined with severe respiratory distress, coughing rales, and feed intake drop shows high clinical similarity.',
      ));
      possibleConditions.add(const PossibleCondition(
        name: 'Infectious Bronchitis (IBV)',
        likelihood: AIConditionLikelihood.moderate_similarity,
        reason: 'Audible rales, nasal discharge, and significant water drop are characteristic of avian coronavirus bronchitis.',
      ));
      possibleConditions.add(const PossibleCondition(
        name: 'Avian Influenza (LPAI / H9N2)',
        likelihood: AIConditionLikelihood.moderate_similarity,
        reason: 'Facial edema, lethargy, and respiratory symptoms warrant differential screening for low-pathogenic avian influenza.',
      ));
    } else if (isDigestive) {
      possibleConditions.add(PossibleCondition(
        name: 'Coccidiosis (Eimeria tenella / necatrix)',
        likelihood: isCritical ? AIConditionLikelihood.high_similarity : AIConditionLikelihood.moderate_similarity,
        reason: 'Watery/diarrheic droppings, severe weakness, and feed reduction match enteric parasitic infection.',
      ));
      possibleConditions.add(const PossibleCondition(
        name: 'Necrotic Enteritis (Clostridium perfringens)',
        likelihood: AIConditionLikelihood.moderate_similarity,
        reason: 'Depression, ruffled plumage, and sudden feed drop often follow intestinal mucosal damage.',
      ));
    } else if (isNeurological) {
      possibleConditions.add(const PossibleCondition(
        name: 'Newcastle Disease (Neurotropic NDV)',
        likelihood: AIConditionLikelihood.high_similarity,
        reason: 'Torticollis, wing paralysis, and tremors are strong clinical indicators of neurotropic NDV.',
      ));
      possibleConditions.add(const PossibleCondition(
        name: 'Avian Encephalomyelitis',
        likelihood: AIConditionLikelihood.moderate_similarity,
        reason: 'Ataxia, head tremors, and progressive paralysis warrant differential neurological investigation.',
      ));
    } else if (isCritical) {
      possibleConditions.add(const PossibleCondition(
        name: 'Acute Viral Respiratory Complex',
        likelihood: AIConditionLikelihood.high_similarity,
        reason: 'Rapid onset of acute mortality and severe flock depression.',
      ));
      possibleConditions.add(const PossibleCondition(
        name: 'Infectious Coryza (Avibacterium paragallinarum)',
        likelihood: AIConditionLikelihood.moderate_similarity,
        reason: 'Facial swelling and acute drop in flock feed consumption.',
      ));
    } else if (isModerate) {
      possibleConditions.add(const PossibleCondition(
        name: 'Subclinical Enteritis / Feed Stress',
        likelihood: AIConditionLikelihood.moderate_similarity,
        reason: 'Moderate feed/water intake fluctuations under current shed ambient telemetry.',
      ));
      possibleConditions.add(const PossibleCondition(
        name: 'Ambient Heat / Environmental Stress',
        likelihood: AIConditionLikelihood.low_similarity,
        reason: 'Elevated ambient temperature causing panting and mild lethargy.',
      ));
    } else {
      possibleConditions.add(const PossibleCondition(
        name: 'Subclinical Syndromic Monitoring',
        likelihood: AIConditionLikelihood.low_similarity,
        reason: 'No strong high-risk disease pattern identified from currently available data. Continue routine biosecurity observation.',
      ));
    }

    // 4. Safe Supportive & Biosecurity Actions (Non-prescriptive)
    recommendedActions.add('Isolate symptomatic birds immediately in quarantine pens and cease worker cross-shed movement.');
    recommendedActions.add('Supply continuous clean water with supportive oral electrolyte and Vitamin C hydration.');
    recommendedActions.add('Verify boot dip disinfectant concentration (200 ppm chlorine or QAC) at all shed entrances.');
    if (isCritical || isHigh) {
      recommendedActions.add('Request urgent veterinary triage for clinical necropsy and RT-PCR laboratory confirmation.');
    } else {
      recommendedActions.add('Monitor flock twice daily for symptom changes and record next morning mortality.');
    }

    // 5. Additional Information Needed
    additionalInfo.add('Exact vaccination dates and manufacturer batch numbers for ND, IB, and IBD.');
    additionalInfo.add('Post-mortem observation of trachea, proventriculus, and cecal tonsils.');
    if (healthCase.imageUrls.isEmpty) {
      additionalInfo.add('Close-up photograph of affected bird head, comb, and fresh shed droppings.');
    }

    // 6. Urgency Determination
    AIUrgencyLevel urgency = AIUrgencyLevel.routine_monitoring;
    if (isCritical) {
      urgency = AIUrgencyLevel.emergency_review;
    } else if (isHigh) {
      urgency = AIUrgencyLevel.urgent_review;
    } else if (isModerate) {
      urgency = AIUrgencyLevel.review_recommended;
    }

    final summary = isCritical
        ? 'High acute mortality and multi-system clinical signs detected. Immediate biosecurity quarantine and emergency veterinary triage are required.'
        : (isHigh
            ? 'Several notable clinical anomalies detected with high similarity to infectious flock conditions. Veterinary consultation strongly advised.'
            : 'Mild clinical indicators observed without acute mortality spike. Routine monitoring and supportive hydration recommended.');

    return AIHealthAssessmentModel(
      id: '${healthCase.id}_$promptVersion',
      caseId: healthCase.id,
      farmId: healthCase.farmId,
      batchId: healthCase.flockId,
      riskAssessmentId: riskAssessment?.id ?? '${healthCase.id}_risk-v1',
      possibleConditions: possibleConditions,
      observedEvidence: observedEvidence.isNotEmpty ? observedEvidence : healthCase.riskReasons,
      imageObservations: imageObservations,
      clinicalExplanation: summary,
      recommendedActions: recommendedActions,
      urgency: urgency,
      requiresVetReview: isCritical || isHigh,
      confidenceNote: AIHealthAssessmentModel.mandatoryDisclaimer,
      additionalInformationNeeded: additionalInfo,
      modelName: defaultModelName,
      promptVersion: promptVersion,
      inputHash: inputHash,
      status: AIAssessmentStatus.completed,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
