import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';

/// Structured Explainable Risk Reason (SIH26128)
class RiskReasonModel {
  final String code; // e.g. mortality_spike, feed_reduction, respiratory_syndrome
  final String label; // Human-readable explanation
  final String value; // Observed telemetry value, e.g. "4.1x baseline", "-18%"
  final int points; // Score points contributed (+12, +25, etc.)
  final String severity; // info, warning, critical

  const RiskReasonModel({
    required this.code,
    required this.label,
    required this.value,
    required this.points,
    required this.severity,
  });

  factory RiskReasonModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return RiskReasonModel(
      code: json['code'] as String? ?? 'general_signal',
      label: json['label'] as String? ?? 'Observed anomaly',
      value: json['value'] as String? ?? '',
      points: parseInt(json['points']),
      severity: json['severity'] as String? ?? 'info',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'label': label,
      'value': value,
      'points': points,
      'severity': severity,
    };
  }
}

/// Clinical & Epidemiological Risk Assessment Model (SIH26128)
class RiskAssessmentModel {
  final String id;
  final String caseId;
  final String farmId;
  final String batchId;

  final int score; // Clamped 0 - 100
  final HealthRiskLevel riskLevel; // LOW, MODERATE, HIGH, CRITICAL
  final List<RiskReasonModel> structuredReasons;
  final List<String> reasons; // Backward-compatible string labels

  // Telemetry & Baseline Metrics
  final double mortalityBaseline;
  final double currentMortality;
  final double mortalityRatio;
  final double mortalityRate; // Normalized to flock population
  final double feedChangePercent;
  final double waterChangePercent;

  // Signal Classifications
  final List<String> symptomSignals;
  final List<String> vaccinationSignals;
  final List<String> environmentalSignals;
  final bool nearbyCaseSignal;

  // Metadata & Engine Versioning
  final String baselineStatus; // sufficient, limited, insufficient_data
  final String dataQuality; // Good, Limited, Insufficient
  final String inputHash; // Deterministic hash for trigger-loop prevention & idempotency
  final String engineVersion;

  final DateTime createdAt;
  final DateTime updatedAt;

  const RiskAssessmentModel({
    required this.id,
    required this.caseId,
    required this.farmId,
    required this.batchId,
    required this.score,
    required this.riskLevel,
    this.structuredReasons = const [],
    this.reasons = const [],
    this.mortalityBaseline = 0.0,
    this.currentMortality = 0.0,
    this.mortalityRatio = 1.0,
    this.mortalityRate = 0.0,
    this.feedChangePercent = 0.0,
    this.waterChangePercent = 0.0,
    this.symptomSignals = const [],
    this.vaccinationSignals = const [],
    this.environmentalSignals = const [],
    this.nearbyCaseSignal = false,
    this.baselineStatus = 'sufficient',
    this.dataQuality = 'Good',
    this.inputHash = '',
    this.engineVersion = 'risk-v1',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Concise veterinary interpretation based on official risk level
  String get interpretation {
    switch (riskLevel) {
      case HealthRiskLevel.critical:
        return 'Multiple significant health abnormalities detected. Urgent veterinary triage and intervention required.';
      case HealthRiskLevel.high:
        return 'Several critical health anomalies detected. Professional veterinary review strongly recommended.';
      case HealthRiskLevel.moderate:
        return 'Moderate clinical indicators observed. Enhanced flock monitoring and preventive measures advised.';
      case HealthRiskLevel.low:
        return 'No major abnormal health patterns identified from available telemetry. Continue standard biosecurity monitoring.';
    }
  }

  factory RiskAssessmentModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    double parseDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    List<String> parseList(dynamic v) {
      if (v is List) {
        return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    List<RiskReasonModel> parseStructuredReasons(dynamic v) {
      if (v is List) {
        return v
            .map((item) {
              if (item is Map<String, dynamic>) {
                return RiskReasonModel.fromJson(item);
              }
              if (item is Map) {
                return RiskReasonModel.fromJson(Map<String, dynamic>.from(item));
              }
              return null;
            })
            .whereType<RiskReasonModel>()
            .toList();
      }
      return [];
    }

    final score = parseInt(json['score']);
    final parsedRisk = json['riskLevel'] != null
        ? HealthRiskLevel.fromString(json['riskLevel'].toString())
        : HealthRiskLevel.fromScore(score);

    final structured = parseStructuredReasons(json['structuredReasons']);
    final plainReasons = parseList(json['reasons']);
    final effectiveReasons = plainReasons.isNotEmpty
        ? plainReasons
        : structured.map((r) => '${r.points > 0 ? "+${r.points} " : ""}${r.label} (${r.value})').toList();

    return RiskAssessmentModel(
      id: json['id'] as String? ?? '',
      caseId: json['caseId'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      batchId: json['batchId'] as String? ?? '',
      score: score,
      riskLevel: parsedRisk,
      structuredReasons: structured,
      reasons: effectiveReasons,
      mortalityBaseline: parseDouble(json['mortalityBaseline']),
      currentMortality: parseDouble(json['currentMortality']),
      mortalityRatio: parseDouble(json['mortalityRatio'] ?? 1.0),
      mortalityRate: parseDouble(json['mortalityRate']),
      feedChangePercent: parseDouble(json['feedChangePercent']),
      waterChangePercent: parseDouble(json['waterChangePercent']),
      symptomSignals: parseList(json['symptomSignals']),
      vaccinationSignals: parseList(json['vaccinationSignals']),
      environmentalSignals: parseList(json['environmentalSignals']),
      nearbyCaseSignal: json['nearbyCaseSignal'] as bool? ?? false,
      baselineStatus: json['baselineStatus'] as String? ?? 'sufficient',
      dataQuality: json['dataQuality'] as String? ?? 'Good',
      inputHash: json['inputHash'] as String? ?? '',
      engineVersion: json['engineVersion'] as String? ?? 'risk-v1',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caseId': caseId,
      'farmId': farmId,
      'batchId': batchId,
      'score': score,
      'riskLevel': riskLevel.name,
      'structuredReasons': structuredReasons.map((r) => r.toJson()).toList(),
      'reasons': reasons,
      'mortalityBaseline': mortalityBaseline,
      'currentMortality': currentMortality,
      'mortalityRatio': mortalityRatio,
      'mortalityRate': mortalityRate,
      'feedChangePercent': feedChangePercent,
      'waterChangePercent': waterChangePercent,
      'symptomSignals': symptomSignals,
      'vaccinationSignals': vaccinationSignals,
      'environmentalSignals': environmentalSignals,
      'nearbyCaseSignal': nearbyCaseSignal,
      'baselineStatus': baselineStatus,
      'dataQuality': dataQuality,
      'inputHash': inputHash,
      'engineVersion': engineVersion,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
