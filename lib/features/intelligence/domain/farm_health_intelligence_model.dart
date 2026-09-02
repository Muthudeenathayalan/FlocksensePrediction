import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/intelligence/domain/disease_evidence_model.dart';
import 'package:flock_sense/features/intelligence/domain/environmental_intelligence_model.dart';
import 'package:flock_sense/features/intelligence/domain/farm_health_timeline_model.dart';
import 'package:flock_sense/features/intelligence/domain/farm_metric_baseline_model.dart';
import 'package:flock_sense/features/intelligence/domain/nearby_exposure_model.dart';
import 'package:flock_sense/features/intelligence/domain/role_recommendation_model.dart';
import 'package:flock_sense/features/intelligence/domain/syndrome_engine_model.dart';
import 'package:flock_sense/features/intelligence/domain/visitor_event_model.dart';

/// Farm Overall Behaviour Status
enum FarmBehaviourStatus {
  normal,
  watch,
  abnormal,
  severeAnomaly;

  String get label {
    switch (this) {
      case FarmBehaviourStatus.normal:
        return 'NORMAL';
      case FarmBehaviourStatus.watch:
        return 'WATCH';
      case FarmBehaviourStatus.abnormal:
        return 'ABNORMAL';
      case FarmBehaviourStatus.severeAnomaly:
        return 'SEVERE ANOMALY';
    }
  }
}

/// Central Unified Farm Health Intelligence Model (Part 9)
/// Represents the authoritative composite intelligence assessment for any poultry farm
class FarmHealthIntelligenceModel {
  final String farmId;
  final String? batchId;
  final String farmName;

  // Composite Multi-Level Scoring
  final int overallRiskScore; // 0 - 100
  final HealthRiskLevel overallRiskLevel; // low, moderate, high, critical
  final FarmBehaviourStatus farmBehaviourStatus;

  // 1. Syndrome Engine
  final PrimarySyndrome primarySyndrome;
  final SyndromeSignalStrength syndromeSignalStrength;
  final SyndromeEvaluationResult? syndromeResult;

  // 2. Environmental & Thermal Telemetry
  final int environmentalStressScore;
  final EnvironmentalStressLevel environmentalStressLevel;
  final EnvironmentalStressResult environmentalStressResult;

  // 3. Visitor & Biosecurity Event Exposure
  final int biosecurityExposureScore;
  final BiosecurityExposureLevel biosecurityExposureLevel;
  final VisitorExposureResult visitorExposureResult;

  // 4. Nearby Spatial-Temporal Correlation
  final int nearbyExposureScore;
  final NearbyExposureLevel nearbyExposureLevel;
  final NearbyExposureModel nearbyExposure;

  // 5. Differential Disease Evidence Matching
  final List<DiseaseCandidate> diseaseCandidates;

  // 6. 7-Day Baseline Metrics
  final Map<String, FarmMetricBaseline> metricBaselines;

  // 7. Explainability & Signals
  final List<String> topContributingSignals;
  final List<String> missingEvidence;
  final String dataQuality; // 'Good', 'Adequate', 'Limited'

  // 8. Actionable Role-Tailored Recommendations
  final List<RoleRecommendationModel> recommendations;

  // 9. Farm Health Timeline
  final List<FarmHealthTimelineEvent> timeline;

  final DateTime updatedAt;

