import 'package:cloud_firestore/cloud_firestore.dart';

/// Clinical diagnosis certainty status (SIH26128 Phase 6)
enum DiagnosisStatus {
  suspected,
  provisional,
  confirmed,
  ruled_out,
  inconclusive;

  String get label {
    switch (this) {
      case DiagnosisStatus.suspected:
        return 'Suspected';
      case DiagnosisStatus.provisional:
        return 'Provisional';
      case DiagnosisStatus.confirmed:
        return 'Clinically Confirmed';
      case DiagnosisStatus.ruled_out:
        return 'Ruled Out';
      case DiagnosisStatus.inconclusive:
        return 'Inconclusive';
    }
  }

  static DiagnosisStatus fromString(String? value) {
    if (value == null) return DiagnosisStatus.suspected;
    final normalized = value.trim().toLowerCase().replaceAll('-', '_');
    for (final s in DiagnosisStatus.values) {
      if (s.name == normalized) return s;
    }
    return DiagnosisStatus.suspected;
  }
}

/// Primary clinical organ/body syndrome
enum PrimarySyndrome {
  respiratory,
  digestive,
  neurological,
  dermatological,
  systemic,
  reproductive,
  unknown_mixed;

  String get label {
    switch (this) {
      case PrimarySyndrome.respiratory:
        return 'Respiratory Syndrome';
      case PrimarySyndrome.digestive:
        return 'Digestive / Enteric Syndrome';
      case PrimarySyndrome.neurological:
        return 'Neurological Syndrome';
      case PrimarySyndrome.dermatological:
        return 'Dermatological / Cutaneous';
      case PrimarySyndrome.systemic:
        return 'Systemic / Septicemic Syndrome';
      case PrimarySyndrome.reproductive:
        return 'Reproductive / Egg Drop';
      case PrimarySyndrome.unknown_mixed:
        return 'Unknown / Mixed Presentation';
    }
  }

  static PrimarySyndrome fromString(String? value) {
    if (value == null) return PrimarySyndrome.unknown_mixed;
    final normalized = value.trim().toLowerCase().replaceAll('-', '_');
    for (final s in PrimarySyndrome.values) {
      if (s.name == normalized) return s;
    }
    return PrimarySyndrome.unknown_mixed;
  }
}

/// Feedback rating on AI decision support accuracy
enum AIFeedbackRating {
  helpful,
  partially_helpful,
  not_helpful;

  String get label {
    switch (this) {
      case AIFeedbackRating.helpful:
        return 'Helpful (Aligned with clinical signs)';
      case AIFeedbackRating.partially_helpful:
        return 'Partially Helpful (Differentials varied)';
      case AIFeedbackRating.not_helpful:
        return 'Not Helpful (Clinical picture differed)';
    }
  }

  static AIFeedbackRating fromString(String? value) {
    if (value == null) return AIFeedbackRating.helpful;
    final normalized = value.trim().toLowerCase().replaceAll('-', '_');
    for (final r in AIFeedbackRating.values) {
      if (r.name == normalized) return r;
    }
    return AIFeedbackRating.helpful;
  }
}

/// Authoritative Veterinary Clinical Assessment Model (SIH26128 Phase 6)
class VetClinicalAssessmentModel {
  final String id;
  final String caseId;
  final String vetId;
  final String vetName;

  final String clinicalObservations;
  final String severity; // 'mild' | 'moderate' | 'severe' | 'critical'
  final PrimarySyndrome primarySyndrome;
  final String preliminaryDiagnosis;
  final DiagnosisStatus diagnosisStatus;
  final String additionalFindings;
  final String recommendedNextStep;

  // Separation of Internal Vet Team Notes from Farmer Guidance
  final String internalNotes;
  final String farmerGuidance;

  // AI Decision Support Feedback
  final AIFeedbackRating? aiFeedback;
  final String? aiFeedbackNotes;

  final DateTime createdAt;
  final DateTime updatedAt;

