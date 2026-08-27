import * as crypto from 'crypto';
import { RiskConfig } from './riskConfig';

export interface RiskReason {
  code: string;
  label: string;
  value: string;
  points: number;
  severity: 'info' | 'warning' | 'critical';
}

export interface RiskEngineInput {
  caseId: string;
  farmId: string;
  batchId: string;
  currentMortality: number;
  affectedCount: number;
  symptoms: string[];
  feedReductionPercent?: number;
  waterReductionPercent?: number;
  temperature?: number;
  humidity?: number;
  incidentDate: Date;
  currentBirdCount?: number;
  recentDailyMortalities?: number[];
  hasOverdueVaccine?: boolean;
  hasVaccineRecords?: boolean;
  recentHealthCasesCount?: number;
}

export interface RiskAssessmentResult {
  id: string;
  caseId: string;
  farmId: string;
  batchId: string;
  score: number;
  riskLevel: 'low' | 'moderate' | 'high' | 'critical';
  structuredReasons: RiskReason[];
  reasons: string[];
  mortalityBaseline: number;
  currentMortality: number;
  mortalityRatio: number;
  mortalityRate: number;
  feedChangePercent: number;
  waterChangePercent: number;
  symptomSignals: string[];
  vaccinationSignals: string[];
  environmentalSignals: string[];
  baselineStatus: string;
  dataQuality: string;
  inputHash: string;
  engineVersion: string;
  createdAt: Date;
  updatedAt: Date;
}

export function computeInputHash(input: RiskEngineInput): string {
  const sortedSymptoms = [...input.symptoms].sort().join(',');
  const raw = [
    input.caseId,
    input.farmId,
    input.batchId,
    input.currentMortality,
    input.affectedCount,
    sortedSymptoms,
    input.feedReductionPercent?.toFixed(1) ?? '0',
    input.waterReductionPercent?.toFixed(1) ?? '0',
    input.temperature?.toFixed(1) ?? '0',
    input.humidity?.toFixed(1) ?? '0',
    input.hasOverdueVaccine ? '1' : '0',
    RiskConfig.engineVersion,
  ].join('|');

  return crypto.createHash('md5').update(raw).digest('hex');
}

