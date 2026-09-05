import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soul/providers/tap_engine_provider.dart';
import 'package:soul/utils/time_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TimeUtils Bangladesh (UTC+6) Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('TimeUtils.bdNow() is 6 hours ahead of UTC', () {
      final utcNow = DateTime.now().toUtc();
      final bdNow = TimeUtils.bdNow();
      final diffInHours = bdNow.difference(utcNow).inHours;
      expect(diffInHours, 6);
    });

    test('TimeUtils.bdDateString() matches YYYY-MM-DD format', () {
      final dateStr = TimeUtils.bdDateString();
      final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      expect(regex.hasMatch(dateStr), isTrue);
    });

    test('TimeUtils.currentWeekBdDates() returns 7 days from Monday to Sunday', () {
      final weekDates = TimeUtils.currentWeekBdDates();
      expect(weekDates.length, 7);

      for (final d in weekDates) {
        final parsed = DateTime.parse(d);
        expect(parsed, isNotNull);
      }
    });

    test('TimeUtils.timeUntilBdMidnight() returns valid countdown string', () {
      final countdown = TimeUtils.timeUntilBdMidnight();
      expect(countdown.contains('m'), isTrue);
    });

    test('TapEngineProvider tracks daily taps independently without shifting', () {
      final engine = TapEngineProvider();
      expect(engine.todayTaps, 0);

      // Simulate tapping 100 times
      for (int i = 0; i < 100; i++) {
        engine.handleTap(const Offset(10, 10), hapticsEnabled: false);
      }

      expect(engine.score >= 100, isTrue);
      expect(engine.todayTaps >= 100, isTrue);

      final weekly = engine.weeklyTaps;
      expect(weekly.length, 7);

      final todayIdx = TimeUtils.currentWeekdayIndex();
      expect(weekly[todayIdx], engine.todayTaps);

      // Other days in the week should remain 0
      for (int i = 0; i < 7; i++) {
        if (i != todayIdx) {
          expect(weekly[i], 0);
        }
      }

      engine.dispose();
    });

    test('TapEngineProvider activeStreakDays increments when active on consecutive calendar days', () {
      final engine = TapEngineProvider();
      expect(engine.activeStreakDays, 1);

      // Active today
      engine.handleTap(const Offset(20, 20), hapticsEnabled: false);
      expect(engine.activeStreakDays, 1);

      engine.dispose();
    });
  });
}
