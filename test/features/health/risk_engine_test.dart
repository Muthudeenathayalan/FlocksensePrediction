import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/health/data/risk_engine.dart';
import 'package:flock_sense/features/health/data/risk_config.dart';

void main() {
  group('RiskEngine Evaluation Tests', () {
    test('calculateThi returns correct Temperature Humidity Index', () {
      final thi = RiskEngine.calculateThi(
        temperatureCelsius: 32.0,
        relativeHumidityPercent: 70.0,
      );
      // THI = 0.8*32 + 0.7*(32-14.4) + 46.4 = 25.6 + 12.32 + 46.4 = 84.32
      expect(thi, closeTo(84.32, 0.5));
    });

    test('classifyHeatStress accurately grades THI ranges', () {
      expect(RiskEngine.classifyHeatStress(72.0), equals(HeatStressLevel.normal));
      expect(RiskEngine.classifyHeatStress(76.0), equals(HeatStressLevel.alert));
      expect(RiskEngine.classifyHeatStress(81.0), equals(HeatStressLevel.danger));
      expect(RiskEngine.classifyHeatStress(86.0), equals(HeatStressLevel.emergency));
    });

    test('evaluateMortalitySpike flags sudden spike above baseline', () {
      final isSpike = RiskEngine.isMortalitySpike(
        dailyMortalityCount: 45,
        totalFlockPopulation: 5000,
        dailyMortalityThresholdPercent: 0.5,
      );
      // 45 / 5000 = 0.9% > 0.5% threshold
      expect(isSpike, isTrue);
    });
  });
}