export function calculateHealthRisk(input: RiskEngineInput): RiskAssessmentResult {
  const structuredReasons: RiskReason[] = [];
  const symptomSignals: string[] = [];
  const vaccinationSignals: string[] = [];
  const environmentalSignals: string[] = [];
  let rawScore = 0;

  // 1. Mortality Baseline & Ratio
  const recent = input.recentDailyMortalities ?? [];
  const flockSize = (input.currentBirdCount && input.currentBirdCount > 0) ? input.currentBirdCount : 1000;
  const mortalityRate = input.currentMortality / flockSize;
  let baselineAvg = 0;
  let ratio = 1.0;
  let baselineStatus = 'sufficient';
  let dataQuality = 'Good';

  if (recent.length < 2) {
    baselineStatus = 'insufficient_data';
    dataQuality = 'Limited';
    let pts = 0;
    let severity: 'info' | 'warning' | 'critical' = 'info';

    if (mortalityRate >= RiskConfig.mortalityRateCriticalThreshold) {
      pts = RiskConfig.mortalityPointsCritical;
      severity = 'critical';
    } else if (mortalityRate >= RiskConfig.mortalityRateHighThreshold) {
      pts = RiskConfig.mortalityPointsHigh;
      severity = 'warning';
    } else if (mortalityRate >= RiskConfig.mortalityRateModerateThreshold) {
      pts = RiskConfig.mortalityPointsModerate;
      severity = 'info';
    } else if (input.currentMortality > 0) {
      pts = RiskConfig.mortalityPointsMild;
    }

    if (pts > 0) {
      rawScore += pts;
      structuredReasons.push({
        code: 'mortality_limited_baseline',
        label: 'Mortality assessed using flock population rate',
        value: `${(mortalityRate * 100).toFixed(1)}% flock loss (${input.currentMortality} birds)`,
        points: pts,
        severity,
      });
    }
  } else {
    const sum = recent.reduce((a, b) => a + b, 0);
    baselineAvg = sum / recent.length;
    const effectiveAvg = baselineAvg < 1.0 ? 1.0 : baselineAvg;
    ratio = input.currentMortality / effectiveAvg;

    let pts = 0;
    let severity: 'info' | 'warning' | 'critical' = 'info';
    let label = 'Slightly elevated mortality';

    if (ratio > RiskConfig.mortalityRatioHigh) {
      pts = RiskConfig.mortalityPointsCritical;
      severity = 'critical';
      label = 'Severe mortality spike anomaly';
    } else if (ratio > RiskConfig.mortalityRatioModerate) {
      pts = RiskConfig.mortalityPointsHigh;
      severity = 'warning';
      label = 'Significant mortality increase';
    } else if (ratio > RiskConfig.mortalityRatioMild) {
      pts = RiskConfig.mortalityPointsModerate;
      severity = 'warning';
      label = 'Mortality above historical average';
    } else if (ratio > RiskConfig.mortalityRatioNormal) {
      pts = RiskConfig.mortalityPointsMild;
      severity = 'info';
    }

    if (pts > 0) {
      rawScore += pts;
      structuredReasons.push({
        code: 'mortality_spike',
        label,
        value: `${ratio.toFixed(1)}x baseline (${input.currentMortality} vs ${baselineAvg.toFixed(1)}/day)`,
        points: pts,
        severity,
      });
    }
  }

  // 2. Feed Reduction
  const feed = input.feedReductionPercent ?? 0;
  if (feed > RiskConfig.feedReductionCritical) {
    rawScore += RiskConfig.feedPointsCritical;
    structuredReasons.push({
      code: 'feed_reduction_critical',
      label: 'Severe feed consumption drop',
      value: `-${feed.toFixed(0)}% intake loss`,
      points: RiskConfig.feedPointsCritical,
      severity: 'critical',
    });
  } else if (feed > RiskConfig.feedReductionHigh) {
    rawScore += RiskConfig.feedPointsHigh;
    structuredReasons.push({
      code: 'feed_reduction_high',
      label: 'Significant feed intake reduction',
      value: `-${feed.toFixed(0)}%`,
      points: RiskConfig.feedPointsHigh,
      severity: 'warning',
    });
  } else if (feed > RiskConfig.feedReductionModerate) {
    rawScore += RiskConfig.feedPointsModerate;
    structuredReasons.push({
      code: 'feed_reduction_moderate',
      label: 'Moderate feed intake drop',
      value: `-${feed.toFixed(0)}%`,
      points: RiskConfig.feedPointsModerate,
      severity: 'warning',
    });
  } else if (feed > RiskConfig.feedReductionMild) {
    rawScore += RiskConfig.feedPointsMild;
    structuredReasons.push({
      code: 'feed_reduction_mild',
      label: 'Minor feed intake reduction',
      value: `-${feed.toFixed(0)}%`,
      points: RiskConfig.feedPointsMild,
      severity: 'info',
    });
  }

  // 3. Water Reduction
  const water = input.waterReductionPercent ?? 0;
  if (water > RiskConfig.waterReductionCritical) {
    rawScore += RiskConfig.waterPointsCritical;
    structuredReasons.push({
      code: 'water_reduction_critical',
      label: 'Severe water consumption drop',
      value: `-${water.toFixed(0)}% water loss`,
      points: RiskConfig.waterPointsCritical,
      severity: 'critical',
    });
  } else if (water > RiskConfig.waterReductionHigh) {
    rawScore += RiskConfig.waterPointsHigh;
    structuredReasons.push({
      code: 'water_reduction_high',
      label: 'Significant water intake drop',
      value: `-${water.toFixed(0)}%`,
      points: RiskConfig.waterPointsHigh,
      severity: 'warning',
    });
  } else if (water > RiskConfig.waterReductionModerate) {
    rawScore += RiskConfig.waterPointsModerate;
    structuredReasons.push({
      code: 'water_reduction_moderate',
      label: 'Moderate water intake drop',
      value: `-${water.toFixed(0)}%`,
      points: RiskConfig.waterPointsModerate,
      severity: 'warning',
    });
  } else if (water > RiskConfig.waterReductionMild) {
    rawScore += RiskConfig.waterPointsMild;
    structuredReasons.push({
      code: 'water_reduction_mild',
      label: 'Minor water intake reduction',
      value: `-${water.toFixed(0)}%`,
      points: RiskConfig.waterPointsMild,
      severity: 'info',
    });
  }

  // 4. Symptoms
  let rawSymptomPts = 0;
  const normalizedSymptoms = input.symptoms.map(s => s.trim().toLowerCase().replace(/ /g, '_'));
  for (const sym of normalizedSymptoms) {
    const weight = RiskConfig.symptomWeights[sym] ?? 4;
    rawSymptomPts += weight;
    symptomSignals.push(sym);
  }
  const effectiveSymptomPts = Math.min(rawSymptomPts, RiskConfig.maxSymptomPoints);
  if (effectiveSymptomPts > 0) {
    rawScore += effectiveSymptomPts;
    structuredReasons.push({
      code: 'clinical_symptoms',
      label: 'Clinical symptoms reported',
      value: `${normalizedSymptoms.length} signs (${effectiveSymptomPts} pts)`,
      points: effectiveSymptomPts,
      severity: effectiveSymptomPts >= 15 ? 'critical' : (effectiveSymptomPts >= 8 ? 'warning' : 'info'),
    });
  }

  // 5. Syndromic Clusters
  const respMatches = normalizedSymptoms.filter(s => RiskConfig.respiratorySymptoms.includes(s)).length;
  if (respMatches >= 2) {
    rawScore += RiskConfig.syndromeBonusPoints;
    structuredReasons.push({
      code: 'respiratory_syndrome',
      label: 'Respiratory syndrome detected',
      value: `${respMatches} distinct respiratory signs`,
      points: RiskConfig.syndromeBonusPoints,
      severity: 'critical',
    });
  }

  // 6. Sudden Death
  if (normalizedSymptoms.includes('sudden_death')) {
    rawScore += RiskConfig.suddenDeathBonusPoints;
    structuredReasons.push({
      code: 'sudden_death_event',
      label: 'Sudden acute mortality event reported',
      value: 'Peracute onset',
      points: RiskConfig.suddenDeathBonusPoints,
      severity: 'critical',
    });
  }

  // 7. Vaccination
  if (input.hasOverdueVaccine) {
    rawScore += RiskConfig.vaccineSignificantlyOverduePoints;
    vaccinationSignals.push('overdue');
    structuredReasons.push({
      code: 'vaccine_overdue',
      label: 'Flock immunization overdue',
      value: 'Missing scheduled vaccine',
      points: RiskConfig.vaccineSignificantlyOverduePoints,
      severity: 'warning',
    });
  } else if (!input.hasVaccineRecords) {
    rawScore += RiskConfig.vaccineUnknownPoints;
    vaccinationSignals.push('unknown');
    structuredReasons.push({
      code: 'vaccine_unverified',
      label: 'Vaccination records unrecorded',
      value: 'Incomplete log',
      points: RiskConfig.vaccineUnknownPoints,
      severity: 'info',
    });
  }

  // 8. Environmental Stress
  let envPts = 0;
  if (input.temperature && (input.temperature < RiskConfig.optimalTempMin || input.temperature > RiskConfig.optimalTempMax)) {
    envPts += RiskConfig.envStressModeratePoints;
    environmentalSignals.push('temp_out_of_range');
  }
  if (input.humidity && (input.humidity < RiskConfig.optimalHumidityMin || input.humidity > RiskConfig.optimalHumidityMax)) {
    envPts += RiskConfig.envStressModeratePoints;
    environmentalSignals.push('humidity_out_of_range');
  }
  const effectiveEnvPts = Math.min(envPts, RiskConfig.maxEnvPoints);
  if (effectiveEnvPts > 0) {
    rawScore += effectiveEnvPts;
    structuredReasons.push({
      code: 'environmental_stress',
      label: 'Environmental stress (Temp/Humidity)',
      value: 'Outside optimal comfort zone',
      points: effectiveEnvPts,
      severity: 'info',
    });
  }

  // 9. Recent Cases
  if (input.recentHealthCasesCount && input.recentHealthCasesCount > 0) {
    rawScore += RiskConfig.recentCaseBonusPoints;
    structuredReasons.push({
      code: 'recent_case_anomaly',
      label: 'Recent health incident reported on farm',
      value: `${input.recentHealthCasesCount} active cases in 14d`,
      points: RiskConfig.recentCaseBonusPoints,
      severity: 'warning',
    });
  }

  // 10. Clamp & Classify
  const finalScore = Math.max(0, Math.min(rawScore, 100));
  let riskLevel: 'low' | 'moderate' | 'high' | 'critical' = 'low';
  if (finalScore >= 76) riskLevel = 'critical';
  else if (finalScore >= 51) riskLevel = 'high';
  else if (finalScore >= 31) riskLevel = 'moderate';

  const readableReasons = structuredReasons.map(
    r => `${r.points > 0 ? '+' + r.points + ' ' : ''}${r.label} (${r.value})`
  );

  return {
    id: `${input.caseId}_${RiskConfig.engineVersion}`,
    caseId: input.caseId,
    farmId: input.farmId,
    batchId: input.batchId,
    score: finalScore,
    riskLevel,
    structuredReasons,
    reasons: readableReasons,
    mortalityBaseline: baselineAvg,
    currentMortality: input.currentMortality,
    mortalityRatio: ratio,
    mortalityRate,
    feedChangePercent: feed,
    waterChangePercent: water,
    symptomSignals,
    vaccinationSignals,
    environmentalSignals,
    baselineStatus,
    dataQuality,
    inputHash: computeInputHash(input),
    engineVersion: RiskConfig.engineVersion,
    createdAt: new Date(),
    updatedAt: new Date(),
  };
}
