import 'package:flock_sense/features/health/data/cluster_detection_engine.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/intelligence/domain/nearby_exposure_model.dart';

/// Nearby Farm Exposure Engine (Part 6)
/// Computes spatio-temporal correlation with nearby farms while ensuring strict privacy anonymization for farmers
class NearbyExposureEngine {
  NearbyExposureEngine._();

  static const double maxRadiusKm = 10.0;
  static const int maxTimeWindowHours = 72;

  /// Calculates nearby exposure metrics for a specific target farm
  static NearbyExposureModel evaluateNearbyExposure({
    required String targetFarmId,
    required double targetLat,
    required double targetLon,
    required String targetSyndrome,
    required List<HealthCaseWithLocation> allRecentCasesWithLocation,
  }) {
    if (targetLat == 0.0 && targetLon == 0.0) {
      return const NearbyExposureModel(
        farmerAnonymizedSummary: 'Farm coordinates not calibrated for geospatial surveillance.',
        clinicalSummary: 'Missing geographic coordinates.',
      );
    }

    final now = DateTime.now();
    final signals = <NearbySignalDetail>[];
    int highRiskCount = 0;
    int criticalCount = 0;
    int similarSyndromeCount = 0;
    int vetSupportedCount = 0;
    int labSupportedCount = 0;
    double nearestDist = 999.0;

    final normalizedTargetSyndrome = targetSyndrome.toLowerCase().trim();

    for (final item in allRecentCasesWithLocation) {
      // Exclude own farm
      if (item.location.farmId == targetFarmId) continue;
      if (!item.location.isValid) continue;

      // Temporal check (<= 72h)
      final hoursDiff = now.difference(item.healthCase.reportedAt).inHours.abs();
      if (hoursDiff > maxTimeWindowHours) continue;

      // Distance check (<= 10 km)
      final dist = ClusterDetectionEngine.calculateDistanceKm(
        targetLat,
        targetLon,
        item.location.latitude,
        item.location.longitude,
      );

      if (dist > maxRadiusKm) continue;

      if (dist < nearestDist) nearestDist = dist;

      final caseSyndrome = ClusterDetectionEngine.normalizeSyndrome(item.healthCase.symptoms);
      final isSimilarSyndrome = caseSyndrome == normalizedTargetSyndrome ||
          (normalizedTargetSyndrome.contains('respiratory') && caseSyndrome.contains('respiratory')) ||
          (normalizedTargetSyndrome.contains('digestive') && caseSyndrome.contains('digestive'));

      if (isSimilarSyndrome) {
        similarSyndromeCount++;
      }

      if (item.healthCase.riskLevel == HealthRiskLevel.critical) {
        criticalCount++;
      } else if (item.healthCase.riskLevel == HealthRiskLevel.high) {
        highRiskCount++;
      }

      if (item.healthCase.diagnosis != null && item.healthCase.diagnosis!.isNotEmpty) {
        vetSupportedCount++;
      }
      if (item.healthCase.labRequired == true) {
        labSupportedCount++;
      }

      signals.add(NearbySignalDetail(
        farmId: item.location.farmId,
        farmName: item.location.farmName.isNotEmpty ? item.location.farmName : 'Premises (${dist.toStringAsFixed(1)}km)',
        distanceKm: double.parse(dist.toStringAsFixed(1)),
        syndrome: caseSyndrome,
        riskLevel: item.healthCase.riskLevel.name,
        reportedAt: item.healthCase.reportedAt,
        hasVetDiagnosis: item.healthCase.diagnosis != null,
        hasLabConfirmation: item.healthCase.labRequired == true,
      ));
    }

    // Exposure Score Calculation (0 - 100)
    int score = 0;
    if (signals.isNotEmpty) {
      score += (similarSyndromeCount * 20).clamp(0, 40);
      score += (criticalCount * 20).clamp(0, 30);
      score += (highRiskCount * 10).clamp(0, 20);

      if (nearestDist <= 3.0) {
        score += 20;
      } else if (nearestDist <= 7.0) {
        score += 10;
      }

      if (vetSupportedCount > 0 || labSupportedCount > 0) {
        score += 10;
      }
    }

    final finalScore = score.clamp(0, 100);

    // Level classification
    NearbyExposureLevel level = NearbyExposureLevel.low;
    if (finalScore >= 70) {
      level = NearbyExposureLevel.critical;
    } else if (finalScore >= 45) {
      level = NearbyExposureLevel.high;
    } else if (finalScore >= 20) {
      level = NearbyExposureLevel.moderate;
    }

    // Farmer Anonymized Text (Privacy Preserving)
    String farmerSummary;
    if (signals.isEmpty) {
      farmerSummary = 'No elevated animal-health signals reported within approximately 10 km during the past 72 hours.';
    } else if (similarSyndromeCount > 0) {
      final approxDist = nearestDist < 999.0 ? nearestDist.toStringAsFixed(1) : '10';
      farmerSummary = '$similarSyndromeCount related $normalizedTargetSyndrome health signals reported within approximately $approxDist km during the past 72 hours.';
    } else {
      farmerSummary = '${signals.length} general health incidents monitored within approximately ${nearestDist.toStringAsFixed(1)} km.';
    }

    // Clinical Summary for Veterinarians & Government
    final clinicalSummary = signals.isNotEmpty
        ? '${signals.length} active epidemiological signals within $maxRadiusKm km corridor ($similarSyndromeCount matching $normalizedTargetSyndrome, $criticalCount critical, $vetSupportedCount clinically verified).'
        : 'Zero active disease alerts in current $maxRadiusKm km buffer.';

    return NearbyExposureModel(
      nearbyHighRiskFarmCount: highRiskCount,
      nearbyCriticalFarmCount: criticalCount,
      nearestCaseDistanceKm: nearestDist < 999.0 ? double.parse(nearestDist.toStringAsFixed(1)) : 999.0,
      similarSyndromeCaseCount: similarSyndromeCount,
      timeWindowHours: maxTimeWindowHours,
      vetSupportedCaseCount: vetSupportedCount,
      labSupportedCaseCount: labSupportedCount,
      nearbyExposureScore: finalScore,
      nearbyExposureLevel: level,
      farmerAnonymizedSummary: farmerSummary,
      clinicalSummary: clinicalSummary,
      nearbySignals: signals,
    );
  }
}
