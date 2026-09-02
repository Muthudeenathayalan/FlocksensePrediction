import 'package:flock_sense/features/intelligence/domain/environmental_intelligence_model.dart';

/// Environmental Stress & Thermal Intelligence Engine (Part 4)
/// Calculates THI, age-specific target bounds, and thermal screening stress
class EnvironmentalIntelligenceEngine {
  EnvironmentalIntelligenceEngine._();

  /// Calculates the Temperature-Humidity Index (THI) for poultry
  /// Standard THI formulation: THI = 0.8 * T + (RH / 100) * (T - 14.4) + 46.4
  static double calculateTHI(double tempC, double humidityPercent) {
    final rhFraction = humidityPercent / 100.0;
    final thi = 0.8 * tempC + rhFraction * (tempC - 14.4) + 46.4;
    return double.parse(thi.toStringAsFixed(1));
  }

  /// Evaluates environmental & thermal telemetry against flock age profile
  static EnvironmentalStressResult evaluate({
    required double ambientTemperature,
    required double humidity,
    int flockAgeDays = 28,
    double? surfaceTemperature,
    int thermalHotspotCount = 0,
    ThermalReadingSource readingSource = ThermalReadingSource.sensor,
    EnvironmentalTargetProfile? customTarget,
  }) {
    final target = customTarget ?? EnvironmentalTargetProfile.getProfileForFlockAge(flockAgeDays);
    final thi = calculateTHI(ambientTemperature, humidity);

    // Temperature deviation from optimal center
    final optimalTempCenter = (target.targetTempMin + target.targetTempMax) / 2.0;
    final tempDev = ambientTemperature - optimalTempCenter;

    // Humidity deviation from optimal center
    final optimalHumCenter = (target.targetHumidityMin + target.targetHumidityMax) / 2.0;
    final humDev = humidity - optimalHumCenter;

    var stressScore = 15; // Baseline normal
    final explanationParts = <String>[];

    // 1. Temperature Evaluation
    if (ambientTemperature >= target.criticalTempMax || ambientTemperature <= target.criticalTempMin) {
      stressScore += 40;
      explanationParts.add('Ambient temperature (${ambientTemperature.toStringAsFixed(1)}°C) is at a CRITICAL extreme (target: ${target.targetTempMin}-${target.targetTempMax}°C).');
    } else if (ambientTemperature >= target.warningTempMax || ambientTemperature <= target.warningTempMin) {
      stressScore += 25;
      explanationParts.add('Ambient temperature (${ambientTemperature.toStringAsFixed(1)}°C) exceeds warning threshold.');
    } else if (ambientTemperature > target.targetTempMax || ambientTemperature < target.targetTempMin) {
      stressScore += 10;
      explanationParts.add('Ambient temperature is slightly outside ideal comfort band.');
    }

    // 2. Humidity Evaluation
    if (humidity >= 85.0 || humidity <= 35.0) {
      stressScore += 20;
      explanationParts.add('Shed humidity (${humidity.toStringAsFixed(0)}%) creates severe microclimate distress.');
    } else if (humidity > target.targetHumidityMax || humidity < target.targetHumidityMin) {
      stressScore += 10;
      explanationParts.add('Humidity is outside optimal band (${target.targetHumidityMin}-${target.targetHumidityMax}%).');
    }

    // 3. THI Heat Stress Index
    if (thi >= 84.0) {
      stressScore += 25;
      explanationParts.add('Severe heat stress index (THI ${thi.toStringAsFixed(1)}) detected.');
    } else if (thi >= 78.0) {
      stressScore += 15;
      explanationParts.add('Elevated THI (${thi.toStringAsFixed(1)}) indicating potential panting and reduced feed intake.');
    }

    // 4. Thermal Surface Screening (Screening Signal Only)
    if (surfaceTemperature != null && surfaceTemperature >= 42.5) {
      stressScore += 15;
      explanationParts.add('Elevated surface thermal reading (${surfaceTemperature.toStringAsFixed(1)}°C) observed via ${readingSource.label}.');
    }

    if (thermalHotspotCount >= 3) {
      stressScore += 10;
      explanationParts.add('$thermalHotspotCount localized thermal hotspots detected in shed.');
    }

    final finalScore = stressScore.clamp(0, 100);

    // Stress Level Classification
    EnvironmentalStressLevel level = EnvironmentalStressLevel.normal;
    if (finalScore >= 75) {
      level = EnvironmentalStressLevel.critical;
    } else if (finalScore >= 50) {
      level = EnvironmentalStressLevel.high;
    } else if (finalScore >= 30) {
      level = EnvironmentalStressLevel.alert;
    }

    final explanation = explanationParts.isNotEmpty
        ? explanationParts.join(' ')
        : 'Telemetry parameters remain within the optimal comfort profile for age day $flockAgeDays.';

    return EnvironmentalStressResult(
      environmentalStressScore: finalScore,
      environmentalStressLevel: level,
      ambientTemperature: ambientTemperature,
      humidity: humidity,
      surfaceTemperature: surfaceTemperature,
      thermalHotspotCount: thermalHotspotCount,
      thi: thi,
      temperatureDeviation: double.parse(tempDev.toStringAsFixed(1)),
      humidityDeviation: double.parse(humDev.toStringAsFixed(1)),
      targetProfile: target,
      explanation: explanation,
      advisory: 'Environmental conditions may contribute to physiological stress and should be considered during veterinary assessment.',
    );
  }
}
