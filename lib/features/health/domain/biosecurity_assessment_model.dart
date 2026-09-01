import 'package:cloud_firestore/cloud_firestore.dart';

/// Answer choice for biosecurity compliance audit questions
enum BiosecurityAnswer {
  yes(2, 'Compliant / Implemented'),
  partial(1, 'Partially Implemented'),
  no(0, 'Non-Compliant / Missing'),
  na(0, 'Not Applicable');

  final int points;
  final String description;
  const BiosecurityAnswer(this.points, this.description);

  static BiosecurityAnswer fromString(String? v) {
    if (v == null) return BiosecurityAnswer.no;
    final norm = v.trim().toLowerCase();
    for (final a in BiosecurityAnswer.values) {
      if (a.name == norm) return a;
    }
    return BiosecurityAnswer.no;
  }
}

/// Qualitative Biosecurity Strength Level
enum BiosecurityStrength {
  strong('STRONG', 'Strong Biosecurity Controls (80-100)'),
  good('GOOD', 'Good Biosecurity Baseline (60-79)'),
  needs_improvement('NEEDS IMPROVEMENT', 'Vulnerabilities Identified (40-59)'),
  high_vulnerability('HIGH VULNERABILITY', 'Critical Biosecurity Gaps (0-39)');

  final String label;
  final String description;
  const BiosecurityStrength(this.label, this.description);

  static BiosecurityStrength fromScore(int score) {
    if (score >= 80) return BiosecurityStrength.strong;
    if (score >= 60) return BiosecurityStrength.good;
    if (score >= 40) return BiosecurityStrength.needs_improvement;
    return BiosecurityStrength.high_vulnerability;
  }
}

/// Structured Risk Factor identified during Biosecurity Audit
class BiosecurityRiskFactor {
  final String code;
  final String category;
  final String severity; // 'critical', 'high', 'medium', 'low'
  final String title;
  final int pointsLost;

  const BiosecurityRiskFactor({
    required this.code,
    required this.category,
    required this.severity,
    required this.title,
    required this.pointsLost,
  });

  factory BiosecurityRiskFactor.fromJson(Map<String, dynamic> json) {
    return BiosecurityRiskFactor(
      code: json['code'] as String? ?? 'gap_general',
      category: json['category'] as String? ?? 'general',
      severity: json['severity'] as String? ?? 'medium',
      title: json['title'] as String? ?? '',
      pointsLost: json['pointsLost'] is int ? json['pointsLost'] as int : 2,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'category': category,
        'severity': severity,
        'title': title,
        'pointsLost': pointsLost,
      };
}

/// Authoritative Farm Biosecurity Assessment Model (SIH26128 Phase 10)
class BiosecurityAssessmentModel {
  final String id;
  final String farmId;
  final String farmName;
  final int score; // 0 - 100
  final BiosecurityStrength strength;

  // 1. Entry & Visitor Control
  final BiosecurityAnswer visitorLogMaintained;
  final BiosecurityAnswer restrictedEntry;
  final BiosecurityAnswer footwearDisinfection;
  final BiosecurityAnswer vehicleDisinfection;
  final BiosecurityAnswer protectiveClothing;

  // 2. Animal & Flock Separation
  final BiosecurityAnswer isolationAreaAvailable;
  final BiosecurityAnswer sickAnimalsIsolated;
  final BiosecurityAnswer newAnimalsQuarantined;
  final BiosecurityAnswer ageGroupsSeparated;

  // 3. Cleaning & Disinfection
  final BiosecurityAnswer routineShedCleaning;
  final BiosecurityAnswer equipmentDisinfection;
  final BiosecurityAnswer feederDrinkerCleaning;
  final BiosecurityAnswer sharedEquipmentControl;

  // 4. Water & Feed Safety
  final BiosecurityAnswer cleanWaterSource;
  final BiosecurityAnswer waterSanitation;
  final BiosecurityAnswer feedContaminationProtection;
  final BiosecurityAnswer feedStorageHygiene;

  // 5. Mortality & Waste Management
  final BiosecurityAnswer safeCarcassDisposal;
  final BiosecurityAnswer wasteDisposal;
  final BiosecurityAnswer litterManureManagement;

