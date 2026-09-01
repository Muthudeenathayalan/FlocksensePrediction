import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/health/data/risk_engine.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';

void main() {
  group('RiskEngine Evaluation Tests', () {
    test('calculateHealthRisk calculates score and detects critical anomalies', () {
      final input = RiskEngineInput(
        caseId: 'case_test_01',
        farmId: 'farm_01',
        batchId: 'batch_01',
        currentMortality: 35,
        affectedCount: 50,
        symptoms: ['respiratory_rales', 'swollen_head', 'sudden_death'],
        feedReductionPercent: 28.0,
        waterReductionPercent: 20.0,
        incidentDate: DateTime.now(),
        currentBirdCount: 5000,
      );

      final assessment = RiskEngine.calculateHealthRisk(input);

      expect(assessment.score, greaterThan(50));
      expect(assessment.riskLevel, isIn([HealthRiskLevel.high, HealthRiskLevel.critical]));
      expect(assessment.structuredReasons, isNotEmpty);
      expect(assessment.inputHash, isNotEmpty);
    });

    test('calculateHealthRisk produces low score for mild symptoms', () {
      final input = RiskEngineInput(
        caseId: 'case_test_02',
        farmId: 'farm_01',
        batchId: 'batch_01',
        currentMortality: 0,
        affectedCount: 2,
        symptoms: ['mild_lethargy'],
        feedReductionPercent: 2.0,
        waterReductionPercent: 0.0,
        incidentDate: DateTime.now(),
        currentBirdCount: 5000,
      );

      final assessment = RiskEngine.calculateHealthRisk(input);
      expect(assessment.score, lessThan(40));
    });
  });
}
