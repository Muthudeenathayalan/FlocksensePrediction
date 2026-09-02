import 'package:flock_sense/features/intelligence/domain/disease_evidence_model.dart';
import 'package:flock_sense/features/intelligence/domain/farm_metric_baseline_model.dart';
import 'package:flock_sense/features/intelligence/domain/syndrome_engine_model.dart';

/// Interface for future ML models (RandomForest, XGBoost, IsolationForest) - Part 23
abstract class DiseasePredictionModel {
  List<DiseaseCandidate> predictCandidates({
    required SyndromeEvaluationResult syndrome,
    required Map<String, FarmMetricBaseline> baselines,
    required List<String> symptoms,
    required bool hasOverdueVaccine,
    required double? temperature,
    required double? humidity,
  });
}

/// Rule-Based + Statistical + Spatio-Temporal Disease Evidence Match Engine (Part 8 & 23)
class DiseaseEvidenceEngine implements DiseasePredictionModel {
  const DiseaseEvidenceEngine();

  @override
  List<DiseaseCandidate> predictCandidates({
    required SyndromeEvaluationResult syndrome,
    required Map<String, FarmMetricBaseline> baselines,
    required List<String> symptoms,
    required bool hasOverdueVaccine,
    required double? temperature,
    required double? humidity,
  }) {
    return evaluateCandidates(
      syndrome: syndrome,
      baselines: baselines,
      symptoms: symptoms,
      hasOverdueVaccine: hasOverdueVaccine,
      temperature: temperature,
      humidity: humidity,
    );
  }

