import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/outbreak_cluster_model.dart';
import 'package:flock_sense/features/intelligence/domain/environmental_intelligence_model.dart';
import 'package:flock_sense/features/intelligence/domain/farm_metric_baseline_model.dart';
import 'package:flock_sense/features/intelligence/domain/nearby_exposure_model.dart';
import 'package:flock_sense/features/intelligence/domain/role_recommendation_model.dart';
import 'package:flock_sense/features/intelligence/domain/syndrome_engine_model.dart';
import 'package:flock_sense/features/intelligence/domain/visitor_event_model.dart';

/// Unified Multi-Role Recommendation Engine (Part 13 & 14)
/// Generates tailored operational, clinical, and regional surveillance actions
class RecommendationEngine {
  RecommendationEngine._();

  /// Primary unified generator for role-specific recommendations
  static List<RoleRecommendationModel> generate({
    required String farmId,
    String? farmName,
    String? batchId,
    required ResponsibleRole role,
    required Map<String, FarmMetricBaseline> baselines,
    required SyndromeEvaluationResult syndrome,
    required EnvironmentalStressResult environmentalStress,
    required VisitorExposureResult visitorExposure,
    required NearbyExposureModel nearbyExposure,
    HealthCaseModel? activeCase,
    List<OutbreakClusterModel> activeClusters = const [],
    bool isOverdueVaccine = false,
  }) {
    final now = DateTime.now();
    final recs = <RoleRecommendationModel>[];

    final mortRatio = baselines['mortality']?.ratio ?? 1.0;
    final mortCurrent = baselines['mortality']?.currentValue ?? 0.0;
    final feedDev = baselines['feed']?.deviationPercent ?? 0.0;
    final waterDev = baselines['water']?.deviationPercent ?? 0.0;
    final effectiveFarmName = farmName ?? 'Farm';

    // ─────────────────────────────────────────────────────────────────────────
    // 1. FARMER ROLE RECOMMENDATIONS (Operational & Protective)
    // ─────────────────────────────────────────────────────────────────────────
    if (role == ResponsibleRole.farmer) {
      // A. Mortality & Clinical Isolation
      if (mortRatio >= 2.5 || mortCurrent >= 8.0) {
        recs.add(RoleRecommendationModel(
          id: 'rec_${farmId}_isolate_symptomatic',
          priority: RecommendationPriority.critical,
          title: 'Isolate Symptomatic Birds Immediately',
          action: 'Separate all birds displaying respiratory rales, gasping, or depression into a dedicated isolation pen.',
          reason: 'Mortality spike ($mortCurrent dead/day, ${mortRatio.toStringAsFixed(1)}x baseline) indicates active pathogen transmission.',
          source: 'Farm Baseline Engine',
          responsibleRole: ResponsibleRole.farmer,
          targetId: farmId,
          createdAt: now,
          updatedAt: now,
        ));

        recs.add(RoleRecommendationModel(
          id: 'rec_${farmId}_contact_vet',
          priority: RecommendationPriority.critical,
          title: 'Contact Duty Veterinarian for Triage',
          action: 'Request an immediate on-site clinical assessment or virtual consultation via FlockSense.',
          reason: 'Flock health risk is elevated and requires registered clinical evaluation.',
          source: 'Health Risk Engine',
          responsibleRole: ResponsibleRole.farmer,
          targetId: farmId,
          createdAt: now,
          updatedAt: now,
        ));
      }

      // B. Visitor & Biosecurity Barrier
      if (visitorExposure.biosecurityExposureLevel == BiosecurityExposureLevel.high ||
          visitorExposure.biosecurityExposureLevel == BiosecurityExposureLevel.critical ||
          nearbyExposure.nearbyExposureLevel == NearbyExposureLevel.high ||
          nearbyExposure.nearbyExposureLevel == NearbyExposureLevel.critical) {
        recs.add(RoleRecommendationModel(
          id: 'rec_${farmId}_restrict_visitors',
          priority: RecommendationPriority.high,
          title: 'Restrict Non-Essential Farm Visitors',
          action: 'Close shed perimeter gates to all external visitors and vehicles until health situation stabilizes.',
          reason: 'Recent external biosecurity exposure + nearby regional disease activity creates high transmission risk.',
          source: 'Visitor Exposure Engine + Nearby Exposure Engine',
          responsibleRole: ResponsibleRole.farmer,
          targetId: farmId,
          createdAt: now,
          updatedAt: now,
        ));

        recs.add(RoleRecommendationModel(
          id: 'rec_${farmId}_renew_disinfectant',
          priority: RecommendationPriority.high,
          title: 'Renew Shed-Entry Footbath Disinfectant',
          action: 'Drain and refill all entrance footbaths with fresh broad-spectrum virucidal solution (e.g. QAC / Chlorine 200 ppm).',
          reason: 'Footwear is the primary vector for carrying viral tracking across agricultural sheds.',
          source: 'Visitor Exposure Engine',
          responsibleRole: ResponsibleRole.farmer,
          targetId: farmId,
          createdAt: now,
          updatedAt: now,
        ));
      }

      // C. Environmental Stress & Ventilation
      if (environmentalStress.environmentalStressLevel == EnvironmentalStressLevel.high ||
          environmentalStress.environmentalStressLevel == EnvironmentalStressLevel.critical) {
        recs.add(RoleRecommendationModel(
          id: 'rec_${farmId}_inspect_ventilation',
          priority: RecommendationPriority.high,
          title: 'Inspect Shed Ventilation & Cooling Systems',
          action: 'Check exhaust fan operation, clean evaporative cooling pads, and verify shed air velocity.',
          reason: 'Ambient temperature (${environmentalStress.ambientTemperature.toStringAsFixed(1)}°C) and THI (${environmentalStress.thi.toStringAsFixed(1)}) exceed flock comfort band.',
          source: 'Environmental Intelligence Engine',
          responsibleRole: ResponsibleRole.farmer,
          targetId: farmId,
          createdAt: now,
          updatedAt: now,
        ));
      }

      // D. Hydration & Feed
      if (waterDev <= -10.0 || feedDev <= -10.0) {
        recs.add(RoleRecommendationModel(
          id: 'rec_${farmId}_verify_water_feed',
          priority: RecommendationPriority.medium,
          title: 'Verify Drinking Water Lines & Hydration',
          action: 'Check nipple drinker line water pressure, flush drinker lines, and supply oral electrolyte hydration.',
          reason: 'Feed intake reduced by ${feedDev.toStringAsFixed(0)}% and water intake by ${waterDev.toStringAsFixed(0)}%.',
          source: 'Farm Baseline Engine',
          responsibleRole: ResponsibleRole.farmer,
          targetId: farmId,
          createdAt: now,
          updatedAt: now,
        ));
      }

      // E. Vaccination Gap
      if (isOverdueVaccine) {
        recs.add(RoleRecommendationModel(
          id: 'rec_${farmId}_review_vaccination',
          priority: RecommendationPriority.medium,
          title: 'Review Scheduled Flock Immunization',
          action: 'Consult your attending veterinarian to administer overdue scheduled vaccine boosters.',
          reason: 'Flock immunity coverage gap detected in immunization registry.',
          source: 'Vaccination Registry',
          responsibleRole: ResponsibleRole.farmer,
          targetId: farmId,
          createdAt: now,
          updatedAt: now,
        ));
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2. VETERINARIAN ROLE RECOMMENDATIONS (Clinical & Diagnostic Decision Support)
    // ─────────────────────────────────────────────────────────────────────────
    if (role == ResponsibleRole.veterinarian) {
      if (mortRatio >= 2.5 || mortCurrent >= 10.0) {
        recs.add(RoleRecommendationModel(
          id: 'rec_vet_${farmId}_physical_exam',
          priority: RecommendationPriority.critical,
          title: 'Prioritize On-Site Physical & Necropsy Examination',
          action: 'Conduct clinical inspection of affected birds and perform post-mortem evaluation on fresh carcasses for $effectiveFarmName.',
          reason: 'High mortality ratio (${mortRatio.toStringAsFixed(1)}x) and acute clinical signs match contagious poultry disease differential.',
          source: 'Clinical Decision Support Engine',
          responsibleRole: ResponsibleRole.veterinarian,
          targetId: farmId,
          createdAt: now,
          updatedAt: now,
        ));

        recs.add(RoleRecommendationModel(
          id: 'rec_vet_${farmId}_order_lab',
          priority: RecommendationPriority.high,
          title: 'Order Diagnostic Laboratory RT-PCR Assay',
          action: 'Collect tracheal and cloacal swabs on viral transport media (VTM) and dispatch to District Diagnostic Lab.',
          reason: 'Differential diagnosis for ${syndrome.primarySyndrome.label} requires definitive viral pathogen confirmation.',
          source: 'Disease Evidence Engine',
          responsibleRole: ResponsibleRole.veterinarian,
          targetId: farmId,
          createdAt: now,
          updatedAt: now,
        ));
      }

      if (visitorExposure.biosecurityExposureLevel != BiosecurityExposureLevel.low) {
        recs.add(RoleRecommendationModel(
          id: 'rec_vet_${farmId}_investigate_biosecurity',
          priority: RecommendationPriority.high,
          title: 'Investigate Recent Biosecurity Exposure Event',
          action: 'Review visitor log entries regarding external livestock contact and vehicle movements prior to symptom onset.',
          reason: 'Visitor Exposure score is elevated (${visitorExposure.biosecurityExposureScore}/100) with potential cross-farm tracking.',
          source: 'Visitor Exposure Engine',
          responsibleRole: ResponsibleRole.veterinarian,
          targetId: farmId,
          createdAt: now,
          updatedAt: now,
        ));
      }

      if (nearbyExposure.nearbyExposureLevel != NearbyExposureLevel.low) {
        recs.add(RoleRecommendationModel(
          id: 'rec_vet_${farmId}_evaluate_cluster',
          priority: RecommendationPriority.high,
          title: 'Evaluate Epidemiological Cluster Proximity',
          action: 'Cross-reference $effectiveFarmName with ${nearbyExposure.similarSyndromeCaseCount} similar cases reported within ${nearbyExposure.nearestCaseDistanceKm} km.',
          reason: 'Spatial clustering indicates potential regional micro-epidemic corridor.',
          source: 'Nearby Exposure Engine',
          responsibleRole: ResponsibleRole.veterinarian,
          targetId: farmId,
          createdAt: now,
          updatedAt: now,
        ));
      }

      recs.add(RoleRecommendationModel(
        id: 'rec_vet_${farmId}_schedule_followup',
        priority: RecommendationPriority.medium,
        title: 'Schedule 48-Hour Recovery Follow-Up',
        action: 'Set mandatory follow-up checkpoint in FlockSense to verify farmer compliance and mortality stabilization.',
        reason: 'Continuous monitoring ensures early detection of potential disease escalation.',
        source: 'Veterinary Clinical Protocol',
        responsibleRole: ResponsibleRole.veterinarian,
        targetId: farmId,
        createdAt: now,
        updatedAt: now,
      ));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3. GOVERNMENT ROLE RECOMMENDATIONS (Regional & Surveillance)
    // ─────────────────────────────────────────────────────────────────────────
    if (role == ResponsibleRole.government) {
      if (activeClusters.isNotEmpty || nearbyExposure.nearbyExposureLevel == NearbyExposureLevel.critical) {
        recs.add(RoleRecommendationModel(
          id: 'rec_gov_${farmId}_intensify_surveillance',
          priority: RecommendationPriority.critical,
          title: 'Intensify District Disease Surveillance & Cordon',
          action: 'Direct local District Veterinary Officers (DVO) to initiate active syndromic surveillance within 10 km cordon.',
          reason: 'Active disease cluster detected with synchronized ${syndrome.primarySyndrome.label} syndrome.',
          source: 'Spatio-Temporal Cluster Detection Engine',
          responsibleRole: ResponsibleRole.government,
          targetId: farmId,
          createdAt: now,
          updatedAt: now,
        ));

        recs.add(RoleRecommendationModel(
          id: 'rec_gov_${farmId}_issue_advisory',
          priority: RecommendationPriority.high,
          title: 'Issue Regional Biosecurity Advisory',
          action: 'Broadcast FlockSense early-warning alert to all registered poultry farms in the district corridor.',
          reason: 'Epidemiological transmission risk elevated across neighboring agricultural premises.',
          source: 'Government Surveillance Engine',
          responsibleRole: ResponsibleRole.government,
          targetId: farmId,
          createdAt: now,
          updatedAt: now,
        ));
      }

      recs.add(RoleRecommendationModel(
        id: 'rec_gov_${farmId}_prioritize_unassigned',
        priority: RecommendationPriority.high,
        title: 'Prioritize Field Clinician Case Allocations',
        action: 'Review unassigned critical health cases and reallocate duty veterinarians to reduce triage latency.',
        reason: 'Maintaining rapid triage response times (<30 min) reduces district-wide contagion velocity.',
        source: 'Veterinary Network Monitoring Service',
        responsibleRole: ResponsibleRole.government,
        targetId: farmId,
        createdAt: now,
        updatedAt: now,
      ));

      if (isOverdueVaccine) {
        recs.add(RoleRecommendationModel(
          id: 'rec_gov_${farmId}_vaccine_audit',
          priority: RecommendationPriority.medium,
          title: 'Audit Regional Immunization Coverage Gaps',
          action: 'Review cold-chain supply and schedule booster drive for overdue poultry flocks in the sub-district.',
          reason: 'Vaccination coverage gaps increase herd vulnerability to virulent field strain challenges.',
          source: 'State Vaccination Surveillance',
          responsibleRole: ResponsibleRole.government,
          targetId: farmId,
          createdAt: now,
          updatedAt: now,
        ));
      }
    }

    // Sort: Critical -> High -> Medium -> Low
    recs.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    return recs;
  }
}
