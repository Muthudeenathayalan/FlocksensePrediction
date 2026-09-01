import 'package:cloud_firestore/cloud_firestore.dart';

/// Clinical similarity ratings for AI-assisted possible conditions (SIH26128)
/// Note: AI is NOT permitted to declare confirmed diagnoses or uncalibrated raw percentages.
enum AIConditionLikelihood {
  high_similarity,
  moderate_similarity,
  low_similarity;

  String get label {
    switch (this) {
      case AIConditionLikelihood.high_similarity:
        return 'High Similarity';
      case AIConditionLikelihood.moderate_similarity:
        return 'Moderate Similarity';
      case AIConditionLikelihood.low_similarity:
        return 'Low Similarity';
    }
  }

  static AIConditionLikelihood fromString(String? value) {
    if (value == null) return AIConditionLikelihood.low_similarity;
    final normalized = value.trim().toLowerCase().replaceAll(' ', '_');
    switch (normalized) {
      case 'high_similarity':
      case 'high':
      case 'strong_similarity':
      case 'probable':
        return AIConditionLikelihood.high_similarity;
      case 'moderate_similarity':
      case 'moderate':
      case 'medium':
      case 'possible':
        return AIConditionLikelihood.moderate_similarity;
      case 'low_similarity':
      case 'low':
      case 'differential':
      default:
        return AIConditionLikelihood.low_similarity;
    }
  }
}

/// Structured Possible Condition / Differential Finding (SIH26128)
class PossibleCondition {
  final String name;
  final AIConditionLikelihood likelihood;
  final String reason;

  const PossibleCondition({
    required this.name,
    required this.likelihood,
    required this.reason,
  });

  factory PossibleCondition.fromJson(Map<String, dynamic> json) {
    return PossibleCondition(
      name: json['name'] as String? ?? 'Undifferentiated Syndromic Anomaly',
      likelihood: AIConditionLikelihood.fromString(
        json['likelihood']?.toString() ?? json['similarity']?.toString(),
      ),
      reason: json['reason'] as String? ?? json['clinicalEvidence'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'likelihood': likelihood.name,
      'reason': reason,
    };
  }
}

/// AI Urgency Recommendation Level (Does not downgrade deterministic Risk Level)
enum AIUrgencyLevel {
  routine_monitoring,
  review_recommended,
  urgent_review,
  emergency_review;

  String get label {
    switch (this) {
      case AIUrgencyLevel.routine_monitoring:
        return 'Routine Monitoring';
      case AIUrgencyLevel.review_recommended:
        return 'Review Recommended';
      case AIUrgencyLevel.urgent_review:
        return 'Urgent Veterinary Review';
      case AIUrgencyLevel.emergency_review:
        return 'Emergency Triage Required';
    }
  }

  static AIUrgencyLevel fromString(String? value) {
    if (value == null) return AIUrgencyLevel.routine_monitoring;
    final normalized = value.trim().toLowerCase().replaceAll(' ', '_');
    switch (normalized) {
      case 'emergency_review':
      case 'emergency':
      case 'critical':
        return AIUrgencyLevel.emergency_review;
      case 'urgent_review':
      case 'urgent':
      case 'high':
        return AIUrgencyLevel.urgent_review;
      case 'review_recommended':
      case 'review':
      case 'moderate':
        return AIUrgencyLevel.review_recommended;
      case 'routine_monitoring':
      case 'routine':
      case 'low':
      default:
        return AIUrgencyLevel.routine_monitoring;
    }
  }
}

/// Execution status of AI Clinical Assessment
enum AIAssessmentStatus {
  pending,
  processing,
  completed,
  failed;

  String get label {
    switch (this) {
      case AIAssessmentStatus.pending:
        return 'Queued';
      case AIAssessmentStatus.processing:
        return 'Analyzing Evidence...';
      case AIAssessmentStatus.completed:
        return 'AI Analysis Ready';
      case AIAssessmentStatus.failed:
        return 'Temporarily Unavailable';
    }
  }

  static AIAssessmentStatus fromString(String? value) {
    if (value == null) return AIAssessmentStatus.pending;
    final normalized = value.trim().toLowerCase();
    for (final s in AIAssessmentStatus.values) {
      if (s.name == normalized) return s;
    }
    return AIAssessmentStatus.pending;
  }
}

/// Authoritative AI Clinical Decision-Support Model (SIH26128 Phase 4)
class AIHealthAssessmentModel {
  final String id;
  final String caseId;
  final String farmId;
  final String batchId;
  final String riskAssessmentId;

  final List<PossibleCondition> possibleConditions;
  final List<String> observedEvidence;
  final List<String> imageObservations;
  final String clinicalExplanation;
  final List<String> recommendedActions;

  final AIUrgencyLevel urgency;
  final bool requiresVetReview;
  final String confidenceNote;
  final List<String> additionalInformationNeeded;

  final String modelName;
  final String promptVersion;
  final String inputHash;
  final AIAssessmentStatus status;
  final String? errorMessage;

  final DateTime createdAt;
  final DateTime updatedAt;

