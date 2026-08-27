import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';

enum VetAssignmentStatus {
  pending,
  accepted,
  in_progress,
  completed,
  declined,
  unassigned;

  String get label {
    switch (this) {
      case VetAssignmentStatus.pending:
        return 'Pending Acceptance';
      case VetAssignmentStatus.accepted:
        return 'Accepted by Vet';
      case VetAssignmentStatus.in_progress:
        return 'Investigation in Progress';
      case VetAssignmentStatus.completed:
        return 'Consultation Completed';
      case VetAssignmentStatus.declined:
        return 'Declined / Re-routed';
      case VetAssignmentStatus.unassigned:
        return 'District Queue (Unassigned)';
    }
  }

  static VetAssignmentStatus fromString(String? value) {
    if (value == null) return VetAssignmentStatus.pending;
    final normalized = value.trim().toLowerCase().replaceAll('-', '_');
    for (final status in VetAssignmentStatus.values) {
      if (status.name == normalized) return status;
    }
    return VetAssignmentStatus.pending;
  }
}

enum VetPriorityLevel {
  critical,
  urgent,
  priority,
  routine;

  String get label {
    switch (this) {
      case VetPriorityLevel.critical:
        return 'CRITICAL PRIORITY';
      case VetPriorityLevel.urgent:
        return 'URGENT REVIEW';
      case VetPriorityLevel.priority:
        return 'STANDARD PRIORITY';
      case VetPriorityLevel.routine:
        return 'ROUTINE MONITORING';
    }
  }

  Color get color {
    switch (this) {
      case VetPriorityLevel.critical:
        return AppColors.critical;
      case VetPriorityLevel.urgent:
        return AppColors.warning;
      case VetPriorityLevel.priority:
        return AppColors.info;
      case VetPriorityLevel.routine:
        return AppColors.healthy;
    }
  }

  Color get bg {
    switch (this) {
      case VetPriorityLevel.critical:
        return AppColors.criticalBg;
      case VetPriorityLevel.urgent:
        return AppColors.warningBg;
      case VetPriorityLevel.priority:
        return AppColors.infoBg;
      case VetPriorityLevel.routine:
        return AppColors.healthyBg;
    }
  }

  static VetPriorityLevel fromString(String? value) {
    if (value == null) return VetPriorityLevel.routine;
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'critical':
      case 'critical_priority':
        return VetPriorityLevel.critical;
      case 'urgent':
      case 'urgent_review':
        return VetPriorityLevel.urgent;
      case 'priority':
      case 'standard_priority':
      case 'high':
        return VetPriorityLevel.priority;
      case 'routine':
      case 'routine_monitoring':
      case 'low':
      case 'moderate':
      default:
        return VetPriorityLevel.routine;
    }
  }

  static VetPriorityLevel fromRiskAndPriority(HealthRiskLevel risk, int score) {
    if (risk == HealthRiskLevel.critical || score >= 75) {
      return VetPriorityLevel.critical;
    }
    if (risk == HealthRiskLevel.high || score >= 55) {
      return VetPriorityLevel.urgent;
    }
    if (risk == HealthRiskLevel.moderate || score >= 35) {
      return VetPriorityLevel.priority;
    }
    return VetPriorityLevel.routine;
  }
}

/// Veterinarian Case Assignment Model (SIH26128 Phase 5)
class VetAssignmentModel {
  final String id;
  final String caseId;
  final String? caseNumber;
  final String vetId; // Empty string if unassigned/queued in district
  final String? vetName;
  final String farmId;
  final String? farmName;
  final String? flockId;
  final String? flockName;
  final String? district;
  final String? districtQueue;

  final HealthRiskLevel priority; // Original HealthRiskLevel
  final int priorityScore; // 0-100+ Calculated Queue Priority
  final VetPriorityLevel priorityLevel;
  final VetAssignmentStatus status;
  final String assignmentMethod; // 'automatic_district' | 'manual' | 'queue' | 'unassigned'

  final int mortalityCount;
  final int affectedCount;
  final List<String> symptoms;

  final DateTime assignedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final String? notes;
  final String? deduplicationKey;

  const VetAssignmentModel({
    required this.id,
    required this.caseId,
    this.caseNumber,
    required this.vetId,
    this.vetName,
    required this.farmId,
    this.farmName,
    this.flockId,
    this.flockName,
    this.district,
    this.districtQueue,
    required this.priority,
    this.priorityScore = 0,
    this.priorityLevel = VetPriorityLevel.routine,
    required this.status,
    this.assignmentMethod = 'automatic_district',
    this.mortalityCount = 0,
    this.affectedCount = 0,
    this.symptoms = const [],
    required this.assignedAt,
    this.acceptedAt,
    this.completedAt,
    this.notes,
    this.deduplicationKey,
  });

