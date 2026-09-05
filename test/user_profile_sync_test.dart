import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soul/models/leaderboard_entry.dart';
import 'package:soul/providers/leaderboard_provider.dart';
import 'package:soul/utils/time_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('User Profile Modal & Leaderboard Bidirectional Sync Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('LeaderboardEntry properly serializes and carries coinsRank, rewardRank, and reward data', () {
      final json = {
        'rank': 9,
        'username': 'Ashik',
        'score': 8234,
        'level': 9,
        'streak_days': 1,
        'reward_amount': 1.98,
        'reward_currency': 'BDT',
        'payout_method': 'bKash',
        'coins_rank': 1,
        'reward_rank': 9,
        'coins_score': 8234,
      };

      final entry = LeaderboardEntry.fromJson(json);
      expect(entry.username, 'Ashik');
      expect(entry.score, 8234);
      expect(entry.rewardAmount, 1.98);
      expect(entry.payoutMethod, 'bKash');
      expect(entry.coinsRank, 1);
      expect(entry.rewardRank, 9);
      expect(entry.coinsScore, 8234);
    });

    test('LeaderboardProvider finds corresponding entries bidirectionally for Rankers and Rewards', () {
      final provider = LeaderboardProvider();

      // Find Ashik in global
      final globalAshik = provider.findGlobalEntry('Ashik');
      expect(globalAshik, isNotNull);
      expect(globalAshik!.score, 8234);
      expect(globalAshik.rank, 1);
      // Even from global, reward data should be present
      expect(globalAshik.rewardAmount, 1.98);
      expect(globalAshik.payoutMethod, 'bKash');

      // Find Ashik in rewards
      final rewardAshik = provider.findRewardEntry('Ashik');
      expect(rewardAshik, isNotNull);
      expect(rewardAshik!.rewardAmount, 1.98);
      expect(rewardAshik.rewardRank, 9);
      // From rewards, coins score & rank should also be accurately resolved
      expect(rewardAshik.score, 8234);
      expect(rewardAshik.coinsRank, 1);

      provider.dispose();
    });

    test('Coins and Rewards cross-reference correctly when simulated from API JSON payload', () {
      // Emulating response where rewards list returns items with coins_rank and real score
      final rewardsJson = [
        {
          'rank': 1,
          'username': 'Alex_Crypto',
          'score': 1550000,
          'level': 10,
          'streak_days': 5,
          'reward_amount': 1550.00,
          'reward_currency': 'BDT',
          'payout_method': 'bKash',
          'coins_rank': 10,
          'reward_rank': 1,
        },
        {
          'rank': 9,
          'username': 'Ashik',
          'score': 8234,
          'level': 9,
          'streak_days': 1,
          'reward_amount': 1.98,
          'reward_currency': 'BDT',
          'payout_method': 'bKash',
          'coins_rank': 1,
          'reward_rank': 9,
        }
      ];

      final entries = rewardsJson.map((j) => LeaderboardEntry.fromJson(j)).toList();
      final ashik = entries.firstWhere((e) => e.username == 'Ashik');

      expect(ashik.score, 8234);
      expect(ashik.coinsRank, 1);
      expect(ashik.rewardRank, 9);
      expect(ashik.rewardAmount, 1.98);
    });

    test('Bangladesh Standard Time UTC+6 calculates 7-day weekday index correctly after 12:00 AM', () {
      final bdNow = TimeUtils.bdNow();
      final weekdayIndex = TimeUtils.currentWeekdayIndex();

      // Monday is index 0, Sunday is index 6
      expect(weekdayIndex >= 0 && weekdayIndex <= 6, isTrue);
      expect(weekdayIndex, bdNow.weekday - 1);

      // Verify that after 12:00 AM midnight BST, currentWeekBdDates correctly aligns with the active week
      final weekDates = TimeUtils.currentWeekBdDates();
      expect(weekDates.length, 7);
      expect(weekDates[weekdayIndex], TimeUtils.bdDateString());
    });
  });
}
