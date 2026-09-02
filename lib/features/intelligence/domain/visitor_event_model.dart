/// Visitor Event & Biosecurity Entry Model (Part 5)
/// Records transparent event-level visitor history and biosecurity exposure
class VisitorEventModel {
  final String id;
  final String farmId;
  final String visitorName;
  final String visitorType; // 'veterinarian', 'feed_supplier', 'chick_delivery', 'buyer', 'neighboring_farmer', 'service_tech', 'inspector', 'other'
  final String organization;
  final String purpose;

  final DateTime enteredAt;
  final DateTime? exitedAt;

  final bool visitedLivestockFarmRecently; // Within last 48-72h
  final bool vehicleEntered;
  final bool footwearDisinfected;
  final bool vehicleDisinfected;
  final bool ppeUsed;

  final List<String> areasVisited; // 'shed_1', 'feed_store', 'perimeter', 'office'
  final bool sharedEquipment;
  final bool newAnimalIntroductionRelated;

  final String notes;
  final int exposureScore; // 0 - 100 calculated by VisitorExposureEngine

  final String createdBy;
  final DateTime createdAt;

  const VisitorEventModel({
    required this.id,
    required this.farmId,
    required this.visitorName,
    this.visitorType = 'visitor',
    this.organization = '',
    required this.purpose,
    required this.enteredAt,
    this.exitedAt,
    this.visitedLivestockFarmRecently = false,
    this.vehicleEntered = false,
    this.footwearDisinfected = true,
    this.vehicleDisinfected = true,
    this.ppeUsed = true,
    this.areasVisited = const ['shed'],
    this.sharedEquipment = false,
    this.newAnimalIntroductionRelated = false,
    this.notes = '',
    this.exposureScore = 15,
    this.createdBy = 'Farmer',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'farmId': farmId,
        'visitorName': visitorName,
        'visitorType': visitorType,
        'organization': organization,
        'purpose': purpose,
        'enteredAt': enteredAt.toIso8601String(),
        'exitedAt': exitedAt?.toIso8601String(),
        'visitedLivestockFarmRecently': visitedLivestockFarmRecently,
        'vehicleEntered': vehicleEntered,
        'footwearDisinfected': footwearDisinfected,
        'vehicleDisinfected': vehicleDisinfected,
        'ppeUsed': ppeUsed,
        'areasVisited': areasVisited,
        'sharedEquipment': sharedEquipment,
        'newAnimalIntroductionRelated': newAnimalIntroductionRelated,
        'notes': notes,
        'exposureScore': exposureScore,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
      };

  factory VisitorEventModel.fromJson(Map<String, dynamic> json) {
    return VisitorEventModel(
      id: json['id'] as String? ?? 'vis_${DateTime.now().millisecondsSinceEpoch}',
      farmId: json['farmId'] as String? ?? '',
      visitorName: json['visitorName'] as String? ?? 'Unknown Visitor',
      visitorType: json['visitorType'] as String? ?? 'visitor',
      organization: json['organization'] as String? ?? '',
      purpose: json['purpose'] as String? ?? 'Routine Visit',
      enteredAt: json['enteredAt'] != null
          ? DateTime.parse(json['enteredAt'] as String)
          : DateTime.now(),
      exitedAt: json['exitedAt'] != null
          ? DateTime.parse(json['exitedAt'] as String)
          : null,
      visitedLivestockFarmRecently:
          json['visitedLivestockFarmRecently'] as bool? ?? false,
      vehicleEntered: json['vehicleEntered'] as bool? ?? false,
      footwearDisinfected: json['footwearDisinfected'] as bool? ?? true,
      vehicleDisinfected: json['vehicleDisinfected'] as bool? ?? true,
      ppeUsed: json['ppeUsed'] as bool? ?? true,
      areasVisited: (json['areasVisited'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['shed'],
      sharedEquipment: json['sharedEquipment'] as bool? ?? false,
      newAnimalIntroductionRelated:
          json['newAnimalIntroductionRelated'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
      exposureScore: (json['exposureScore'] as num?)?.toInt() ?? 15,
      createdBy: json['createdBy'] as String? ?? 'Farmer',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

/// Aggregated Biosecurity Exposure Status
enum BiosecurityExposureLevel {
  low,
  moderate,
  high,
  critical;

  String get label {
    switch (this) {
      case BiosecurityExposureLevel.low:
        return 'LOW';
      case BiosecurityExposureLevel.moderate:
        return 'MODERATE';
      case BiosecurityExposureLevel.high:
        return 'HIGH';
      case BiosecurityExposureLevel.critical:
        return 'CRITICAL';
    }
  }
}

/// Visitor & Biosecurity Exposure Evaluation Output
class VisitorExposureResult {
  final int biosecurityExposureScore; // 0 - 100
  final BiosecurityExposureLevel biosecurityExposureLevel;
  final List<VisitorEventModel> recentEvents;
  final List<String> contributingFactors;
  final String explanation;

  const VisitorExposureResult({
    required this.biosecurityExposureScore,
    required this.biosecurityExposureLevel,
    this.recentEvents = const [],
    this.contributingFactors = const [],
    this.explanation =
        'Recent external-contact/biosecurity exposure occurred before the health deterioration and should be reviewed.',
  });

  Map<String, dynamic> toJson() => {
        'biosecurityExposureScore': biosecurityExposureScore,
        'biosecurityExposureLevel': biosecurityExposureLevel.name,
        'contributingFactors': contributingFactors,
        'explanation': explanation,
      };

  factory VisitorExposureResult.fromJson(Map<String, dynamic> json) {
    return VisitorExposureResult(
      biosecurityExposureScore:
          (json['biosecurityExposureScore'] as num?)?.toInt() ?? 0,
      biosecurityExposureLevel: BiosecurityExposureLevel.values.firstWhere(
        (e) => e.name == json['biosecurityExposureLevel'],
        orElse: () => BiosecurityExposureLevel.low,
      ),
      contributingFactors: (json['contributingFactors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      explanation: json['explanation'] as String? ??
          'Recent external-contact/biosecurity exposure occurred before the health deterioration and should be reviewed.',
    );
  }
}
