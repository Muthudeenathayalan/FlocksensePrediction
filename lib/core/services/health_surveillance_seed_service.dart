import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/disease_alert_model.dart';
import 'package:flock_sense/features/health/domain/outbreak_cluster_model.dart';
import 'package:flock_sense/features/health/domain/vet_assignment_model.dart';
import 'package:flock_sense/features/health/domain/biosecurity_assessment_model.dart';

/// Isolated Development & Demo Data Seed Utility (SIH26128)
///
/// NOTE: This utility NEVER runs automatically. It requires explicit invocation.
class HealthSurveillanceSeedService {
  HealthSurveillanceSeedService._();

  static final _firestore = FirebaseFirestore.instance;

  /// Explicitly seed demo disease surveillance records to Firestore
  static Future<void> seedDemoSurveillanceData({bool force = false}) async {
    debugPrint('[HealthSurveillanceSeedService] Checking if demo data is required...');
    try {
      final existingCases = await _firestore.collection('health_cases').limit(1).get();
      if (existingCases.docs.isNotEmpty && !force) {
        debugPrint('[HealthSurveillanceSeedService] Firestore already contains health cases. Skipping seed.');
        return;
      }

      final now = DateTime.now();

      // 1. Seed Health Cases
      final cases = [
        HealthCaseModel(
          id: 'hc_1042',
          caseNumber: 'HC-1042',
          farmId: 'farm_01',
          farmName: 'Green Valley Poultry Farm',
          flockId: 'flock_08',
          flockName: 'Cobb 500 — Batch 08',
          symptoms: ['Respiratory clicking', 'Reduced feed intake', 'Watery eyes', 'Lethargy'],
          affectedCount: 18,
          mortalityCount: 2,
          feedReductionPercent: 18.5,
          waterReductionPercent: 12.0,
          temperature: 31.5,
          humidity: 68.0,
          riskScore: 86,
          riskLevel: HealthRiskLevel.critical,
          possibleDiseases: ['Newcastle Disease (NDV)', 'Infectious Bronchitis', 'Avian Influenza'],
          riskReasons: [
            'Mortality increased 4.1× over baseline',
            'Feed intake dropped 18.5% in 24h',
            'Concurrent respiratory sounds and watery eyes reported',
          ],
          status: HealthCaseStatus.under_investigation,
          notes: 'Sudden drop in feed consumption and audible rales in Shed 2.',
          veterinarianAssessment: 'Suspected acute respiratory infection. Prescribed oral antimicrobial and isolation protocol.',
          diagnosis: 'Suspected Newcastle Disease (ND) / IB Complex',
          labRequired: true,
          reportedAt: now.subtract(const Duration(hours: 3)),
          updatedAt: now.subtract(const Duration(hours: 1)),
        ),
        HealthCaseModel(
          id: 'hc_1041',
          caseNumber: 'HC-1041',
          farmId: 'farm_01',
          farmName: 'Green Valley Poultry Farm',
          flockId: 'flock_06',
          flockName: 'Ross 308 — Batch 06',
          symptoms: ['Lethargy', 'Ruffled feathers'],
          affectedCount: 5,
          mortalityCount: 0,
          feedReductionPercent: 6.0,
          temperature: 34.2,
          humidity: 45.0,
          riskScore: 48,
          riskLevel: HealthRiskLevel.moderate,
          possibleDiseases: ['Acute Heat Stress', 'Subclinical Enteritis'],
          riskReasons: ['Ambient temperature peaked at 34.2°C during midday'],
          status: HealthCaseStatus.treatment_started,
          notes: 'Birds showing signs of heat stress during afternoon peak.',
          veterinarianAssessment: 'Increase ventilation fan speed and add Vitamin C to water.',
          diagnosis: 'Acute Ambient Heat Stress',
          reportedAt: now.subtract(const Duration(days: 1)),
          updatedAt: now.subtract(const Duration(hours: 12)),
        ),
      ];

      for (final hc in cases) {
        await _firestore.collection('health_cases').doc(hc.id).set(hc.toJson());
      }

      // 2. Seed Disease Alerts
      final alerts = [
        DiseaseAlertModel(
          id: 'alert_01',
          farmId: 'farm_01',
          batchId: 'flock_08',
          caseId: 'hc_1042',
          type: 'mortality_spike',
          severity: HealthRiskLevel.critical,
          title: 'Mortality Anomaly Detected in Batch B08',
          message: 'Mortality rate 4.1× above historical shed baseline with concurrent feed intake drop.',
          recipientRoles: ['farmer', 'veterinarian', 'government'],
          createdAt: now.subtract(const Duration(minutes: 15)),
          updatedAt: now.subtract(const Duration(minutes: 15)),
        ),
        DiseaseAlertModel(
          id: 'alert_02',
          farmId: 'farm_01',
          batchId: 'flock_04',
          type: 'vaccine_overdue',
          severity: HealthRiskLevel.moderate,
          title: 'Vaccination Due: ND LaSota Booster',
          message: 'Flock age 21 days reached. Recommended vaccination window closing in 24 hours.',
          recipientRoles: ['farmer', 'veterinarian'],
          createdAt: now.subtract(const Duration(hours: 2)),
          updatedAt: now.subtract(const Duration(hours: 2)),
        ),
      ];

      for (final al in alerts) {
        await _firestore.collection('disease_alerts').doc(al.id).set(al.toJson());
      }

      // 3. Seed Regional Outbreak Cluster
      final cluster = OutbreakClusterModel(
        id: 'cluster_nsk_01',
        clusterCode: 'OUT-2026-NSK-001',
        caseIds: const ['hc_1042'],
        farmIds: const ['farm_01'],
        district: 'Nashik',
        state: 'Maharashtra',
        possibleDisease: 'Newcastle Disease (NDV)',
        syndrome: 'respiratory',
        centerLatitude: 20.0110,
        centerLongitude: 73.7900,
        radiusKm: 12.5,
        caseCount: 1,
        farmCount: 1,
        affectedCount: 20,
        mortalityCount: 15,
        clusterConfidence: 85,
        confidenceLabel: ClusterConfidenceLabel.high_confidence_cluster,
        severity: 'critical',
        status: OutbreakClusterStatus.under_investigation,
        firstDetectedAt: now.subtract(const Duration(days: 2)),
        lastCaseAt: now.subtract(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      );
      await _firestore.collection('outbreak_clusters').doc(cluster.id).set(cluster.toJson());

      // 4. Seed Biosecurity Assessment
      final bio = BiosecurityAssessmentModel(
        id: 'bio_farm_01',
        farmId: 'farm_01',
        farmName: 'Green Valley Poultry Farm',
        score: 88,
        strength: BiosecurityStrength.strong,
        visitorLogMaintained: BiosecurityAnswer.yes,
        restrictedEntry: BiosecurityAnswer.yes,
        footwearDisinfection: BiosecurityAnswer.yes,
        vehicleDisinfection: BiosecurityAnswer.yes,
        protectiveClothing: BiosecurityAnswer.yes,
        isolationAreaAvailable: BiosecurityAnswer.yes,
        sickAnimalsIsolated: BiosecurityAnswer.yes,
        newAnimalsQuarantined: BiosecurityAnswer.yes,
        ageGroupsSeparated: BiosecurityAnswer.yes,
        routineShedCleaning: BiosecurityAnswer.yes,
        equipmentDisinfection: BiosecurityAnswer.yes,
        feederDrinkerCleaning: BiosecurityAnswer.yes,
        sharedEquipmentControl: BiosecurityAnswer.yes,
        cleanWaterSource: BiosecurityAnswer.yes,
        waterSanitation: BiosecurityAnswer.yes,
        feedContaminationProtection: BiosecurityAnswer.yes,
        feedStorageHygiene: BiosecurityAnswer.yes,
        safeCarcassDisposal: BiosecurityAnswer.yes,
        wasteDisposal: BiosecurityAnswer.yes,
        litterManureManagement: BiosecurityAnswer.yes,
        vaccinationRecordsMaintained: BiosecurityAnswer.yes,
        vaccinationUpToDate: BiosecurityAnswer.yes,
        regularHealthMonitoring: BiosecurityAnswer.yes,
        veterinaryContactAvailable: BiosecurityAnswer.yes,
        riskFactors: const [
          BiosecurityRiskFactor(
            code: 'env_proximity',
            category: 'environment',
            severity: 'medium',
            title: 'Proximity to open irrigation canal (400m)',
            pointsLost: 4,
          ),
        ],
        recommendations: const [
          'Maintain disinfectant footbath concentration at Shed entrances',
          'Keep wild bird netting tightly fastened',
        ],
        assessedAt: now.subtract(const Duration(days: 5)),
      );
      await _firestore.collection('biosecurity_assessments').doc(bio.id).set(bio.toJson());

      debugPrint('[HealthSurveillanceSeedService] Successfully seeded demo surveillance records.');
    } catch (e) {
      debugPrint('[HealthSurveillanceSeedService] Error seeding demo data: $e');
    }
  }
}
