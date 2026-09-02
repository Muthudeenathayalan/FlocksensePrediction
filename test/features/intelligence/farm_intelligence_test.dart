import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/health/data/cluster_detection_engine.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/intelligence/data/disease_evidence_engine.dart';
import 'package:flock_sense/features/intelligence/data/environmental_intelligence_engine.dart';
import 'package:flock_sense/features/intelligence/data/farm_baseline_engine.dart';
import 'package:flock_sense/features/intelligence/data/farm_intelligence_service.dart';
import 'package:flock_sense/features/intelligence/data/nearby_exposure_engine.dart';
import 'package:flock_sense/features/intelligence/data/recommendation_engine.dart';
import 'package:flock_sense/features/intelligence/data/syndrome_engine.dart';
import 'package:flock_sense/features/intelligence/data/visitor_exposure_engine.dart';
import 'package:flock_sense/features/intelligence/domain/disease_evidence_model.dart';
import 'package:flock_sense/features/intelligence/domain/environmental_intelligence_model.dart';
import 'package:flock_sense/features/intelligence/domain/farm_health_intelligence_model.dart';
import 'package:flock_sense/features/intelligence/domain/farm_metric_baseline_model.dart';
import 'package:flock_sense/features/intelligence/domain/nearby_exposure_model.dart';
import 'package:flock_sense/features/intelligence/domain/role_recommendation_model.dart';
import 'package:flock_sense/features/intelligence/domain/syndrome_engine_model.dart';
import 'package:flock_sense/features/intelligence/domain/visitor_event_model.dart';

