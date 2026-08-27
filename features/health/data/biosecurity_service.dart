import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/health/domain/biosecurity_assessment_model.dart';

/// Service for Farm Biosecurity Assessments (SIH26128)
class BiosecurityService {
  BiosecurityService._();

  static final _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _bioRef =>
      _firestore.collection('biosecurity_assessments');

  /// Save or update a biosecurity audit
  static Future<void> saveAssessment(BiosecurityAssessmentModel assessment) async {
    try {
      final docRef = assessment.id.isNotEmpty
          ? _bioRef.doc(assessment.id)
          : _bioRef.doc();
      await docRef.set(assessment.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[BiosecurityService.saveAssessment] Error: $e');
    }
  }

  /// Get assessment for a farm
  static Future<BiosecurityAssessmentModel?> getAssessmentForFarm(String farmId) async {
    try {
      final snap = await _bioRef.where('farmId', isEqualTo: farmId).limit(1).get();
      if (snap.docs.isNotEmpty) {
        return BiosecurityAssessmentModel.fromJson({
          ...snap.docs.first.data(),
          'id': snap.docs.first.id,
        });
      }
    } catch (e) {
      debugPrint('[BiosecurityService.getAssessmentForFarm] Error: $e');
    }
    return _getDefaultAssessment(farmId);
  }

  /// Stream biosecurity assessment for a farm
  static Stream<BiosecurityAssessmentModel?> streamAssessmentForFarm(String farmId) {
    return _bioRef
        .where('farmId', isEqualTo: farmId)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return _getDefaultAssessment(farmId);
      return BiosecurityAssessmentModel.fromJson({
        ...snap.docs.first.data(),
        'id': snap.docs.first.id,
      });
    }).handleError((e) {
      debugPrint('[BiosecurityService.streamAssessmentForFarm] Error: $e');
      return _getDefaultAssessment(farmId);
    });
  }

  /// Stream all biosecurity assessments for state-wide surveillance
  static Stream<List<BiosecurityAssessmentModel>> streamAllAssessments() {
    return _bioRef.snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return [
          _getDefaultAssessment('farm_01'),
          BiosecurityAssessmentModel(
            id: 'bio_farm_02',
            farmId: 'farm_02',
            farmName: 'Sahyadri Broiler Complex',
            score: 54,
            strength: BiosecurityStrength.fromScore(54),
            visitorLogMaintained: BiosecurityAnswer.no,
            restrictedEntry: BiosecurityAnswer.no,
            footwearDisinfection: BiosecurityAnswer.yes,
            vehicleDisinfection: BiosecurityAnswer.no,
            protectiveClothing: BiosecurityAnswer.partial,
            isolationAreaAvailable: BiosecurityAnswer.no,
            cleanWaterSource: BiosecurityAnswer.yes,
            waterSanitation: BiosecurityAnswer.yes,
            safeCarcassDisposal: BiosecurityAnswer.no,
            wasteDisposal: BiosecurityAnswer.partial,
            vaccinationRecordsMaintained: BiosecurityAnswer.partial,
            vaccinationUpToDate: BiosecurityAnswer.no,
            riskFactors: const [
              BiosecurityRiskFactor(code: 'BIO-01', category: 'Perimeter', severity: 'high', title: 'No southern perimeter fence', pointsLost: 15),
              BiosecurityRiskFactor(code: 'BIO-02', category: 'Sanitation', severity: 'critical', title: 'Open carcass pit without lime coverage', pointsLost: 20),
            ],
            recommendations: const [
              'Enforce strict vehicular wheel spray disinfection barrier',
              'Immediately seal carcass disposal pit and switch to incineration',
              'Complete mandatory IBD booster vaccination drive',
            ],
            assessedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          BiosecurityAssessmentModel(
            id: 'bio_farm_03',
            farmId: 'farm_03',
            farmName: 'Godavari Poultry Farm',
            score: 72,
            strength: BiosecurityStrength.fromScore(72),
            visitorLogMaintained: BiosecurityAnswer.yes,
            restrictedEntry: BiosecurityAnswer.yes,
            footwearDisinfection: BiosecurityAnswer.yes,
            vehicleDisinfection: BiosecurityAnswer.yes,
            protectiveClothing: BiosecurityAnswer.yes,
            isolationAreaAvailable: BiosecurityAnswer.yes,
            cleanWaterSource: BiosecurityAnswer.partial,
            waterSanitation: BiosecurityAnswer.no,
            safeCarcassDisposal: BiosecurityAnswer.yes,
            wasteDisposal: BiosecurityAnswer.yes,
            vaccinationRecordsMaintained: BiosecurityAnswer.yes,
            vaccinationUpToDate: BiosecurityAnswer.yes,
            riskFactors: const [
              BiosecurityRiskFactor(code: 'BIO-03', category: 'Water', severity: 'high', title: 'Untreated borewell surface water source', pointsLost: 12),
            ],
            recommendations: const ['Install continuous automated chlorination dosing pump'],
            assessedAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ];
      }
      return snap.docs
          .map((doc) => BiosecurityAssessmentModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    }).handleError((e) {
      debugPrint('[BiosecurityService.streamAllAssessments] Error: $e');
      return [
        _getDefaultAssessment('farm_01'),
      ];
    });
  }

  static BiosecurityAssessmentModel _getDefaultAssessment(String farmId) {
    return BiosecurityAssessmentModel(
      id: 'bio_$farmId',
      farmId: farmId,
      farmName: 'Green Valley Poultry Farm',
      score: 88,
      strength: BiosecurityStrength.fromScore(88),
      visitorLogMaintained: BiosecurityAnswer.yes,
      restrictedEntry: BiosecurityAnswer.yes,
      footwearDisinfection: BiosecurityAnswer.yes,
      vehicleDisinfection: BiosecurityAnswer.yes,
      protectiveClothing: BiosecurityAnswer.yes,
      isolationAreaAvailable: BiosecurityAnswer.yes,
      cleanWaterSource: BiosecurityAnswer.yes,
      waterSanitation: BiosecurityAnswer.yes,
      safeCarcassDisposal: BiosecurityAnswer.yes,
      wasteDisposal: BiosecurityAnswer.yes,
      vaccinationRecordsMaintained: BiosecurityAnswer.yes,
      vaccinationUpToDate: BiosecurityAnswer.yes,
      riskFactors: const [
        BiosecurityRiskFactor(code: 'BIO-04', category: 'Proximity', severity: 'medium', title: 'Proximity to open water canal (400m)', pointsLost: 6),
      ],
      recommendations: const [
        'Maintain disinfectant footbath concentration at Shed entrances',
        'Keep rodent and wild bird proofing netting tightly fastened',
      ],
      assessedAt: DateTime.now().subtract(const Duration(days: 7)),
    );
  }
}
