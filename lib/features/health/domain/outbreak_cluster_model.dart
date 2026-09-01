import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';

/// Epidemiological Status of Regional Outbreak Cluster (SIH26128 Phase 8)
enum OutbreakClusterStatus {
  potential,
  under_investigation,
  supported,
  confirmed,
  contained,
  closed,
  dismissed;

  String get label {
    switch (this) {
      case OutbreakClusterStatus.potential:
        return 'Potential Cluster Detected';
      case OutbreakClusterStatus.under_investigation:
        return 'Field Epidemiological Investigation';
      case OutbreakClusterStatus.supported:
        return 'Laboratory / Clinically Supported';
      case OutbreakClusterStatus.confirmed:
        return 'Confirmed Outbreak Zone';
      case OutbreakClusterStatus.contained:
        return 'Contained & Monitored';
      case OutbreakClusterStatus.closed:
        return 'Outbreak Resolved & Closed';
      case OutbreakClusterStatus.dismissed:
        return 'Dismissed (False Positive / Uncorrelated)';
    }
  }

  static OutbreakClusterStatus fromString(String? value) {
    if (value == null) return OutbreakClusterStatus.potential;
    final normalized = value.trim().toLowerCase().replaceAll('-', '_');
    for (final status in OutbreakClusterStatus.values) {
      if (status.name == normalized) return status;
    }
    return OutbreakClusterStatus.potential;
  }
}

/// Cluster Confidence Categorization
enum ClusterConfidenceLabel {
  weak_signal,
  possible_cluster,
  strong_cluster,
  high_confidence_cluster;

  String get label {
    switch (this) {
      case ClusterConfidenceLabel.weak_signal:
        return 'Weak Early Signal (0-30)';
      case ClusterConfidenceLabel.possible_cluster:
        return 'Possible Disease Cluster (31-60)';
      case ClusterConfidenceLabel.strong_cluster:
        return 'Strong Correlated Cluster (61-80)';
      case ClusterConfidenceLabel.high_confidence_cluster:
        return 'High Confidence Hotspot (81-100)';
    }
  }

  static ClusterConfidenceLabel fromScore(int score) {
    if (score >= 81) return ClusterConfidenceLabel.high_confidence_cluster;
    if (score >= 61) return ClusterConfidenceLabel.strong_cluster;
    if (score >= 31) return ClusterConfidenceLabel.possible_cluster;
    return ClusterConfidenceLabel.weak_signal;
  }

  static ClusterConfidenceLabel fromString(String? value) {
    if (value == null) return ClusterConfidenceLabel.possible_cluster;
    final normalized = value.trim().toLowerCase().replaceAll('-', '_');
    for (final c in ClusterConfidenceLabel.values) {
      if (c.name == normalized) return c;
    }
    return ClusterConfidenceLabel.possible_cluster;
  }
}

/// Authoritative Multi-Farm Outbreak Cluster Model (SIH26128 Phase 8)
class OutbreakClusterModel {
  final String id;
  final String clusterCode; // e.g. 'OUT-2026-NSK-001'
  final String species; // 'poultry'
  final String syndrome; // 'respiratory', 'digestive', 'neurological', 'systemic'
  final String possibleDisease;

  final List<String> caseIds;
  final List<String> farmIds; // Unique distinct farms
  final String district;
  final String state;

  final double centerLatitude;
  final double centerLongitude;
  final double radiusKm;

  final int caseCount;
  final int farmCount;
  final int affectedCount;
  final int mortalityCount;

  final int clusterConfidence; // 0-100
  final ClusterConfidenceLabel confidenceLabel;
  final String severity; // 'low', 'moderate', 'high', 'critical'
  final OutbreakClusterStatus status;

  final DateTime firstDetectedAt;
  final DateTime lastCaseAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String engineVersion; // 'cluster-v1'
  final List<String> evidenceSummary;
  final String dataQuality; // 'limited', 'moderate', 'strong'

  const OutbreakClusterModel({
    required this.id,
    required this.clusterCode,
    this.species = 'poultry',
    required this.syndrome,
    required this.possibleDisease,
    this.caseIds = const [],
    this.farmIds = const [],
    required this.district,
    this.state = 'Maharashtra',
    required this.centerLatitude,
    required this.centerLongitude,
    this.radiusKm = 10.0,
    this.caseCount = 0,
    this.farmCount = 0,
    this.affectedCount = 0,
    this.mortalityCount = 0,
    this.clusterConfidence = 65,
    this.confidenceLabel = ClusterConfidenceLabel.possible_cluster,
    this.severity = 'high',
    this.status = OutbreakClusterStatus.potential,
    required this.firstDetectedAt,
    required this.lastCaseAt,
    required this.createdAt,
    required this.updatedAt,
    this.engineVersion = 'cluster-v1',
    this.evidenceSummary = const [],
    this.dataQuality = 'strong',
  });

