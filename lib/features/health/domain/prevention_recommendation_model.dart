import 'package:cloud_firestore/cloud_firestore.dart';

/// Priority levels for preventive actions
enum PreventionPriority {
  low,
  medium,
  high,
  critical;

  String get label {
    switch (this) {
      case PreventionPriority.low:
        return 'Low Priority';
      case PreventionPriority.medium:
        return 'Medium Priority';
      case PreventionPriority.high:
        return 'High Priority';
      case PreventionPriority.critical:
        return 'Critical Action';
    }
  }

  static PreventionPriority fromString(String? v) {
    if (v == null) return PreventionPriority.medium;
    for (final p in PreventionPriority.values) {
      if (p.name == v.trim().toLowerCase()) return p;
    }
    return PreventionPriority.medium;
  }
}

/// Status of farmer preventive recommendations
enum PreventionActionStatus {
  recommended,
  acknowledged,
  in_progress,
  completed,
  dismissed;

  String get label {
    switch (this) {
      case PreventionActionStatus.recommended:
        return 'Action Recommended';
      case PreventionActionStatus.acknowledged:
        return 'Acknowledged';
      case PreventionActionStatus.in_progress:
        return 'In Progress';
      case PreventionActionStatus.completed:
        return 'Completed';
      case PreventionActionStatus.dismissed:
        return 'Dismissed';
    }
  }

  static PreventionActionStatus fromString(String? v) {
    if (v == null) return PreventionActionStatus.recommended;
    final norm = v.trim().toLowerCase().replaceAll('-', '_');
    for (final s in PreventionActionStatus.values) {
      if (s.name == norm) return s;
    }
    return PreventionActionStatus.recommended;
  }
}

/// Structured Prevention Recommendation & Protective Action (SIH26128 Phase 10)
class PreventionRecommendationModel {
  final String id;
  final String farmId;
  final String? batchId;
  final String? caseId;
  final String? clusterId;

  final String source; // 'biosecurity_assessment', 'vaccination_gap', 'health_case', 'nearby_cluster', 'veterinarian', 'system'
  final String category; // 'visitor_control', 'flock_isolation', 'disinfection', 'water_feed', 'waste_management', 'vaccination', 'veterinary_triage'
  final PreventionPriority priority;

  final String title;
  final String description;
  final String recommendedAction;
  final String reason;
  final String ruleCode;

  final PreventionActionStatus status;
  final String? evidenceNote;
  final DateTime? completedAt;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PreventionRecommendationModel({
    required this.id,
    required this.farmId,
    this.batchId,
    this.caseId,
    this.clusterId,
    required this.source,
    required this.category,
    required this.priority,
    required this.title,
    required this.description,
    required this.recommendedAction,
    required this.reason,
    required this.ruleCode,
    this.status = PreventionActionStatus.recommended,
    this.evidenceNote,
    this.completedAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isVeterinarianRecommended => source == 'veterinarian';
  bool get isNearbyClusterTriggered => source == 'nearby_cluster';

  PreventionRecommendationModel copyWith({
    String? id,
    String? farmId,
    String? batchId,
    String? caseId,
    String? clusterId,
    String? source,
    String? category,
    PreventionPriority? priority,
    String? title,
    String? description,
    String? recommendedAction,
    String? reason,
    String? ruleCode,
    PreventionActionStatus? status,
    String? evidenceNote,
    DateTime? completedAt,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PreventionRecommendationModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      batchId: batchId ?? this.batchId,
      caseId: caseId ?? this.caseId,
      clusterId: clusterId ?? this.clusterId,
      source: source ?? this.source,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      description: description ?? this.description,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      reason: reason ?? this.reason,
      ruleCode: ruleCode ?? this.ruleCode,
      status: status ?? this.status,
      evidenceNote: evidenceNote ?? this.evidenceNote,
      completedAt: completedAt ?? this.completedAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory PreventionRecommendationModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return PreventionRecommendationModel(
      id: json['id'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      batchId: json['batchId'] as String?,
      caseId: json['caseId'] as String?,
      clusterId: json['clusterId'] as String?,
      source: json['source'] as String? ?? 'system',
      category: json['category'] as String? ?? 'general',
      priority: PreventionPriority.fromString(json['priority'] as String?),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      recommendedAction: json['recommendedAction'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      ruleCode: json['ruleCode'] as String? ?? 'rule_generic',
      status: PreventionActionStatus.fromString(json['status'] as String?),
      evidenceNote: json['evidenceNote'] as String?,
      completedAt: json['completedAt'] != null ? parseDate(json['completedAt']) : null,
      createdBy: json['createdBy'] as String?,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmId': farmId,
      'batchId': batchId,
      'caseId': caseId,
      'clusterId': clusterId,
      'source': source,
      'category': category,
      'priority': priority.name,
      'title': title,
      'description': description,
      'recommendedAction': recommendedAction,
      'reason': reason,
      'ruleCode': ruleCode,
      'status': status.name,
      'evidenceNote': evidenceNote,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
