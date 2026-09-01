/// Centralized Configuration for FlockSense Health Risk Engine (SIH26128)
///
/// NOTE: This is a prototype risk-screening algorithm.
/// It is not a validated veterinary diagnostic model.
/// Thresholds are configurable and require veterinary/domain validation.
class RiskConfig {
  RiskConfig._();

  static const String engineVersion = 'risk-v1';

  // ── Standard Risk Level Thresholds ──────────────────────────────────────────
  static const int lowMaxScore = 30; // 0–30: LOW
  static const int moderateMaxScore = 50; // 31–50: MODERATE
  static const int highMaxScore = 75; // 51–75: HIGH
  // 76–100: CRITICAL

  // ── Mortality Scoring Configuration ─────────────────────────────────────────
  static const double mortalityRatioNormal = 1.25; // <= 1.25x -> +0
  static const double mortalityRatioMild = 1.50; // > 1.25x -> +5
  static const double mortalityRatioModerate = 2.00; // > 1.50x -> +10
  static const double mortalityRatioHigh = 3.00; // > 2.00x -> +18
  // > 3.00x -> +25

  static const int mortalityPointsMild = 5;
  static const int mortalityPointsModerate = 10;
  static const int mortalityPointsHigh = 18;
  static const int mortalityPointsCritical = 25;
  static const int maxMortalityPoints = 25;

  // Fallback mortality rate scoring when baseline is limited
  static const double mortalityRateCriticalThreshold = 0.05; // 5% flock mortality
  static const double mortalityRateHighThreshold = 0.02; // 2% flock mortality
  static const double mortalityRateModerateThreshold = 0.008; // 0.8% flock mortality

  // ── Feed Reduction Scoring (Max: 15 pts) ────────────────────────────────────
  static const double feedReductionMild = 5.0; // > 5% -> +4
  static const double feedReductionModerate = 10.0; // > 10% -> +8
  static const double feedReductionHigh = 15.0; // > 15% -> +12
  static const double feedReductionCritical = 25.0; // > 25% -> +15

  static const int feedPointsMild = 4;
  static const int feedPointsModerate = 8;
  static const int feedPointsHigh = 12;
  static const int feedPointsCritical = 15;
  static const int maxFeedPoints = 15;

  // ── Water Reduction Scoring (Max: 15 pts) ───────────────────────────────────
  static const double waterReductionMild = 5.0; // > 5% -> +4
  static const double waterReductionModerate = 10.0; // > 10% -> +8
  static const double waterReductionHigh = 15.0; // > 15% -> +12
  static const double waterReductionCritical = 25.0; // > 25% -> +15

  static const int waterPointsMild = 4;
  static const int waterPointsModerate = 8;
  static const int waterPointsHigh = 12;
  static const int waterPointsCritical = 15;
  static const int maxWaterPoints = 15;

  // ── Symptom Category Weights (Max total symptom contribution: 25 pts) ───────
  static const int maxSymptomPoints = 25;

  static const Map<String, int> symptomWeights = {
    // Mild Symptoms (3–5 pts each)
    'reduced_activity': 4,
    'reduced_appetite': 4,
    'mild_weakness': 4,
    'lethargy': 4,
    'ruffled_feathers': 4,
    'huddling': 3,

    // Moderate Symptoms (5–8 pts each)
    'coughing': 6,
    'sneezing': 6,
    'diarrhoea': 7,
    'diarrhea': 7,
    'nasal_discharge': 6,
    'eye_swelling': 7,
    'swollen_head': 8,
    'facial_swelling': 7,
    'drop_in_egg_production': 8,
    'watery_droppings': 6,
    'greenish_droppings': 7,
    'white_chalky_droppings': 7,

    // Severe Symptoms (10–15 pts each)
    'respiratory_difficulty': 14,
    'gasping': 14,
    'neurological_signs': 15,
    'tremors': 12,
    'paralysis': 14,
    'twisted_neck': 15,
    'torticollis': 15,
    'sudden_death': 15,
    'severe_weakness': 12,
    'cyanosis': 14,
    'comb_cyanosis': 14,
    'wattles_cyanosis': 14,
  };

  // ── Syndrome Bonus Scoring (+5 pts each) ────────────────────────────────────
  static const int syndromeBonusPoints = 5;

  static const List<String> respiratorySymptoms = [
    'respiratory_difficulty',
    'gasping',
    'coughing',
    'sneezing',
    'nasal_discharge',
    'facial_swelling',
    'swollen_head',
    'eye_swelling',
  ];

  static const List<String> digestiveSymptoms = [
    'diarrhoea',
    'diarrhea',
    'greenish_droppings',
    'white_chalky_droppings',
    'watery_droppings',
    'reduced_appetite',
  ];

  static const List<String> neurologicalSymptoms = [
    'neurological_signs',
    'torticollis',
    'twisted_neck',
    'paralysis',
    'tremors',
  ];

  static const List<String> systemicSymptoms = [
    'sudden_death',
    'cyanosis',
    'comb_cyanosis',
    'severe_weakness',
  ];

  // ── Sudden Death Acute Signal ───────────────────────────────────────────────
  static const int suddenDeathBonusPoints = 10;

  // ── Vaccination Compliance Scoring (Max: 10 pts) ────────────────────────────
  static const int vaccineUpToDatePoints = 0;
  static const int vaccineUnknownPoints = 3;
  static const int vaccineRecentlyOverduePoints = 6;
  static const int vaccineSignificantlyOverduePoints = 10;
  static const int maxVaccinePoints = 10;

  // ── Environmental Stress Range (Poultry Comfort) ────────────────────────────
  static const double optimalTempMin = 20.0; // °C
  static const double optimalTempMax = 30.0; // °C
  static const double optimalHumidityMin = 50.0; // %
  static const double optimalHumidityMax = 75.0; // %

  static const int envStressModeratePoints = 5;
  static const int envStressSeverePoints = 8;
  static const int maxEnvPoints = 10;

  // ── Recent Flock Health Incident Signal ─────────────────────────────────────
  static const int recentCaseBonusPoints = 5;
  static const int recentCaseLookbackDays = 14;
}
