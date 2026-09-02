/// Nearby Disease Exposure Level
enum NearbyExposureLevel {
  low,
  moderate,
  high,
  critical;

  String get label {
    switch (this) {
      case NearbyExposureLevel.low:
        return 'LOW';
      case NearbyExposureLevel.moderate:
        return 'MODERATE';
      case NearbyExposureLevel.high:
        return 'HIGH';
      case NearbyExposureLevel.critical:
        return 'CRITICAL';
    }
  }
}

/// Detailed Nearby Signal Data for Authorized Clinician / Government View
class NearbySignalDetail {
  final String farmId;
  final String farmName; // Anonymized when displayed to farmers
  final double distanceKm;
  final String syndrome;
  final String riskLevel;
  final DateTime reportedAt;
  final bool hasVetDiagnosis;
  final bool hasLabConfirmation;

  const NearbySignalDetail({
    required this.farmId,
    required this.farmName,
    required this.distanceKm,
    required this.syndrome,
    required this.riskLevel,
    required this.reportedAt,
    this.hasVetDiagnosis = false,
    this.hasLabConfirmation = false,
  });

  Map<String, dynamic> toJson() => {
        'farmId': farmId,
        'farmName': farmName,
        'distanceKm': distanceKm,
        'syndrome': syndrome,
        'riskLevel': riskLevel,
        'reportedAt': reportedAt.toIso8601String(),
        'hasVetDiagnosis': hasVetDiagnosis,
        'hasLabConfirmation': hasLabConfirmation,
      };

  factory NearbySignalDetail.fromJson(Map<String, dynamic> json) {
    return NearbySignalDetail(
      farmId: json['farmId'] as String? ?? '',
      farmName: json['farmName'] as String? ?? 'Nearby Farm',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      syndrome: json['syndrome'] as String? ?? 'respiratory',
      riskLevel: json['riskLevel'] as String? ?? 'high',
      reportedAt: json['reportedAt'] != null
          ? DateTime.parse(json['reportedAt'] as String)
          : DateTime.now(),
      hasVetDiagnosis: json['hasVetDiagnosis'] as bool? ?? false,
      hasLabConfirmation: json['hasLabConfirmation'] as bool? ?? false,
    );
  }
}

/// Nearby Farm Exposure Model (Part 6)
/// Provides spatio-temporal disease correlation and privacy-safe anonymization
class NearbyExposureModel {
  final int nearbyHighRiskFarmCount;
  final int nearbyCriticalFarmCount;
  final double nearestCaseDistanceKm;
  final int similarSyndromeCaseCount;
  final int timeWindowHours;
  final int vetSupportedCaseCount;
  final int labSupportedCaseCount;

  final int nearbyExposureScore; // 0 - 100
  final NearbyExposureLevel nearbyExposureLevel;

  /// Privacy-safe output for farmer: never reveals other farm's identity or coordinates
  final String farmerAnonymizedSummary;

  /// Detailed clinical context for authorized veterinarians and government officers
  final String clinicalSummary;

  final List<NearbySignalDetail> nearbySignals;

  const NearbyExposureModel({
    this.nearbyHighRiskFarmCount = 0,
    this.nearbyCriticalFarmCount = 0,
    this.nearestCaseDistanceKm = 999.0,
    this.similarSyndromeCaseCount = 0,
    this.timeWindowHours = 72,
    this.vetSupportedCaseCount = 0,
    this.labSupportedCaseCount = 0,
    this.nearbyExposureScore = 0,
    this.nearbyExposureLevel = NearbyExposureLevel.low,
    required this.farmerAnonymizedSummary,
    required this.clinicalSummary,
    this.nearbySignals = const [],
  });

  Map<String, dynamic> toJson() => {
        'nearbyHighRiskFarmCount': nearbyHighRiskFarmCount,
        'nearbyCriticalFarmCount': nearbyCriticalFarmCount,
        'nearestCaseDistanceKm': nearestCaseDistanceKm,
        'similarSyndromeCaseCount': similarSyndromeCaseCount,
        'timeWindowHours': timeWindowHours,
        'vetSupportedCaseCount': vetSupportedCaseCount,
        'labSupportedCaseCount': labSupportedCaseCount,
        'nearbyExposureScore': nearbyExposureScore,
        'nearbyExposureLevel': nearbyExposureLevel.name,
        'farmerAnonymizedSummary': farmerAnonymizedSummary,
        'clinicalSummary': clinicalSummary,
        'nearbySignals': nearbySignals.map((s) => s.toJson()).toList(),
      };

  factory NearbyExposureModel.fromJson(Map<String, dynamic> json) {
    return NearbyExposureModel(
      nearbyHighRiskFarmCount:
          (json['nearbyHighRiskFarmCount'] as num?)?.toInt() ?? 0,
      nearbyCriticalFarmCount:
          (json['nearbyCriticalFarmCount'] as num?)?.toInt() ?? 0,
      nearestCaseDistanceKm:
          (json['nearestCaseDistanceKm'] as num?)?.toDouble() ?? 999.0,
      similarSyndromeCaseCount:
          (json['similarSyndromeCaseCount'] as num?)?.toInt() ?? 0,
      timeWindowHours: (json['timeWindowHours'] as num?)?.toInt() ?? 72,
      vetSupportedCaseCount:
          (json['vetSupportedCaseCount'] as num?)?.toInt() ?? 0,
      labSupportedCaseCount:
          (json['labSupportedCaseCount'] as num?)?.toInt() ?? 0,
      nearbyExposureScore: (json['nearbyExposureScore'] as num?)?.toInt() ?? 0,
      nearbyExposureLevel: NearbyExposureLevel.values.firstWhere(
        (e) => e.name == json['nearbyExposureLevel'],
        orElse: () => NearbyExposureLevel.low,
      ),
      farmerAnonymizedSummary: json['farmerAnonymizedSummary'] as String? ??
          'No elevated disease activity reported in the immediate surrounding corridor.',
      clinicalSummary: json['clinicalSummary'] as String? ??
          'Baseline epidemiological corridor stable.',
      nearbySignals: (json['nearbySignals'] as List<dynamic>?)
              ?.map((e) =>
                  NearbySignalDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
