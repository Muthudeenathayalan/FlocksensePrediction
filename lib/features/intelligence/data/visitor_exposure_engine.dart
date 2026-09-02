import 'package:flock_sense/features/intelligence/domain/visitor_event_model.dart';

/// Visitor & Biosecurity Event Exposure Engine (Part 5)
/// Evaluates transparent biosecurity exposure based on visitor log history
class VisitorExposureEngine {
  VisitorExposureEngine._();

  /// Calculates the exposure score for an individual visitor event
  static int scoreEvent(VisitorEventModel event) {
    int score = 10; // Baseline visit contact

    if (event.visitedLivestockFarmRecently) {
      score += 25; // Contact with other livestock premises within 48-72h
    }
    if (!event.footwearDisinfected) {
      score += 20; // Direct tracking vector
    }
    if (event.vehicleEntered && !event.vehicleDisinfected) {
      score += 20; // Vehicle tyre contamination
    }
    if (!event.ppeUsed) {
      score += 15; // Unprotected entry
    }
    if (event.sharedEquipment) {
      score += 20; // Shared crates/tools vector
    }
    if (event.newAnimalIntroductionRelated) {
      score += 20; // New stock introduction
    }

    return score.clamp(0, 100);
  }

  /// Aggregates multiple visitor events over the past 7-14 days
  static VisitorExposureResult evaluateFarmVisitorHistory(
      List<VisitorEventModel> events) {
    if (events.isEmpty) {
      return const VisitorExposureResult(
        biosecurityExposureScore: 10,
        biosecurityExposureLevel: BiosecurityExposureLevel.low,
        recentEvents: [],
        contributingFactors: ['No external visitor events logged in recent 7 days.'],
        explanation: 'Low external contact exposure logged.',
      );
    }

    // Sort recent first
    final sorted = List<VisitorEventModel>.from(events)
      ..sort((a, b) => b.enteredAt.compareTo(a.enteredAt));

    final recent = sorted.take(10).toList();
    int highestSingleScore = 0;
    int cumulativeBonus = 0;
    final factors = <String>[];

    for (final e in recent) {
      final s = scoreEvent(e);
      if (s > highestSingleScore) highestSingleScore = s;

      if (e.visitedLivestockFarmRecently) {
        factors.add('Visitor (${e.visitorName}) had recent external livestock farm contact.');
      }
      if (!e.footwearDisinfected) {
        factors.add('Entry recorded without footwear disinfection footbath verification.');
      }
      if (e.vehicleEntered && !e.vehicleDisinfected) {
        factors.add('Vehicle entered perimeter without tyre disinfection.');
      }
      if (e.sharedEquipment) {
        factors.add('Shared agricultural equipment/crates brought onto farm.');
      }
      if (e.newAnimalIntroductionRelated) {
        factors.add('New livestock introduction logged.');
      }
    }

    if (recent.length >= 3) {
      cumulativeBonus += 10;
      factors.add('${recent.length} external visitor contacts logged within active window.');
    }

    final totalExposureScore = (highestSingleScore + cumulativeBonus).clamp(0, 100);

    BiosecurityExposureLevel level = BiosecurityExposureLevel.low;
    if (totalExposureScore >= 75) {
      level = BiosecurityExposureLevel.critical;
    } else if (totalExposureScore >= 50) {
      level = BiosecurityExposureLevel.high;
    } else if (totalExposureScore >= 30) {
      level = BiosecurityExposureLevel.moderate;
    }

    final explanation = factors.isNotEmpty
        ? 'Recent external-contact/biosecurity exposure occurred before the health deterioration and should be reviewed.'
        : 'Routine external visitor logs with protective disinfection compliance maintained.';

    return VisitorExposureResult(
      biosecurityExposureScore: totalExposureScore,
      biosecurityExposureLevel: level,
      recentEvents: recent,
      contributingFactors: factors.toSet().toList(),
      explanation: explanation,
    );
  }
}
