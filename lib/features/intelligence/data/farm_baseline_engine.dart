import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/intelligence/domain/farm_metric_baseline_model.dart';

/// Farm Baseline Intelligence Engine (Part 3)
/// Calculates statistical 7-day rolling baselines and percentage deviations for key operational metrics
class FarmBaselineEngine {
  FarmBaselineEngine._();

  /// Calculates baseline metrics for mortality, feed, water, temperature, and humidity
  static Map<String, FarmMetricBaseline> calculateBaselines({
    required List<DailyRecordModel> dailyRecords,
    int? currentMortality,
    double? currentFeedKg,
    double? currentWaterLiters,
    double? currentTemperature,
    double? currentHumidity,
  }) {
    // Sort records descending by date
    final sorted = List<DailyRecordModel>.from(dailyRecords)
      ..sort((a, b) => b.recordDate.compareTo(a.recordDate));

    final baselines = <String, FarmMetricBaseline>{};

    // 1. Mortality Baseline
    final mortRecordValues = sorted.take(7).map((r) => r.mortalityCount.toDouble()).toList();
    final effectiveCurrentMort = currentMortality?.toDouble() ?? (sorted.isNotEmpty ? sorted.first.mortalityCount.toDouble() : 3.0);
    baselines['mortality'] = _calculateSingleBaseline(
      metric: 'mortality',
      currentValue: effectiveCurrentMort,
      priorValues: mortRecordValues.length > 1 ? mortRecordValues.sublist(1) : mortRecordValues,
      unit: 'birds/day',
      isMortality: true,
    );

    // 2. Feed Baseline
    final feedRecordValues = sorted.take(7).map((r) => r.feedConsumedKg.toDouble()).toList();
    final effectiveCurrentFeed = currentFeedKg ?? (sorted.isNotEmpty ? sorted.first.feedConsumedKg.toDouble() : 500.0);
    baselines['feed'] = _calculateSingleBaseline(
      metric: 'feed',
      currentValue: effectiveCurrentFeed,
      priorValues: feedRecordValues.length > 1 ? feedRecordValues.sublist(1) : feedRecordValues,
      unit: 'kg/day',
      isDropAnomaly: true,
    );

    // 3. Water Baseline
    final waterRecordValues = sorted.take(7).map((r) => r.waterConsumedLiters.toDouble()).toList();
    final effectiveCurrentWater = currentWaterLiters ?? (sorted.isNotEmpty ? sorted.first.waterConsumedLiters.toDouble() : 850.0);
    baselines['water'] = _calculateSingleBaseline(
      metric: 'water',
      currentValue: effectiveCurrentWater,
      priorValues: waterRecordValues.length > 1 ? waterRecordValues.sublist(1) : waterRecordValues,
      unit: 'L/day',
      isDropAnomaly: true,
    );

    // 4. Temperature Baseline
    final tempRecordValues = sorted.take(7).map((r) => (r.temperature ?? 28.0).toDouble()).toList();
    final effectiveCurrentTemp = currentTemperature ?? (sorted.isNotEmpty ? (sorted.first.temperature ?? 28.0).toDouble() : 28.0);
    baselines['temperature'] = _calculateSingleBaseline(
      metric: 'temperature',
      currentValue: effectiveCurrentTemp,
      priorValues: tempRecordValues.length > 1 ? tempRecordValues.sublist(1) : tempRecordValues,
      unit: '°C',
    );

    // 5. Humidity Baseline
    final humRecordValues = sorted.take(7).map((r) => (r.humidity ?? 65.0).toDouble()).toList();
    final effectiveCurrentHum = currentHumidity ?? (sorted.isNotEmpty ? (sorted.first.humidity ?? 65.0).toDouble() : 65.0);
    baselines['humidity'] = _calculateSingleBaseline(
      metric: 'humidity',
      currentValue: effectiveCurrentHum,
      priorValues: humRecordValues.length > 1 ? humRecordValues.sublist(1) : humRecordValues,
      unit: '%',
    );

    return baselines;
  }

