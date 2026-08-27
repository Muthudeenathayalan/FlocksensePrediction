/// Sanity checker and bounds validator for daily poultry log entries
class BiometricValidator {
  BiometricValidator._();

  static bool isValidTemperature(double tempCelsius) {
    return tempCelsius >= 10.0 && tempCelsius <= 50.0;
  }

  static bool isValidHumidity(double humidityPercent) {
    return humidityPercent >= 10.0 && humidityPercent <= 100.0;
  }

  static bool isValidDailyMortality(int mortalityCount, int flockPopulation) {
    return mortalityCount >= 0 && mortalityCount <= flockPopulation;
  }

  static bool isValidFeedIntakeKg(double feedKg, int flockPopulation) {
    // 0 to 350 grams per bird per day max for adult birds
    final maxAllowedKg = (flockPopulation * 0.35);
    return feedKg >= 0 && feedKg <= maxAllowedKg;
  }

  static bool isValidWaterIntakeLiters(double waterLiters, int flockPopulation) {
    // 0 to 700 ml per bird per day max
    final maxAllowedLiters = (flockPopulation * 0.70);
    return waterLiters >= 0 && waterLiters <= maxAllowedLiters;
  }
}