  bool get isUnassigned => vetId.isEmpty || status == VetAssignmentStatus.unassigned;

  factory VetAssignmentModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseOptionalDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    List<String> parseList(dynamic v) {
      if (v is List) {
        return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    final parsedPriority = HealthRiskLevel.fromString(json['priority'] as String?);
    final priorityScore = (json['priorityScore'] as num?)?.toInt() ??
        (json['priority'] == 'critical' ? 85 : (json['priority'] == 'high' ? 65 : 40));

    return VetAssignmentModel(
      id: json['id'] as String? ?? '',
      caseId: json['caseId'] as String? ?? '',
      caseNumber: json['caseNumber'] as String?,
      vetId: json['vetId'] as String? ?? '',
      vetName: json['vetName'] as String?,
      farmId: json['farmId'] as String? ?? '',
      farmName: json['farmName'] as String?,
      flockId: json['flockId'] as String? ?? json['batchId'] as String?,
      flockName: json['flockName'] as String? ?? json['batchName'] as String?,
      district: json['district'] as String?,
      districtQueue: json['districtQueue'] as String?,
      priority: parsedPriority,
      priorityScore: priorityScore,
      priorityLevel: json['priorityLevel'] != null
          ? VetPriorityLevel.fromString(json['priorityLevel'] as String?)
          : VetPriorityLevel.fromRiskAndPriority(parsedPriority, priorityScore),
      status: VetAssignmentStatus.fromString(json['status'] as String?),
      assignmentMethod: json['assignmentMethod'] as String? ?? 'automatic_district',
      mortalityCount: (json['mortalityCount'] as num?)?.toInt() ?? 0,
      affectedCount: (json['affectedCount'] as num?)?.toInt() ?? 0,
      symptoms: parseList(json['symptoms']),
      assignedAt: parseDate(json['assignedAt'] ?? json['createdAt']),
      acceptedAt: parseOptionalDate(json['acceptedAt']),
      completedAt: parseOptionalDate(json['completedAt']),
      notes: json['notes'] as String?,
      deduplicationKey: json['deduplicationKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caseId': caseId,
      if (caseNumber != null) 'caseNumber': caseNumber,
      'vetId': vetId,
      if (vetName != null) 'vetName': vetName,
      'farmId': farmId,
      if (farmName != null) 'farmName': farmName,
      if (flockId != null) 'flockId': flockId,
      if (flockName != null) 'flockName': flockName,
      if (district != null) 'district': district,
      if (districtQueue != null) 'districtQueue': districtQueue,
      'priority': priority.name,
      'priorityScore': priorityScore,
      'priorityLevel': priorityLevel.name,
      'status': status.name,
      'assignmentMethod': assignmentMethod,
      'mortalityCount': mortalityCount,
      'affectedCount': affectedCount,
      'symptoms': symptoms,
      'assignedAt': Timestamp.fromDate(assignedAt),
      if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      if (notes != null) 'notes': notes,
      if (deduplicationKey != null) 'deduplicationKey': deduplicationKey,
    };
  }

  VetAssignmentModel copyWith({
    String? id,
    String? caseId,
    String? caseNumber,
    String? vetId,
    String? vetName,
    String? farmId,
    String? farmName,
    String? flockId,
    String? flockName,
    String? district,
    String? districtQueue,
    HealthRiskLevel? priority,
    int? priorityScore,
    VetPriorityLevel? priorityLevel,
    VetAssignmentStatus? status,
    String? assignmentMethod,
    int? mortalityCount,
    int? affectedCount,
    List<String>? symptoms,
    DateTime? assignedAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    String? notes,
    String? deduplicationKey,
  }) {
    return VetAssignmentModel(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      caseNumber: caseNumber ?? this.caseNumber,
      vetId: vetId ?? this.vetId,
      vetName: vetName ?? this.vetName,
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      flockId: flockId ?? this.flockId,
      flockName: flockName ?? this.flockName,
      district: district ?? this.district,
      districtQueue: districtQueue ?? this.districtQueue,
      priority: priority ?? this.priority,
      priorityScore: priorityScore ?? this.priorityScore,
      priorityLevel: priorityLevel ?? this.priorityLevel,
      status: status ?? this.status,
      assignmentMethod: assignmentMethod ?? this.assignmentMethod,
      mortalityCount: mortalityCount ?? this.mortalityCount,
      affectedCount: affectedCount ?? this.affectedCount,
      symptoms: symptoms ?? this.symptoms,
      assignedAt: assignedAt ?? this.assignedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      deduplicationKey: deduplicationKey ?? this.deduplicationKey,
    );
  }
}
