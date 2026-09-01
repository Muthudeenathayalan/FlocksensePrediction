import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';

void main() {
  group('Batch Lifecycle & Service Tests', () {
    test('watchBatches returns initial in-memory batches', () async {
      final stream = BatchService.watchBatches('farm_01');
      final initialList = await stream.first;

      expect(initialList, isNotEmpty);
      expect(initialList.first.farmId, 'farm_01');
      expect(initialList.first.currentBirds, greaterThan(0));
    });

    test('createBatch adds new batch with correct live birds calculation', () async {
      final now = DateTime.now();
      final batch = await BatchService.createBatch(
        farmId: 'farm_01',
        batchName: 'Broiler Batch 03',
        lengthFt: 100.0,
        widthFt: 30.0,
        sizeUnit: 'ft',
        placementDate: now,
        hatchDate: now.subtract(const Duration(days: 1)),
        maleCount: 2500,
        femaleCount: 2500,
        breedOrFlockType: 'Cobb 500',
        chickAvgWeight: 42.0,
      );

      expect(batch.id, isNotEmpty);
      expect(batch.batchName, 'Broiler Batch 03');
      expect(batch.totalBirds, 5000);
      expect(batch.currentBirds, 5000);

      final batches = await BatchService.getBatchesByFarmId('farm_01');
      expect(batches.any((b) => b.batchName == 'Broiler Batch 03'), isTrue);
    });

    test('BatchModel serialization and deserialization retains fidelity', () {
      final now = DateTime.now();
      final batch = BatchModel(
        id: 'batch_test_01',
        farmId: 'farm_01',
        ownerId: 'farmer_demo_user',
        batchName: 'Serialization Flock',
        hatchDate: now.subtract(const Duration(days: 1)),
        placementDate: now,
        maleCount: 1000,
        femaleCount: 1000,
        totalBirds: 2000,
        currentBirds: 1995,
        breedOrFlockType: 'Ross 308',
        createdAt: now,
        updatedAt: now,
      );

      final json = batch.toJson();
      final deserialized = BatchModel.fromJson(json);

      expect(deserialized.id, batch.id);
      expect(deserialized.batchName, batch.batchName);
      expect(deserialized.currentBirds, 1995);
      expect(deserialized.breed, 'Ross 308');
    });
  });
}
