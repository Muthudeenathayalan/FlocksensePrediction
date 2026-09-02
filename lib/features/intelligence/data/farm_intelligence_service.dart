import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/health/data/cluster_detection_engine.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/outbreak_cluster_model.dart';
import 'package:flock_sense/features/intelligence/data/disease_evidence_engine.dart';
import 'package:flock_sense/features/intelligence/data/environmental_intelligence_engine.dart';
import 'package:flock_sense/features/intelligence/data/farm_baseline_engine.dart';
import 'package:flock_sense/features/intelligence/data/nearby_exposure_engine.dart';
import 'package:flock_sense/features/intelligence/data/recommendation_engine.dart';
import 'package:flock_sense/features/intelligence/data/syndrome_engine.dart';
import 'package:flock_sense/features/intelligence/data/visitor_exposure_engine.dart';
import 'package:flock_sense/features/intelligence/domain/environmental_intelligence_model.dart';
import 'package:flock_sense/features/intelligence/domain/farm_health_intelligence_model.dart';
import 'package:flock_sense/features/intelligence/domain/farm_health_timeline_model.dart';
import 'package:flock_sense/features/intelligence/domain/farm_metric_baseline_model.dart';
import 'package:flock_sense/features/intelligence/domain/nearby_exposure_model.dart';
import 'package:flock_sense/features/intelligence/domain/role_recommendation_model.dart';
import 'package:flock_sense/features/intelligence/domain/visitor_event_model.dart';

/// Central Orchestrator for the FlockSense Farm Health Intelligence Engine
class FarmIntelligenceService {
  FarmIntelligenceService._();