void main() {
  group('FlockSense Farm Health Intelligence Engine — Exhaustive Test Suite', () {
    // ═════════════════════════════════════════════════════════════════════════
    // PHASE 3 — VALIDATE FARM BASELINE ENGINE
    // ═════════════════════════════════════════════════════════════════════════
    test('Phase 3.1: Green Valley historical baseline and acute anomaly calculation', () {
      // Historical mortality: 3, 2, 4, 3, 3, 4, 2 (mean = 3.0) -> current 15 (5x spike)
      final mortHistory = [3.0, 2.0, 4.0, 3.0, 3.0, 4.0, 2.0];
      final mortResult = FarmBaselineEngine.calculateSingleBaseline(
        metric: 'mortality',
        priorValues: mortHistory,
        currentValue: 15.0,
        unit: 'birds/day',
        isMortality: true,
      );

      expect(mortResult.baselineMean, closeTo(3.0, 0.1));
      expect(mortResult.ratio, closeTo(5.0, 0.2));
      expect(mortResult.status, MetricStatus.severeAnomaly);
      expect(mortResult.trend, 'worsening');

      // Historical feed: 510, 505, 515, 500, 510, 500, 510 -> current 410 (-19.6%)
      final feedHistory = [510.0, 505.0, 515.0, 500.0, 510.0, 500.0, 510.0];
      final feedResult = FarmBaselineEngine.calculateSingleBaseline(
        metric: 'feed',
        priorValues: feedHistory,
        currentValue: 410.0,
        unit: 'kg/day',
        isDropAnomaly: true,
      );

      expect(feedResult.baselineMean, closeTo(507.1, 1.0));
      expect(feedResult.deviationPercent, lessThan(-15.0));
      expect(feedResult.status, isIn([MetricStatus.abnormal, MetricStatus.severeAnomaly]));

      // Historical water: 900, 910, 895, 905, 900, 890, 905 -> current 720 (-20.0%)
      final waterHistory = [900.0, 910.0, 895.0, 905.0, 900.0, 890.0, 905.0];
      final waterResult = FarmBaselineEngine.calculateSingleBaseline(
        metric: 'water',
        priorValues: waterHistory,
        currentValue: 720.0,
        unit: 'L/day',
        isDropAnomaly: true,
      );

      expect(waterResult.baselineMean, closeTo(900.7, 1.0));
      expect(waterResult.deviationPercent, lessThan(-18.0));
      expect(waterResult.status, isIn([MetricStatus.abnormal, MetricStatus.severeAnomaly]));
    });

    test('Phase 3.2: FarmBaselineEngine handles edge cases (empty, zero baseline, single value, negative values)', () {
      // Empty history
      final emptyResult = FarmBaselineEngine.calculateSingleBaseline(
        metric: 'mortality',
        priorValues: [],
        currentValue: 5.0,
        unit: 'birds/day',
        isMortality: true,
      );
      expect(emptyResult.baselineMean, equals(3.0));
      expect(emptyResult.status, MetricStatus.watch);

      // Single historical value
      final singleResult = FarmBaselineEngine.calculateSingleBaseline(
        metric: 'mortality',
        priorValues: [3.0],
        currentValue: 12.0,
        unit: 'birds/day',
        isMortality: true,
      );
      expect(singleResult.baselineMean, equals(3.0));
      expect(singleResult.ratio, equals(4.0));
      expect(singleResult.status, MetricStatus.severeAnomaly);

      // Zero baseline (must not divide by zero or crash)
      final zeroResult = FarmBaselineEngine.calculateSingleBaseline(
        metric: 'mortality',
        priorValues: [0.0, 0.0, 0.0],
        currentValue: 8.0,
        unit: 'birds/day',
        isMortality: true,
      );
      expect(zeroResult.baselineMean, equals(0.0));
      expect(zeroResult.ratio, greaterThan(1.0));
      expect(zeroResult.status, MetricStatus.severeAnomaly);
    });

    // ═════════════════════════════════════════════════════════════════════════
    // PHASE 4 — VALIDATE ENVIRONMENTAL / THERMAL INTELLIGENCE
    // ═════════════════════════════════════════════════════════════════════════
    test('Phase 4.1: THI Heat Stress calculation and age-specific profile evaluation', () {
      // Normal environment (24°C, 60% RH -> THI 71.4, normal)
      final normalEnv = EnvironmentalIntelligenceEngine.evaluate(
        ambientTemperature: 24.0,
        humidity: 60.0,
        flockAgeDays: 28,
      );
      expect(normalEnv.thi, closeTo(71.4, 0.5));
      expect(normalEnv.environmentalStressLevel, EnvironmentalStressLevel.normal);

      // High heat load (35°C, 82% RH -> THI 91.3, critical)
      final criticalEnv = EnvironmentalIntelligenceEngine.evaluate(
        ambientTemperature: 35.0,
        humidity: 82.0,
        flockAgeDays: 28,
      );
      expect(criticalEnv.thi, closeTo(91.3, 0.5));
      expect(criticalEnv.environmentalStressLevel, EnvironmentalStressLevel.critical);
      expect(criticalEnv.explanation, contains('temperature'));
    });

    test('Phase 4.2: Surface temperature is interpreted as screening signal, not false disease/fever', () {
      final surfaceTelemetry = EnvironmentalIntelligenceEngine.evaluate(
        ambientTemperature: 30.0,
        humidity: 70.0,
        surfaceTemperature: 43.8, // Elevated surface hotspot
        thermalHotspotCount: 4,
        flockAgeDays: 28,
      );

      expect(surfaceTelemetry.surfaceTemperature, equals(43.8));
      expect(surfaceTelemetry.thermalHotspotCount, equals(4));
      expect(surfaceTelemetry.explanation, contains('hotspot'));
      expect(surfaceTelemetry.advisory, contains('physiological stress'));
    });

    // ═════════════════════════════════════════════════════════════════════════
    // PHASE 5 — VALIDATE VISITOR EXPOSURE ENGINE
    // ═════════════════════════════════════════════════════════════════════════
    test('Phase 5.1: Case A (Compliant Biosecurity) -> LOW exposure', () {
      final now = DateTime.now();
      final compliantEvents = [
        VisitorEventModel(
          id: 'v1',
          farmId: 'farm_01',
          visitorName: 'Feed Delivery Officer',
          visitorType: 'feed_supplier',
          purpose: 'Feed restocking',
          enteredAt: now.subtract(const Duration(hours: 12)),
          visitedLivestockFarmRecently: false,
          footwearDisinfected: true,
          vehicleDisinfected: true,
          ppeUsed: true,
          sharedEquipment: false,
          newAnimalIntroductionRelated: false,
          createdAt: now,
        ),
      ];

      final result = VisitorExposureEngine.evaluateFarmVisitorHistory(compliantEvents);
      expect(result.biosecurityExposureLevel, BiosecurityExposureLevel.low);
      expect(result.biosecurityExposureScore, lessThan(30));
    });

    test('Phase 5.2: Case B (Recent livestock contact, missing footbath, shared equipment) -> HIGH exposure', () {
      final now = DateTime.now();
      final breachEvents = [
        VisitorEventModel(
          id: 'v2',
          farmId: 'farm_01',
          visitorName: 'Poultry Supplier Rep',
          visitorType: 'poultry_supplier',
          purpose: 'Chicks consultation',
          enteredAt: now.subtract(const Duration(hours: 24)),
          visitedLivestockFarmRecently: true,
          footwearDisinfected: false,
          vehicleDisinfected: false,
          ppeUsed: false,
          sharedEquipment: true,
          newAnimalIntroductionRelated: false,
          createdAt: now,
        ),
      ];

      final result = VisitorExposureEngine.evaluateFarmVisitorHistory(breachEvents);
      expect(result.biosecurityExposureLevel, isIn([BiosecurityExposureLevel.moderate, BiosecurityExposureLevel.high, BiosecurityExposureLevel.critical]));
      expect(result.biosecurityExposureScore, greaterThanOrEqualTo(50));
      // Non-causal explanation check: Never say "Visitor caused disease"
      for (final factor in result.contributingFactors) {
        expect(factor, isNot(contains('caused disease')));
      }
    });

    // ═════════════════════════════════════════════════════════════════════════
    // PHASE 6 — VALIDATE NEARBY EXPOSURE ENGINE
    // ═════════════════════════════════════════════════════════════════════════
    test('Phase 6.1: Spatio-temporal corridor (4km, 6km, 8km within 72h) -> HIGH/CRITICAL exposure & Anonymized Farmer View', () {
      final now = DateTime.now();

      final externalCases = [
        HealthCaseWithLocation(
          healthCase: HealthCaseModel(
            id: 'c1',
            caseNumber: 'CASE-001',
            farmId: 'farm_02', // 4 km away
            farmName: 'Sunrise Broiler Farm',
            flockId: 'flock_02',
            flockName: 'Batch B',
            affectedCount: 20,
            mortalityCount: 5,
            symptoms: const ['coughing', 'gasping'],
            possibleDiseases: const ['Newcastle Disease'],
            riskLevel: HealthRiskLevel.high,
            status: HealthCaseStatus.reported,
            district: 'Nashik',
            farmerId: 'farmer_02',
            notes: 'Confidential clinical suspicion of Newcastle',
            reportedAt: now.subtract(const Duration(hours: 18)),
            updatedAt: now.subtract(const Duration(hours: 18)),
          ),
          location: const FarmLocation(farmId: 'farm_02', farmName: 'Sunrise Broiler Farm', latitude: 20.0200, longitude: 73.8100),
        ),
        HealthCaseWithLocation(
          healthCase: HealthCaseModel(
            id: 'c2',
            caseNumber: 'CASE-002',
            farmId: 'farm_03', // 6 km away
            farmName: 'Highland Layer Farm',
            flockId: 'flock_03',
            flockName: 'Batch C',
            affectedCount: 35,
            mortalityCount: 12,
            symptoms: const ['coughing', 'rales'],
            possibleDiseases: const ['Infectious Bronchitis'],
            riskLevel: HealthRiskLevel.critical,
            status: HealthCaseStatus.reported,
            district: 'Nashik',
            farmerId: 'farmer_03',
            notes: 'Confidential lab isolate sent',
            reportedAt: now.subtract(const Duration(hours: 36)),
            updatedAt: now.subtract(const Duration(hours: 36)),
          ),
          location: const FarmLocation(farmId: 'farm_03', farmName: 'Highland Layer Farm', latitude: 20.0400, longitude: 73.8200),
        ),
        HealthCaseWithLocation(
          healthCase: HealthCaseModel(
            id: 'c3',
            caseNumber: 'CASE-003',
            farmId: 'farm_04', // 8 km away
            farmName: 'Valley Edge Broilers',
            flockId: 'flock_04',
            flockName: 'Batch D',
            affectedCount: 18,
            mortalityCount: 4,
            symptoms: const ['coughing', 'gasping'],
            possibleDiseases: const ['Newcastle Disease'],
            riskLevel: HealthRiskLevel.high,
            status: HealthCaseStatus.reported,
            district: 'Nashik',
            farmerId: 'farmer_04',
            reportedAt: now.subtract(const Duration(hours: 48)),
            updatedAt: now.subtract(const Duration(hours: 48)),
          ),
          location: const FarmLocation(farmId: 'farm_04', farmName: 'Valley Edge Broilers', latitude: 20.0600, longitude: 73.8300),
        ),
      ];

      final result = NearbyExposureEngine.evaluateNearbyExposure(
        targetFarmId: 'farm_01',
        targetLat: 19.9975,
        targetLon: 73.7898,
        targetSyndrome: 'respiratory',
        allRecentCasesWithLocation: externalCases,
      );

      expect(result.similarSyndromeCaseCount, greaterThanOrEqualTo(2));
      expect(result.nearbyExposureLevel, isIn([NearbyExposureLevel.high, NearbyExposureLevel.critical]));
      expect(result.nearestCaseDistanceKm, lessThan(10.0));

      // Privacy verification: Farmer view must NOT reveal names, phone, exact coordinates or vet notes
      final summary = result.farmerAnonymizedSummary;
      expect(summary, contains('respiratory health signals reported within approximately'));
      expect(summary, isNot(contains('Private Farmer B')));
      expect(summary, isNot(contains('Confidential clinical suspicion')));
    });

    test('Phase 6.2: Negative scenarios (>10km, >72h, same farm repeat, low risk) are excluded', () {
      final now = DateTime.now();

      final negativeCases = [
        // Same farm repeat (must not count as external nearby farm)
        HealthCaseWithLocation(
          healthCase: HealthCaseModel(
            id: 'c_same',
            caseNumber: 'CASE-000',
            farmId: 'farm_01',
            farmName: 'Green Valley',
            flockId: 'flock_01',
            flockName: 'Batch A',
            affectedCount: 10,
            mortalityCount: 3,
            symptoms: const ['coughing'],
            riskLevel: HealthRiskLevel.high,
            status: HealthCaseStatus.reported,
            reportedAt: now.subtract(const Duration(hours: 10)),
            updatedAt: now,
          ),
          location: const FarmLocation(farmId: 'farm_01', latitude: 19.9975, longitude: 73.7898),
        ),
        // > 10 km away (approx 50 km)
        HealthCaseWithLocation(
          healthCase: HealthCaseModel(
            id: 'c_far',
            caseNumber: 'CASE-FAR',
            farmId: 'farm_distant',
            farmName: 'Distant Farm',
            flockId: 'flock_x',
            flockName: 'Batch X',
            affectedCount: 50,
            mortalityCount: 20,
            symptoms: const ['coughing'],
            riskLevel: HealthRiskLevel.critical,
            status: HealthCaseStatus.reported,
            reportedAt: now.subtract(const Duration(hours: 10)),
            updatedAt: now,
          ),
          location: const FarmLocation(farmId: 'farm_distant', latitude: 20.5000, longitude: 74.2000),
        ),
        // > 72 hours old (5 days old)
        HealthCaseWithLocation(
          healthCase: HealthCaseModel(
            id: 'c_old',
            caseNumber: 'CASE-OLD',
            farmId: 'farm_old',
            farmName: 'Old Farm',
            flockId: 'flock_y',
            flockName: 'Batch Y',
            affectedCount: 10,
            mortalityCount: 2,
            symptoms: const ['coughing'],
            riskLevel: HealthRiskLevel.high,
            status: HealthCaseStatus.reported,
            reportedAt: now.subtract(const Duration(days: 5)),
            updatedAt: now,
          ),
          location: const FarmLocation(farmId: 'farm_old', latitude: 20.0100, longitude: 73.8000),
        ),
      ];

      final result = NearbyExposureEngine.evaluateNearbyExposure(
        targetFarmId: 'farm_01',
        targetLat: 19.9975,
        targetLon: 73.7898,
        targetSyndrome: 'respiratory',
        allRecentCasesWithLocation: negativeCases,
      );

      expect(result.similarSyndromeCaseCount, equals(0));
      expect(result.nearbyExposureLevel, equals(NearbyExposureLevel.low));
    });

    // ═════════════════════════════════════════════════════════════════════════
    // PHASE 7 — VALIDATE CLUSTER ENGINE
    // ═════════════════════════════════════════════════════════════════════════
    test('Phase 7.1: ClusterDetectionEngine requires >=3 distinct farms within 10km and 72h', () {
      final now = DateTime.now();

      // 2 farms -> NO cluster
      final twoFarmCases = [
        HealthCaseWithLocation(
          healthCase: HealthCaseModel(
            id: 'c1',
            caseNumber: 'CASE-01',
            farmId: 'farm_01',
            farmName: 'Farm 1',
            flockId: 'flock_1',
            flockName: 'Batch 1',
            affectedCount: 15,
            mortalityCount: 4,
            symptoms: const ['coughing', 'rales'],
            riskLevel: HealthRiskLevel.high,
            status: HealthCaseStatus.reported,
            district: 'Nashik',
            reportedAt: now.subtract(const Duration(hours: 10)),
            updatedAt: now,
          ),
          location: const FarmLocation(farmId: 'farm_01', latitude: 20.0000, longitude: 73.8000),
        ),
        HealthCaseWithLocation(
          healthCase: HealthCaseModel(
            id: 'c2',
            caseNumber: 'CASE-02',
            farmId: 'farm_02',
            farmName: 'Farm 2',
            flockId: 'flock_2',
            flockName: 'Batch 2',
            affectedCount: 20,
            mortalityCount: 6,
            symptoms: const ['coughing', 'gasping'],
            riskLevel: HealthRiskLevel.high,
            status: HealthCaseStatus.reported,
            district: 'Nashik',
            reportedAt: now.subtract(const Duration(hours: 15)),
            updatedAt: now,
          ),
          location: const FarmLocation(farmId: 'farm_02', latitude: 20.0200, longitude: 73.8100),
        ),
      ];
      final noClusterResult = ClusterDetectionEngine.detectClustersPure(casesWithLocation: twoFarmCases);
      expect(noClusterResult.isEmpty, isTrue);

      // 3 distinct farms -> Potential Disease Cluster
      final threeFarmCases = [
        ...twoFarmCases,
        HealthCaseWithLocation(
          healthCase: HealthCaseModel(
            id: 'c3',
            caseNumber: 'CASE-03',
            farmId: 'farm_03',
            farmName: 'Farm 3',
            flockId: 'flock_3',
            flockName: 'Batch 3',
            affectedCount: 25,
            mortalityCount: 8,
            symptoms: const ['coughing', 'rales'],
            riskLevel: HealthRiskLevel.high,
            status: HealthCaseStatus.reported,
            district: 'Nashik',
            reportedAt: now.subtract(const Duration(hours: 20)),
            updatedAt: now,
          ),
          location: const FarmLocation(farmId: 'farm_03', latitude: 20.0300, longitude: 73.8200),
        ),
      ];
      final clusterResult = ClusterDetectionEngine.detectClustersPure(casesWithLocation: threeFarmCases);
      expect(clusterResult.isNotEmpty, isTrue);
      expect(clusterResult.first.farmCount, equals(3));
      expect(clusterResult.first.confidenceLabel.label, contains('Cluster'));

      // 3 cases from SAME farm -> NO cluster
      final sameFarmThreeCases = [
        twoFarmCases[0],
        HealthCaseWithLocation(
          healthCase: twoFarmCases[0].healthCase.copyWith(id: 'c1_dup2', reportedAt: now.subtract(const Duration(hours: 12))),
          location: twoFarmCases[0].location,
        ),
        HealthCaseWithLocation(
          healthCase: twoFarmCases[0].healthCase.copyWith(id: 'c1_dup3', reportedAt: now.subtract(const Duration(hours: 14))),
          location: twoFarmCases[0].location,
        ),
      ];
      final sameFarmResult = ClusterDetectionEngine.detectClustersPure(casesWithLocation: sameFarmThreeCases);
      expect(sameFarmResult.isEmpty, isTrue);
    });

    // ═════════════════════════════════════════════════════════════════════════
    // PHASE 8 — VALIDATE SYNDROME ENGINE
    // ═════════════════════════════════════════════════════════════════════════
    test('Phase 8.1: SyndromeEngine correctly classifies Respiratory, Digestive, Neurological, and Mixed syndromes', () {
      // Respiratory
      final resp = SyndromeEngine.evaluateSyndrome(
        symptoms: ['coughing', 'gasping', 'nasal discharge', 'rales'],
      );
      expect(resp.primarySyndrome, PrimarySyndrome.respiratory);
      expect(resp.signalStrength, isIn([SyndromeSignalStrength.high, SyndromeSignalStrength.veryHigh]));

      // Digestive
      final dig = SyndromeEngine.evaluateSyndrome(
        symptoms: ['diarrhea', 'greenish droppings', 'reduced appetite', 'vent pasting'],
      );
      expect(dig.primarySyndrome, PrimarySyndrome.digestive);

      // Neurological
      final neuro = SyndromeEngine.evaluateSyndrome(
        symptoms: ['torticolis', 'twisted neck', 'tremors', 'wing paralysis'],
      );
      expect(neuro.primarySyndrome, PrimarySyndrome.neurological);

      // Mixed (Respiratory + Neurological)
      final mixed = SyndromeEngine.evaluateSyndrome(
        symptoms: ['coughing', 'gasping', 'twisted neck', 'tremors'],
      );
      expect(mixed.secondarySyndromes.isNotEmpty, isTrue);
      expect([mixed.primarySyndrome, ...mixed.secondarySyndromes], contains(PrimarySyndrome.respiratory));
      expect([mixed.primarySyndrome, ...mixed.secondarySyndromes], contains(PrimarySyndrome.neurological));
    });

    // ═════════════════════════════════════════════════════════════════════════
    // PHASE 9 — VALIDATE DISEASE EVIDENCE ENGINE
    // ═════════════════════════════════════════════════════════════════════════
    test('Phase 9.1: DiseaseEvidenceEngine matches differential candidates without fake percentages or premature confirmation', () {
      final candidates = DiseaseEvidenceEngine.evaluateCandidates(
        syndrome: SyndromeEngine.evaluateSyndrome(
          symptoms: ['coughing', 'respiratory difficulty', 'weakness'],
        ),
        baselines: {
          'mortality': FarmBaselineEngine.calculateSingleBaseline(
            metric: 'mortality',
            priorValues: [3.0, 3.0, 3.0, 3.0, 3.0, 3.0, 3.0],
            currentValue: 15.0,
            unit: 'birds/day',
            isMortality: true,
          ),
          'feed': FarmBaselineEngine.calculateSingleBaseline(
            metric: 'feed',
            priorValues: [510.0, 510.0, 510.0],
            currentValue: 410.0,
            unit: 'kg/day',
            isDropAnomaly: true,
          ),
        },
        symptoms: ['coughing', 'respiratory difficulty', 'weakness'],
        hasOverdueVaccine: true,
        temperature: 35.0,
        humidity: 82.0,
      );

      expect(candidates.isNotEmpty, isTrue);

      // Newcastle Disease candidate
      final ndv = candidates.firstWhere((c) => c.name.contains('Newcastle'));
      expect(ndv.evidenceMatch, isIn([EvidenceMatchLevel.veryHigh, EvidenceMatchLevel.high]));
      expect(ndv.supportingEvidence, isNotEmpty);
      expect(ndv.missingEvidence, isNotEmpty); // Missing lab confirmation / neurological
      expect(ndv.supportingEvidence.any((s) => s.toLowerCase().contains('mortality')), isTrue);
      expect(ndv.supportingEvidence.any((s) => s.toLowerCase().contains('immunization') || s.toLowerCase().contains('vaccin') || s.toLowerCase().contains('booster')), isTrue);

      // Infectious Bronchitis candidate
      final ibv = candidates.firstWhere((c) => c.name.contains('Bronchitis'));
      expect(ibv.supportingEvidence, isNotEmpty);

      // Environmental Heat Stress candidate
      final heatStress = candidates.firstWhere((c) => c.name.contains('Heat'));
      expect(heatStress.supportingEvidence.any((s) => s.contains('telemetry') || s.contains('temperature') || s.contains('ambient')), isTrue);
      expect(heatStress.requiresLabConfirmation, isFalse);

      // Infectious disease candidates require laboratory confirmation
      for (final candidate in candidates.where((c) => c != heatStress)) {
        expect(candidate.requiresLabConfirmation, isTrue);
      }
    });

    // ═════════════════════════════════════════════════════════════════════════
    // PHASE 14 — ROLE-SPECIFIC RECOMMENDATIONS & LIFECYCLE
    // ═════════════════════════════════════════════════════════════════════════
    test('Phase 14.1: RecommendationEngine produces role-tailored actions from same intelligence state', () {
      final baselines = {
        'mortality': FarmBaselineEngine.calculateSingleBaseline(
          metric: 'mortality',
          priorValues: [3.0, 3.0, 3.0],
          currentValue: 15.0,
          unit: 'birds/day',
          isMortality: true,
        ),
      };
      final syndrome = SyndromeEngine.evaluateSyndrome(symptoms: ['coughing']);
      final env = EnvironmentalIntelligenceEngine.evaluate(
        ambientTemperature: 35.0,
        humidity: 82.0,
        flockAgeDays: 28,
      );
      final visitor = VisitorExposureEngine.evaluateFarmVisitorHistory([
        VisitorEventModel(
          id: 'v1',
          farmId: 'farm_01',
          visitorName: 'Visitor',
          purpose: 'Consult',
          enteredAt: DateTime.now(),
          footwearDisinfected: false,
          createdAt: DateTime.now(),
        ),
      ]);
      final nearby = NearbyExposureEngine.evaluateNearbyExposure(
        targetFarmId: 'farm_01',
        targetLat: 19.9975,
        targetLon: 73.7898,
        targetSyndrome: 'respiratory',
        allRecentCasesWithLocation: const [],
      );

      final farmerRecs = RecommendationEngine.generate(
        farmId: 'farm_01',
        farmName: 'Green Valley Poultry Farm',
        role: ResponsibleRole.farmer,
        baselines: baselines,
        syndrome: syndrome,
        environmentalStress: env,
        visitorExposure: visitor,
        nearbyExposure: nearby,
      );

      final vetRecs = RecommendationEngine.generate(
        farmId: 'farm_01',
        farmName: 'Green Valley Poultry Farm',
        role: ResponsibleRole.veterinarian,
        baselines: baselines,
        syndrome: syndrome,
        environmentalStress: env,
        visitorExposure: visitor,
        nearbyExposure: nearby,
      );

      final govRecs = RecommendationEngine.generate(
        farmId: 'farm_01',
        farmName: 'Green Valley Poultry Farm',
        role: ResponsibleRole.government,
        baselines: baselines,
        syndrome: syndrome,
        environmentalStress: env,
        visitorExposure: visitor,
        nearbyExposure: nearby,
      );

      expect(farmerRecs.isNotEmpty, isTrue);
      expect(vetRecs.isNotEmpty, isTrue);
      expect(govRecs.isNotEmpty, isTrue);

      // Farmer gets operational biosecurity & cooling actions
      expect(farmerRecs.any((r) => r.action.toLowerCase().contains('isolate') || r.action.toLowerCase().contains('ventilation') || r.action.toLowerCase().contains('disinfection') || r.title.toLowerCase().contains('biosecurity') || r.title.toLowerCase().contains('isolate')), isTrue);

      // Veterinarian gets clinical examination & diagnostic recommendations
      expect(vetRecs.any((r) => r.action.toLowerCase().contains('examination') || r.action.toLowerCase().contains('necropsy') || r.action.toLowerCase().contains('sample') || r.title.toLowerCase().contains('physical') || r.title.toLowerCase().contains('diagnostic') || r.title.toLowerCase().contains('order')), isTrue);

      // Government gets surveillance & network actions (never treatment prescriptions)
      expect(govRecs.any((r) => r.title.toLowerCase().contains('surveillance') || r.title.toLowerCase().contains('alert') || r.title.toLowerCase().contains('cordon') || r.title.toLowerCase().contains('network') || r.title.toLowerCase().contains('monitor') || r.title.toLowerCase().contains('prioritize')), isTrue);
      for (final rec in govRecs) {
        expect(rec.action, isNot(contains('Administer Antibiotic')));
        expect(rec.action, isNot(contains('Prescribe')));
      }

      // Lifecycle status defaults to recommended
      for (final rec in farmerRecs) {
        expect(rec.status, RecommendationStatus.recommended);
      }
    });

    // ═════════════════════════════════════════════════════════════════════════
    // PHASE 11 & 7: FULL GREEN VALLEY POULTRY SCENARIO ORCHESTRATION
    // ═════════════════════════════════════════════════════════════════════════
    test('Phase 11.1: Complete Green Valley Poultry Scenario through FarmIntelligenceService', () {
      final now = DateTime.now();
      final historyRecords = List.generate(
        7,
        (i) => DailyRecordModel(
          id: 'rec_${i + 1}',
          farmId: 'farm_01',
          batchId: 'flock_01',
          recordDate: now.subtract(Duration(days: 7 - i)),
          batchAgeDay: 21 + i,
          openingBirds: 10000,
          mortalityCount: 3,
          cullCount: 0,
          adjustmentCount: 0,
          closingBirds: 9997,
          feedConsumedKg: 510,
          waterConsumedLiters: 900,
          avgWeightGrams: 1500 + (i * 50),
          medicineGiven: false,
          vaccineGiven: false,
          ownerId: 'farmer_01',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final todayRecord = DailyRecordModel(
        id: 'rec_today',
        farmId: 'farm_01',
        batchId: 'flock_01',
        recordDate: now,
        batchAgeDay: 28,
        openingBirds: 9979,
        mortalityCount: 15, // 5x spike
        cullCount: 0,
        adjustmentCount: 0,
        closingBirds: 9964,
        feedConsumedKg: 410, // -19.6% drop
        waterConsumedLiters: 720, // -20.0% drop
        avgWeightGrams: 1850,
        medicineGiven: false,
        vaccineGiven: false,
        ownerId: 'farmer_01',
        createdAt: now,
        updatedAt: now,
      );

      final activeCase = HealthCaseModel(
        id: 'hc_1042',
        caseNumber: 'CASE-1042',
        farmId: 'farm_01',
        farmName: 'Green Valley Poultry Farm',
        flockId: 'flock_01',
        flockName: 'Batch 1',
        affectedCount: 25,
        mortalityCount: 15,
        symptoms: const ['coughing', 'respiratory difficulty', 'weakness'],
        possibleDiseases: const ['Newcastle Disease'],
        riskLevel: HealthRiskLevel.high,
        status: HealthCaseStatus.reported,
        district: 'Nashik',
        farmerId: 'farmer_01',
        reportedAt: now.subtract(const Duration(hours: 4)),
        updatedAt: now,
      );

      final visitorEvents = [
        VisitorEventModel(
          id: 'v_breach',
          farmId: 'farm_01',
          visitorName: 'Supplier Delivery Agent',
          visitorType: 'poultry_supplier',
          purpose: 'Stock delivery',
          enteredAt: now.subtract(const Duration(hours: 14)),
          visitedLivestockFarmRecently: true,
          footwearDisinfected: false,
          vehicleDisinfected: false,
          ppeUsed: false,
          sharedEquipment: true,
          newAnimalIntroductionRelated: false,
          createdAt: now,
        ),
      ];

      final intelligence = FarmIntelligenceService.computeIntelligence(
        farmId: 'farm_01',
        farmName: 'Green Valley Poultry Farm',
        batchId: 'flock_01',
        latitude: 19.9975,
        longitude: 73.7898,
        dailyRecords: [todayRecord, ...historyRecords],
        visitorEvents: visitorEvents,
        nearbyCandidateCases: const [],
        activeClusters: const [],
        activeHealthCase: activeCase,
        isOverdueVaccine: true,
      );

      // Verify Composite Health Score & Overall Status
      expect(intelligence.overallRiskScore, greaterThanOrEqualTo(80));
      expect(intelligence.farmBehaviourStatus, FarmBehaviourStatus.severeAnomaly);
      expect(intelligence.primarySyndrome, PrimarySyndrome.respiratory);
      expect(intelligence.diseaseCandidates.first.name, contains('Newcastle'));
      expect(intelligence.environmentalStressLevel, EnvironmentalStressLevel.normal);
      expect(intelligence.biosecurityExposureLevel, isIn([BiosecurityExposureLevel.high, BiosecurityExposureLevel.critical, BiosecurityExposureLevel.moderate]));
      expect(intelligence.recommendations.isNotEmpty, isTrue);
      expect(intelligence.timeline.isNotEmpty, isTrue);
      expect(intelligence.topContributingSignals, isNotEmpty);
    });
  });
}
