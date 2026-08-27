import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/health/data/risk_config.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/risk_assessment_model.dart';
import 'package:flock_sense/features/vaccine/domain/vaccine_record_model.dart';

/// Calculation Input Payload for Risk Engine
class RiskEngineInput {
  final String caseId;
  final String farmId;
  final String batchId;
  final int currentMortality;
  final int affectedCount;
  final List<String> symptoms;
  final double? feedReductionPercent;
  final double? waterReductionPercent;
  final double? temperature;
  final double? humidity;
  final DateTime incidentDate;
  final int currentBirdCount;
  final List<DailyRecordModel> recentDailyRecords;
  final List<VaccineRecordModel> vaccinationRecords;
  final List<HealthCaseModel> recentHealthCases;
  final bool hasOverdueVaccine;

  const RiskEngineInput({
    required this.caseId,
    required this.farmId,
    required this.batchId,
    required this.currentMortality,
    required this.affectedCount,
    required this.symptoms,
    this.feedReductionPercent,
    this.waterReductionPercent,
    this.temperature,
    this.humidity,
    required this.incidentDate,
    this.currentBirdCount = 1000,
    this.recentDailyRecords = const [],
    this.vaccinationRecords = const [],
    this.recentHealthCases = const [],
    this.hasOverdueVaccine = false,
  });

  /// Deterministic Hash for Trigger-Loop Prevention & Idempotency
  String computeInputHash() {
    final normalizedSymptoms = List<String>.from(symptoms)..sort();
    final raw = [
      caseId,
      farmId,
      batchId,
      currentMortality,
      affectedCount,
      normalizedSymptoms.join(','),
      feedReductionPercent?.toStringAsFixed(1) ?? '0',
      waterReductionPercent?.toStringAsFixed(1) ?? '0',
      temperature?.toStringAsFixed(1) ?? '0',
      humidity?.toStringAsFixed(1) ?? '0',
      hasOverdueVaccine ? '1' : '0',
      RiskConfig.engineVersion,
    ].join('|');

    return md5.convert(utf8.encode(raw)).toString();
  }
}

/// Centralized Explainable Health Risk Engine (SIH26128)
class RiskEngine {
  RiskEngine._();

