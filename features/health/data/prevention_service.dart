import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/core/services/audit_service.dart';
import 'package:flock_sense/features/health/data/prevention_engine.dart';
import 'package:flock_sense/features/health/domain/biosecurity_assessment_model.dart';
import 'package:flock_sense/features/health/domain/prevention_recommendation_model.dart';

/// Central Service for Biosecurity Assessments & Protective Action Tracking (SIH26128 Phase 10)
class PreventionService {
  PreventionService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _auditService = AuditService();

  static CollectionReference<Map<String, dynamic>> get _assessmentsRef =>
      _firestore.collection('biosecurity_assessments');
  static CollectionReference<Map<String, dynamic>> get _recommendationsRef =>
      _firestore.collection('prevention_recommendations');

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. SAVE / REASSESS BIOSECURITY AUDIT
  // ─────────────────────────────────────────────────────────────────────────────

  /// Saves a new versioned biosecurity assessment without overwriting history
  static Future<bool> saveAssessment(BiosecurityAssessmentModel assessment) async {
    try {
      final docRef = _assessmentsRef.doc(assessment.id);
      await docRef.set(assessment.toJson());

      await _auditService.logOperation(
        operation: AuditOperation.dataSync,
        resourceType: 'BiosecurityAssessment',
        resourceId: assessment.id,
        changes: {
          'action': 'BIOSECURITY_ASSESSMENT_CREATED',
          'farmId': assessment.farmId,
          'score': assessment.score,
          'strength': assessment.strength.name,
          'version': assessment.assessmentVersion,
        },
      );
      return true;
    } catch (e) {
      debugPrint('[PreventionService.saveAssessment] Error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. STREAM LATEST ASSESSMENT & HISTORY FOR A FARM
  // ─────────────────────────────────────────────────────────────────────────────

  static Stream<BiosecurityAssessmentModel?> streamLatestAssessment(String farmId) {
    return _assessmentsRef
        .where('farmId', isEqualTo: farmId)
        .orderBy('assessedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return _getDefaultAssessment(farmId);
      return BiosecurityAssessmentModel.fromJson({
        ...snap.docs.first.data(),
        'id': snap.docs.first.id,
      });
    }).handleError((e) {
      debugPrint('[PreventionService.streamLatestAssessment] Error: $e');
      return _getDefaultAssessment(farmId);
    });
  }

  static Stream<List<BiosecurityAssessmentModel>> streamAssessmentHistory(String farmId) {
    return _assessmentsRef
        .where('farmId', isEqualTo: farmId)
        .orderBy('assessedAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((d) => BiosecurityAssessmentModel.fromJson({...d.data(), 'id': d.id}))
          .toList();
    }).handleError((e) {
      debugPrint('[PreventionService.streamAssessmentHistory] Error: $e');
      return <BiosecurityAssessmentModel>[_getDefaultAssessment(farmId)];
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. STREAM & MANAGE PREVENTIVE RECOMMENDATIONS
  // ─────────────────────────────────────────────────────────────────────────────

  static Stream<List<PreventionRecommendationModel>> streamActiveRecommendations(String farmId) {
    return _recommendationsRef
        .where('farmId', isEqualTo: farmId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => PreventionRecommendationModel.fromJson({...d.data(), 'id': d.id}))
          .toList();
      list.sort((a, b) => b.priority.index.compareTo(a.priority.index));
      return list;
    }).handleError((e) {
      debugPrint('[PreventionService.streamActiveRecommendations] Error: $e');
      return _getDefaultRecommendations(farmId);
    });
  }

  /// Updates recommendation status with optional farmer evidence
  static Future<bool> updateRecommendationStatus(
    String recommendationId,
    PreventionActionStatus status, {
    String? evidenceNote,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == PreventionActionStatus.completed) {
        updates['completedAt'] = FieldValue.serverTimestamp();
      }
      if (evidenceNote != null && evidenceNote.isNotEmpty) {
        updates['evidenceNote'] = evidenceNote;
      }

      await _recommendationsRef.doc(recommendationId).update(updates);

      await _auditService.logOperation(
        operation: AuditOperation.dataSync,
        resourceType: 'PreventionRecommendation',
        resourceId: recommendationId,
        changes: {
          'action': 'PREVENTION_ACTION_STATUS_CHANGED',
          'newStatus': status.name,
          'note': evidenceNote ?? '',
        },
      );
      return true;
    } catch (e) {
      debugPrint('[PreventionService.updateRecommendationStatus] Error: $e');
      return false;
    }
  }

  /// Saves a custom preventive recommendation authored by an attending veterinarian
  static Future<bool> addVetRecommendation(PreventionRecommendationModel rec) async {
    try {
      await _recommendationsRef.doc(rec.id).set(rec.toJson());

      await _auditService.logOperation(
        operation: AuditOperation.dataSync,
        resourceType: 'PreventionRecommendation',
        resourceId: rec.id,
        changes: {
          'action': 'VET_PREVENTION_ACTION_ADDED',
          'farmId': rec.farmId,
          'title': rec.title,
          'vet': rec.createdBy ?? 'Attending Vet',
        },
      );
      return true;
    } catch (e) {
      debugPrint('[PreventionService.addVetRecommendation] Error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SAMPLE DEFAULTS & FALLBACKS
  // ─────────────────────────────────────────────────────────────────────────────

  static BiosecurityAssessmentModel _getDefaultAssessment(String farmId) {
    return PreventionEngine.evaluateBiosecurity(
      farmId: farmId,
      farmName: 'Green Valley Poultry Farm',
      visitorLogMaintained: BiosecurityAnswer.partial,
      restrictedEntry: BiosecurityAnswer.yes,
      footwearDisinfection: BiosecurityAnswer.no,
      vehicleDisinfection: BiosecurityAnswer.partial,
      protectiveClothing: BiosecurityAnswer.partial,
      isolationAreaAvailable: BiosecurityAnswer.no,
      sickAnimalsIsolated: BiosecurityAnswer.no,
      newAnimalsQuarantined: BiosecurityAnswer.yes,
      ageGroupsSeparated: BiosecurityAnswer.yes,
      routineShedCleaning: BiosecurityAnswer.yes,
      equipmentDisinfection: BiosecurityAnswer.partial,
      feederDrinkerCleaning: BiosecurityAnswer.yes,
      sharedEquipmentControl: BiosecurityAnswer.no,
      cleanWaterSource: BiosecurityAnswer.yes,
      waterSanitation: BiosecurityAnswer.no,
      feedContaminationProtection: BiosecurityAnswer.yes,
      feedStorageHygiene: BiosecurityAnswer.yes,
      safeCarcassDisposal: BiosecurityAnswer.no,
      wasteDisposal: BiosecurityAnswer.partial,
      litterManureManagement: BiosecurityAnswer.yes,
      vaccinationRecordsMaintained: BiosecurityAnswer.yes,
      vaccinationUpToDate: BiosecurityAnswer.no,
      regularHealthMonitoring: BiosecurityAnswer.yes,
      veterinaryContactAvailable: BiosecurityAnswer.yes,
    );
  }

  static List<PreventionRecommendationModel> _getDefaultRecommendations(String farmId) {
    final now = DateTime.now();
    return [
      PreventionRecommendationModel(
        id: 'rec_${farmId}_nearby_outbreak_01',
        farmId: farmId,
        source: 'nearby_cluster',
        category: 'biosecurity_perimeter',
        priority: PreventionPriority.critical,
        title: 'Nearby Outbreak Early Warning (~6.8 km)',
        description: 'A respiratory disease cluster is actively monitored within ~6.8 km of your premises in Nashik.',
        recommendedAction: 'Enforce immediate visitor freeze, refresh shed entry footbaths daily, and monitor flock clicking sounds.',
        reason: 'Epidemiological proximity increases pathogen transmission risk via vehicles, wild birds, or shared transit.',
        ruleCode: 'nearby_cluster_advisory',
        status: PreventionActionStatus.recommended,
        createdAt: now,
        updatedAt: now,
      ),
      PreventionRecommendationModel(
        id: 'rec_${farmId}_sick_isolation_02',
        farmId: farmId,
        source: 'biosecurity_assessment',
        category: 'flock_isolation',
        priority: PreventionPriority.critical,
        title: 'Establish Sick Bird Isolation Pen',
        description: 'Audit flags that symptomatic birds remain in the main shed airspace.',
        recommendedAction: 'Segregate birds showing respiratory distress or rales into a secure recovery pen immediately.',
        reason: 'Reduces viral aerosol shedding into healthy flock population.',
        ruleCode: 'bio_isolate_sick_birds',
        status: PreventionActionStatus.in_progress,
        createdAt: now.subtract(const Duration(hours: 12)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      PreventionRecommendationModel(
        id: 'rec_${farmId}_footbath_03',
        farmId: farmId,
        source: 'biosecurity_assessment',
        category: 'disinfection',
        priority: PreventionPriority.high,
        title: 'Install Disinfectant Footbaths at Shed Doors',
        description: 'Footwear disinfection at shed entry is currently missing.',
        recommendedAction: 'Place shallow plastic trays with fresh virucidal disinfectant solution at all active shed entrances.',
        reason: 'Prevents attendants from tracking field pathogens across shed thresholds.',
        ruleCode: 'bio_footwear_disinfection',
        status: PreventionActionStatus.recommended,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      PreventionRecommendationModel(
        id: 'rec_${farmId}_vet_chlorination_04',
        farmId: farmId,
        source: 'veterinarian',
        category: 'water_feed',
        priority: PreventionPriority.high,
        title: 'Maintain 2.5 ppm Water Chlorination',
        description: 'Prescribed by Dr. Rajesh Sharma (Nashik DVO) during routine surveillance visit.',
        recommendedAction: 'Dose overhead water storage tanks with sodium hypochlorite daily to eliminate waterborne pathogens.',
        reason: 'Water chlorination breaks bacterial secondary infections during high-risk disease season.',
        ruleCode: 'vet_water_chlorine',
        status: PreventionActionStatus.completed,
        completedAt: now.subtract(const Duration(hours: 4)),
        evidenceNote: 'Installed chlorine dosing float in overhead tank #1 and #2.',
        createdBy: 'Dr. Rajesh Sharma (Vet Officer)',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 4)),
      ),
    ];
  }
}
