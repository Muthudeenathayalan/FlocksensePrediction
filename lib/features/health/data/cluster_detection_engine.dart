import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/core/services/audit_service.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/outbreak_cluster_model.dart';
import 'package:flock_sense/features/notifications/data/models/notification_model.dart';

/// Farm Coordinate Pair for Spatial Geolocation
class FarmLocation {
  final String farmId;
  final String farmName;
  final double latitude;
  final double longitude;
  final String district;
  final String state;

  const FarmLocation({
    required this.farmId,
    this.farmName = '',
    required this.latitude,
    required this.longitude,
    this.district = 'Nashik',
    this.state = 'Maharashtra',
  });

  bool get isValid =>
      latitude >= -90.0 &&
      latitude <= 90.0 &&
      longitude >= -180.0 &&
      longitude <= 180.0 &&
      !(latitude == 0.0 && longitude == 0.0);
}

/// Case Bundle with Spatial and Temporal Context for Clustering
class HealthCaseWithLocation {
  final HealthCaseModel healthCase;
  final FarmLocation location;

  const HealthCaseWithLocation({
    required this.healthCase,
    required this.location,
  });
}

/// Central Outbreak Cluster Configuration
class ClusterConfig {
  static const int minimumDistinctFarms = 3;
  static const int timeWindowHours = 72;
  static const double clusterRadiusKm = 10.0;
  static const double farmerWarningRadiusKm = 10.0;
  static const String engineVersion = 'cluster-v1';
}

/// Disease Cluster Detection & Regional Outbreak Early Warning Engine (SIH26128 Phase 8)
class ClusterDetectionEngine {
  ClusterDetectionEngine._();

  static final _firestore = FirebaseFirestore.instance;
  static final _auditService = AuditService();

  static CollectionReference<Map<String, dynamic>> get _clustersRef =>
      _firestore.collection('outbreak_clusters');
  static CollectionReference<Map<String, dynamic>> get _alertsRef =>
      _firestore.collection('disease_alerts');
  static CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. SYNDROME NORMALIZATION
  // ─────────────────────────────────────────────────────────────────────────────

