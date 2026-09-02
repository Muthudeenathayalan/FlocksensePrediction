/// Event Type for Farm Health Timeline (Part 21)
enum TimelineEventType {
  daily_metric_anomaly,
  environment_event,
  visitor_event,
  vaccination,
  health_report,
  risk_assessment,
  vet_assignment,
  lab_test,
  diagnosis,
  treatment,
  cluster_warning,
  recommendation_completed;

  String get label {
    switch (this) {
      case TimelineEventType.daily_metric_anomaly:
        return 'Telemetry Anomaly';
      case TimelineEventType.environment_event:
        return 'Environment Shift';
      case TimelineEventType.visitor_event:
        return 'Visitor & Biosecurity Event';
      case TimelineEventType.vaccination:
        return 'Immunization';
      case TimelineEventType.health_report:
        return 'Health Report Filed';
      case TimelineEventType.risk_assessment:
        return 'Risk Assessment Calculated';
      case TimelineEventType.vet_assignment:
        return 'Veterinary Triage Assigned';
      case TimelineEventType.lab_test:
        return 'Diagnostic Lab Sample';
      case TimelineEventType.diagnosis:
        return 'Veterinary Diagnosis';
      case TimelineEventType.treatment:
        return 'Treatment Protocol Initiated';
      case TimelineEventType.cluster_warning:
        return 'Regional Cluster Warning';
      case TimelineEventType.recommendation_completed:
        return 'Protective Action Completed';
    }
  }
}

/// Farm Health Timeline Event
class FarmHealthTimelineEvent {
  final String id;
  final String farmId;
  final DateTime timestamp;
  final TimelineEventType eventType;
  final String title;
  final String description;
  final String severity; // 'info', 'warning', 'critical', 'success'
  final String? sourceId; // e.g. caseId, visitorId, clusterId
  final Map<String, dynamic>? metadata;

  const FarmHealthTimelineEvent({
    required this.id,
    required this.farmId,
    required this.timestamp,
    required this.eventType,
    required this.title,
    required this.description,
    this.severity = 'info',
    this.sourceId,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'farmId': farmId,
        'timestamp': timestamp.toIso8601String(),
        'eventType': eventType.name,
        'title': title,
        'description': description,
        'severity': severity,
        'sourceId': sourceId,
        'metadata': metadata,
      };

  factory FarmHealthTimelineEvent.fromJson(Map<String, dynamic> json) {
    return FarmHealthTimelineEvent(
      id: json['id'] as String? ?? 'event_${DateTime.now().millisecondsSinceEpoch}',
      farmId: json['farmId'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      eventType: TimelineEventType.values.firstWhere(
        (e) => e.name == json['eventType'],
        orElse: () => TimelineEventType.daily_metric_anomaly,
      ),
      title: json['title'] as String? ?? 'Farm Event',
      description: json['description'] as String? ?? '',
      severity: json['severity'] as String? ?? 'info',
      sourceId: json['sourceId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