  // Constant mandatory disclaimer
  static const String mandatoryDisclaimer =
      'AI-assisted health assessment. Results indicate possible conditions only and are not a confirmed diagnosis. Veterinary examination and laboratory testing may be required.';

  const AIHealthAssessmentModel({
    required this.id,
    required this.caseId,
    required this.farmId,
    required this.batchId,
    required this.riskAssessmentId,
    this.possibleConditions = const [],
    this.observedEvidence = const [],
    this.imageObservations = const [],
    this.clinicalExplanation = '',
    this.recommendedActions = const [],
    this.urgency = AIUrgencyLevel.routine_monitoring,
    this.requiresVetReview = false,
    this.confidenceNote = mandatoryDisclaimer,
    this.additionalInformationNeeded = const [],
    this.modelName = 'gemini-1.5-flash',
    this.promptVersion = 'health-ai-v1',
    this.inputHash = '',
    this.status = AIAssessmentStatus.pending,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AIHealthAssessmentModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    List<String> parseStringList(dynamic v) {
      if (v is List) {
        return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    List<PossibleCondition> parseConditions(dynamic v) {
      if (v is List) {
        return v
            .map((item) {
              if (item is Map<String, dynamic>) {
                return PossibleCondition.fromJson(item);
              }
              if (item is Map) {
                return PossibleCondition.fromJson(Map<String, dynamic>.from(item));
              }
              return null;
            })
            .whereType<PossibleCondition>()
            .toList();
      }
      return [];
    }

    return AIHealthAssessmentModel(
      id: json['id'] as String? ?? '',
      caseId: json['caseId'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      batchId: json['batchId'] as String? ?? '',
      riskAssessmentId: json['riskAssessmentId'] as String? ?? '',
      possibleConditions: parseConditions(json['possibleConditions']),
      observedEvidence: parseStringList(json['observedEvidence'] ?? json['evidence']),
      imageObservations: parseStringList(json['imageObservations']),
      clinicalExplanation: json['clinicalExplanation'] as String? ?? json['summary'] as String? ?? '',
      recommendedActions: parseStringList(json['recommendedActions']),
      urgency: AIUrgencyLevel.fromString(json['urgency'] as String?),
      requiresVetReview: json['requiresVetReview'] as bool? ?? false,
      confidenceNote: json['confidenceNote'] as String? ?? mandatoryDisclaimer,
      additionalInformationNeeded: parseStringList(
        json['additionalInformationNeeded'] ?? json['missingInformation'],
      ),
      modelName: json['modelName'] as String? ?? 'gemini-1.5-flash',
      promptVersion: json['promptVersion'] as String? ?? 'health-ai-v1',
      inputHash: json['inputHash'] as String? ?? '',
      status: AIAssessmentStatus.fromString(json['status'] as String?),
      errorMessage: json['errorMessage'] as String?,
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
      'riskAssessmentId': riskAssessmentId,
      'possibleConditions': possibleConditions.map((c) => c.toJson()).toList(),
      'observedEvidence': observedEvidence,
      'imageObservations': imageObservations,
      'clinicalExplanation': clinicalExplanation,
      'recommendedActions': recommendedActions,
      'urgency': urgency.name,
      'requiresVetReview': requiresVetReview,
      'confidenceNote': confidenceNote,
      'additionalInformationNeeded': additionalInformationNeeded,
      'modelName': modelName,
      'promptVersion': promptVersion,
      'inputHash': inputHash,
      'status': status.name,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AIHealthAssessmentModel copyWith({
    String? id,
    String? caseId,
    String? farmId,
    String? batchId,
    String? riskAssessmentId,
    List<PossibleCondition>? possibleConditions,
    List<String>? observedEvidence,
    List<String>? imageObservations,
    String? clinicalExplanation,
    List<String>? recommendedActions,
    AIUrgencyLevel? urgency,
    bool? requiresVetReview,
    String? confidenceNote,
    List<String>? additionalInformationNeeded,
    String? modelName,
    String? promptVersion,
    String? inputHash,
    AIAssessmentStatus? status,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AIHealthAssessmentModel(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      farmId: farmId ?? this.farmId,
      batchId: batchId ?? this.batchId,
      riskAssessmentId: riskAssessmentId ?? this.riskAssessmentId,
      possibleConditions: possibleConditions ?? this.possibleConditions,
      observedEvidence: observedEvidence ?? this.observedEvidence,
      imageObservations: imageObservations ?? this.imageObservations,
      clinicalExplanation: clinicalExplanation ?? this.clinicalExplanation,
      recommendedActions: recommendedActions ?? this.recommendedActions,
      urgency: urgency ?? this.urgency,
      requiresVetReview: requiresVetReview ?? this.requiresVetReview,
      confidenceNote: confidenceNote ?? this.confidenceNote,
      additionalInformationNeeded:
          additionalInformationNeeded ?? this.additionalInformationNeeded,
      modelName: modelName ?? this.modelName,
      promptVersion: promptVersion ?? this.promptVersion,
      inputHash: inputHash ?? this.inputHash,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
