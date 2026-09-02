import 'package:flock_sense/features/intelligence/domain/syndrome_engine_model.dart';

/// Central Syndromic Pattern Classifier (Part 7)
/// Classifies raw clinical observations into standardized syndromic categories before disease differential
class SyndromeEngine {
  SyndromeEngine._();

  static const List<String> respiratoryKeywords = [
    'cough', 'coughing', 'sneeze', 'sneezing', 'gasp', 'gasping',
    'rales', 'râles', 'clicking', 'nasal', 'discharge', 'respiratory',
    'tracheal', 'snick', 'snicking', 'swollen_head', 'facial_edema', 'eye_swelling'
  ];

  static const List<String> digestiveKeywords = [
    'diarrhea', 'diarrhoea', 'watery_droppings', 'green_droppings',
    'white_droppings', 'bloody_droppings', 'enteritis', 'crop_bound',
    'pasty_vent', 'undigested_feed', 'foul_odor', 'coccidiosis'
  ];

  static const List<String> neurologicalKeywords = [
    'tremor', 'tremors', 'paralysis', 'torticollis', 'twisting_neck',
    'twisted_neck', 'ataxia', 'circling', 'wing_drop', 'leg_weakness',
    'stumbling', 'spasms', 'loss_of_balance'
  ];

  static const List<String> systemicKeywords = [
    'sudden_death', 'cyanosis', 'dark_comb', 'ruffled_feathers',
    'lethargy', 'depression', 'severe_weakness', 'huddling',
    'high_fever', 'anorexia', 'dehydration', 'high_mortality'
  ];

  static const List<String> reproductiveKeywords = [
    'egg_drop', 'soft_shelled_eggs', 'misshapen_eggs', 'pale_eggs',
    'reduced_lay', 'peritonitis'
  ];

  /// Evaluates symptom tokens and text descriptions
  static SyndromeEvaluationResult evaluateSyndrome({
    required List<String> symptoms,
    String? clinicalNotes,
    double? temperature,
    double? humidity,
  }) {
    final tokens = symptoms.map((s) => s.toLowerCase().trim().replaceAll(' ', '_')).toList();
    if (clinicalNotes != null && clinicalNotes.isNotEmpty) {
      final noteTokens = clinicalNotes.toLowerCase().split(RegExp(r'\W+'));
      tokens.addAll(noteTokens);
    }

    int respCount = 0;
    int digestCount = 0;
    int neuroCount = 0;
    int sysCount = 0;
    int reproCount = 0;

    final matchedResp = <String>[];
    final matchedDigest = <String>[];
    final matchedNeuro = <String>[];
    final matchedSys = <String>[];
    final matchedRepro = <String>[];

    for (final t in tokens) {
      if (respiratoryKeywords.any((k) => t.contains(k))) {
        respCount++;
        matchedResp.add(t);
      }
      if (digestiveKeywords.any((k) => t.contains(k))) {
        digestCount++;
        matchedDigest.add(t);
      }
      if (neurologicalKeywords.any((k) => t.contains(k))) {
        neuroCount++;
        matchedNeuro.add(t);
      }
      if (systemicKeywords.any((k) => t.contains(k))) {
        sysCount++;
        matchedSys.add(t);
      }
      if (reproductiveKeywords.any((k) => t.contains(k))) {
        reproCount++;
        matchedRepro.add(t);
      }
    }

    // Heat stress telemetry check
    final isHeatStress = (temperature != null && temperature >= 33.0) &&
        (humidity != null && humidity >= 75.0) &&
        (respCount == 0 && digestCount == 0 && neuroCount == 0);

    if (isHeatStress) {
      return SyndromeEvaluationResult(
        primarySyndrome: PrimarySyndrome.environmentalStress,
        signalStrength: SyndromeSignalStrength.high,
        matchedSymptoms: ['high_ambient_heat', 'high_humidity'],
        evidenceObservations: ['Extreme ambient heat index ($temperature°C, $humidity% RH) triggers physiological thermal distress.'],
        clinicalDescription: 'Physiological environmental heat stress without overt infectious pathogen signs.',
      );
    }

    final counts = <PrimarySyndrome, int>{
      PrimarySyndrome.respiratory: respCount,
      PrimarySyndrome.digestive: digestCount,
      PrimarySyndrome.neurological: neuroCount,
      PrimarySyndrome.systemic: sysCount,
      PrimarySyndrome.reproductive: reproCount,
    };

    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topEntry = sorted.first;

    if (topEntry.value == 0) {
      return const SyndromeEvaluationResult(
        primarySyndrome: PrimarySyndrome.unknown,
        signalStrength: SyndromeSignalStrength.low,
        clinicalDescription: 'Subclinical or unrecorded symptom profile.',
      );
    }

    // Check for mixed multi-systemic pattern
    final secondary = <PrimarySyndrome>[];
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i].value >= 2) {
        secondary.add(sorted[i].key);
      }
    }

    PrimarySyndrome primary = topEntry.key;
    if (secondary.length >= 2 && topEntry.value <= 2) {
      primary = PrimarySyndrome.mixed;
    }

    // Signal strength
    SyndromeSignalStrength strength = SyndromeSignalStrength.low;
    if (topEntry.value >= 4) {
      strength = SyndromeSignalStrength.veryHigh;
    } else if (topEntry.value >= 3) {
      strength = SyndromeSignalStrength.high;
    } else if (topEntry.value >= 2) {
      strength = SyndromeSignalStrength.moderate;
    }

    final allMatched = <String>{
      ...matchedResp,
      ...matchedDigest,
      ...matchedNeuro,
      ...matchedSys,
      ...matchedRepro,
    }.toList();

    final observations = <String>[
      if (respCount > 0) '$respCount respiratory signs (${matchedResp.toSet().join(", ")})',
      if (digestCount > 0) '$digestCount digestive signs (${matchedDigest.toSet().join(", ")})',
      if (neuroCount > 0) '$neuroCount neurological signs (${matchedNeuro.toSet().join(", ")})',
      if (sysCount > 0) '$sysCount systemic/acute signs (${matchedSys.toSet().join(", ")})',
    ];

    final desc = 'Flock presents primary ${primary.label} syndrome with ${strength.label} clinical signal strength.';

    return SyndromeEvaluationResult(
      primarySyndrome: primary,
      secondarySyndromes: secondary,
      signalStrength: strength,
      matchedSymptoms: allMatched,
      evidenceObservations: observations,
      clinicalDescription: desc,
    );
  }
}
