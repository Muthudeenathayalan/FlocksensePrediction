import 'dart:math';

/// Utility to generate realistic daily logs for a 42-day broiler flock lifecycle
void main() {
  final random = Random();
  const initialPopulation = 10000;
  var currentPopulation = initialPopulation;
  var cumulativeFeed = 0.0;
  var averageWeightGrams = 42.0;

  print('Day,Population,Mortality,FeedKg,CumulativeFeedKg,WeightGrams,FCR');

  for (int day = 1; day <= 42; day++) {
    // Mortality: usually 2-10 birds/day with occasional fluctuations
    final dailyMortality = (random.nextDouble() * 8 + 1).toInt();
    currentPopulation -= dailyMortality;

    // Daily feed intake grows from ~15g/bird on Day 1 to ~180g/bird on Day 42
    final feedPerBirdGrams = 15.0 + (165.0 * (day / 42.0));
    final dailyFeedKg = (currentPopulation * feedPerBirdGrams) / 1000.0;
    cumulativeFeed += dailyFeedKg;

    // Weight gain: ~55g/day average
    final dailyGain = 20.0 + (50.0 * (day / 42.0)) + (random.nextDouble() * 6 - 3);
    averageWeightGrams += dailyGain;

    final totalLiveWeightKg = (currentPopulation * averageWeightGrams) / 1000.0;
    final fcr = cumulativeFeed / totalLiveWeightKg;

    print('$day,$currentPopulation,$dailyMortality,${dailyFeedKg.toStringAsFixed(1)},${cumulativeFeed.toStringAsFixed(1)},${averageWeightGrams.toStringAsFixed(0)},${fcr.toStringAsFixed(2)}');
  }
}