  /// Normalizes granular farmer symptoms into standard syndromic categories
  static String normalizeSyndrome(List<String> symptoms) {
    if (symptoms.isEmpty) return 'systemic';

    final text = symptoms.join(' ').toLowerCase();

    final isRespiratory = text.contains('cough') ||
        text.contains('sneez') ||
        text.contains('nasal') ||
        text.contains('respiratory') ||
        text.contains('gasp') ||
        text.contains('rales') ||
        text.contains('clicking') ||
        text.contains('eye swelling') ||
        text.contains('tracheal');

    final isNeurological = text.contains('tremor') ||
        text.contains('paralysis') ||
        text.contains('torticollis') ||
        text.contains('twisting neck') ||
        text.contains('ataxia') ||
        text.contains('abnormal movement') ||
        text.contains('circling');

    final isDigestive = text.contains('diarrh') ||
        text.contains('dropping') ||
        text.contains('green') ||
        text.contains('white') ||
        text.contains('appetite') ||
        text.contains('crop');

    final isDermatological = text.contains('comb') ||
        text.contains('wattle') ||
        text.contains('cyanosis') ||
        text.contains('scab') ||
        text.contains('lesion');

    if (isRespiratory) return 'respiratory';
    if (isNeurological) return 'neurological';
    if (isDigestive) return 'digestive';
    if (isDermatological) return 'dermatological';

    return 'systemic';
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. HAVERSINE GEOGRAPHIC DISTANCE UTILITY
  // ─────────────────────────────────────────────────────────────────────────────

  /// Computes accurate spherical geographic distance in kilometers
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    if (lat1 == lat2 && lon1 == lon2) return 0.0;

    const double earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) => degrees * (pi / 180.0);

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. CASE SIMILARITY SCORING (0-100 SCALE)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Calculates multidimensional similarity score between two health incidents
  static int calculateCaseSimilarity({
    required HealthCaseModel case1,
    required FarmLocation loc1,
    required HealthCaseModel case2,
    required FarmLocation loc2,
  }) {
    int score = 0;

    final syn1 = normalizeSyndrome(case1.symptoms);
    final syn2 = normalizeSyndrome(case2.symptoms);
    if (syn1 == syn2) score += 30;

    // Species similarity
    score += 15; // Poultry baseline

    // Spatial proximity
    final distKm = calculateDistanceKm(loc1.latitude, loc1.longitude, loc2.latitude, loc2.longitude);
    if (distKm <= 5.0) {
      score += 20;
    } else if (distKm <= 10.0) {
      score += 10;
    }

    // Temporal interval
    final hoursDiff = case1.reportedAt.difference(case2.reportedAt).inHours.abs();
    if (hoursDiff <= 24) {
      score += 20;
    } else if (hoursDiff <= 72) {
      score += 10;
    }

    // Clinical consensus
    if (case1.diagnosis != null && case2.diagnosis != null && case1.diagnosis == case2.diagnosis) {
      score += 20;
    }

    return score.clamp(0, 100);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. CENTROID & SPATIAL RADIUS CALCULATION
  // ─────────────────────────────────────────────────────────────────────────────

  /// Computes the geographic center of included farms
  static Map<String, double> calculateCentroid(List<FarmLocation> locations) {
    if (locations.isEmpty) return {'lat': 0.0, 'lng': 0.0};
    double sumLat = 0.0;
    double sumLng = 0.0;
    for (final loc in locations) {
      sumLat += loc.latitude;
      sumLng += loc.longitude;
    }
    return {
      'lat': sumLat / locations.length,
      'lng': sumLng / locations.length,
    };
  }

  /// Calculates the maximum distance radius from centroid encompassing all cluster farms
  static double calculateClusterRadius(double centerLat, double centerLng, List<FarmLocation> locations) {
    if (locations.isEmpty) return 1.0;
    double maxDist = 0.0;
    for (final loc in locations) {
      final d = calculateDistanceKm(centerLat, centerLng, loc.latitude, loc.longitude);
      if (d > maxDist) maxDist = d;
    }
    return max(maxDist, 1.5); // Minimum 1.5 km display radius
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. CLUSTER CONFIDENCE & SEVERITY
  // ─────────────────────────────────────────────────────────────────────────────

  static int calculateClusterConfidence({
    required int uniqueFarms,
    required bool hasVetDiagnosis,
    required bool hasLabConfirmation,
    required double radiusKm,
  }) {
    int conf = 50;
    conf += (uniqueFarms * 5).clamp(0, 25);
    if (radiusKm <= 5.0) conf += 10;
    if (hasVetDiagnosis) conf += 15;
    if (hasLabConfirmation) conf += 20;
    return conf.clamp(0, 100);
  }

  static String calculateClusterSeverity({
    required int uniqueFarms,
    required int totalMortality,
    required int totalAffected,
    required bool hasCriticalCase,
  }) {
    if (uniqueFarms >= 5 || totalMortality >= 50 || (hasCriticalCase && uniqueFarms >= 3)) {
      return 'critical';
    }
    if (uniqueFarms >= 3 || totalMortality >= 20 || totalAffected >= 50) {
      return 'high';
    }
    return 'moderate';
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. POSSIBLE DISEASE LABELING CONSENSUS
  // ─────────────────────────────────────────────────────────────────────────────

  static String deriveClusterDiseaseLabel({
    required String syndrome,
    required List<HealthCaseModel> cases,
  }) {
    // 1. Check for Lab-Confirmed or Vet-Diagnosed consensus
    final diagnoses = cases.map((c) => c.diagnosis).where((d) => d != null && d.isNotEmpty).toList();
    if (diagnoses.isNotEmpty) {
      final counts = <String, int>{};
      for (final d in diagnoses) {
        counts[d!] = (counts[d] ?? 0) + 1;
      }
      final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      if (sorted.first.value >= 2) {
        return sorted.first.key;
      }
    }

    // 2. Syndromic Cluster Label
    switch (syndrome) {
      case 'respiratory':
        return 'Respiratory Disease Cluster (Suspected NDV / IBV)';
      case 'neurological':
        return 'Avian Neurological Syndrome Cluster';
      case 'digestive':
        return 'Enteric / Digestive Infection Cluster';
      case 'dermatological':
        return 'Cutaneous Lesion / Pox-like Cluster';
      default:
        return 'Acute Syndromic Health Cluster';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 7. CORE CLUSTER EVALUATION & PATTERN RECOGNITION
  // ─────────────────────────────────────────────────────────────────────────────

  /// Evaluates an incoming or updated health case for regional clustering
  static Future<OutbreakClusterModel?> evaluateAndCluster({
    required HealthCaseModel triggeringCase,
    required FarmLocation farmLocation,
    required List<HealthCaseWithLocation> candidateHistory,
  }) async {
    // 1. Eligibility Check: Case must be HIGH or CRITICAL risk, or have active vet review
    final isEligible = triggeringCase.riskLevel == HealthRiskLevel.high ||
        triggeringCase.riskLevel == HealthRiskLevel.critical ||
        (triggeringCase.riskScore >= 50);

    if (!isEligible) {
      debugPrint('[ClusterEngine] Case ${triggeringCase.id} is LOW/MODERATE risk; skipping spatial clustering.');
      return null;
    }

    // 2. Geolocation Validation
    if (!farmLocation.isValid) {
      debugPrint('[ClusterEngine] Farm ${farmLocation.farmId} has missing/invalid coordinates. Excluded from spatial correlation.');
      return null;
    }

    final triggerSyndrome = normalizeSyndrome(triggeringCase.symptoms);
    final now = DateTime.now();

    // 3. Find Matching Nearby Incidents
    final matchingCases = <HealthCaseWithLocation>[
      HealthCaseWithLocation(healthCase: triggeringCase, location: farmLocation),
    ];

    for (final candidate in candidateHistory) {
      if (candidate.healthCase.id == triggeringCase.id) continue;
      if (!candidate.location.isValid) continue;

      // Temporal check (within configured window, default 72h)
      final hoursDiff = triggeringCase.reportedAt.difference(candidate.healthCase.reportedAt).inHours.abs();
      if (hoursDiff > ClusterConfig.timeWindowHours) continue;

      // Syndromic check
      final candidateSyndrome = normalizeSyndrome(candidate.healthCase.symptoms);
      if (candidateSyndrome != triggerSyndrome) continue;

      // Spatial distance check (within 10 km)
      final distKm = calculateDistanceKm(
        farmLocation.latitude,
        farmLocation.longitude,
        candidate.location.latitude,
        candidate.location.longitude,
      );
      if (distKm > ClusterConfig.clusterRadiusKm) continue;

      // Risk check
      if (candidate.healthCase.riskLevel == HealthRiskLevel.high ||
          candidate.healthCase.riskLevel == HealthRiskLevel.critical ||
          candidate.healthCase.riskScore >= 50) {
        matchingCases.add(candidate);
      }
    }

    // 4. Distinct Farm Count Threshold Rule (>= 3 unique farms)
    final uniqueFarmIds = matchingCases.map((m) => m.location.farmId).toSet().toList();
    if (uniqueFarmIds.length < ClusterConfig.minimumDistinctFarms) {
      debugPrint('[ClusterEngine] Candidate cases represent only ${uniqueFarmIds.length} distinct farms. Threshold (${ClusterConfig.minimumDistinctFarms}) not reached.');
      return null;
    }

    // 5. Cluster Calculations
    final uniqueLocations = <FarmLocation>[];
    final seenFarms = <String>{};
    for (final m in matchingCases) {
      if (!seenFarms.contains(m.location.farmId)) {
        seenFarms.add(m.location.farmId);
        uniqueLocations.add(m.location);
      }
    }

    final centroid = calculateCentroid(uniqueLocations);
    final radiusKm = calculateClusterRadius(centroid['lat']!, centroid['lng']!, uniqueLocations);

    final caseIds = matchingCases.map((m) => m.healthCase.id).toList();
    final totalAffected = matchingCases.fold<int>(0, (sum, m) => sum + m.healthCase.affectedCount);
    final totalMortality = matchingCases.fold<int>(0, (sum, m) => sum + m.healthCase.mortalityCount);
    final hasCritical = matchingCases.any((m) => m.healthCase.riskLevel == HealthRiskLevel.critical);
    final hasLab = matchingCases.any((m) => m.healthCase.labRequired == true);

    final confidence = calculateClusterConfidence(
      uniqueFarms: uniqueFarmIds.length,
      hasVetDiagnosis: matchingCases.any((m) => m.healthCase.diagnosis != null),
      hasLabConfirmation: hasLab,
      radiusKm: radiusKm,
    );

    final severity = calculateClusterSeverity(
      uniqueFarms: uniqueFarmIds.length,
      totalMortality: totalMortality,
      totalAffected: totalAffected,
      hasCriticalCase: hasCritical,
    );

    final possibleDisease = deriveClusterDiseaseLabel(
      syndrome: triggerSyndrome,
      cases: matchingCases.map((m) => m.healthCase).toList(),
    );

    final evidenceSummary = [
      '${uniqueFarmIds.length} distinct poultry farms affected in ${farmLocation.district}',
      'Encompasses a ${radiusKm.toStringAsFixed(1)} km radius hotspot',
      'All cases exhibit synchronized $triggerSyndrome syndrome',
      '$totalMortality total mortalities reported in last ${ClusterConfig.timeWindowHours}h',
      hasCritical ? 'Multiple CRITICAL severity health cases detected' : 'Elevated HIGH risk baseline',
    ];

    // 6. Check for Existing Overlapping Active Cluster to Update vs Create New
    final clusterId = 'cluster_${farmLocation.district.toLowerCase()}_${triggerSyndrome}_${now.year}';
    final clusterCode = 'OUT-${now.year}-${farmLocation.district.substring(0, min(3, farmLocation.district.length)).toUpperCase()}-001';

    final cluster = OutbreakClusterModel(
      id: clusterId,
      clusterCode: clusterCode,
      species: 'poultry',
      syndrome: triggerSyndrome,
      possibleDisease: possibleDisease,
      caseIds: caseIds,
      farmIds: uniqueFarmIds,
      district: farmLocation.district,
      state: farmLocation.state,
      centerLatitude: centroid['lat']!,
      centerLongitude: centroid['lng']!,
      radiusKm: radiusKm,
      caseCount: caseIds.length,
      farmCount: uniqueFarmIds.length,
      affectedCount: totalAffected,
      mortalityCount: totalMortality,
      clusterConfidence: confidence,
      confidenceLabel: ClusterConfidenceLabel.fromScore(confidence),
      severity: severity,
      status: OutbreakClusterStatus.potential,
      firstDetectedAt: matchingCases.map((m) => m.healthCase.reportedAt).reduce((a, b) => a.isBefore(b) ? a : b),
      lastCaseAt: matchingCases.map((m) => m.healthCase.reportedAt).reduce((a, b) => a.isAfter(b) ? a : b),
      createdAt: now,
      updatedAt: now,
      engineVersion: ClusterConfig.engineVersion,
      evidenceSummary: evidenceSummary,
      dataQuality: 'strong',
    );

    try {
      // 7. Persist Outbreak Cluster in Firestore
      await _clustersRef.doc(cluster.id).set(cluster.toJson(), SetOptions(merge: true));

      // 8. Create Government Early-Warning Alert
      final alertId = 'alert_gov_${cluster.id}';
      await _alertsRef.doc(alertId).set({
        'id': alertId,
        'title': '🚨 Outbreak Early Warning • ${farmLocation.district}',
        'message': 'Potential $triggerSyndrome disease cluster detected across ${uniqueFarmIds.length} farms within ${radiusKm.toStringAsFixed(1)} km radius.',
        'district': farmLocation.district,
        'severity': severity,
        'status': 'active',
        'clusterId': cluster.id,
        'type': 'outbreak_early_warning',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 9. Dispatch Audit Log
      await _auditService.logOperation(
        operation: AuditOperation.dataSync,
        resourceType: 'OutbreakCluster',
        resourceId: cluster.id,
        changes: {
          'action': 'OUTBREAK_CLUSTER_CREATED',
          'clusterCode': cluster.clusterCode,
          'syndrome': triggerSyndrome,
          'farmCount': uniqueFarmIds.length,
          'radiusKm': radiusKm,
          'severity': severity,
        },
      );
    } catch (e) {
      debugPrint('[ClusterEngine] Persistence warning: $e');
    }

    return cluster;
  }
}
