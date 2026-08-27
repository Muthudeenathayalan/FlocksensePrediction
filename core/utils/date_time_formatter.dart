import 'package:intl/intl.dart';

/// Date and time formatting utility tailored for flock age and batch lifecycles
class DateTimeFormatter {
  DateTimeFormatter._();

  static String formatDate(DateTime date, {String pattern = 'MMM dd, yyyy'}) {
    return DateFormat(pattern).format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('dd/MM/yy').format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  static int calculateAgeInDays(DateTime placementDate, [DateTime? currentDate]) {
    final now = currentDate ?? DateTime.now();
    final difference = now.difference(placementDate).inDays;
    return difference < 0 ? 0 : difference;
  }

  static String formatAge(int ageDays) {
    if (ageDays == 0) return 'Day 0 (Placed)';
    final weeks = ageDays ~/ 7;
    final remainingDays = ageDays % 7;
    if (weeks == 0) return 'Day $ageDays';
    if (remainingDays == 0) return '$weeks ${weeks == 1 ? 'Week' : 'Weeks'}';
    return '$weeks w, $remainingDays d (Day $ageDays)';
  }
}
