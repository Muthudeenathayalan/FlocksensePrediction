import 'package:flock_sense/features/intelligence/domain/syndrome_engine_model.dart';

/// Evidence Match Strength for Disease Differential (Part 8)
enum EvidenceMatchLevel {
  low,
  moderate,
  high,
  veryHigh;

  String get label {
    switch (this) {
      case EvidenceMatchLevel.low:
        return 'LOW EVIDENCE MATCH';
      case EvidenceMatchLevel.moderate:
        return 'MODERATE EVIDENCE MATCH';
      case EvidenceMatchLevel.high:
        return 'HIGH EVIDENCE MATCH';
      case EvidenceMatchLevel.veryHigh:
        return 'VERY HIGH EVIDENCE MATCH';
    }
  }
}

/// Disease Candidate Representation in FlockSense Decision Support
class DiseaseCandidate {
  final String name;
  final PrimarySyndrome syndrome;
  final EvidenceMatchLevel evidenceMatch;
  final int matchScore; // 0 - 100

  final List<String> supportingEvidence;
  final List<String> missingEvidence;
  final List<String> conflictingEvidence;

  final bool requiresLabConfirmation;
  final List<String> recommendedDiagnosticEvidence;
  final String clinicalNote;

  const DiseaseCandidate({
    required this.name,
    required this.syndrome,
    required this.evidenceMatch,
    required this.matchScore,
    this.supportingEvidence = const [],
    this.missingEvidence = const [],
    this.conflictingEvidence = const [],
    this.requiresLabConfirmation = true,
    this.recommendedDiagnosticEvidence = const [],
    this.clinicalNote =
        'Clinical decision support matching. Laboratory or veterinary confirmation required.',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'syndrome': syndrome.name,
        'evidenceMatch': evidenceMatch.name,
        'matchScore': matchScore,
        'supportingEvidence': supportingEvidence,
        'missingEvidence': missingEvidence,
        'conflictingEvidence': conflictingEvidence,
        'requiresLabConfirmation': requiresLabConfirmation,
        'recommendedDiagnosticEvidence': recommendedDiagnosticEvidence,
        'clinicalNote': clinicalNote,
      };

  factory DiseaseCandidate.fromJson(Map<String, dynamic> json) {
    return DiseaseCandidate(
      name: json['name'] as String? ?? 'Candidate Disease',
      syndrome: PrimarySyndrome.values.firstWhere(
        (e) => e.name == json['syndrome'],
        orElse: () => PrimarySyndrome.unknown,
      ),
      evidenceMatch: EvidenceMatchLevel.values.firstWhere(
        (e) => e.name == json['evidenceMatch'],
        orElse: () => EvidenceMatchLevel.low,
      ),
      matchScore: (json['matchScore'] as num?)?.toInt() ?? 20,
      supportingEvidence: (json['supportingEvidence'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      missingEvidence: (json['missingEvidence'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      conflictingEvidence: (json['conflictingEvidence'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      requiresLabConfirmation:
          json['requiresLabConfirmation'] as bool? ?? true,
      recommendedDiagnosticEvidence:
          (json['recommendedDiagnosticEvidence'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
      clinicalNote: json['clinicalNote'] as String? ??
          'Clinical decision support matching. Laboratory or veterinary confirmation required.',
    );
  }
}
