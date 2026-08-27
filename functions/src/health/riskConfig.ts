/**
 * Centralized Configuration for FlockSense Health Risk Engine (SIH26128)
 */
export const RiskConfig = {
  engineVersion: 'risk-v1',

  // Standard Risk Level Thresholds
  lowMaxScore: 30, // 0–30: LOW
  moderateMaxScore: 50, // 31–50: MODERATE
  highMaxScore: 75, // 51–75: HIGH
  // 76–100: CRITICAL

  // Mortality Thresholds
  mortalityRatioNormal: 1.25,
  mortalityRatioMild: 1.5,
  mortalityRatioModerate: 2.0,
  mortalityRatioHigh: 3.0,

  mortalityPointsMild: 5,
  mortalityPointsModerate: 10,
  mortalityPointsHigh: 18,
  mortalityPointsCritical: 25,
  maxMortalityPoints: 25,

  // Fallback rate thresholds
  mortalityRateCriticalThreshold: 0.05,
  mortalityRateHighThreshold: 0.02,
  mortalityRateModerateThreshold: 0.008,

  // Feed Reduction (Max 15 pts)
  feedReductionMild: 5.0,
  feedReductionModerate: 10.0,
  feedReductionHigh: 15.0,
  feedReductionCritical: 25.0,

  feedPointsMild: 4,
  feedPointsModerate: 8,
  feedPointsHigh: 12,
  feedPointsCritical: 15,
  maxFeedPoints: 15,

  // Water Reduction (Max 15 pts)
  waterReductionMild: 5.0,
  waterReductionModerate: 10.0,
  waterReductionHigh: 15.0,
  waterReductionCritical: 25.0,

  waterPointsMild: 4,
  waterPointsModerate: 8,
  waterPointsHigh: 12,
  waterPointsCritical: 15,
  maxWaterPoints: 15,

  // Symptom Weights (Max 25 pts)
  maxSymptomPoints: 25,
  symptomWeights: {
    reduced_activity: 4,
    reduced_appetite: 4,
    mild_weakness: 4,
    lethargy: 4,
    ruffled_feathers: 4,
    huddling: 3,

    coughing: 6,
    sneezing: 6,
    diarrhoea: 7,
    diarrhea: 7,
    nasal_discharge: 6,
    eye_swelling: 7,
    swollen_head: 8,
    facial_swelling: 7,
    drop_in_egg_production: 8,
    watery_droppings: 6,
    greenish_droppings: 7,
    white_chalky_droppings: 7,

    respiratory_difficulty: 14,
    gasping: 14,
    neurological_signs: 15,
    tremors: 12,
    paralysis: 14,
    twisted_neck: 15,
    torticollis: 15,
    sudden_death: 15,
    severe_weakness: 12,
    cyanosis: 14,
    comb_cyanosis: 14,
    wattles_cyanosis: 14,
  } as Record<string, number>,

  // Syndromic Bonuses (+5 pts)
  syndromeBonusPoints: 5,
  respiratorySymptoms: [
    'respiratory_difficulty',
    'gasping',
    'coughing',
    'sneezing',
    'nasal_discharge',
    'facial_swelling',
    'swollen_head',
    'eye_swelling',
  ],
  digestiveSymptoms: [
    'diarrhoea',
    'diarrhea',
    'greenish_droppings',
    'white_chalky_droppings',
    'watery_droppings',
    'reduced_appetite',
  ],
  neurologicalSymptoms: [
    'neurological_signs',
    'torticollis',
    'twisted_neck',
    'paralysis',
    'tremors',
  ],

  suddenDeathBonusPoints: 10,

  // Vaccine Scoring (Max 10 pts)
  vaccineUpToDatePoints: 0,
  vaccineUnknownPoints: 3,
  vaccineSignificantlyOverduePoints: 10,
  maxVaccinePoints: 10,

  // Environmental Stress (Max 10 pts)
  optimalTempMin: 20.0,
  optimalTempMax: 30.0,
  optimalHumidityMin: 50.0,
  optimalHumidityMax: 75.0,
  envStressModeratePoints: 5,
  maxEnvPoints: 10,

  recentCaseBonusPoints: 5,
};
