/// Primary Syndromic Categories for Clinical Decision Support (Part 7)
enum PrimarySyndrome {
  respiratory,
  digestive,
  neurological,
  systemic,
  reproductive,
  environmentalStress,
  mixed,
  unknown;

  String get label {
    switch (this) {
      case PrimarySyndrome.respiratory:
        return 'Respiratory';
      case PrimarySyndrome.digestive:
        return 'Digestive / Enteric';
      case PrimarySyndrome.neurological:
        return 'Neurological';
      case PrimarySyndrome.systemic:
        return 'Systemic / Septicemic';
      case PrimarySyndrome.reproductive:
        return 'Reproductive / Egg Drop';
      case PrimarySyndrome.environmentalStress:
        return 'Environmental Heat Stress';
      case PrimarySyndrome.mixed:
        return 'Mixed Multi-Systemic';
      case PrimarySyndrome.unknown:
        return 'Undetermined / Subclinical';
    }
  }
}

/// Syndrome Signal Strength
enum SyndromeSignalStrength {
  low,
  moderate,
  high,
  veryHigh;

  String get label {
    switch (this) {
      case SyndromeSignalStrength.low:
        return 'LOW';
      case SyndromeSignalStrength.moderate:
        return 'MODERATE';
      case SyndromeSignalStrength.high:
        return 'HIGH';
      case SyndromeSignalStrength.veryHigh:
        return 'VERY HIGH';
    }
  }
}

/// Result of Syndromic Pattern Evaluation
class SyndromeEvaluationResult {
  final PrimarySyndrome primarySyndrome;
  final List<PrimarySyndrome> secondarySyndromes;
  final SyndromeSignalStrength signalStrength;
  final List<String> matchedSymptoms;
  final List<String> evidenceObservations;
  final String clinicalDescription;

  const SyndromeEvaluationResult({
    required this.primarySyndrome,
    this.secondarySyndromes = const [],
    required this.signalStrength,
    this.matchedSymptoms = const [],
    this.evidenceObservations = const [],
    required this.clinicalDescription,
  });

  Map<String, dynamic> toJson() => {
        'primarySyndrome': primarySyndrome.name,
        'secondarySyndromes': secondarySyndromes.map((s) => s.name).toList(),
        'signalStrength': signalStrength.name,
        'matchedSymptoms': matchedSymptoms,
        'evidenceObservations': evidenceObservations,
        'clinicalDescription': clinicalDescription,
      };

  factory SyndromeEvaluationResult.fromJson(Map<String, dynamic> json) {
    return SyndromeEvaluationResult(
      primarySyndrome: PrimarySyndrome.values.firstWhere(
        (e) => e.name == json['primarySyndrome'],
        orElse: () => PrimarySyndrome.unknown,
      ),
      secondarySyndromes: (json['secondarySyndromes'] as List<dynamic>?)
              ?.map((s) => PrimarySyndrome.values.firstWhere(
                    (e) => e.name == s,
                    orElse: () => PrimarySyndrome.unknown,
                  ))
              .toList() ??
          const [],
      signalStrength: SyndromeSignalStrength.values.firstWhere(
        (e) => e.name == json['signalStrength'],
        orElse: () => SyndromeSignalStrength.low,
      ),
      matchedSymptoms: (json['matchedSymptoms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      evidenceObservations: (json['evidenceObservations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      clinicalDescription: json['clinicalDescription'] as String? ?? '',
    );
  }
}