  const VetClinicalAssessmentModel({
    required this.id,
    required this.caseId,
    required this.vetId,
    required this.vetName,
    required this.clinicalObservations,
    this.severity = 'severe',
    this.primarySyndrome = PrimarySyndrome.respiratory,
    required this.preliminaryDiagnosis,
    this.diagnosisStatus = DiagnosisStatus.suspected,
    this.additionalFindings = '',
    this.recommendedNextStep = 'Isolate flock and commence supportive care.',
    this.internalNotes = '',
    this.farmerGuidance = '',
    this.aiFeedback,
    this.aiFeedbackNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VetClinicalAssessmentModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return VetClinicalAssessmentModel(
      id: json['id'] as String? ?? '',
      caseId: json['caseId'] as String? ?? '',
      vetId: json['vetId'] as String? ?? '',
      vetName: json['vetName'] as String? ?? 'District Veterinarian',
      clinicalObservations: json['clinicalObservations'] as String? ?? '',
      severity: json['severity'] as String? ?? 'severe',
      primarySyndrome: PrimarySyndrome.fromString(json['primarySyndrome'] as String?),
      preliminaryDiagnosis: json['preliminaryDiagnosis'] as String? ?? 'Syndromic Anomaly',
      diagnosisStatus: DiagnosisStatus.fromString(json['diagnosisStatus'] as String?),
      additionalFindings: json['additionalFindings'] as String? ?? '',
      recommendedNextStep: json['recommendedNextStep'] as String? ?? '',
      internalNotes: json['internalNotes'] as String? ?? '',
      farmerGuidance: json['farmerGuidance'] as String? ?? '',
      aiFeedback: json['aiFeedback'] != null ? AIFeedbackRating.fromString(json['aiFeedback'] as String?) : null,
      aiFeedbackNotes: json['aiFeedbackNotes'] as String?,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caseId': caseId,
      'vetId': vetId,
      'vetName': vetName,
      'clinicalObservations': clinicalObservations,
      'severity': severity,
      'primarySyndrome': primarySyndrome.name,
      'preliminaryDiagnosis': preliminaryDiagnosis,
      'diagnosisStatus': diagnosisStatus.name,
      'additionalFindings': additionalFindings,
      'recommendedNextStep': recommendedNextStep,
      'internalNotes': internalNotes,
      'farmerGuidance': farmerGuidance,
      if (aiFeedback != null) 'aiFeedback': aiFeedback!.name,
      if (aiFeedbackNotes != null) 'aiFeedbackNotes': aiFeedbackNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  VetClinicalAssessmentModel copyWith({
    String? id,
    String? caseId,
    String? vetId,
    String? vetName,
    String? clinicalObservations,
    String? severity,
    PrimarySyndrome? primarySyndrome,
    String? preliminaryDiagnosis,
    DiagnosisStatus? diagnosisStatus,
    String? additionalFindings,
    String? recommendedNextStep,
    String? internalNotes,
    String? farmerGuidance,
    AIFeedbackRating? aiFeedback,
    String? aiFeedbackNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VetClinicalAssessmentModel(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      vetId: vetId ?? this.vetId,
      vetName: vetName ?? this.vetName,
      clinicalObservations: clinicalObservations ?? this.clinicalObservations,
      severity: severity ?? this.severity,
      primarySyndrome: primarySyndrome ?? this.primarySyndrome,
      preliminaryDiagnosis: preliminaryDiagnosis ?? this.preliminaryDiagnosis,
      diagnosisStatus: diagnosisStatus ?? this.diagnosisStatus,
      additionalFindings: additionalFindings ?? this.additionalFindings,
      recommendedNextStep: recommendedNextStep ?? this.recommendedNextStep,
      internalNotes: internalNotes ?? this.internalNotes,
      farmerGuidance: farmerGuidance ?? this.farmerGuidance,
      aiFeedback: aiFeedback ?? this.aiFeedback,
      aiFeedbackNotes: aiFeedbackNotes ?? this.aiFeedbackNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
