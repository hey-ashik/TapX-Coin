import 'package:intl/intl.dart';

/// Centralized utility for Bangladesh Standard Time (BST, UTC+6).
/// Ensures front-end daily resets, streak calculations, and 7-day activity graphs
/// strictly align with 12:00 AM (midnight) Bangladesh Time.
class TimeUtils {
  /// Bangladesh timezone offset from UTC is +6 hours.
  static const Duration bdOffset = Duration(hours: 6);

  /// Returns current DateTime in Bangladesh Standard Time.
  static DateTime bdNow() {
    return DateTime.now().toUtc().add(bdOffset);
  }

  /// Formats date to 'yyyy-MM-dd' in Bangladesh time.
  static String bdDateString([DateTime? dt]) {
    final target = dt != null 
        ? dt.toUtc().add(bdOffset) 
        : bdNow();
    return DateFormat('yyyy-MM-dd').format(target);
  }

  /// Calculates duration remaining until next 12:00 AM (midnight) Bangladesh time.
  static Duration durationUntilBdMidnight([DateTime? dt]) {
    final now = dt ?? bdNow();
    final nextMidnight = DateTime.utc(now.year, now.month, now.day + 1);
    final currentUtc = DateTime.utc(now.year, now.month, now.day, now.hour, now.minute, now.second);
    return nextMidnight.difference(currentUtc);
  }

  /// Returns friendly string like '13h 8m' or '45m' until 12:00 AM BD midnight.
  static String timeUntilBdMidnight([DateTime? dt]) {
    final diff = durationUntilBdMidnight(dt);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Returns calendar days between two DateTimes based on BD calendar day boundaries.
  static int calendarDaysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }

  /// Returns the 7 'yyyy-MM-dd' date strings from Monday (idx 0) to Sunday (idx 6)
  /// of the current week in Bangladesh time.
  static List<String> currentWeekBdDates([DateTime? dt]) {
    final now = dt ?? bdNow();
    // In Dart DateTime, Monday is 1, Sunday is 7
    final weekday = now.weekday; // 1 to 7
    final monday = DateTime.utc(now.year, now.month, now.day - (weekday - 1));

    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return DateFormat('yyyy-MM-dd').format(day);
    });
  }

  /// Returns the weekday index (0 = Monday, 6 = Sunday) for Bangladesh now.
  static int currentWeekdayIndex([DateTime? dt]) {
    final now = dt ?? bdNow();
    return (now.weekday - 1).clamp(0, 6);
  }
}