  /// Primary pure calculation method
  static RiskAssessmentModel calculateHealthRisk(RiskEngineInput input) {
    final structuredReasons = <RiskReasonModel>[];
    final symptomSignals = <String>[];
    final vaccinationSignals = <String>[];
    final environmentalSignals = <String>[];
    var rawScore = 0;

    // ── 1. Mortality Baseline & Spike Analysis (Max 25 pts) ───────────────────
    final baselineResult = _analyzeMortality(
      currentMortality: input.currentMortality,
      currentBirdCount: input.currentBirdCount,
      recentRecords: input.recentDailyRecords,
      incidentDate: input.incidentDate,
    );

    rawScore += baselineResult.pointsAdded;
    if (baselineResult.reason != null) {
      structuredReasons.add(baselineResult.reason!);
    }

    // ── 2. Feed Reduction Analysis (Max 15 pts) ──────────────────────────────
    final feedReduction = input.feedReductionPercent ?? 0.0;
    if (feedReduction > RiskConfig.feedReductionCritical) {
      const pts = RiskConfig.feedPointsCritical;
      rawScore += pts;
      structuredReasons.add(const RiskReasonModel(
        code: 'feed_reduction_critical',
        label: 'Severe feed consumption drop',
        value: '>25% intake loss',
        points: pts,
        severity: 'critical',
      ));
    } else if (feedReduction > RiskConfig.feedReductionHigh) {
      const pts = RiskConfig.feedPointsHigh;
      rawScore += pts;
      structuredReasons.add(RiskReasonModel(
        code: 'feed_reduction_high',
        label: 'Significant feed intake reduction',
        value: '-${feedReduction.toStringAsFixed(0)}%',
        points: pts,
        severity: 'warning',
      ));
    } else if (feedReduction > RiskConfig.feedReductionModerate) {
      const pts = RiskConfig.feedPointsModerate;
      rawScore += pts;
      structuredReasons.add(RiskReasonModel(
        code: 'feed_reduction_moderate',
        label: 'Moderate feed intake drop',
        value: '-${feedReduction.toStringAsFixed(0)}%',
        points: pts,
        severity: 'warning',
      ));
    } else if (feedReduction > RiskConfig.feedReductionMild) {
      const pts = RiskConfig.feedPointsMild;
      rawScore += pts;
      structuredReasons.add(RiskReasonModel(
        code: 'feed_reduction_mild',
        label: 'Minor feed intake reduction',
        value: '-${feedReduction.toStringAsFixed(0)}%',
        points: pts,
        severity: 'info',
      ));
    }

    // ── 3. Water Reduction Analysis (Max 15 pts) ─────────────────────────────
    final waterReduction = input.waterReductionPercent ?? 0.0;
    if (waterReduction > RiskConfig.waterReductionCritical) {
      const pts = RiskConfig.waterPointsCritical;
      rawScore += pts;
      structuredReasons.add(const RiskReasonModel(
        code: 'water_reduction_critical',
        label: 'Severe water consumption drop',
        value: '>25% water loss',
        points: pts,
        severity: 'critical',
      ));
    } else if (waterReduction > RiskConfig.waterReductionHigh) {
      const pts = RiskConfig.waterPointsHigh;
      rawScore += pts;
      structuredReasons.add(RiskReasonModel(
        code: 'water_reduction_high',
        label: 'Significant water intake drop',
        value: '-${waterReduction.toStringAsFixed(0)}%',
        points: pts,
        severity: 'warning',
      ));
    } else if (waterReduction > RiskConfig.waterReductionModerate) {
      const pts = RiskConfig.waterPointsModerate;
      rawScore += pts;
      structuredReasons.add(RiskReasonModel(
        code: 'water_reduction_moderate',
        label: 'Moderate water intake drop',
        value: '-${waterReduction.toStringAsFixed(0)}%',
        points: pts,
        severity: 'warning',
      ));
    } else if (waterReduction > RiskConfig.waterReductionMild) {
      const pts = RiskConfig.waterPointsMild;
      rawScore += pts;
      structuredReasons.add(RiskReasonModel(
        code: 'water_reduction_mild',
        label: 'Minor water intake reduction',
        value: '-${waterReduction.toStringAsFixed(0)}%',
        points: pts,
        severity: 'info',
      ));
    }

    // ── 4. Clinical Symptom Weighting (Capped at 25 pts) ─────────────────────
    var rawSymptomScore = 0;
    final normalizedSymptoms = input.symptoms.map((s) => s.trim().toLowerCase().replaceAll(' ', '_')).toList();

    for (final symptom in normalizedSymptoms) {
      final weight = RiskConfig.symptomWeights[symptom] ?? 4;
      rawSymptomScore += weight;
      symptomSignals.add(symptom);
    }

    final effectiveSymptomPoints = rawSymptomScore > RiskConfig.maxSymptomPoints
        ? RiskConfig.maxSymptomPoints
        : rawSymptomScore;

    if (effectiveSymptomPoints > 0) {
      rawScore += effectiveSymptomPoints;
      final severity = effectiveSymptomPoints >= 15
          ? 'critical'
          : (effectiveSymptomPoints >= 8 ? 'warning' : 'info');
      structuredReasons.add(RiskReasonModel(
        code: 'clinical_symptoms',
        label: 'Clinical symptoms reported',
        value: '${normalizedSymptoms.length} signs (${effectiveSymptomPoints} pts)',
        points: effectiveSymptomPoints,
        severity: severity,
      ));
    }

    // ── 5. Syndromic Cluster Bonuses (+5 pts each) ───────────────────────────
    final respMatches = normalizedSymptoms.where((s) => RiskConfig.respiratorySymptoms.contains(s)).length;
    if (respMatches >= 2) {
      const pts = RiskConfig.syndromeBonusPoints;
      rawScore += pts;
      structuredReasons.add(RiskReasonModel(
        code: 'respiratory_syndrome',
        label: 'Respiratory syndrome detected',
        value: '$respMatches distinct respiratory signs',
        points: pts,
        severity: 'critical',
      ));
    }

    final digestMatches = normalizedSymptoms.where((s) => RiskConfig.digestiveSymptoms.contains(s)).length;
    if (digestMatches >= 2) {
      const pts = RiskConfig.syndromeBonusPoints;
      rawScore += pts;
      structuredReasons.add(RiskReasonModel(
        code: 'digestive_syndrome',
        label: 'Digestive / enteric syndrome detected',
        value: '$digestMatches enteric signs',
        points: pts,
        severity: 'warning',
      ));
    }

    final neuroMatches = normalizedSymptoms.where((s) => RiskConfig.neurologicalSymptoms.contains(s)).length;
    if (neuroMatches >= 1) {
      const pts = RiskConfig.syndromeBonusPoints;
      rawScore += pts;
      structuredReasons.add(RiskReasonModel(
        code: 'neurological_syndrome',
        label: 'Neurological distress signs detected',
        value: '$neuroMatches neuro sign',
        points: pts,
        severity: 'critical',
      ));
    }

    // ── 6. Sudden Death Acute Signal (+10 pts) ────────────────────────────────
    if (normalizedSymptoms.contains('sudden_death')) {
      const pts = RiskConfig.suddenDeathBonusPoints;
      rawScore += pts;
      structuredReasons.add(const RiskReasonModel(
        code: 'sudden_death_event',
        label: 'Sudden acute mortality event reported',
        value: 'Peracute onset',
        points: pts,
        severity: 'critical',
      ));
    }

    // ── 7. Vaccination Compliance Signal (Max 10 pts) ─────────────────────────
    if (input.hasOverdueVaccine) {
      const pts = RiskConfig.vaccineSignificantlyOverduePoints;
      rawScore += pts;
      vaccinationSignals.add('overdue');
      structuredReasons.add(const RiskReasonModel(
        code: 'vaccine_overdue',
        label: 'Flock immunization overdue',
        value: 'Missing scheduled vaccine',
        points: pts,
        severity: 'warning',
      ));
    } else if (input.vaccinationRecords.isEmpty) {
      const pts = RiskConfig.vaccineUnknownPoints;
      rawScore += pts;
      vaccinationSignals.add('unknown');
      structuredReasons.add(const RiskReasonModel(
        code: 'vaccine_unverified',
        label: 'Vaccination records unrecorded',
        value: 'Incomplete immunization log',
        points: pts,
        severity: 'info',
      ));
    } else {
      vaccinationSignals.add('up_to_date');
    }

    // ── 8. Environmental Stress Signal (Max 10 pts) ───────────────────────────
    var envPoints = 0;
    if (input.temperature != null) {
      final t = input.temperature!;
      if (t < RiskConfig.optimalTempMin || t > RiskConfig.optimalTempMax) {
        envPoints += RiskConfig.envStressModeratePoints;
        environmentalSignals.add('temp_out_of_range');
      }
    }
    if (input.humidity != null) {
      final h = input.humidity!;
      if (h < RiskConfig.optimalHumidityMin || h > RiskConfig.optimalHumidityMax) {
        envPoints += RiskConfig.envStressModeratePoints;
        environmentalSignals.add('humidity_out_of_range');
      }
    }

    final effectiveEnvPoints = envPoints > RiskConfig.maxEnvPoints ? RiskConfig.maxEnvPoints : envPoints;
    if (effectiveEnvPoints > 0) {
      rawScore += effectiveEnvPoints;
      structuredReasons.add(RiskReasonModel(
        code: 'environmental_stress',
        label: 'Environmental stress (Temp/Humidity)',
        value: 'Outside optimal comfort zone',
        points: effectiveEnvPoints,
        severity: 'info',
      ));
    }

    // ── 9. Recent Health Incident Signal (+5 pts) ─────────────────────────────
    if (input.recentHealthCases.isNotEmpty) {
      const pts = RiskConfig.recentCaseBonusPoints;
      rawScore += pts;
      structuredReasons.add(RiskReasonModel(
        code: 'recent_case_anomaly',
        label: 'Recent health incident reported on farm',
        value: '${input.recentHealthCases.length} recent cases in 14d',
        points: pts,
        severity: 'warning',
      ));
    }

    // ── 10. Clamp & Classify ──────────────────────────────────────────────────
    final finalScore = rawScore.clamp(0, 100);
    final riskLevel = HealthRiskLevel.fromScore(finalScore);

    final readableReasons = structuredReasons
        .map((r) => '${r.points > 0 ? "+${r.points} " : ""}${r.label} (${r.value})')
        .toList();

    return RiskAssessmentModel(
      id: '${input.caseId}_${RiskConfig.engineVersion}',
      caseId: input.caseId,
      farmId: input.farmId,
      batchId: input.batchId,
      score: finalScore,
      riskLevel: riskLevel,
      structuredReasons: structuredReasons,
      reasons: readableReasons,
      mortalityBaseline: baselineResult.baselineAverage,
      currentMortality: input.currentMortality.toDouble(),
      mortalityRatio: baselineResult.ratio,
      mortalityRate: baselineResult.mortalityRate,
      feedChangePercent: feedReduction,
      waterChangePercent: waterReduction,
      symptomSignals: symptomSignals,
      vaccinationSignals: vaccinationSignals,
      environmentalSignals: environmentalSignals,
      nearbyCaseSignal: false,
      baselineStatus: baselineResult.baselineStatus,
      dataQuality: baselineResult.dataQuality,
      inputHash: input.computeInputHash(),
      engineVersion: RiskConfig.engineVersion,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Helper to calculate historical mortality baseline and spike points
  static _MortalityAnalysisResult _analyzeMortality({
    required int currentMortality,
    required int currentBirdCount,
    required List<DailyRecordModel> recentRecords,
    required DateTime incidentDate,
  }) {
    // 1. Filter prior records (before current incident date, up to 7 latest records)
    final priorRecords = recentRecords
        .where((r) => r.recordDate.isBefore(incidentDate) || r.recordDate.isAtSameMomentAs(incidentDate))
        .take(7)
        .toList();

    final safeFlockSize = currentBirdCount > 0 ? currentBirdCount : 1000;
    final mortalityRate = currentMortality / safeFlockSize;

    // 2. Insufficient baseline fallback
    if (priorRecords.length < 2) {
      int ratePoints = 0;
      RiskReasonModel? reason;

      if (mortalityRate >= RiskConfig.mortalityRateCriticalThreshold) {
        ratePoints = RiskConfig.mortalityPointsCritical;
        reason = RiskReasonModel(
          code: 'mortality_rate_critical',
          label: 'Severe mortality rate for flock size',
          value: '${(mortalityRate * 100).toStringAsFixed(1)}% flock loss ($currentMortality birds)',
          points: ratePoints,
          severity: 'critical',
        );
      } else if (mortalityRate >= RiskConfig.mortalityRateHighThreshold) {
        ratePoints = RiskConfig.mortalityPointsHigh;
        reason = RiskReasonModel(
          code: 'mortality_rate_high',
          label: 'Elevated mortality rate for flock size',
          value: '${(mortalityRate * 100).toStringAsFixed(1)}% flock loss',
          points: ratePoints,
          severity: 'warning',
        );
      } else if (mortalityRate >= RiskConfig.mortalityRateModerateThreshold) {
        ratePoints = RiskConfig.mortalityPointsModerate;
        reason = RiskReasonModel(
          code: 'mortality_rate_moderate',
          label: 'Moderate flock mortality rate',
          value: '${(mortalityRate * 100).toStringAsFixed(1)}% flock loss',
          points: ratePoints,
          severity: 'info',
        );
      } else if (currentMortality > 0) {
        ratePoints = RiskConfig.mortalityPointsMild;
        reason = RiskReasonModel(
          code: 'mortality_limited_baseline',
          label: 'Mortality assessed using available flock data',
          value: '$currentMortality birds (Limited history)',
          points: ratePoints,
          severity: 'info',
        );
      }

      return _MortalityAnalysisResult(
        pointsAdded: ratePoints,
        baselineAverage: 0.0,
        ratio: 1.0,
        mortalityRate: mortalityRate,
        baselineStatus: 'insufficient_data',
        dataQuality: 'Limited',
        reason: reason,
      );
    }

    // 3. Robust 7-Day Baseline Calculation
    final totalPriorMortality = priorRecords.fold<int>(0, (sum, r) => sum + r.mortalityCount);
    final avgMortality = totalPriorMortality / priorRecords.length;
    final effectiveAvg = avgMortality < 1.0 ? 1.0 : avgMortality; // Prevent division anomalies
    final ratio = currentMortality / effectiveAvg;

    int points = 0;
    RiskReasonModel? reason;

    if (ratio > RiskConfig.mortalityRatioHigh) {
      points = RiskConfig.mortalityPointsCritical;
      reason = RiskReasonModel(
        code: 'mortality_spike_critical',
        label: 'Severe mortality spike anomaly',
        value: '${ratio.toStringAsFixed(1)}x baseline ($currentMortality vs ${avgMortality.toStringAsFixed(1)}/day)',
        points: points,
        severity: 'critical',
      );
    } else if (ratio > RiskConfig.mortalityRatioModerate) {
      points = RiskConfig.mortalityPointsHigh;
      reason = RiskReasonModel(
        code: 'mortality_spike_high',
        label: 'Significant mortality increase',
        value: '${ratio.toStringAsFixed(1)}x baseline',
        points: points,
        severity: 'warning',
      );
    } else if (ratio > RiskConfig.mortalityRatioMild) {
      points = RiskConfig.mortalityPointsModerate;
      reason = RiskReasonModel(
        code: 'mortality_spike_moderate',
        label: 'Mortality above historical average',
        value: '${ratio.toStringAsFixed(1)}x baseline',
        points: points,
        severity: 'warning',
      );
    } else if (ratio > RiskConfig.mortalityRatioNormal) {
      points = RiskConfig.mortalityPointsMild;
      reason = RiskReasonModel(
        code: 'mortality_spike_mild',
        label: 'Slightly elevated mortality',
        value: '${ratio.toStringAsFixed(1)}x baseline',
        points: points,
        severity: 'info',
      );
    }

    return _MortalityAnalysisResult(
      pointsAdded: points,
      baselineAverage: avgMortality,
      ratio: ratio,
      mortalityRate: mortalityRate,
      baselineStatus: 'sufficient',
      dataQuality: 'Good',
      reason: reason,
    );
  }
}

class _MortalityAnalysisResult {
  final int pointsAdded;
  final double baselineAverage;
  final double ratio;
  final double mortalityRate;
  final String baselineStatus;
  final String dataQuality;
  final RiskReasonModel? reason;

  const _MortalityAnalysisResult({
    required this.pointsAdded,
    required this.baselineAverage,
    required this.ratio,
    required this.mortalityRate,
    required this.baselineStatus,
    required this.dataQuality,
    this.reason,
  });
}