  static FarmMetricBaseline calculateSingleBaseline({
    required String metric,
    required double currentValue,
    required List<double> priorValues,
    required String unit,
    bool isMortality = false,
    bool isDropAnomaly = false,
  }) => _calculateSingleBaseline(
    metric: metric,
    currentValue: currentValue,
    priorValues: priorValues,
    unit: unit,
    isMortality: isMortality,
    isDropAnomaly: isDropAnomaly,
  );

  static FarmMetricBaseline _calculateSingleBaseline({
    required String metric,
    required double currentValue,
    required List<double> priorValues,
    required String unit,
    bool isMortality = false,
    bool isDropAnomaly = false,
  }) {
    if (priorValues.isEmpty) {
      // Default fallback baseline
      final fallbackMean = isMortality ? 3.0 : (currentValue > 0 ? currentValue : 100.0);
      final ratio = fallbackMean > 0 ? currentValue / fallbackMean : 1.0;
      final devPct = ((currentValue - fallbackMean) / fallbackMean) * 100.0;

      MetricStatus status = MetricStatus.normal;
      if (isMortality) {
        if (ratio >= 4.0 || currentValue >= 15) {
          status = MetricStatus.severeAnomaly;
        } else if (ratio >= 2.5 || currentValue >= 8) {
          status = MetricStatus.abnormal;
        } else if (ratio >= 1.5) {
          status = MetricStatus.watch;
        }
      }

      return FarmMetricBaseline(
        metric: metric,
        currentValue: currentValue,
        baselineMean: fallbackMean,
        deviationPercent: devPct,
        ratio: ratio,
        trend: 'stable',
        status: status,
        dataQuality: 'Limited',
        sampleCount: 1,
        unit: unit,
      );
    }

    final sum = priorValues.fold<double>(0.0, (acc, v) => acc + v);
    final mean = sum / priorValues.length;
    final effectiveMean = mean < 0.1 ? 1.0 : mean;

    final ratio = currentValue / effectiveMean;
    final devPct = ((currentValue - effectiveMean) / effectiveMean) * 100.0;

    // Trend Direction
    String trend = 'stable';
    if (priorValues.length >= 2) {
      final prevVal = priorValues.first;
      if (currentValue > prevVal * 1.05) {
        trend = isMortality ? 'worsening' : 'increasing';
      } else if (currentValue < prevVal * 0.95) {
        trend = isMortality ? 'improving' : 'decreasing';
      }
    }

    // Status Determination
    MetricStatus status = MetricStatus.normal;

    if (isMortality) {
      if (ratio >= 4.0 || currentValue >= 15) {
        status = MetricStatus.severeAnomaly;
      } else if (ratio >= 2.5 || currentValue >= 8) {
        status = MetricStatus.abnormal;
      } else if (ratio >= 1.5 || currentValue >= 5) {
        status = MetricStatus.watch;
      }
    } else if (isDropAnomaly) {
      // Feed or water consumption drops
      if (devPct <= -25.0) {
        status = MetricStatus.severeAnomaly;
      } else if (devPct <= -15.0) {
        status = MetricStatus.abnormal;
      } else if (devPct <= -8.0) {
        status = MetricStatus.watch;
      }
    } else {
      // Environmental (temp/humidity)
      if (devPct.abs() >= 25.0) {
        status = MetricStatus.severeAnomaly;
      } else if (devPct.abs() >= 15.0) {
        status = MetricStatus.abnormal;
      } else if (devPct.abs() >= 8.0) {
        status = MetricStatus.watch;
      }
    }

    return FarmMetricBaseline(
      metric: metric,
      currentValue: currentValue,
      baselineMean: double.parse(mean.toStringAsFixed(1)),
      deviationPercent: double.parse(devPct.toStringAsFixed(1)),
      ratio: double.parse(ratio.toStringAsFixed(2)),
      trend: trend,
      status: status,
      dataQuality: priorValues.length >= 5 ? 'Good' : 'Adequate',
      sampleCount: priorValues.length,
      unit: unit,
    );
  }
}