  const FarmHealthIntelligenceModel({
    required this.farmId,
    this.batchId,
    this.farmName = 'Poultry Farm',
    required this.overallRiskScore,
    required this.overallRiskLevel,
    required this.farmBehaviourStatus,
    required this.primarySyndrome,
    required this.syndromeSignalStrength,
    this.syndromeResult,
    required this.environmentalStressScore,
    required this.environmentalStressLevel,
    required this.environmentalStressResult,
    required this.biosecurityExposureScore,
    required this.biosecurityExposureLevel,
    required this.visitorExposureResult,
    required this.nearbyExposureScore,
    required this.nearbyExposureLevel,
    required this.nearbyExposure,
    this.diseaseCandidates = const [],
    this.metricBaselines = const {},
    this.topContributingSignals = const [],
    this.missingEvidence = const [],
    this.dataQuality = 'Good',
    this.recommendations = const [],
    this.timeline = const [],
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'farmId': farmId,
        'batchId': batchId,
        'farmName': farmName,
        'overallRiskScore': overallRiskScore,
        'overallRiskLevel': overallRiskLevel.name,
        'farmBehaviourStatus': farmBehaviourStatus.name,
        'primarySyndrome': primarySyndrome.name,
        'syndromeSignalStrength': syndromeSignalStrength.name,
        'environmentalStressScore': environmentalStressScore,
        'environmentalStressLevel': environmentalStressLevel.name,
        'environmentalStressResult': environmentalStressResult.toJson(),
        'biosecurityExposureScore': biosecurityExposureScore,
        'biosecurityExposureLevel': biosecurityExposureLevel.name,
        'visitorExposureResult': visitorExposureResult.toJson(),
        'nearbyExposureScore': nearbyExposureScore,
        'nearbyExposureLevel': nearbyExposureLevel.name,
        'nearbyExposure': nearbyExposure.toJson(),
        'diseaseCandidates':
            diseaseCandidates.map((d) => d.toJson()).toList(),
        'metricBaselines': metricBaselines.map(
            (k, v) => MapEntry(k, v.toJson())),
        'topContributingSignals': topContributingSignals,
        'missingEvidence': missingEvidence,
        'dataQuality': dataQuality,
        'recommendations':
            recommendations.map((r) => r.toJson()).toList(),
        'timeline': timeline.map((t) => t.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory FarmHealthIntelligenceModel.fromJson(Map<String, dynamic> json) {
    return FarmHealthIntelligenceModel(
      farmId: json['farmId'] as String? ?? 'farm_demo_001',
      batchId: json['batchId'] as String?,
      farmName: json['farmName'] as String? ?? 'Poultry Farm',
      overallRiskScore: (json['overallRiskScore'] as num?)?.toInt() ?? 25,
      overallRiskLevel: HealthRiskLevel.values.firstWhere(
        (e) => e.name == json['overallRiskLevel'],
        orElse: () => HealthRiskLevel.low,
      ),
      farmBehaviourStatus: FarmBehaviourStatus.values.firstWhere(
        (e) => e.name == json['farmBehaviourStatus'],
        orElse: () => FarmBehaviourStatus.normal,
      ),
      primarySyndrome: PrimarySyndrome.values.firstWhere(
        (e) => e.name == json['primarySyndrome'],
        orElse: () => PrimarySyndrome.unknown,
      ),
      syndromeSignalStrength: SyndromeSignalStrength.values.firstWhere(
        (e) => e.name == json['syndromeSignalStrength'],
        orElse: () => SyndromeSignalStrength.low,
      ),
      environmentalStressScore:
          (json['environmentalStressScore'] as num?)?.toInt() ?? 20,
      environmentalStressLevel: EnvironmentalStressLevel.values.firstWhere(
        (e) => e.name == json['environmentalStressLevel'],
        orElse: () => EnvironmentalStressLevel.normal,
      ),
      environmentalStressResult: json['environmentalStressResult'] != null
          ? EnvironmentalStressResult.fromJson(
              json['environmentalStressResult'] as Map<String, dynamic>)
          : const EnvironmentalStressResult(
              environmentalStressScore: 20,
              environmentalStressLevel: EnvironmentalStressLevel.normal,
              ambientTemperature: 24.0,
              humidity: 60.0,
              thi: 70.0,
              temperatureDeviation: 0.0,
              humidityDeviation: 0.0,
              targetProfile: EnvironmentalTargetProfile(),
              explanation: 'Ambient telemetry within target range.',
            ),
      biosecurityExposureScore:
          (json['biosecurityExposureScore'] as num?)?.toInt() ?? 10,
      biosecurityExposureLevel: BiosecurityExposureLevel.values.firstWhere(
        (e) => e.name == json['biosecurityExposureLevel'],
        orElse: () => BiosecurityExposureLevel.low,
      ),
      visitorExposureResult: json['visitorExposureResult'] != null
          ? VisitorExposureResult.fromJson(
              json['visitorExposureResult'] as Map<String, dynamic>)
          : const VisitorExposureResult(
              biosecurityExposureScore: 10,
              biosecurityExposureLevel: BiosecurityExposureLevel.low,
            ),
      nearbyExposureScore:
          (json['nearbyExposureScore'] as num?)?.toInt() ?? 0,
      nearbyExposureLevel: NearbyExposureLevel.values.firstWhere(
        (e) => e.name == json['nearbyExposureLevel'],
        orElse: () => NearbyExposureLevel.low,
      ),
      nearbyExposure: json['nearbyExposure'] != null
          ? NearbyExposureModel.fromJson(
              json['nearbyExposure'] as Map<String, dynamic>)
          : const NearbyExposureModel(
              farmerAnonymizedSummary:
                  'No elevated disease activity in immediate corridor.',
              clinicalSummary: 'Surrounding corridor stable.',
            ),
      diseaseCandidates: (json['diseaseCandidates'] as List<dynamic>?)
              ?.map((d) => DiseaseCandidate.fromJson(d as Map<String, dynamic>))
              .toList() ??
          const [],
      metricBaselines: (json['metricBaselines'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              k,
              FarmMetricBaseline.fromJson(v as Map<String, dynamic>),
            ),
          ) ??
          const {},
      topContributingSignals:
          (json['topContributingSignals'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
      missingEvidence: (json['missingEvidence'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      dataQuality: json['dataQuality'] as String? ?? 'Good',
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((r) =>
                  RoleRecommendationModel.fromJson(r as Map<String, dynamic>))
              .toList() ??
          const [],
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((t) =>
                  FarmHealthTimelineEvent.fromJson(t as Map<String, dynamic>))
              .toList() ??
          const [],
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
