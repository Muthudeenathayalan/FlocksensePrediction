import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/sheds/data/shed_service.dart';
import 'package:flock_sense/features/sheds/domain/shed_model.dart';

void main() {
  group('Shed Structure & Density Tests', () {
    test('calculate area and physical bird capacity accurately', () {
      final shed = ShedModel(
        id: 'shed_01',
        farmId: 'farm_01',
        ownerId: 'farmer_demo_user',
        name: 'Broiler Tunnel Shed 1',
        lengthFt: 250.0,
        widthFt: 40.0,
        totalSqFt: 10000.0,
        capacity: 8500,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(shed.totalSqFt, 10000.0);
      expect(shed.physicalCapacity, 8500);
      expect(shed.name, 'Broiler Tunnel Shed 1');
    });

    test('createShed adds new facility structure', () async {
      final shed = await ShedService.createShed(
        farmId: 'farm_01',
        name: 'Nursery Shed A',
        lengthFt: 150.0,
        widthFt: 30.0,
        capacity: 4000,
        notes: 'Environmentally controlled brooder house',
      );

      expect(shed.id, isNotEmpty);
      expect(shed.name, 'Nursery Shed A');
      expect(shed.totalSqFt, 4500.0);
      expect(shed.capacity, 4000);
    });

    test('watchSheds emits valid facility list', () async {
      final sheds = await ShedService.watchSheds('farm_01').first;
      expect(sheds, isNotEmpty);
    });
  });
}