  factory OutbreakClusterModel.fromJson(Map<String, dynamic> json) {
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
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    List<String> parseList(dynamic v) {
      if (v is List) {
        return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    final caseIdsList = parseList(json['caseIds']);
    final farmIdsList = parseList(json['farmIds']).toSet().toList();
    final conf = parseInt(json['clusterConfidence'] ?? 65);

    return OutbreakClusterModel(
      id: json['id'] as String? ?? '',
      clusterCode: json['clusterCode'] as String? ?? 'OUT-2026-${json['id']?.toString().substring(0, 4) ?? "001"}',
      species: json['species'] as String? ?? 'poultry',
      syndrome: json['syndrome'] as String? ?? 'respiratory',
      possibleDisease: json['possibleDisease'] as String? ?? 'Respiratory Disease Cluster',
      caseIds: caseIdsList,
      farmIds: farmIdsList,
      district: json['district'] as String? ?? 'Nashik',
      state: json['state'] as String? ?? 'Maharashtra',
      centerLatitude: parseDouble(json['centerLatitude'] ?? json['lat']),
      centerLongitude: parseDouble(json['centerLongitude'] ?? json['lng']),
      radiusKm: parseDouble(json['radiusKm'] ?? 10.0),
      caseCount: parseInt(json['caseCount'] ?? caseIdsList.length),
      farmCount: parseInt(json['farmCount'] ?? farmIdsList.length),
      affectedCount: parseInt(json['affectedCount']),
      mortalityCount: parseInt(json['mortalityCount']),
      clusterConfidence: conf,
      confidenceLabel: json['confidenceLabel'] != null
          ? ClusterConfidenceLabel.fromString(json['confidenceLabel'] as String?)
          : ClusterConfidenceLabel.fromScore(conf),
      severity: json['severity'] as String? ?? 'high',
      status: OutbreakClusterStatus.fromString(json['status'] as String?),
      firstDetectedAt: parseDate(json['firstDetectedAt'] ?? json['createdAt']),
      lastCaseAt: parseDate(json['lastCaseAt'] ?? json['updatedAt']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt'] ?? json['lastUpdatedAt']),
      engineVersion: json['engineVersion'] as String? ?? 'cluster-v1',
      evidenceSummary: parseList(json['evidenceSummary']),
      dataQuality: json['dataQuality'] as String? ?? 'strong',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clusterCode': clusterCode,
      'species': species,
      'syndrome': syndrome,
      'possibleDisease': possibleDisease,
      'caseIds': caseIds,
      'farmIds': farmIds,
      'district': district,
      'state': state,
      'centerLatitude': centerLatitude,
      'centerLongitude': centerLongitude,
      'radiusKm': radiusKm,
      'caseCount': caseCount,
      'farmCount': farmCount,
      'affectedCount': affectedCount,
      'mortalityCount': mortalityCount,
      'clusterConfidence': clusterConfidence,
      'confidenceLabel': confidenceLabel.name,
      'severity': severity,
      'status': status.name,
      'firstDetectedAt': Timestamp.fromDate(firstDetectedAt),
      'lastCaseAt': Timestamp.fromDate(lastCaseAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'engineVersion': engineVersion,
      'evidenceSummary': evidenceSummary,
      'dataQuality': dataQuality,
    };
  }

  OutbreakClusterModel copyWith({
    String? id,
    String? clusterCode,
    String? species,
    String? syndrome,
    String? possibleDisease,
    List<String>? caseIds,
    List<String>? farmIds,
    String? district,
    String? state,
    double? centerLatitude,
    double? centerLongitude,
    double? radiusKm,
    int? caseCount,
    int? farmCount,
    int? affectedCount,
    int? mortalityCount,
    int? clusterConfidence,
    ClusterConfidenceLabel? confidenceLabel,
    String? severity,
    OutbreakClusterStatus? status,
    DateTime? firstDetectedAt,
    DateTime? lastCaseAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? engineVersion,
    List<String>? evidenceSummary,
    String? dataQuality,
  }) {
    return OutbreakClusterModel(
      id: id ?? this.id,
      clusterCode: clusterCode ?? this.clusterCode,
      species: species ?? this.species,
      syndrome: syndrome ?? this.syndrome,
      possibleDisease: possibleDisease ?? this.possibleDisease,
      caseIds: caseIds ?? this.caseIds,
      farmIds: farmIds ?? this.farmIds,
      district: district ?? this.district,
      state: state ?? this.state,
      centerLatitude: centerLatitude ?? this.centerLatitude,
      centerLongitude: centerLongitude ?? this.centerLongitude,
      radiusKm: radiusKm ?? this.radiusKm,
      caseCount: caseCount ?? this.caseCount,
      farmCount: farmCount ?? this.farmCount,
      affectedCount: affectedCount ?? this.affectedCount,
      mortalityCount: mortalityCount ?? this.mortalityCount,
      clusterConfidence: clusterConfidence ?? this.clusterConfidence,
      confidenceLabel: confidenceLabel ?? this.confidenceLabel,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      firstDetectedAt: firstDetectedAt ?? this.firstDetectedAt,
      lastCaseAt: lastCaseAt ?? this.lastCaseAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      engineVersion: engineVersion ?? this.engineVersion,
      evidenceSummary: evidenceSummary ?? this.evidenceSummary,
      dataQuality: dataQuality ?? this.dataQuality,
    );
  }
}
