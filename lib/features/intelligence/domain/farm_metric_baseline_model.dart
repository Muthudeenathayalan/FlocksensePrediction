/// Metric Behavior Status
enum MetricStatus {
  normal,
  watch,
  abnormal,
  severeAnomaly;

  String get label {
    switch (this) {
      case MetricStatus.normal:
        return 'NORMAL';
      case MetricStatus.watch:
        return 'WATCH';
      case MetricStatus.abnormal:
        return 'ABNORMAL';
      case MetricStatus.severeAnomaly:
        return 'SEVERE ANOMALY';
    }
  }
}

/// Farm Metric Baseline Model (Part 3)
/// Represents statistical 7-day baseline and deviation calculation for a single key farm telemetry metric
class FarmMetricBaseline {
  final String metric; // 'mortality', 'feed', 'water', 'temperature', 'humidity'
  final double currentValue;
  final double baselineMean;
  final double deviationPercent;
  final double ratio; // currentValue / baselineMean
  final String trend; // 'improving', 'stable', 'worsening'
  final MetricStatus status;
  final String dataQuality; // 'Good', 'Adequate', 'Limited'
  final int sampleCount;
  final String unit;

  const FarmMetricBaseline({
    required this.metric,
    required this.currentValue,
    required this.baselineMean,
    required this.deviationPercent,
    required this.ratio,
    required this.trend,
    required this.status,
    this.dataQuality = 'Good',
    this.sampleCount = 7,
    this.unit = '',
  });

  Map<String, dynamic> toJson() => {
        'metric': metric,
        'currentValue': currentValue,
        'baselineMean': baselineMean,
        'deviationPercent': deviationPercent,
        'ratio': ratio,
        'trend': trend,
        'status': status.name,
        'dataQuality': dataQuality,
        'sampleCount': sampleCount,
        'unit': unit,
      };

  factory FarmMetricBaseline.fromJson(Map<String, dynamic> json) {
    return FarmMetricBaseline(
      metric: json['metric'] as String? ?? 'metric',
      currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0.0,
      baselineMean: (json['baselineMean'] as num?)?.toDouble() ?? 0.0,
      deviationPercent: (json['deviationPercent'] as num?)?.toDouble() ?? 0.0,
      ratio: (json['ratio'] as num?)?.toDouble() ?? 1.0,
      trend: json['trend'] as String? ?? 'stable',
      status: MetricStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MetricStatus.normal,
      ),
      dataQuality: json['dataQuality'] as String? ?? 'Good',
      sampleCount: (json['sampleCount'] as num?)?.toInt() ?? 7,
      unit: json['unit'] as String? ?? '',
    );
  }
}