  // 6. Vaccination & Health Management
  final BiosecurityAnswer vaccinationRecordsMaintained;
  final BiosecurityAnswer vaccinationUpToDate;
  final BiosecurityAnswer regularHealthMonitoring;
  final BiosecurityAnswer veterinaryContactAvailable;

  // Category-specific percentage scores (0-100)
  final Map<String, int> categoryScores;
  final List<BiosecurityRiskFactor> riskFactors;
  final List<String> recommendations;

  final DateTime assessedAt;
  final String assessedBy;
  final String assessmentVersion; // 'biosecurity-v1'

  const BiosecurityAssessmentModel({
    required this.id,
    required this.farmId,
    this.farmName = 'Primary Farm',
    required this.score,
    required this.strength,
    this.visitorLogMaintained = BiosecurityAnswer.yes,
    this.restrictedEntry = BiosecurityAnswer.yes,
    this.footwearDisinfection = BiosecurityAnswer.yes,
    this.vehicleDisinfection = BiosecurityAnswer.yes,
    this.protectiveClothing = BiosecurityAnswer.yes,
    this.isolationAreaAvailable = BiosecurityAnswer.yes,
    this.sickAnimalsIsolated = BiosecurityAnswer.yes,
    this.newAnimalsQuarantined = BiosecurityAnswer.yes,
    this.ageGroupsSeparated = BiosecurityAnswer.yes,
    this.routineShedCleaning = BiosecurityAnswer.yes,
    this.equipmentDisinfection = BiosecurityAnswer.yes,
    this.feederDrinkerCleaning = BiosecurityAnswer.yes,
    this.sharedEquipmentControl = BiosecurityAnswer.yes,
    this.cleanWaterSource = BiosecurityAnswer.yes,
    this.waterSanitation = BiosecurityAnswer.yes,
    this.feedContaminationProtection = BiosecurityAnswer.yes,
    this.feedStorageHygiene = BiosecurityAnswer.yes,
    this.safeCarcassDisposal = BiosecurityAnswer.yes,
    this.wasteDisposal = BiosecurityAnswer.yes,
    this.litterManureManagement = BiosecurityAnswer.yes,
    this.vaccinationRecordsMaintained = BiosecurityAnswer.yes,
    this.vaccinationUpToDate = BiosecurityAnswer.yes,
    this.regularHealthMonitoring = BiosecurityAnswer.yes,
    this.veterinaryContactAvailable = BiosecurityAnswer.yes,
    this.categoryScores = const {},
    this.riskFactors = const [],
    this.recommendations = const [],
    required this.assessedAt,
    this.assessedBy = 'Farmer',
    this.assessmentVersion = 'biosecurity-v1',
  });

  factory BiosecurityAssessmentModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    BiosecurityAnswer parseAnswer(dynamic v) {
      if (v is bool) return v ? BiosecurityAnswer.yes : BiosecurityAnswer.no;
      return BiosecurityAnswer.fromString(v as String?);
    }

    Map<String, int> parseCatScores(dynamic v) {
      if (v is Map) {
        return v.map((key, val) => MapEntry(key.toString(), parseInt(val)));
      }
      return {};
    }

    List<BiosecurityRiskFactor> parseFactors(dynamic v) {
      if (v is List) {
        return v.map((e) {
          if (e is Map<String, dynamic>) return BiosecurityRiskFactor.fromJson(e);
          if (e is Map) return BiosecurityRiskFactor.fromJson(Map<String, dynamic>.from(e));
          return BiosecurityRiskFactor(
            code: 'legacy_factor',
            category: 'general',
            severity: 'medium',
            title: e.toString(),
            pointsLost: 2,
          );
        }).toList();
      }
      return [];
    }

