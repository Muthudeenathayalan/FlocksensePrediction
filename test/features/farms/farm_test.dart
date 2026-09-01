import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/core/utils/input_sanitizer.dart';

void main() {
  group('Farm Registration & Validation Tests', () {
    test('Valid farm name passes validation', () {
      expect(InputSanitizer.isValidFarmName('Green Valley Farm'), isTrue);
      expect(InputSanitizer.isValidFarmName('Farm 01'), isTrue);
      expect(InputSanitizer.isValidFarmName(''), isFalse);
      expect(InputSanitizer.isValidFarmName('A'), isFalse);
    });

    test('FarmModel serializes and deserializes correctly', () {
      final now = DateTime.now();
      final farm = FarmModel(
        id: 'farm_test_01',
        userId: 'user_123',
        farmName: 'Coimbatore Broiler Unit 1',
        farmType: 'EC',
        flockType: 'Broiler',
        address: 'Pollachi Road, Coimbatore, Tamil Nadu, India',
        areaName: 'Pollachi',
        district: 'Coimbatore',
        state: 'Tamil Nadu',
        country: 'India',
        lengthFt: 200,
        widthFt: 35,
        totalSqFt: 7000,
        capacity: 5800,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      final json = farm.toJson();
      expect(json['id'], 'farm_test_01');
      expect(json['farmName'], 'Coimbatore Broiler Unit 1');
      expect(json['totalSqFt'], 7000);
      expect(json['capacity'], 5800);

      final deserialized = FarmModel.fromJson(json);
      expect(deserialized.id, farm.id);
      expect(deserialized.farmName, farm.farmName);
      expect(deserialized.farmType, 'EC');
      expect(deserialized.flockType, 'Broiler');
      expect(deserialized.capacity, 5800);
    });
  });
}
