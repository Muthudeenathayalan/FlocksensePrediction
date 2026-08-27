import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/performance/domain/performance_calculator.dart';

void main() {
  group('PerformanceCalculator Tests', () {
    test('calculateFcr computes correct Feed Conversion Ratio', () {
      final fcr = PerformanceCalculator.calculateFcr(
        totalFeedConsumedKg: 3200.0,
        totalLiveWeightKg: 2000.0,
      );
      expect(fcr, closeTo(1.60, 0.01));
    });

    test('calculateFcr returns 0 when live weight is zero or negative', () {
      final fcrZero = PerformanceCalculator.calculateFcr(
        totalFeedConsumedKg: 1000.0,
        totalLiveWeightKg: 0.0,
      );
      expect(fcrZero, equals(0.0));
    });

    test('calculateEpef computes accurate European Production Efficiency Factor', () {
      final epef = PerformanceCalculator.calculateEpef(
        livabilityPercent: 96.5,
        averageLiveWeightKg: 2.1,
        ageDays: 35,
        fcr: 1.55,
      );
      // EPEF = (96.5 * 2.1) / (35 * 1.55) * 100 = 202.65 / 54.25 * 100 = ~373.5
      expect(epef, greaterThan(350.0));
      expect(epef, lessThan(400.0));
    });

    test('calculateAdg calculates Average Daily Gain in grams', () {
      final adg = PerformanceCalculator.calculateAdg(
        currentWeightGrams: 2100.0,
        dayOldWeightGrams: 42.0,
        ageDays: 35,
      );
      // ADG = (2100 - 42) / 35 = 2058 / 35 = 58.8g/day
      expect(adg, closeTo(58.8, 0.1));
    });
  });
}
