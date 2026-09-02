/// Priority levels for recommendations
enum RecommendationPriority {
  low,
  medium,
  high,
  critical;

  String get label {
    switch (this) {
      case RecommendationPriority.low:
        return 'LOW';
      case RecommendationPriority.medium:
        return 'MEDIUM';
      case RecommendationPriority.high:
        return 'HIGH';
      case RecommendationPriority.critical:
        return 'CRITICAL';
    }
  }
}

/// Action Status Lifecycle (Part 10 & 14)
enum RecommendationStatus {
  recommended,
  acknowledged,
  in_progress,
  completed,
  dismissed,
  reassess_required;

  String get label {
    switch (this) {
      case RecommendationStatus.recommended:
        return 'Recommended';
      case RecommendationStatus.acknowledged:
        return 'Acknowledged';
      case RecommendationStatus.in_progress:
        return 'In Progress';
      case RecommendationStatus.completed:
        return 'Completed';
      case RecommendationStatus.dismissed:
        return 'Dismissed';
      case RecommendationStatus.reassess_required:
        return 'Reassess Required';
    }
  }
}

/// Responsible Role for Action Execution
enum ResponsibleRole {
  farmer,
  veterinarian,
  government;

  String get label {
    switch (this) {
      case ResponsibleRole.farmer:
        return 'Farmer';
      case ResponsibleRole.veterinarian:
        return 'Veterinarian';
      case ResponsibleRole.government:
        return 'Government Officer';
    }
  }
}

/// Unified Role-Tailored Recommendation Model (Part 14)
/// Explicitly answers: WHAT?, WHY?, PRIORITY?, WHO?, SOURCE?, STATUS?
class RoleRecommendationModel {
  final String id;
  final RecommendationPriority priority;
  final String title;
  final String action; // WHAT?
  final String reason; // WHY?
  final String source; // SOURCE? (e.g. 'Nearby Exposure Engine + Visitor Log')
  final ResponsibleRole responsibleRole; // WHO?
  final RecommendationStatus status; // STATUS?
  final String? targetId; // FarmId or CaseId
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoleRecommendationModel({
    required this.id,
    required this.priority,
    required this.title,
    required this.action,
    required this.reason,
    required this.source,
    required this.responsibleRole,
    this.status = RecommendationStatus.recommended,
    this.targetId,
    required this.createdAt,
    required this.updatedAt,
  });

  RoleRecommendationModel copyWith({
    String? id,
    RecommendationPriority? priority,
    String? title,
    String? action,
    String? reason,
    String? source,
    ResponsibleRole? responsibleRole,
    RecommendationStatus? status,
    String? targetId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoleRecommendationModel(
      id: id ?? this.id,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      action: action ?? this.action,
      reason: reason ?? this.reason,
      source: source ?? this.source,
      responsibleRole: responsibleRole ?? this.responsibleRole,
      status: status ?? this.status,
      targetId: targetId ?? this.targetId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'priority': priority.name,
        'title': title,
        'action': action,
        'reason': reason,
        'source': source,
        'responsibleRole': responsibleRole.name,
        'status': status.name,
        'targetId': targetId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory RoleRecommendationModel.fromJson(Map<String, dynamic> json) {
    return RoleRecommendationModel(
      id: json['id'] as String? ?? 'rec_${DateTime.now().millisecondsSinceEpoch}',
      priority: RecommendationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => RecommendationPriority.medium,
      ),
      title: json['title'] as String? ?? 'Recommended Action',
      action: json['action'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      source: json['source'] as String? ?? 'Intelligence Engine',
      responsibleRole: ResponsibleRole.values.firstWhere(
        (e) => e.name == json['responsibleRole'],
        orElse: () => ResponsibleRole.farmer,
      ),
      status: RecommendationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RecommendationStatus.recommended,
      ),
      targetId: json['targetId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
