import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/daily_records/data/daily_record_service.dart';

void main() {
  group('Daily Records Creation & Retrieval Tests', () {
    test('createOrUpdateDailyRecord creates and saves record into storage', () async {
      final now = DateTime.now();
      final record = await DailyRecordService.createOrUpdateDailyRecord(
        farmId: 'farm_01',
        batchId: 'batch_01',
        recordDate: now,
        batchAgeDay: 28,
        openingBirds: 8314,
        mortalityCount: 2,
        cullCount: 0,
        feedConsumedKg: 420.0,
        waterConsumedLiters: 840.0,
        avgWeightGrams: 1450.0,
        medicineGiven: false,
        vaccineGiven: false,
        feedType: 'Finisher Pellets',
        temperature: 28.0,
        humidity: 60.0,
      );

      expect(record.farmId, 'farm_01');
      expect(record.batchId, 'batch_01');
      expect(record.closingBirds, 8312);
      expect(record.feedConsumedKg, 420.0);

      // Verify retrieval
      final retrieved = await DailyRecordService.getDailyRecordByDate(
        farmId: 'farm_01',
        batchId: 'batch_01',
        recordDate: now,
      );
      expect(retrieved, isNotNull);
      expect(retrieved!.mortalityCount, 2);
      expect(retrieved.feedConsumedKg, 420.0);
    });

    test('getAllDailyRecords returns list of stored records', () async {
      final records = await DailyRecordService.getAllDailyRecords(
        farmId: 'farm_01',
        batchId: 'batch_01',
      );
      expect(records, isNotEmpty);
      expect(records.first.batchId, 'batch_01');
    });
  });
}
