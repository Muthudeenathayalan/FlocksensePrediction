import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';

/// Real-time Disease Alert Model (SIH26128)
class DiseaseAlertModel {
  final String id;
  final String farmId;
  final String? batchId;
  final String? caseId;

  final String type; // 'mortality_spike' | 'symptom_cluster' | 'outbreak_proximity' | 'vaccine_overdue'
  final HealthRiskLevel severity;

  final String title;
  final String message;
  final List<String> recipientRoles; // ['farmer', 'veterinarian', 'government']

  final bool read;
  final bool resolved;
  final String? deduplicationKey;

  final DateTime createdAt;
  final DateTime updatedAt;

  const DiseaseAlertModel({
    required this.id,
    required this.farmId,
    this.batchId,
    this.caseId,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.recipientRoles = const ['farmer'],
    this.read = false,
    this.resolved = false,
    this.deduplicationKey,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiseaseAlertModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    List<String> parseList(dynamic v) {
      if (v is List) {
        return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    return DiseaseAlertModel(
      id: json['id'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      batchId: json['batchId'] as String?,
      caseId: json['caseId'] as String?,
      type: json['type'] as String? ?? 'health_alert',
      severity: HealthRiskLevel.fromString(json['severity'] as String?),
      title: json['title'] as String? ?? 'Disease Surveillance Alert',
      message: json['message'] as String? ?? '',
      recipientRoles: parseList(json['recipientRoles']),
      read: json['read'] as bool? ?? false,
      resolved: json['resolved'] as bool? ?? false,
      deduplicationKey: json['deduplicationKey'] as String?,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmId': farmId,
      if (batchId != null) 'batchId': batchId,
      if (caseId != null) 'caseId': caseId,
      'type': type,
      'severity': severity.name,
      'title': title,
      'message': message,
      'recipientRoles': recipientRoles,
      'read': read,
      'resolved': resolved,
      if (deduplicationKey != null) 'deduplicationKey': deduplicationKey,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  DiseaseAlertModel copyWith({
    String? id,
    String? farmId,
    String? batchId,
    String? caseId,
    String? type,
    HealthRiskLevel? severity,
    String? title,
    String? message,
    List<String>? recipientRoles,
    bool? read,
    bool? resolved,
    String? deduplicationKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiseaseAlertModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      batchId: batchId ?? this.batchId,
      caseId: caseId ?? this.caseId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      recipientRoles: recipientRoles ?? this.recipientRoles,
      read: read ?? this.read,
      resolved: resolved ?? this.resolved,
      deduplicationKey: deduplicationKey ?? this.deduplicationKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
