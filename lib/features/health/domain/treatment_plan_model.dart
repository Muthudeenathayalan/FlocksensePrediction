import 'package:cloud_firestore/cloud_firestore.dart';

enum TreatmentPlanStatus {
  draft,
  active,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case TreatmentPlanStatus.draft:
        return 'Prescription Draft';
      case TreatmentPlanStatus.active:
        return 'Treatment Active';
      case TreatmentPlanStatus.completed:
        return 'Course Completed';
      case TreatmentPlanStatus.cancelled:
        return 'Cancelled / Discontinued';
    }
  }

  static TreatmentPlanStatus fromString(String? value) {
    if (value == null) return TreatmentPlanStatus.active;
    final normalized = value.trim().toLowerCase().replaceAll('-', '_');
    for (final status in TreatmentPlanStatus.values) {
      if (status.name == normalized) return status;
    }
    return TreatmentPlanStatus.active;
  }
}

/// Veterinary Clinical Treatment & Medication Plan Model (SIH26128)
class TreatmentPlanModel {
  final String id;
  final String caseId;
  final String vetId;
  final String farmId;
  final String batchId;

  final String diagnosis;
  final List<String> instructions;
  final List<Map<String, dynamic>> medications; // [{name, dosage, route, durationDays, withdrawalDays}]
  final List<String> biosecurityActions;

  final DateTime startDate;
  final DateTime endDate;
  final TreatmentPlanStatus status;

  final DateTime createdAt;
  final DateTime updatedAt;

  const TreatmentPlanModel({
    required this.id,
    required this.caseId,
    required this.vetId,
    required this.farmId,
    required this.batchId,
    required this.diagnosis,
    this.instructions = const [],
    this.medications = const [],
    this.biosecurityActions = const [],
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TreatmentPlanModel.fromJson(Map<String, dynamic> json) {
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

    List<Map<String, dynamic>> parseMeds(dynamic v) {
      if (v is List) {
        return v
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    }

    return TreatmentPlanModel(
      id: json['id'] as String? ?? '',
      caseId: json['caseId'] as String? ?? '',
      vetId: json['vetId'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      batchId: json['batchId'] as String? ?? '',
      diagnosis: json['diagnosis'] as String? ?? 'Clinical Treatment',
      instructions: parseList(json['instructions']),
      medications: parseMeds(json['medications']),
      biosecurityActions: parseList(json['biosecurityActions']),
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      status: TreatmentPlanStatus.fromString(json['status'] as String?),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caseId': caseId,
      'vetId': vetId,
      'farmId': farmId,
      'batchId': batchId,
      'diagnosis': diagnosis,
      'instructions': instructions,
      'medications': medications,
      'biosecurityActions': biosecurityActions,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