  /// Primary pure evaluation method for poultry disease differential evidence
  static List<DiseaseCandidate> evaluateCandidates({
    required SyndromeEvaluationResult syndrome,
    required Map<String, FarmMetricBaseline> baselines,
    required List<String> symptoms,
    required bool hasOverdueVaccine,
    required double? temperature,
    required double? humidity,
  }) {
    final candidates = <DiseaseCandidate>[];
    final normSymptoms = symptoms.map((s) => s.toLowerCase().trim().replaceAll(' ', '_')).toList();

    final mortRatio = baselines['mortality']?.ratio ?? 1.0;
    final mortCurrent = baselines['mortality']?.currentValue ?? 0.0;
    final feedDev = baselines['feed']?.deviationPercent ?? 0.0;
    final isHighMortality = mortRatio >= 3.0 || mortCurrent >= 10.0;
    final isSevereFeedDrop = feedDev <= -15.0;

    // ── 1. Newcastle Disease (Velogenic / Neurotropic NDV) ─────────────────────
    int ndScore = 10;
    final ndSupporting = <String>[];
    final ndMissing = <String>[];

    if (syndrome.primarySyndrome == PrimarySyndrome.respiratory ||
        syndrome.primarySyndrome == PrimarySyndrome.neurological ||
        syndrome.primarySyndrome == PrimarySyndrome.mixed) {
      ndScore += 30;
      ndSupporting.add('Respiratory / Neurological distress aligned with virulent NDV pathotypes.');
    }

    if (mortRatio >= 4.0 || mortCurrent >= 15.0) {
      ndScore += 35;
      ndSupporting.add('Acute severe mortality spike (${mortRatio.toStringAsFixed(1)}x baseline, ${mortCurrent.toInt()} dead) strongly matches velogenic NDV onset.');
    } else if (isHighMortality) {
      ndScore += 25;
      ndSupporting.add('Acute mortality spike (${mortRatio.toStringAsFixed(1)}x baseline, ${mortCurrent.toInt()} dead) matches velogenic onset.');
    } else {
      ndMissing.add('Peracute mass mortality spike not present.');
    }

    if (hasOverdueVaccine) {
      ndScore += 15;
      ndSupporting.add('Scheduled NDV immunization booster overdue on farm.');
    } else {
      ndMissing.add('Flock has recorded NDV vaccination history.');
    }

    final hasNeuro = normSymptoms.any((s) => s.contains('torti') || s.contains('paralys') || s.contains('tremor') || s.contains('neck'));
    if (hasNeuro) {
      ndScore += 20;
      ndSupporting.add('Characteristic neurological torticollis / wing tremors observed.');
    } else {
      ndMissing.add('Neurological torticollis/tremors not yet recorded in current report.');
    }

    ndMissing.add('Proventricular petechiae necropsy unverified.');
    ndMissing.add('RT-PCR / Viral Isolation laboratory assay pending.');

    candidates.add(DiseaseCandidate(
      name: 'Newcastle Disease (NDV)',
      syndrome: PrimarySyndrome.respiratory,
      evidenceMatch: _scoreToLevel(ndScore),
      matchScore: ndScore.clamp(0, 100),
      supportingEvidence: ndSupporting,
      missingEvidence: ndMissing,
      requiresLabConfirmation: true,
      recommendedDiagnosticEvidence: const [
        'Tracheal & cloacal swab RT-PCR assay',
        'Post-mortem proventriculus & cecal tonsil inspection',
        'Hemagglutination Inhibition (HI) serology titer',
      ],
      clinicalNote: 'High consequence notifiable disease. Quarantine flock immediately while veterinary sample is processed.',
    ));

    // ── 2. Infectious Bronchitis (Avian Coronavirus IBV) ──────────────────────
    int ibScore = 15;
    final ibSupporting = <String>[];
    final ibMissing = <String>[];

    final hasRespRales = normSymptoms.any((s) => s.contains('cough') || s.contains('rale') || s.contains('click') || s.contains('sneez') || s.contains('gasp'));
    if (hasRespRales) {
      ibScore += 35;
      ibSupporting.add('Audible tracheal rales, sneezing, and coughing characteristic of IBV viral spread.');
    }

    if (syndrome.primarySyndrome == PrimarySyndrome.respiratory) {
      ibScore += 20;
      ibSupporting.add('Primary respiratory syndrome without overt neurological paralysis.');
    }

    if (isSevereFeedDrop) {
      ibScore += 15;
      ibSupporting.add('Rapid flock feed consumption reduction (-${feedDev.abs().toStringAsFixed(0)}%).');
    }

    if (mortRatio >= 1.5 && mortRatio < 4.0) {
      ibScore += 15;
      ibSupporting.add('Moderate-to-elevated flock mortality consistent with standard IBV strain field challenge.');
    }

    ibMissing.add('Renal urate swelling post-mortem not evaluated.');
    ibMissing.add('IBV S1-gene RT-PCR confirmation not available.');

    candidates.add(DiseaseCandidate(
      name: 'Infectious Bronchitis (IBV)',
      syndrome: PrimarySyndrome.respiratory,
      evidenceMatch: _scoreToLevel(ibScore),
      matchScore: ibScore.clamp(0, 100),
      supportingEvidence: ibSupporting,
      missingEvidence: ibMissing,
      requiresLabConfirmation: true,
      recommendedDiagnosticEvidence: const [
        'Tracheal swab IBV RT-PCR',
        'Serological ELISA antibody titer profiling',
        'Kidney and tracheal mucosal histopathology',
      ],
      clinicalNote: 'High morbidity viral infection. Support with respiratory comfort, electrolyte hydration, and anti-stress vitamins.',
    ));

    // ── 3. Coccidiosis (Eimeria tenella / necatrix / acervulina) ─────────────
    int cocciScore = 10;
    final cocciSupporting = <String>[];
    final cocciMissing = <String>[];

    final hasEnteric = normSymptoms.any((s) => s.contains('diarrh') || s.contains('drop') || s.contains('green') || s.contains('white') || s.contains('blood'));
    if (hasEnteric) {
      cocciScore += 40;
      cocciSupporting.add('Diarrheic/anomalous droppings and fecal consistency breakdown.');
    }

    if (normSymptoms.any((s) => s.contains('huddle') || s.contains('ruffl') || s.contains('weak'))) {
      cocciScore += 20;
      cocciSupporting.add('Depressed posture, ruffled plumage, and huddling.');
    }

    if (syndrome.primarySyndrome == PrimarySyndrome.digestive) {
      cocciScore += 20;
      cocciSupporting.add('Primary enteric syndrome detected.');
    }

    cocciMissing.add('Microscopic fecal oocyst count (OPG) not performed.');
    cocciMissing.add('Cecal wall thickening necropsy pending.');

    candidates.add(DiseaseCandidate(
      name: 'Coccidiosis (Eimeria spp.)',
      syndrome: PrimarySyndrome.digestive,
      evidenceMatch: _scoreToLevel(cocciScore),
      matchScore: cocciScore.clamp(0, 100),
      supportingEvidence: cocciSupporting,
      missingEvidence: cocciMissing,
      requiresLabConfirmation: true,
      recommendedDiagnosticEvidence: const [
        'Fresh dropping microscopic McMaster oocyst count',
        'Necropsy mucosal scraping of mid-gut and ceca',
      ],
      clinicalNote: 'Parasitic protozoan infection. Check litter moisture and consult veterinarian for anticoccidial therapy.',
    ));

    // ── 4. Necrotic Enteritis (Clostridium perfringens) ────────────────────────
    int neScore = 10;
    final neSupporting = <String>[];
    final neMissing = <String>[];

    if (syndrome.primarySyndrome == PrimarySyndrome.digestive && isHighMortality) {
      neScore += 35;
      neSupporting.add('Acute mortality with enteric depression indicative of clostridial toxemia.');
    }

    if (isSevereFeedDrop) {
      neScore += 20;
      neSupporting.add('Sudden dramatic drop in flock appetite.');
    }

    neMissing.add('Turkish-towel mucosal necrosis post-mortem unverified.');
    neMissing.add('Anaerobic bacterial culture pending.');

    candidates.add(DiseaseCandidate(
      name: 'Necrotic Enteritis (Clostridium perfringens)',
      syndrome: PrimarySyndrome.digestive,
      evidenceMatch: _scoreToLevel(neScore),
      matchScore: neScore.clamp(0, 100),
      supportingEvidence: neSupporting,
      missingEvidence: neMissing,
      requiresLabConfirmation: true,
      recommendedDiagnosticEvidence: const [
        'Small intestinal mucosal scrapings & Gram stain',
        'Anaerobic culture for Clostridium perfringens',
      ],
      clinicalNote: 'Severe bacterial enterotoxemia often secondary to subclinical coccidiosis.',
    ));

    // ── 5. Infectious Coryza (Avibacterium paragallinarum) ────────────────────
    int coryzaScore = 10;
    final coryzaSupporting = <String>[];
    final coryzaMissing = <String>[];

    final hasFacialSwelling = normSymptoms.any((s) => s.contains('swollen') || s.contains('edema') || s.contains('facial') || s.contains('eye'));
    if (hasFacialSwelling) {
      coryzaScore += 45;
      coryzaSupporting.add('Facial edema, infraorbital sinus swelling, and conjunctival discharge.');
    }

    if (hasRespRales) {
      coryzaScore += 20;
      coryzaSupporting.add('Upper respiratory snicking and nasal exudate.');
    }

    coryzaMissing.add('Sinus aspirate bacterial culture and PCR pending.');

    candidates.add(DiseaseCandidate(
      name: 'Infectious Coryza (Avibacterium paragallinarum)',
      syndrome: PrimarySyndrome.respiratory,
      evidenceMatch: _scoreToLevel(coryzaScore),
      matchScore: coryzaScore.clamp(0, 100),
      supportingEvidence: coryzaSupporting,
      missingEvidence: coryzaMissing,
      requiresLabConfirmation: true,
      recommendedDiagnosticEvidence: const [
        'Infraorbital sinus exudate culture on chocolate agar',
        'Species-specific PCR for Avibacterium paragallinarum',
      ],
      clinicalNote: 'Acute upper respiratory bacterial disease. Strict disinfection and isolation required.',
    ));

    // ── 6. Environmental Respiratory & Heat Stress ────────────────────────────
    int envScore = 10;
    final envSupporting = <String>[];
    final envMissing = <String>[];

    if (temperature != null && temperature >= 32.0) {
      envScore += 35;
      envSupporting.add('Elevated ambient telemetry (${temperature.toStringAsFixed(1)}°C) exceeding bird comfort threshold.');
    }

    if (humidity != null && humidity >= 75.0) {
      envScore += 25;
      envSupporting.add('High ambient humidity (${humidity.toStringAsFixed(0)}%) impedes evaporative panting.');
    }

    if (!hasRespRales && !hasNeuro && !hasEnteric) {
      envScore += 20;
      envSupporting.add('Absence of overt infectious pathogen signs.');
    } else {
      envMissing.add('Clinical infectious signs (coughing/diarrhea) present alongside heat.');
    }

    candidates.add(DiseaseCandidate(
      name: 'Environmental Heat & Ventilation Stress',
      syndrome: PrimarySyndrome.environmentalStress,
      evidenceMatch: _scoreToLevel(envScore),
      matchScore: envScore.clamp(0, 100),
      supportingEvidence: envSupporting,
      missingEvidence: envMissing,
      requiresLabConfirmation: false,
      recommendedDiagnosticEvidence: const [
        'Shed thermal imaging and air velocity anemometer audit',
        'Water intake to feed intake ratio measurement',
      ],
      clinicalNote: 'Physiological stressor. Inspect fan operation, cooling pads, and waterer availability immediately.',
    ));

    // Sort descending by match score
    candidates.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return candidates;
  }

  static EvidenceMatchLevel _scoreToLevel(int score) {
    if (score >= 75) return EvidenceMatchLevel.veryHigh;
    if (score >= 50) return EvidenceMatchLevel.high;
    if (score >= 30) return EvidenceMatchLevel.moderate;
    return EvidenceMatchLevel.low;
  }
}
