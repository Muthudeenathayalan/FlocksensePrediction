import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/performance/domain/performance_calculator.dart';

void main() {
  group('PerformanceCalculator Tests', () {
    final now = DateTime.now();

    test('calculateDayFcr computes correct Feed Conversion Ratio for a daily record', () {
      final record = DailyRecordModel(
        id: 'rec_01',
        farmId: 'farm_01',
        batchId: 'batch_01',
        ownerId: 'user_01',
        recordDate: now,
        batchAgeDay: 21,
        openingBirds: 5000,
        mortalityCount: 2,
        cullCount: 0,
        adjustmentCount: 0,
        closingBirds: 4998,
        feedConsumedKg: 320.0,
        waterConsumedLiters: 640.0,
        avgWeightGrams: 850.0,
        medicineGiven: false,
        vaccineGiven: false,
        createdAt: now,
        updatedAt: now,
      );

      final fcr = PerformanceCalculator.calculateDayFcr(record);
      expect(fcr, isNotNull);
      expect(fcr!, greaterThan(0));
    });

    test('calculateCumulativeFcr computes cumulative FCR across records', () {
      final List<DailyRecordModel> records = [
        DailyRecordModel(
          id: 'rec_01',
          farmId: 'farm_01',
          batchId: 'batch_01',
          ownerId: 'user_01',
          recordDate: now.subtract(const Duration(days: 1)),
          batchAgeDay: 20,
          openingBirds: 5000,
          mortalityCount: 2,
          cullCount: 0,
          adjustmentCount: 0,
          closingBirds: 4998,
          feedConsumedKg: 300.0,
          waterConsumedLiters: 600.0,
          avgWeightGrams: 800.0,
          medicineGiven: false,
          vaccineGiven: false,
          createdAt: now,
          updatedAt: now,
        ),
        DailyRecordModel(
          id: 'rec_02',
          farmId: 'farm_01',
          batchId: 'batch_01',
          ownerId: 'user_01',
          recordDate: now,
          batchAgeDay: 21,
          openingBirds: 4998,
          mortalityCount: 1,
          cullCount: 0,
          adjustmentCount: 0,
          closingBirds: 4997,
          feedConsumedKg: 320.0,
          waterConsumedLiters: 640.0,
          avgWeightGrams: 850.0,
          medicineGiven: false,
          vaccineGiven: false,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final cumulativeFcr = PerformanceCalculator.calculateCumulativeFcr(records, 21);
      expect(cumulativeFcr, isNotNull);
      expect(cumulativeFcr!, greaterThan(0));
    });

    test('calculateCumulativeMortalityPct calculates mortality percentage', () {
      final List<DailyRecordModel> records = [
        DailyRecordModel(
          id: 'rec_01',
          farmId: 'farm_01',
          batchId: 'batch_01',
          ownerId: 'user_01',
          recordDate: now,
          batchAgeDay: 1,
          openingBirds: 5000,
          mortalityCount: 25,
          cullCount: 5,
          adjustmentCount: 0,
          closingBirds: 4970,
          feedConsumedKg: 100.0,
          waterConsumedLiters: 200.0,
          avgWeightGrams: 55.0,
          medicineGiven: false,
          vaccineGiven: false,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final mortalityPct = PerformanceCalculator.calculateCumulativeMortalityPct(records, 5000, 1);
      expect(mortalityPct, closeTo(0.6, 0.01));
    });
  });
}
