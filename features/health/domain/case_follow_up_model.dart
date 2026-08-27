import 'package:cloud_firestore/cloud_firestore.dart';

/// Condition progression status reported in follow-up
enum ConditionProgression {
  improving,
  same,
  worse;

  String get label {
    switch (this) {
      case ConditionProgression.improving:
        return 'Improving / Stabilized';
      case ConditionProgression.same:
        return 'Unchanged / Same';
      case ConditionProgression.worse:
        return 'Deteriorating / Worse';
    }
  }

  static ConditionProgression fromString(String? value) {
    if (value == null) return ConditionProgression.same;
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'improving':
      case 'improved':
      case 'better':
        return ConditionProgression.improving;
      case 'worse':
      case 'deteriorating':
      case 'critical':
        return ConditionProgression.worse;
      case 'same':
      case 'unchanged':
      default:
        return ConditionProgression.same;
    }
  }
}

/// Farmer Case Follow-Up Progress Report Model (SIH26128 Phase 6)
class CaseFollowUpModel {
  final String id;
  final String caseId;
  final String farmerId;
  final String farmId;
  final String batchId;

  final int currentAffectedCount;
  final int currentMortalityCount;
  final ConditionProgression condition;
  final List<String> newSymptoms;
  final String notes;
  final List<String> imageUrls;

  final DateTime createdAt;

  const CaseFollowUpModel({
    required this.id,
    required this.caseId,
    required this.farmerId,
    required this.farmId,
    required this.batchId,
    required this.currentAffectedCount,
    required this.currentMortalityCount,
    this.condition = ConditionProgression.same,
    this.newSymptoms = const [],
    this.notes = '',
    this.imageUrls = const [],
    required this.createdAt,
  });

  factory CaseFollowUpModel.fromJson(Map<String, dynamic> json) {
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

    return CaseFollowUpModel(
      id: json['id'] as String? ?? '',
      caseId: json['caseId'] as String? ?? '',
      farmerId: json['farmerId'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      batchId: json['batchId'] as String? ?? json['flockId'] as String? ?? '',
      currentAffectedCount: (json['currentAffectedCount'] as num?)?.toInt() ?? 0,
      currentMortalityCount: (json['currentMortalityCount'] as num?)?.toInt() ?? 0,
      condition: ConditionProgression.fromString(json['condition'] as String?),
      newSymptoms: parseList(json['newSymptoms'] ?? json['symptoms']),
      notes: json['notes'] as String? ?? '',
      imageUrls: parseList(json['imageUrls'] ?? json['images']),
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caseId': caseId,
      'farmerId': farmerId,
      'farmId': farmId,
      'batchId': batchId,
      'currentAffectedCount': currentAffectedCount,
      'currentMortalityCount': currentMortalityCount,
      'condition': condition.name,
      'newSymptoms': newSymptoms,
      'notes': notes,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
