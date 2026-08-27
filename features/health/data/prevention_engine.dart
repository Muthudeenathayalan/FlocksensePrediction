import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/core/services/audit_service.dart';
import 'package:flock_sense/features/health/data/cluster_detection_engine.dart';
import 'package:flock_sense/features/health/domain/biosecurity_assessment_model.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/outbreak_cluster_model.dart';
import 'package:flock_sense/features/health/domain/prevention_recommendation_model.dart';
import 'package:flock_sense/features/vaccine/domain/vaccine_record_model.dart';

/// Central Deterministic Prevention & Protective Intelligence Engine (SIH26128 Phase 10)
class PreventionEngine {
  PreventionEngine._();

  static final _firestore = FirebaseFirestore.instance;
  static final _auditService = AuditService();

  static const String preventionEngineVersion = 'prevention-v1';
  static const String biosecurityAssessmentVersion = 'biosecurity-v1';

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. CALCULATE BIOSECURITY ASSESSMENT SCORE & RISK FACTORS
  // ─────────────────────────────────────────────────────────────────────────────

  /// Computes deterministic biosecurity score (0-100), category scores, and risk factors
  static BiosecurityAssessmentModel evaluateBiosecurity({
    required String farmId,
    required String farmName,
    required BiosecurityAnswer visitorLogMaintained,
    required BiosecurityAnswer restrictedEntry,
    required BiosecurityAnswer footwearDisinfection,
    required BiosecurityAnswer vehicleDisinfection,
    required BiosecurityAnswer protectiveClothing,
    required BiosecurityAnswer isolationAreaAvailable,
    required BiosecurityAnswer sickAnimalsIsolated,
    required BiosecurityAnswer newAnimalsQuarantined,
    required BiosecurityAnswer ageGroupsSeparated,
    required BiosecurityAnswer routineShedCleaning,
    required BiosecurityAnswer equipmentDisinfection,
    required BiosecurityAnswer feederDrinkerCleaning,
    required BiosecurityAnswer sharedEquipmentControl,
    required BiosecurityAnswer cleanWaterSource,
    required BiosecurityAnswer waterSanitation,
    required BiosecurityAnswer feedContaminationProtection,
    required BiosecurityAnswer feedStorageHygiene,
    required BiosecurityAnswer safeCarcassDisposal,
    required BiosecurityAnswer wasteDisposal,
    required BiosecurityAnswer litterManureManagement,
    required BiosecurityAnswer vaccinationRecordsMaintained,
    required BiosecurityAnswer vaccinationUpToDate,
    required BiosecurityAnswer regularHealthMonitoring,
    required BiosecurityAnswer veterinaryContactAvailable,
    String assessedBy = 'Farmer',
    String id = '',
  }) {
    int earnedPoints = 0;
    int maxPoints = 0;

    final riskFactors = <BiosecurityRiskFactor>[];
    final recommendations = <String>[];

    // Helper for evaluating items
    void evalItem({
      required BiosecurityAnswer answer,
      required String code,
      required String category,
      required String title,
      required String rec,
      String severity = 'high',
    }) {
      if (answer == BiosecurityAnswer.na) return;
      maxPoints += 2;
      earnedPoints += answer.points;

      if (answer == BiosecurityAnswer.no) {
        riskFactors.add(BiosecurityRiskFactor(
          code: code,
          category: category,
          severity: severity,
          title: title,
          pointsLost: 2,
        ));
        recommendations.add(rec);
      } else if (answer == BiosecurityAnswer.partial) {
        riskFactors.add(BiosecurityRiskFactor(
          code: code,
          category: category,
          severity: 'medium',
          title: '$title (Partially Implemented)',
          pointsLost: 1,
        ));
        recommendations.add('Upgrade $rec to full operational standard');
      }
    }

    // Category 1: Entry & Visitor Control (10 max pts)
    int cat1Earned = 0;
    int cat1Max = 10;
    evalItem(answer: visitorLogMaintained, code: 'no_visitor_log', category: 'visitor_control', title: 'Visitor log not maintained', rec: 'Implement mandatory entry registry at farm perimeter', severity: 'medium');
    evalItem(answer: restrictedEntry, code: 'unrestricted_entry', category: 'visitor_control', title: 'Unrestricted entry to poultry houses', rec: 'Restrict poultry shed access exclusively to trained attendants');
    evalItem(answer: footwearDisinfection, code: 'no_footbath', category: 'visitor_control', title: 'Footwear disinfection footbath absent or inactive', rec: 'Install disinfectant footbaths at each shed entrance with daily renewal');
    evalItem(answer: vehicleDisinfection, code: 'no_wheel_dip', category: 'visitor_control', title: 'Vehicle wheels not disinfected at gate', rec: 'Spray vehicle tyres with virucidal disinfectant before gate clearance', severity: 'medium');
    evalItem(answer: protectiveClothing, code: 'no_farm_ppe', category: 'visitor_control', title: 'Attendants enter without dedicated farm boots/overalls', rec: 'Require dedicated farm boots and clean protective clothing');
    cat1Earned = visitorLogMaintained.points + restrictedEntry.points + footwearDisinfection.points + vehicleDisinfection.points + protectiveClothing.points;

    // Category 2: Animal & Flock Separation (8 max pts)
    int cat2Earned = 0;
    int cat2Max = 8;
    evalItem(answer: isolationAreaAvailable, code: 'no_isolation_pen', category: 'flock_isolation', title: 'Dedicated sick-bird isolation pen absent', rec: 'Establish secure isolation pen separated from primary sheds');
    evalItem(answer: sickAnimalsIsolated, code: 'sick_birds_not_isolated', category: 'flock_isolation', title: 'Clinically ill birds remain with healthy flock', rec: 'Immediately isolate any birds displaying respiratory or enteric signs', severity: 'critical');
    evalItem(answer: newAnimalsQuarantined, code: 'no_quarantine', category: 'flock_isolation', title: 'New birds introduced without 14-day quarantine', rec: 'Quarantine newly arrived flocks for 14 days before shed mixing');
    evalItem(answer: ageGroupsSeparated, code: 'multi_age_housing', category: 'flock_isolation', title: 'Different age batches co-housed in same airspace', rec: 'Enforce all-in/all-out batch management to prevent cross-age infection', severity: 'medium');
    cat2Earned = isolationAreaAvailable.points + sickAnimalsIsolated.points + newAnimalsQuarantined.points + ageGroupsSeparated.points;

    // Category 3: Cleaning & Disinfection (8 max pts)
    int cat3Earned = 0;
    int cat3Max = 8;
    evalItem(answer: routineShedCleaning, code: 'irregular_cleaning', category: 'cleaning_disinfection', title: 'Shed disinfection schedule irregular', rec: 'Perform thorough terminal shed disinfection between batch cycles');
    evalItem(answer: equipmentDisinfection, code: 'unwashed_crates', category: 'cleaning_disinfection', title: 'Transport crates and tools not sanitized', rec: 'Sanitize all transport crates, egg trays, and tools after every use');
    evalItem(answer: feederDrinkerCleaning, code: 'drinker_biofilm', category: 'cleaning_disinfection', title: 'Drinkers and feeders not flushed/cleaned weekly', rec: 'Clean and sanitize bell drinkers and nipple lines weekly');
    evalItem(answer: sharedEquipmentControl, code: 'shared_equipment', category: 'cleaning_disinfection', title: 'Equipment shared with neighboring farms without washing', rec: 'Cease sharing tools/crates with neighboring farms without certified wash');
    cat3Earned = routineShedCleaning.points + equipmentDisinfection.points + feederDrinkerCleaning.points + sharedEquipmentControl.points;

    // Category 4: Water & Feed Safety (8 max pts)
    int cat4Earned = 0;
    int cat4Max = 8;
    evalItem(answer: cleanWaterSource, code: 'open_water_source', category: 'water_feed', title: 'Poultry drinking water from untreated surface water', rec: 'Source drinking water from deep borewells or municipal supply', severity: 'critical');
    evalItem(answer: waterSanitation, code: 'no_water_chlorination', category: 'water_feed', title: 'Drinking water is not sanitized/chlorinated', rec: 'Maintain 2-3 ppm free chlorine or hydrogen peroxide water sanitation');
    evalItem(answer: feedContaminationProtection, code: 'feed_pest_access', category: 'water_feed', title: 'Feed storage accessible to wild birds and rodents', rec: 'Secure feed silos and store bagged feed on pallets away from walls');
    evalItem(answer: feedStorageHygiene, code: 'feed_moisture_mould', category: 'water_feed', title: 'Feed exposed to dampness with risk of mycotoxins', rec: 'Ensure feed store is well-ventilated and dry to avoid mycotoxin formation');
    cat4Earned = cleanWaterSource.points + waterSanitation.points + feedContaminationProtection.points + feedStorageHygiene.points;

    // Category 5: Mortality & Waste Management (6 max pts)
    int cat5Earned = 0;
    int cat5Max = 6;
    evalItem(answer: safeCarcassDisposal, code: 'open_carcass_dumping', category: 'waste_management', title: 'Mortalities dumped in open pits accessible to scavengers', rec: 'Dispose of carcasses via deep burial (>1.5m with lime) or closed incineration', severity: 'critical');
    evalItem(answer: wasteDisposal, code: 'unmanaged_waste', category: 'waste_management', title: 'Spent litter stacked near shed air inlets', rec: 'Store composted manure at downwind perimeter away from shed inlets');
    evalItem(answer: litterManureManagement, code: 'wet_caked_litter', category: 'waste_management', title: 'Litter condition wet/caked exceeding ammonia safety', rec: 'Top-dress or turn wet litter to maintain dry friable bedding below 25% moisture');
    cat5Earned = safeCarcassDisposal.points + wasteDisposal.points + litterManureManagement.points;

    // Category 6: Vaccination & Health Management (8 max pts)
    int cat6Earned = 0;
    int cat6Max = 8;
    evalItem(answer: vaccinationRecordsMaintained, code: 'missing_vax_log', category: 'vaccination_health', title: 'Vaccination log book not up to date', rec: 'Log batch numbers, dates, and cold-chain compliance for all immunizations');
    evalItem(answer: vaccinationUpToDate, code: 'overdue_vaccine_doses', category: 'vaccination_health', title: 'Scheduled NDV/IBD vaccine doses overdue', rec: 'Administer due booster doses per state poultry health calendar');
    evalItem(answer: regularHealthMonitoring, code: 'irregular_mortality_tally', category: 'vaccination_health', title: 'Daily mortality and feed intake not logged', rec: 'Log daily flock mortality and water consumption in FlockSense');
    evalItem(answer: veterinaryContactAvailable, code: 'no_vet_retained', category: 'vaccination_health', title: 'No registered poultry veterinarian retained', rec: 'Register with local District Veterinary Officer or retained poultry specialist', severity: 'medium');
    cat6Earned = vaccinationRecordsMaintained.points + vaccinationUpToDate.points + regularHealthMonitoring.points + veterinaryContactAvailable.points;

    // Calculate final overall score
    final totalScore = maxPoints > 0 ? ((earnedPoints / maxPoints) * 100).round().clamp(0, 100) : 0;

    final categoryScores = {
      'visitor_control': ((cat1Earned / cat1Max) * 100).round().clamp(0, 100),
      'flock_isolation': ((cat2Earned / cat2Max) * 100).round().clamp(0, 100),
      'cleaning_disinfection': ((cat3Earned / cat3Max) * 100).round().clamp(0, 100),
      'water_feed': ((cat4Earned / cat4Max) * 100).round().clamp(0, 100),
      'waste_management': ((cat5Earned / cat5Max) * 100).round().clamp(0, 100),
      'vaccination_health': ((cat6Earned / cat6Max) * 100).round().clamp(0, 100),
    };

    return BiosecurityAssessmentModel(
      id: id.isNotEmpty ? id : 'bio_${farmId}_${DateTime.now().millisecondsSinceEpoch}',
      farmId: farmId,
      farmName: farmName,
      score: totalScore,
      strength: BiosecurityStrength.fromScore(totalScore),
      visitorLogMaintained: visitorLogMaintained,
      restrictedEntry: restrictedEntry,
      footwearDisinfection: footwearDisinfection,
      vehicleDisinfection: vehicleDisinfection,
      protectiveClothing: protectiveClothing,
      isolationAreaAvailable: isolationAreaAvailable,
      sickAnimalsIsolated: sickAnimalsIsolated,
      newAnimalsQuarantined: newAnimalsQuarantined,
      ageGroupsSeparated: ageGroupsSeparated,
      routineShedCleaning: routineShedCleaning,
      equipmentDisinfection: equipmentDisinfection,
      feederDrinkerCleaning: feederDrinkerCleaning,
      sharedEquipmentControl: sharedEquipmentControl,
      cleanWaterSource: cleanWaterSource,
      waterSanitation: waterSanitation,
      feedContaminationProtection: feedContaminationProtection,
      feedStorageHygiene: feedStorageHygiene,
      safeCarcassDisposal: safeCarcassDisposal,
      wasteDisposal: wasteDisposal,
      litterManureManagement: litterManureManagement,
      vaccinationRecordsMaintained: vaccinationRecordsMaintained,
      vaccinationUpToDate: vaccinationUpToDate,
      regularHealthMonitoring: regularHealthMonitoring,
      veterinaryContactAvailable: veterinaryContactAvailable,
      categoryScores: categoryScores,
      riskFactors: riskFactors,
      recommendations: recommendations,
      assessedAt: DateTime.now(),
      assessedBy: assessedBy,
      assessmentVersion: biosecurityAssessmentVersion,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. GENERATE DETERMINISTIC PRIORITIZED PREVENTIVE ACTIONS
  // ─────────────────────────────────────────────────────────────────────────────

  /// Generates explainable, deduplicated protective action recommendations
  static List<PreventionRecommendationModel> generateRecommendations({
    required String farmId,
    String? batchId,
    required BiosecurityAssessmentModel assessment,
    required double farmLat,
    required double farmLon,
    required List<OutbreakClusterModel> activeClusters,
    HealthCaseModel? activeCase,
    String species = 'poultry',
  }) {
    final now = DateTime.now();
    final recs = <PreventionRecommendationModel>[];

    // Helper to add recommendation with deterministic deduplication key
    void addRec({
      required String ruleCode,
      required String source,
      required String category,
      required PreventionPriority priority,
      required String title,
      required String description,
      required String recommendedAction,
      required String reason,
      String? clusterId,
    }) {
      final id = 'rec_${farmId}_${ruleCode}_${source}';
      recs.add(PreventionRecommendationModel(
        id: id,
        farmId: farmId,
        batchId: batchId,
        caseId: activeCase?.id,
        clusterId: clusterId,
        source: source,
        category: category,
        priority: priority,
        title: title,
        description: description,
        recommendedAction: recommendedAction,
        reason: reason,
        ruleCode: ruleCode,
        status: PreventionActionStatus.recommended,
        createdAt: now,
        updatedAt: now,
      ));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // RULE SET A: NEARBY ACTIVE OUTBREAK CLUSTERS (PHASE 8/9 CORRELATION)
    // ─────────────────────────────────────────────────────────────────────────
    for (final cluster in activeClusters) {
      if (cluster.status == OutbreakClusterStatus.dismissed ||
          cluster.status == OutbreakClusterStatus.closed) {
        continue;
      }

      // Check species alignment
      if (cluster.species.toLowerCase() != species.toLowerCase()) {
        continue; // Do not apply poultry cluster alarm to cattle without cross-species rule
      }

      final dist = ClusterDetectionEngine.calculateDistanceKm(
        farmLat,
        farmLon,
        cluster.centerLatitude,
        cluster.centerLongitude,
      );

      if (dist <= 10.0) {
        final isVeryClose = dist <= 5.0;
        final priority = isVeryClose ? PreventionPriority.critical : PreventionPriority.high;

        addRec(
          ruleCode: 'nearby_cluster_advisory',
          source: 'nearby_cluster',
          category: 'biosecurity_perimeter',
          priority: priority,
          title: 'Nearby Disease Activity Detected (~${dist.toStringAsFixed(1)} km)',
          description: 'A ${cluster.syndrome} disease cluster is actively monitored within ~${dist.toStringAsFixed(1)} km of your facility.',
          recommendedAction: 'Enforce zero-visitor policy, daily footbath renewal, and immediate clinical mortality isolation.',
          reason: 'Proximity within 10 km epidemiological corridor creates heightened transmission risk via shared transit, wild birds, or equipment.',
          clusterId: cluster.id,
        );

        if (assessment.footwearDisinfection != BiosecurityAnswer.yes) {
          addRec(
            ruleCode: 'nearby_cluster_footbath_gap',
            source: 'nearby_cluster',
            category: 'disinfection',
            priority: PreventionPriority.critical,
            title: 'Critical Disinfection Barrier Required',
            description: 'Footwear disinfection at shed entry is non-compliant while an active cluster is within ~${dist.toStringAsFixed(1)} km.',
            recommendedAction: 'Install heavy-duty disinfectant footbaths with virucidal disinfectant at all shed doorways immediately.',
            reason: 'Footwear is the primary vector for carrying viral tracking between agricultural premises.',
            clusterId: cluster.id,
          );
        }
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // RULE SET B: ACTIVE HEALTH CASE ON FARM (PHASE 3/6 ISOLATION)
    // ─────────────────────────────────────────────────────────────────────────
    if (activeCase != null &&
        (activeCase.riskLevel == HealthRiskLevel.high || activeCase.riskLevel == HealthRiskLevel.critical)) {
      addRec(
        ruleCode: 'active_case_flock_isolation',
        source: 'health_case',
        category: 'flock_isolation',
        priority: PreventionPriority.critical,
        title: 'Emergency Sick Flock Isolation',
        description: 'Active ${activeCase.riskLevel.name.toUpperCase()} health case (${activeCase.caseNumber}) reported on your farm.',
        recommendedAction: 'Move affected birds to isolated pen. Restrict attendant flow from healthy sheds to sick shed last.',
        reason: 'Prevents aerosol and direct contact transmission across neighboring sheds.',
      );

      addRec(
        ruleCode: 'active_case_movement_freeze',
        source: 'health_case',
        category: 'visitor_control',
        priority: PreventionPriority.high,
        title: 'Freeze Livestock & Equipment Movement',
        description: 'Do not transport birds or share manure/egg crates during active clinical investigation.',
        recommendedAction: 'Halt bird dispatch and post Quarantine Notice at main gate until attending veterinarian approves.',
        reason: 'Biosecurity containment protects broader district flock network.',
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // RULE SET C: BIOSECURITY AUDIT WEAKNESSES
    // ─────────────────────────────────────────────────────────────────────────
    if (assessment.sickAnimalsIsolated != BiosecurityAnswer.yes) {
      addRec(
        ruleCode: 'bio_isolate_sick_birds',
        source: 'biosecurity_assessment',
        category: 'flock_isolation',
        priority: PreventionPriority.critical,
        title: 'Establish Sick Bird Isolation Protocol',
        description: 'Audit indicates symptomatic birds are not consistently segregated.',
        recommendedAction: 'Designate a separate pen with independent feeders and drinkers for symptomatic birds.',
        reason: 'Immediate removal of high viral shedders reduces pathogen load in healthy flocks.',
      );
    }

    if (assessment.safeCarcassDisposal != BiosecurityAnswer.yes) {
      addRec(
        ruleCode: 'bio_carcass_disposal',
        source: 'biosecurity_assessment',
        category: 'waste_management',
        priority: PreventionPriority.high,
        title: 'Implement Sealed Carcass Disposal',
        description: 'Open carcass dumping exposes farm to scavengers and wild predator disease transmission.',
        recommendedAction: 'Construct a closed deep burial pit (>1.5m) lined with quicklime or use closed incineration.',
        reason: 'Decomposing carcasses attract flies and wild scavengers that carry pathogens to neighboring sheds.',
      );
    }

    if (assessment.cleanWaterSource != BiosecurityAnswer.yes || assessment.waterSanitation != BiosecurityAnswer.yes) {
      addRec(
        ruleCode: 'bio_water_sanitation',
        source: 'biosecurity_assessment',
        category: 'water_feed',
        priority: PreventionPriority.high,
        title: 'Sanitize Flock Drinking Water',
        description: 'Drinking water is untreated or exposed to surface runoff contamination.',
        recommendedAction: 'Add water sanitation tablets (Chlorine / Hydrogen peroxide) to achieve 2-3 ppm residual.',
        reason: 'Waterborne viral and bacterial pathogens multiply rapidly in biofilm of poultry drinking systems.',
      );
    }

    if (assessment.vaccinationUpToDate != BiosecurityAnswer.yes) {
      addRec(
        ruleCode: 'bio_vaccination_review',
        source: 'vaccination_gap',
        category: 'vaccination',
        priority: PreventionPriority.high,
        title: 'Review Scheduled Flock Immunizations',
        description: 'Vaccination audit flags overdue doses or missing booster records.',
        recommendedAction: 'Consult your attending veterinarian to review vaccination schedule before administering boosters.',
        reason: 'Maintaining flock herd immunity prevents virulent field strain outbreaks.',
      );
    }

    // Sort: Critical first, then High, then Medium, then Low
    recs.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    // Return top prioritized recommendations (maximum 6)
    return recs.take(6).toList();
  }
}
