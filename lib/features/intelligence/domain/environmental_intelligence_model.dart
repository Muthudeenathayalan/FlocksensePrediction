/// Environmental Stress Level
enum EnvironmentalStressLevel {
  normal,
  alert,
  high,
  critical;

  String get label {
    switch (this) {
      case EnvironmentalStressLevel.normal:
        return 'NORMAL';
      case EnvironmentalStressLevel.alert:
        return 'ALERT';
      case EnvironmentalStressLevel.high:
        return 'HIGH';
      case EnvironmentalStressLevel.critical:
        return 'CRITICAL';
    }
  }
}

/// Source of thermal / surface reading
enum ThermalReadingSource {
  manual,
  sensor,
  infrared_sensor,
  thermal_camera;

  String get label {
    switch (this) {
      case ThermalReadingSource.manual:
        return 'Manual Thermometer';
      case ThermalReadingSource.sensor:
        return 'IoT Probe Sensor';
      case ThermalReadingSource.infrared_sensor:
        return 'Infrared Pyrometer';
      case ThermalReadingSource.thermal_camera:
        return 'Thermal Imaging Radiometer';
    }
  }
}

/// Thermal Surface Reading Model (Part 4)
/// Note: Surface temperature is a SCREENING signal, not a confirmed clinical fever.
class ThermalSurfaceReading {
  final double? surfaceTemperature;
  final int thermalHotspotCount;
  final ThermalReadingSource readingSource;
  final DateTime recordedAt;
  final String note;

  const ThermalSurfaceReading({
    this.surfaceTemperature,
    this.thermalHotspotCount = 0,
    this.readingSource = ThermalReadingSource.sensor,
    required this.recordedAt,
    this.note = 'Animal surface temperature is a screening signal; clinical fever requires veterinary confirmation.',
  });

  Map<String, dynamic> toJson() => {
        'surfaceTemperature': surfaceTemperature,
        'thermalHotspotCount': thermalHotspotCount,
        'readingSource': readingSource.name,
        'recordedAt': recordedAt.toIso8601String(),
        'note': note,
      };

  factory ThermalSurfaceReading.fromJson(Map<String, dynamic> json) {
    return ThermalSurfaceReading(
      surfaceTemperature: (json['surfaceTemperature'] as num?)?.toDouble(),
      thermalHotspotCount: (json['thermalHotspotCount'] as num?)?.toInt() ?? 0,
      readingSource: ThermalReadingSource.values.firstWhere(
        (e) => e.name == json['readingSource'],
        orElse: () => ThermalReadingSource.sensor,
      ),
      recordedAt: json['recordedAt'] != null
          ? DateTime.parse(json['recordedAt'] as String)
          : DateTime.now(),
      note: json['note'] as String? ??
          'Animal surface temperature is a screening signal; clinical fever requires veterinary confirmation.',
    );
  }
}

/// Environmental Target Profile depending on Flock Age & Stage
class EnvironmentalTargetProfile {
  final String id;
  final String species;
  final String breed;
  final String productionType; // 'Broiler', 'Layer', 'Breeder'
  final int ageMinDays;
  final int ageMaxDays;

  final double targetTempMin;
  final double targetTempMax;

  final double targetHumidityMin;
  final double targetHumidityMax;

  final double warningTempMin;
  final double warningTempMax;

  final double criticalTempMin;
  final double criticalTempMax;