  /// Pure computation of FarmHealthIntelligenceModel from raw data inputs
  static FarmHealthIntelligenceModel computeIntelligence({
    required String farmId,
    String? farmName,
    String? batchId,
    required double latitude,
    required double longitude,
    required List<DailyRecordModel> dailyRecords,
    required List<VisitorEventModel> visitorEvents,
    required List<HealthCaseWithLocation> nearbyCandidateCases,
    required List<OutbreakClusterModel> activeClusters,
    HealthCaseModel? activeHealthCase,
    double? surfaceTemperature,
    int thermalHotspots = 0,
    bool isOverdueVaccine = false,
    ResponsibleRole targetRole = ResponsibleRole.farmer,
  }) {
    final now = DateTime.now();

    // 1. Calculate 7-Day Statistical Baselines
    final baselines = FarmBaselineEngine.calculateBaselines(
      dailyRecords: dailyRecords,
      currentMortality: activeHealthCase?.mortalityCount,
      currentFeedKg: activeHealthCase?.feedReductionPercent != null
          ? 500.0 * (1.0 - (activeHealthCase!.feedReductionPercent! / 100.0))
          : null,
      currentWaterLiters: activeHealthCase?.waterReductionPercent != null
          ? 850.0 * (1.0 - (activeHealthCase!.waterReductionPercent! / 100.0))
          : null,
      currentTemperature: activeHealthCase?.temperature,
      currentHumidity: activeHealthCase?.humidity,
    );

    // Current Telemetry
    final currentTemp = activeHealthCase?.temperature ??
        (dailyRecords.isNotEmpty ? (dailyRecords.first.temperature ?? 26.0).toDouble() : 26.0);
    final currentHum = activeHealthCase?.humidity ??
        (dailyRecords.isNotEmpty ? (dailyRecords.first.humidity ?? 60.0).toDouble() : 60.0);

    // 2. Evaluate Environmental & Thermal Telemetry
    final envResult = EnvironmentalIntelligenceEngine.evaluate(
      ambientTemperature: currentTemp,
      humidity: currentHum,
      flockAgeDays: 28,
      surfaceTemperature: surfaceTemperature,
      thermalHotspotCount: thermalHotspots,
    );

    // 3. Evaluate Visitor & Biosecurity History
    final visitorResult = VisitorExposureEngine.evaluateFarmVisitorHistory(visitorEvents);

    // 4. Evaluate Syndromic Pattern
    final symptoms = activeHealthCase?.symptoms ??
        (dailyRecords.isNotEmpty && dailyRecords.first.notes != null
            ? [dailyRecords.first.notes!]
            : <String>[]);

    final syndromeResult = SyndromeEngine.evaluateSyndrome(
      symptoms: symptoms,
      clinicalNotes: activeHealthCase?.notes,
      temperature: currentTemp,
      humidity: currentHum,
    );

    // 5. Evaluate Nearby Spatio-Temporal Exposure
    final nearbyResult = NearbyExposureEngine.evaluateNearbyExposure(
      targetFarmId: farmId,
      targetLat: latitude,
      targetLon: longitude,
      targetSyndrome: syndromeResult.primarySyndrome.name,
      allRecentCasesWithLocation: nearbyCandidateCases,
    );

    // 6. Disease Evidence Matching
    final diseaseCandidates = DiseaseEvidenceEngine.evaluateCandidates(
      syndrome: syndromeResult,
      baselines: baselines,
      symptoms: symptoms,
      hasOverdueVaccine: isOverdueVaccine,
      temperature: currentTemp,
      humidity: currentHum,
    );

    // 7. Overall Composite Risk Calculation (0 - 100)
    final mortRatio = baselines['mortality']?.ratio ?? 1.0;
    final mortCurrent = baselines['mortality']?.currentValue ?? 0.0;
    final feedDev = baselines['feed']?.deviationPercent ?? 0.0;

    int compositeRisk = 15; // Baseline healthy
    final topSignals = <String>[];
    final missingEvidenceList = <String>[];

    // Baseline Mortality contribution (Up to 35 pts)
    if (mortRatio >= 4.0 || mortCurrent >= 15) {
      compositeRisk += 35;
      topSignals.add('Severe mortality spike: ${mortCurrent.toInt()} dead/day (${mortRatio.toStringAsFixed(1)}x baseline)');
    } else if (mortRatio >= 2.0 || mortCurrent >= 8) {
      compositeRisk += 20;
      topSignals.add('Elevated mortality: ${mortCurrent.toInt()} dead/day (${mortRatio.toStringAsFixed(1)}x baseline)');
    } else if (mortRatio >= 1.5) {
      compositeRisk += 10;
      topSignals.add('Mortality slightly above baseline');
    }

    // Feed / Water drop contribution (Up to 15 pts)
    if (feedDev <= -15.0) {
      compositeRisk += 15;
      topSignals.add('Significant feed consumption drop: ${feedDev.toStringAsFixed(0)}%');
    } else if (feedDev <= -8.0) {
      compositeRisk += 8;
      topSignals.add('Moderate feed drop: ${feedDev.toStringAsFixed(0)}%');
    }

    // Clinical Symptoms (Up to 20 pts)
    if (syndromeResult.matchedSymptoms.isNotEmpty) {
      compositeRisk += (syndromeResult.matchedSymptoms.length * 6).clamp(0, 20);
      topSignals.add('Clinical symptoms observed: ${syndromeResult.matchedSymptoms.join(", ")}');
    }

    // Environmental Stress (Up to 15 pts)
    if (envResult.environmentalStressLevel == EnvironmentalStressLevel.critical) {
      compositeRisk += 15;
      topSignals.add('Extreme ambient heat index: ${currentTemp.toStringAsFixed(1)}°C, ${currentHum.toStringAsFixed(0)}% RH (THI ${envResult.thi.toStringAsFixed(1)})');
    } else if (envResult.environmentalStressLevel == EnvironmentalStressLevel.high) {
      compositeRisk += 10;
      topSignals.add('Elevated environmental stress: THI ${envResult.thi.toStringAsFixed(1)}');
    }

    // Biosecurity Exposure (Up to 10 pts)
    if (visitorResult.biosecurityExposureLevel == BiosecurityExposureLevel.critical ||
        visitorResult.biosecurityExposureLevel == BiosecurityExposureLevel.high) {
      compositeRisk += 10;
      topSignals.add('Recent external visitor/biosecurity exposure recorded on farm');
    }

    // Nearby Disease Exposure (Up to 15 pts)
    if (nearbyResult.nearbyExposureLevel == NearbyExposureLevel.critical ||
        nearbyResult.nearbyExposureLevel == NearbyExposureLevel.high) {
      compositeRisk += 15;
      topSignals.add(nearbyResult.farmerAnonymizedSummary);
    }

    // Overdue Vaccine (Up to 10 pts)
    if (isOverdueVaccine) {
      compositeRisk += 10;
      topSignals.add('Scheduled flock vaccination overdue');
    }

    final finalRiskScore = compositeRisk.clamp(0, 100);
    final overallRiskLevel = HealthRiskLevel.fromScore(finalRiskScore);

    // Behaviour Status
    FarmBehaviourStatus behaviourStatus = FarmBehaviourStatus.normal;
    if (mortRatio >= 4.0 || finalRiskScore >= 75) {
      behaviourStatus = FarmBehaviourStatus.severeAnomaly;
    } else if (mortRatio >= 2.0 || feedDev <= -15.0 || finalRiskScore >= 50) {
      behaviourStatus = FarmBehaviourStatus.abnormal;
    } else if (mortRatio >= 1.5 || finalRiskScore >= 30) {
      behaviourStatus = FarmBehaviourStatus.watch;
    }

    // Collect missing evidence
    if (diseaseCandidates.isNotEmpty) {
      missingEvidenceList.addAll(diseaseCandidates.first.missingEvidence);
    }
    if (activeHealthCase?.diagnosis == null || activeHealthCase!.diagnosis!.isEmpty) {
      missingEvidenceList.add('Veterinary clinical assessment: Pending');
    }
    if (activeHealthCase?.labRequired != true) {
      missingEvidenceList.add('Diagnostic laboratory confirmation: Not requested/available');
    }

    // 8. Generate Role-Tailored Recommendations
    final recommendations = RecommendationEngine.generate(
      farmId: farmId,
      farmName: farmName,
      batchId: batchId,
      role: targetRole,
      baselines: baselines,
      syndrome: syndromeResult,
      environmentalStress: envResult,
      visitorExposure: visitorResult,
      nearbyExposure: nearbyResult,
      activeCase: activeHealthCase,
      activeClusters: activeClusters,
      isOverdueVaccine: isOverdueVaccine,
    );

    // 9. Build Farm Health Timeline (Chronological events)
    final timelineEvents = _buildTimelineEvents(
      farmId: farmId,
      dailyRecords: dailyRecords,
      visitorEvents: visitorEvents,
      activeHealthCase: activeHealthCase,
      envResult: envResult,
      nearbyResult: nearbyResult,
      baselines: baselines,
      recommendations: recommendations,
    );

    return FarmHealthIntelligenceModel(
      farmId: farmId,
      batchId: batchId,
      farmName: farmName ?? 'Poultry Farm',
      overallRiskScore: finalRiskScore,
      overallRiskLevel: overallRiskLevel,
      farmBehaviourStatus: behaviourStatus,
      primarySyndrome: syndromeResult.primarySyndrome,
      syndromeSignalStrength: syndromeResult.signalStrength,
      syndromeResult: syndromeResult,
      environmentalStressScore: envResult.environmentalStressScore,
      environmentalStressLevel: envResult.environmentalStressLevel,
      environmentalStressResult: envResult,
      biosecurityExposureScore: visitorResult.biosecurityExposureScore,
      biosecurityExposureLevel: visitorResult.biosecurityExposureLevel,
      visitorExposureResult: visitorResult,
      nearbyExposureScore: nearbyResult.nearbyExposureScore,
      nearbyExposureLevel: nearbyResult.nearbyExposureLevel,
      nearbyExposure: nearbyResult,
      diseaseCandidates: diseaseCandidates,
      metricBaselines: baselines,
      topContributingSignals: topSignals,
      missingEvidence: missingEvidenceList.toSet().toList(),
      dataQuality: dailyRecords.length >= 5 ? 'Good' : 'Adequate',
      recommendations: recommendations,
      timeline: timelineEvents,
      updatedAt: now,
    );
  }

