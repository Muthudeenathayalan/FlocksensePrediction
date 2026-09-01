import 'package:flock_sense/features/health/domain/health_case_model.dart';

/// Regional District Animal Health & Disease Surveillance Summary (SIH26128 Phase 9)
class DistrictSurveillanceSummary {
  final String district;
  final String state;

  final int activeCases;
  final int criticalCases;
  final int highRiskCases;
  final int farmsAtRisk; // Unique distinct farms
  final int activeClusters;

  final int affectedCount;
  final int mortalityCount;

  final double vaccinationCoveragePercent;
  final int averageVetResponseTimeMinutes;

  final int districtRiskScore; // 0-100
  final HealthRiskLevel districtRiskLevel;
  final List<String> riskReasons; // Explainable evidence points

  final DateTime updatedAt;

  const DistrictSurveillanceSummary({
    required this.district,
    this.state = 'Maharashtra',
    required this.activeCases,
    required this.criticalCases,
    required this.highRiskCases,
    required this.farmsAtRisk,
    required this.activeClusters,
    required this.affectedCount,
    required this.mortalityCount,
    required this.vaccinationCoveragePercent,
    required this.averageVetResponseTimeMinutes,
    required this.districtRiskScore,
    required this.districtRiskLevel,
    this.riskReasons = const [],
    required this.updatedAt,
  });

  factory DistrictSurveillanceSummary.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    double parseDouble(dynamic v) {
      if (v is double) return v;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    List<String> parseList(dynamic v) {
      if (v is List) {
        return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    final score = parseInt(json['districtRiskScore'] ?? 0);

    return DistrictSurveillanceSummary(
      district: json['district'] as String? ?? 'Nashik',
      state: json['state'] as String? ?? 'Maharashtra',
      activeCases: parseInt(json['activeCases']),
      criticalCases: parseInt(json['criticalCases']),
      highRiskCases: parseInt(json['highRiskCases']),
      farmsAtRisk: parseInt(json['farmsAtRisk']),
      activeClusters: parseInt(json['activeClusters']),
      affectedCount: parseInt(json['affectedCount']),
      mortalityCount: parseInt(json['mortalityCount']),
      vaccinationCoveragePercent: parseDouble(json['vaccinationCoveragePercent'] ?? 78.0),
      averageVetResponseTimeMinutes: parseInt(json['averageVetResponseTimeMinutes'] ?? 18),
      districtRiskScore: score,
      districtRiskLevel: HealthRiskLevel.fromScore(score),
      riskReasons: parseList(json['riskReasons']),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'district': district,
      'state': state,
      'activeCases': activeCases,
      'criticalCases': criticalCases,
      'highRiskCases': highRiskCases,
      'farmsAtRisk': farmsAtRisk,
      'activeClusters': activeClusters,
      'affectedCount': affectedCount,
      'mortalityCount': mortalityCount,
      'vaccinationCoveragePercent': vaccinationCoveragePercent,
      'averageVetResponseTimeMinutes': averageVetResponseTimeMinutes,
      'districtRiskScore': districtRiskScore,
      'districtRiskLevel': districtRiskLevel.name,
      'riskReasons': riskReasons,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Farm Risk Map Point for Government GIS Layer
class FarmGisMapMarker {
  final String farmId;
  final String farmName;
  final String district;
  final double latitude;
  final double longitude;
  final HealthRiskLevel highestRiskLevel;
  final int activeCases;
  final int mortalityCount;
  final String currentSyndrome;
  final DateTime lastReportedAt;

  const FarmGisMapMarker({
    required this.farmId,
    required this.farmName,
    required this.district,
    required this.latitude,
    required this.longitude,
    required this.highestRiskLevel,
    required this.activeCases,
    required this.mortalityCount,
    required this.currentSyndrome,
    required this.lastReportedAt,
  });

  bool get isValidLocation =>
      latitude >= -90.0 &&
      latitude <= 90.0 &&
      longitude >= -180.0 &&
      longitude <= 180.0 &&
      !(latitude == 0.0 && longitude == 0.0);
}