  const EnvironmentalTargetProfile({
    this.id = 'target_default_broiler',
    this.species = 'poultry',
    this.breed = 'Cobb 500',
    this.productionType = 'Broiler',
    this.ageMinDays = 1,
    this.ageMaxDays = 42,
    this.targetTempMin = 20.0,
    this.targetTempMax = 26.0,
    this.targetHumidityMin = 50.0,
    this.targetHumidityMax = 70.0,
    this.warningTempMin = 18.0,
    this.warningTempMax = 30.0,
    this.criticalTempMin = 14.0,
    this.criticalTempMax = 34.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'species': species,
        'breed': breed,
        'productionType': productionType,
        'ageMinDays': ageMinDays,
        'ageMaxDays': ageMaxDays,
        'targetTempMin': targetTempMin,
        'targetTempMax': targetTempMax,
        'targetHumidityMin': targetHumidityMin,
        'targetHumidityMax': targetHumidityMax,
        'warningTempMin': warningTempMin,
        'warningTempMax': warningTempMax,
        'criticalTempMin': criticalTempMin,
        'criticalTempMax': criticalTempMax,
      };

  factory EnvironmentalTargetProfile.fromJson(Map<String, dynamic> json) {
    return EnvironmentalTargetProfile(
      id: json['id'] as String? ?? 'target_default_broiler',
      species: json['species'] as String? ?? 'poultry',
      breed: json['breed'] as String? ?? 'Cobb 500',
      productionType: json['productionType'] as String? ?? 'Broiler',
      ageMinDays: (json['ageMinDays'] as num?)?.toInt() ?? 1,
      ageMaxDays: (json['ageMaxDays'] as num?)?.toInt() ?? 42,
      targetTempMin: (json['targetTempMin'] as num?)?.toDouble() ?? 20.0,
      targetTempMax: (json['targetTempMax'] as num?)?.toDouble() ?? 26.0,
      targetHumidityMin: (json['targetHumidityMin'] as num?)?.toDouble() ?? 50.0,
      targetHumidityMax: (json['targetHumidityMax'] as num?)?.toDouble() ?? 70.0,
      warningTempMin: (json['warningTempMin'] as num?)?.toDouble() ?? 18.0,
      warningTempMax: (json['warningTempMax'] as num?)?.toDouble() ?? 30.0,
      criticalTempMin: (json['criticalTempMin'] as num?)?.toDouble() ?? 14.0,
      criticalTempMax: (json['criticalTempMax'] as num?)?.toDouble() ?? 34.0,
    );
  }

  static EnvironmentalTargetProfile getProfileForFlockAge(int ageInDays) {
    if (ageInDays <= 7) {
      // Brooding week 1
      return const EnvironmentalTargetProfile(
        id: 'brooding_w1',
        ageMinDays: 1,
        ageMaxDays: 7,
        targetTempMin: 30.0,
        targetTempMax: 33.0,
        targetHumidityMin: 60.0,
        targetHumidityMax: 70.0,
        warningTempMin: 28.0,
        warningTempMax: 35.0,
        criticalTempMin: 24.0,
        criticalTempMax: 38.0,
      );
    } else if (ageInDays <= 14) {
      // Brooding week 2
      return const EnvironmentalTargetProfile(
        id: 'brooding_w2',
        ageMinDays: 8,
        ageMaxDays: 14,
        targetTempMin: 27.0,
        targetTempMax: 30.0,
        targetHumidityMin: 55.0,
        targetHumidityMax: 70.0,
        warningTempMin: 25.0,
        warningTempMax: 32.0,
        criticalTempMin: 20.0,
        criticalTempMax: 35.0,
      );
    } else if (ageInDays <= 21) {
      // Grower week 3
      return const EnvironmentalTargetProfile(
        id: 'grower_w3',
        ageMinDays: 15,
        ageMaxDays: 21,
        targetTempMin: 24.0,
        targetTempMax: 27.0,
        targetHumidityMin: 50.0,
        targetHumidityMax: 70.0,
        warningTempMin: 21.0,
        warningTempMax: 29.0,
        criticalTempMin: 17.0,
        criticalTempMax: 33.0,
      );
    } else {
      // Finisher / Adult
      return const EnvironmentalTargetProfile(
        id: 'finisher_adult',
        ageMinDays: 22,
        ageMaxDays: 70,
        targetTempMin: 20.0,
        targetTempMax: 25.0,
        targetHumidityMin: 50.0,
        targetHumidityMax: 70.0,
        warningTempMin: 18.0,
        warningTempMax: 29.0,
        criticalTempMin: 14.0,
        criticalTempMax: 34.0,
      );
    }
  }
}

/// Comprehensive result of environmental & thermal stress evaluation
class EnvironmentalStressResult {
  final int environmentalStressScore; // 0 - 100
  final EnvironmentalStressLevel environmentalStressLevel;
  final double ambientTemperature;
  final double humidity;
  final double? surfaceTemperature;
  final int thermalHotspotCount;
  final double thi; // Temperature-Humidity Index
  final double temperatureDeviation;
  final double humidityDeviation;
  final EnvironmentalTargetProfile targetProfile;
  final String explanation;
  final String advisory;

  const EnvironmentalStressResult({
    required this.environmentalStressScore,
    required this.environmentalStressLevel,
    required this.ambientTemperature,
    required this.humidity,
    this.surfaceTemperature,
    this.thermalHotspotCount = 0,
    required this.thi,
    required this.temperatureDeviation,
    required this.humidityDeviation,
    required this.targetProfile,
    required this.explanation,
    this.advisory =
        'Environmental conditions may contribute to physiological stress and should be considered during veterinary assessment.',
  });

  Map<String, dynamic> toJson() => {
        'environmentalStressScore': environmentalStressScore,
        'environmentalStressLevel': environmentalStressLevel.name,
        'ambientTemperature': ambientTemperature,
        'humidity': humidity,
        'surfaceTemperature': surfaceTemperature,
        'thermalHotspotCount': thermalHotspotCount,
        'thi': thi,
        'temperatureDeviation': temperatureDeviation,
        'humidityDeviation': humidityDeviation,
        'targetProfile': targetProfile.toJson(),
        'explanation': explanation,
        'advisory': advisory,
      };

  factory EnvironmentalStressResult.fromJson(Map<String, dynamic> json) {
    return EnvironmentalStressResult(
      environmentalStressScore:
          (json['environmentalStressScore'] as num?)?.toInt() ?? 0,
      environmentalStressLevel: EnvironmentalStressLevel.values.firstWhere(
        (e) => e.name == json['environmentalStressLevel'],
        orElse: () => EnvironmentalStressLevel.normal,
      ),
      ambientTemperature:
          (json['ambientTemperature'] as num?)?.toDouble() ?? 25.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 60.0,
      surfaceTemperature:
          (json['surfaceTemperature'] as num?)?.toDouble(),
      thermalHotspotCount:
          (json['thermalHotspotCount'] as num?)?.toInt() ?? 0,
      thi: (json['thi'] as num?)?.toDouble() ?? 70.0,
      temperatureDeviation:
          (json['temperatureDeviation'] as num?)?.toDouble() ?? 0.0,
      humidityDeviation:
          (json['humidityDeviation'] as num?)?.toDouble() ?? 0.0,
      targetProfile: json['targetProfile'] != null
          ? EnvironmentalTargetProfile.fromJson(
              json['targetProfile'] as Map<String, dynamic>)
          : const EnvironmentalTargetProfile(),
      explanation: json['explanation'] as String? ?? 'Normal conditions',
      advisory: json['advisory'] as String? ??
          'Environmental conditions may contribute to physiological stress and should be considered during veterinary assessment.',
    );
  }
}