  /// Builds a coherent chronological timeline of farm events
  static List<FarmHealthTimelineEvent> _buildTimelineEvents({
    required String farmId,
    required List<DailyRecordModel> dailyRecords,
    required List<VisitorEventModel> visitorEvents,
    HealthCaseModel? activeHealthCase,
    required EnvironmentalStressResult envResult,
    required NearbyExposureModel nearbyResult,
    required Map<String, FarmMetricBaseline> baselines,
    required List<RoleRecommendationModel> recommendations,
  }) {
    final events = <FarmHealthTimelineEvent>[];
    final now = DateTime.now();

    // 1. Visitor Events
    for (final v in visitorEvents.take(5)) {
      events.add(FarmHealthTimelineEvent(
        id: 'ev_vis_${v.id}',
        farmId: farmId,
        timestamp: v.enteredAt,
        eventType: TimelineEventType.visitor_event,
        title: 'Visitor Logged: ${v.visitorName}',
        description: 'Purpose: ${v.purpose}. Disinfection: ${v.footwearDisinfected ? "Verified" : "Missing"}.',
        severity: v.footwearDisinfected && !v.visitedLivestockFarmRecently ? 'info' : 'warning',
        sourceId: v.id,
      ));
    }

    // 2. Health Case
    if (activeHealthCase != null) {
      events.add(FarmHealthTimelineEvent(
        id: 'ev_case_${activeHealthCase.id}',
        farmId: farmId,
        timestamp: activeHealthCase.reportedAt,
        eventType: TimelineEventType.health_report,
        title: 'Health Incident Reported (${activeHealthCase.caseNumber})',
        description: 'Symptoms: ${activeHealthCase.symptoms.join(", ")}. Mortalities: ${activeHealthCase.mortalityCount} birds.',
        severity: activeHealthCase.riskLevel == HealthRiskLevel.critical ? 'critical' : 'warning',
        sourceId: activeHealthCase.id,
      ));

      if (activeHealthCase.assignedVetId != null) {
        events.add(FarmHealthTimelineEvent(
          id: 'ev_vet_${activeHealthCase.id}',
          farmId: farmId,
          timestamp: activeHealthCase.reportedAt.add(const Duration(minutes: 18)),
          eventType: TimelineEventType.vet_assignment,
          title: 'Veterinary Triage Assigned',
          description: 'Attending Clinician ID: ${activeHealthCase.assignedVetId}. Priority Queue active.',
          severity: 'info',
          sourceId: activeHealthCase.id,
        ));
      }

      if (activeHealthCase.diagnosis != null && activeHealthCase.diagnosis!.isNotEmpty) {
        events.add(FarmHealthTimelineEvent(
          id: 'ev_diag_${activeHealthCase.id}',
          farmId: farmId,
          timestamp: activeHealthCase.reportedAt.add(const Duration(hours: 4)),
          eventType: TimelineEventType.diagnosis,
          title: 'Clinical Diagnosis: ${activeHealthCase.diagnosis}',
          description: 'Attending clinician recorded diagnostic assessment.',
          severity: 'success',
          sourceId: activeHealthCase.id,
        ));
      }
    }

    // 3. Telemetry / Metric Anomaly
    final mort = baselines['mortality'];
    if (mort != null && (mort.status == MetricStatus.severeAnomaly || mort.status == MetricStatus.abnormal)) {
      events.add(FarmHealthTimelineEvent(
        id: 'ev_mort_spike_${now.day}',
        farmId: farmId,
        timestamp: now.subtract(const Duration(hours: 6)),
        eventType: TimelineEventType.daily_metric_anomaly,
        title: 'Mortality Spike Detected',
        description: '${mort.currentValue.toInt()} mortalities recorded (${mort.ratio.toStringAsFixed(1)}x baseline average of ${mort.baselineMean.toStringAsFixed(1)}/day).',
        severity: mort.status == MetricStatus.severeAnomaly ? 'critical' : 'warning',
      ));
    }

    // 4. Environmental Event
    if (envResult.environmentalStressLevel != EnvironmentalStressLevel.normal) {
      events.add(FarmHealthTimelineEvent(
        id: 'ev_env_${now.day}',
        farmId: farmId,
        timestamp: now.subtract(const Duration(hours: 12)),
        eventType: TimelineEventType.environment_event,
        title: 'Environmental Heat Stress Alert',
        description: 'Ambient telemetry (${envResult.ambientTemperature}°C, ${envResult.humidity}% RH, THI ${envResult.thi}) outside optimal comfort profile.',
        severity: envResult.environmentalStressLevel == EnvironmentalStressLevel.critical ? 'critical' : 'warning',
      ));
    }

    // 5. Nearby Cluster Warning
    if (nearbyResult.nearbyExposureLevel == NearbyExposureLevel.critical ||
        nearbyResult.nearbyExposureLevel == NearbyExposureLevel.high) {
      events.add(FarmHealthTimelineEvent(
        id: 'ev_cluster_${now.day}',
        farmId: farmId,
        timestamp: now.subtract(const Duration(hours: 18)),
        eventType: TimelineEventType.cluster_warning,
        title: 'Nearby Disease Cluster Warning',
        description: nearbyResult.farmerAnonymizedSummary,
        severity: 'warning',
      ));
    }

    // Sort descending by timestamp
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events;
  }
}