    List<String> parseList(dynamic v) {
      if (v is List) {
        return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    final scoreVal = parseInt(json['score'] ?? 85);

    return BiosecurityAssessmentModel(
      id: json['id'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      farmName: json['farmName'] as String? ?? 'Primary Farm',
      score: scoreVal,
      strength: BiosecurityStrength.fromScore(scoreVal),
      visitorLogMaintained: parseAnswer(json['visitorLogMaintained']),
      restrictedEntry: parseAnswer(json['restrictedEntry']),
      footwearDisinfection: parseAnswer(json['footwearDisinfection']),
      vehicleDisinfection: parseAnswer(json['vehicleDisinfection']),
      protectiveClothing: parseAnswer(json['protectiveClothing']),
      isolationAreaAvailable: parseAnswer(json['isolationAreaAvailable']),
      sickAnimalsIsolated: parseAnswer(json['sickAnimalsIsolated']),
      newAnimalsQuarantined: parseAnswer(json['newAnimalsQuarantined']),
      ageGroupsSeparated: parseAnswer(json['ageGroupsSeparated']),
      routineShedCleaning: parseAnswer(json['routineShedCleaning']),
      equipmentDisinfection: parseAnswer(json['equipmentDisinfection']),
      feederDrinkerCleaning: parseAnswer(json['feederDrinkerCleaning']),
      sharedEquipmentControl: parseAnswer(json['sharedEquipmentControl']),
      cleanWaterSource: parseAnswer(json['cleanWaterSource']),
      waterSanitation: parseAnswer(json['waterSanitation']),
      feedContaminationProtection: parseAnswer(json['feedContaminationProtection']),
      feedStorageHygiene: parseAnswer(json['feedStorageHygiene']),
      safeCarcassDisposal: parseAnswer(json['safeCarcassDisposal']),
      wasteDisposal: parseAnswer(json['wasteDisposal']),
      litterManureManagement: parseAnswer(json['litterManureManagement']),
      vaccinationRecordsMaintained: parseAnswer(json['vaccinationRecordsMaintained']),
      vaccinationUpToDate: parseAnswer(json['vaccinationUpToDate']),
      regularHealthMonitoring: parseAnswer(json['regularHealthMonitoring']),
      veterinaryContactAvailable: parseAnswer(json['veterinaryContactAvailable']),
      categoryScores: parseCatScores(json['categoryScores']),
      riskFactors: parseFactors(json['riskFactors']),
      recommendations: parseList(json['recommendations']),
      assessedAt: parseDate(json['assessedAt'] ?? json['createdAt']),
      assessedBy: json['assessedBy'] as String? ?? 'Farmer',
      assessmentVersion: json['assessmentVersion'] as String? ?? 'biosecurity-v1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmId': farmId,
      'farmName': farmName,
      'score': score,
      'strength': strength.name,
      'visitorLogMaintained': visitorLogMaintained.name,
      'restrictedEntry': restrictedEntry.name,
      'footwearDisinfection': footwearDisinfection.name,
      'vehicleDisinfection': vehicleDisinfection.name,
      'protectiveClothing': protectiveClothing.name,
      'isolationAreaAvailable': isolationAreaAvailable.name,
      'sickAnimalsIsolated': sickAnimalsIsolated.name,
      'newAnimalsQuarantined': newAnimalsQuarantined.name,
      'ageGroupsSeparated': ageGroupsSeparated.name,
      'routineShedCleaning': routineShedCleaning.name,
      'equipmentDisinfection': equipmentDisinfection.name,
      'feederDrinkerCleaning': feederDrinkerCleaning.name,
      'sharedEquipmentControl': sharedEquipmentControl.name,
      'cleanWaterSource': cleanWaterSource.name,
      'waterSanitation': waterSanitation.name,
      'feedContaminationProtection': feedContaminationProtection.name,
      'feedStorageHygiene': feedStorageHygiene.name,
      'safeCarcassDisposal': safeCarcassDisposal.name,
      'wasteDisposal': wasteDisposal.name,
      'litterManureManagement': litterManureManagement.name,
      'vaccinationRecordsMaintained': vaccinationRecordsMaintained.name,
      'vaccinationUpToDate': vaccinationUpToDate.name,
      'regularHealthMonitoring': regularHealthMonitoring.name,
      'veterinaryContactAvailable': veterinaryContactAvailable.name,
      'categoryScores': categoryScores,
      'riskFactors': riskFactors.map((f) => f.toJson()).toList(),
      'recommendations': recommendations,
      'assessedAt': Timestamp.fromDate(assessedAt),
      'assessedBy': assessedBy,
      'assessmentVersion': assessmentVersion,
    };
  }
}
