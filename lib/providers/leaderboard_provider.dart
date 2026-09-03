import 'dart:async';
import 'package:flutter/material.dart';
import '../models/leaderboard_entry.dart';
import '../services/api_service.dart';

class LeaderboardProvider extends ChangeNotifier {
  int _selectedTab = 0; // 0 = Rankers (Global Scores), 1 = Rewards (Completed Payouts)
  LeaderboardEntry? _selectedEntry;
  bool _isLoading = false;
  String _searchQuery = '';
  Timer? _autoRefreshTimer;

  int get selectedTab => _selectedTab;
  LeaderboardEntry? get selectedEntry => _selectedEntry;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  LeaderboardProvider() {
    fetchLeaderboard(silent: false);
    // Auto-refresh leaderboard silently in real-time every 60 seconds (1 minute)
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      fetchLeaderboard(silent: true);
    });
  }

  void setSelectedTab(int index) {
    if (_selectedTab == index) return;
    _selectedTab = index;
    notifyListeners();
    // Fetch silently in background so UI tab slide is 60fps butter smooth with zero lag or stutter
    fetchLeaderboard(silent: true);
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void selectEntry(LeaderboardEntry? entry) {
    _selectedEntry = entry;
    notifyListeners();
  }

  // Top Global Rankers (Ordered by Tap Score)
  List<LeaderboardEntry> _globalEntries = [
    const LeaderboardEntry(
      rank: 1,
      username: 'QuantumTapper',
      avatarUrl: 'https://ui-avatars.com/api/?name=Quantum+Tapper&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 4850,
      level: 5,
      streakDays: 4,
      joinedDate: '2026',
      twitterHandle: 'quantum_tap',
      discordUsername: 'quantum#1337',
      activityRates: [0.8, 0.7, 0.9, 0.6, 1.0, 0.85, 0.9],
    ),
    const LeaderboardEntry(
      rank: 2,
      username: 'CyberGhost',
      avatarUrl: 'https://ui-avatars.com/api/?name=Cyber+Ghost&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 4200,
      level: 4,
      streakDays: 3,
      joinedDate: '2026',
      twitterHandle: 'cyberghost_x',
      discordUsername: 'ghost#0042',
      activityRates: [0.6, 0.8, 0.5, 0.7, 0.8, 0.75, 0.7],
    ),
    const LeaderboardEntry(
      rank: 3,
      username: 'NovaStriker',
      avatarUrl: 'https://ui-avatars.com/api/?name=Nova+Striker&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 3750,
      level: 4,
      streakDays: 3,
      joinedDate: '2026',
      twitterHandle: 'nova_striker',
      discordUsername: 'nova#9999',
      activityRates: [0.5, 0.6, 0.7, 0.6, 0.8, 0.7, 0.5],
    ),
    const LeaderboardEntry(
      rank: 4,
      username: 'VortexMaster',
      avatarUrl: 'https://ui-avatars.com/api/?name=Vortex+Master&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 3200,
      level: 3,
      streakDays: 2,
      joinedDate: '2026',
      twitterHandle: 'vortex_m',
      discordUsername: 'vortex#4040',
      activityRates: [0.4, 0.5, 0.6, 0.5, 0.7, 0.6, 0.65],
    ),
    const LeaderboardEntry(
      rank: 5,
      username: 'HyperPulse',
      avatarUrl: 'https://ui-avatars.com/api/?name=Hyper+Pulse&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 2850,
      level: 3,
      streakDays: 2,
      joinedDate: '2026',
      twitterHandle: 'hyperpulse_hq',
      discordUsername: 'hyper#7777',
      activityRates: [0.3, 0.4, 0.6, 0.5, 0.7, 0.6, 0.5],
    ),
    const LeaderboardEntry(
      rank: 6,
      username: 'ApexPredator',
      avatarUrl: 'https://ui-avatars.com/api/?name=Apex+Predator&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 2400,
      level: 2,
      streakDays: 2,
      joinedDate: '2026',
      twitterHandle: 'apex_taps',
      discordUsername: 'apex#0000',
      activityRates: [0.4, 0.3, 0.5, 0.6, 0.4, 0.7, 0.5],
    ),
    const LeaderboardEntry(
      rank: 7,
      username: 'ShadowTap',
      avatarUrl: 'https://ui-avatars.com/api/?name=Shadow+Tap&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 1950,
      level: 2,
      streakDays: 1,
      joinedDate: '2026',
      twitterHandle: 'shadow_tap',
      discordUsername: 'shadow#1111',
      activityRates: [0.3, 0.5, 0.4, 0.6, 0.5, 0.6, 0.4],
    ),
    const LeaderboardEntry(
      rank: 8,
      username: 'PulseRider',
      avatarUrl: 'https://ui-avatars.com/api/?name=Pulse+Rider&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 1600,
      level: 2,
      streakDays: 1,
      joinedDate: '2026',
      twitterHandle: 'pulserider',
      discordUsername: 'pulse#2024',
      activityRates: [0.3, 0.4, 0.5, 0.6, 0.4, 0.6, 0.5],
    ),
    const LeaderboardEntry(
      rank: 9,
      username: 'NeonFlash',
      avatarUrl: 'https://ui-avatars.com/api/?name=Neon+Flash&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 1300,
      level: 1,
      streakDays: 1,
      joinedDate: '2026',
      twitterHandle: 'neon_flash',
      discordUsername: 'neon#3333',
      activityRates: [0.4, 0.2, 0.5, 0.6, 0.5, 0.5, 0.4],
    ),
    const LeaderboardEntry(
      rank: 10,
      username: 'ChronoTrigger',
      avatarUrl: 'https://ui-avatars.com/api/?name=Chrono+Trigger&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 1050,
      level: 1,
      streakDays: 1,
      joinedDate: '2026',
      twitterHandle: 'chrono_tap',
      discordUsername: 'chrono#5555',
      activityRates: [0.5, 0.3, 0.4, 0.6, 0.5, 0.6, 0.7],
    ),
  ];

  // Top Completed Payout Rewards (Amounts in Taka ৳ / USD $ from verified transactions, ordered descending)
  List<LeaderboardEntry> _rewardEntries = [
    const LeaderboardEntry(
      rank: 1,
      username: 'QuantumTapper',
      avatarUrl: 'https://ui-avatars.com/api/?name=Quantum+Tapper&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 2500,
      rewardAmount: 2500.0,
      rewardCurrency: '৳',
      rewardMethod: 'bKash',
      isRewardEntry: true,
      level: 5,
      streakDays: 4,
      joinedDate: '2026',
    ),
    const LeaderboardEntry(
      rank: 2,
      username: 'CyberGhost',
      avatarUrl: 'https://ui-avatars.com/api/?name=Cyber+Ghost&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 2000,
      rewardAmount: 2000.0,
      rewardCurrency: '৳',
      rewardMethod: 'Nagad',
      isRewardEntry: true,
      level: 4,
      streakDays: 3,
      joinedDate: '2026',
    ),
    const LeaderboardEntry(
      rank: 3,
      username: 'NovaStriker',
      avatarUrl: 'https://ui-avatars.com/api/?name=Nova+Striker&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 1750,
      rewardAmount: 1750.0,
      rewardCurrency: '৳',
      rewardMethod: 'bKash',
      isRewardEntry: true,
      level: 4,
      streakDays: 3,
      joinedDate: '2026',
    ),
    const LeaderboardEntry(
      rank: 4,
      username: 'VortexMaster',
      avatarUrl: 'https://ui-avatars.com/api/?name=Vortex+Master&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 1500,
      rewardAmount: 1500.0,
      rewardCurrency: '৳',
      rewardMethod: 'Rocket',
      isRewardEntry: true,
      level: 3,
      streakDays: 2,
      joinedDate: '2026',
    ),
    const LeaderboardEntry(
      rank: 5,
      username: 'HyperPulse',
      avatarUrl: 'https://ui-avatars.com/api/?name=Hyper+Pulse&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 1200,
      rewardAmount: 1200.0,
      rewardCurrency: '৳',
      rewardMethod: 'bKash',
      isRewardEntry: true,
      level: 3,
      streakDays: 2,
      joinedDate: '2026',
    ),
    const LeaderboardEntry(
      rank: 6,
      username: 'ApexPredator',
      avatarUrl: 'https://ui-avatars.com/api/?name=Apex+Predator&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 1000,
      rewardAmount: 1000.0,
      rewardCurrency: '৳',
      rewardMethod: 'Nagad',
      isRewardEntry: true,
      level: 2,
      streakDays: 2,
      joinedDate: '2026',
    ),
    const LeaderboardEntry(
      rank: 7,
      username: 'ShadowTap',
      avatarUrl: 'https://ui-avatars.com/api/?name=Shadow+Tap&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 800,
      rewardAmount: 800.0,
      rewardCurrency: '৳',
      rewardMethod: 'bKash',
      isRewardEntry: true,
      level: 2,
      streakDays: 1,
      joinedDate: '2026',
    ),
    const LeaderboardEntry(
      rank: 8,
      username: 'PulseRider',
      avatarUrl: 'https://ui-avatars.com/api/?name=Pulse+Rider&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 500,
      rewardAmount: 500.0,
      rewardCurrency: '৳',
      rewardMethod: 'Rocket',
      isRewardEntry: true,
      level: 2,
      streakDays: 1,
      joinedDate: '2026',
    ),
    const LeaderboardEntry(
      rank: 9,
      username: 'Ashik',
      avatarUrl: 'https://tapx.ashiik.com/api/uploads/avatars/avatar_ce0e001f4d_1788357926.png',
      score: 1,
      rewardAmount: 1.98,
      rewardCurrency: '৳',
      rewardMethod: 'bKash',
      isRewardEntry: true,
      level: 9,
      streakDays: 1,
      joinedDate: '2026',
    ),
    const LeaderboardEntry(
      rank: 10,
      username: 'Shofiq',
      avatarUrl: 'https://ui-avatars.com/api/?name=Shofik&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 1,
      rewardAmount: 1.00,
      rewardCurrency: '৳',
      rewardMethod: 'bKash',
      isRewardEntry: true,
      level: 9,
      streakDays: 1,
      joinedDate: '2026',
    ),
  ];

  List<LeaderboardEntry> get globalEntriesList => _globalEntries;
  List<LeaderboardEntry> get rewardEntriesList => _rewardEntries;

  List<LeaderboardEntry> get currentList {
    final list = _selectedTab == 0 ? _globalEntries : _rewardEntries;
    if (_searchQuery.isEmpty) return list;
    return list.where((e) {
      final name = e.username.toLowerCase();
      return name.contains(_searchQuery);
    }).toList();
  }

  static String cleanCurrencySymbol(String? currency) {
    if (currency == null || currency.trim().isEmpty) return '৳';
    final c = currency.trim().toUpperCase();
    if (c == 'USD' || c == r'$') return r'$';
    return '৳';
  }

  Future<void> fetchLeaderboard({bool silent = false, String search = ''}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    final type = _selectedTab == 0 ? 'global' : 'rewards';
    final entriesData = await ApiService.getLeaderboard(type: type, search: search);

    if (entriesData != null && entriesData.isNotEmpty) {
      final now = DateTime.now();
      final weekdayIndex = (now.weekday - 1).clamp(0, 6);

      final fetched = entriesData.map((e) {
        final score = (e['score'] as num?)?.toInt() ?? 0;
        final isReward = e['is_reward_entry'] == true || _selectedTab == 1;
        
        // Ensure reward_amount is strictly parsed from verified payout amount, NEVER tap score
        final rawRewardAmount = (e['reward_amount'] as num?)?.toDouble();
        final rewardAmount = isReward ? (rawRewardAmount ?? 0.0) : null;
        
        final currencySymbol = cleanCurrencySymbol(e['reward_currency']?.toString());
        final method = e['reward_method']?.toString();

        List<int> rawWeekly = [0, 0, 0, 0, 0, 0, 0];
        if (e['raw_weekly_taps'] is List) {
          rawWeekly = (e['raw_weekly_taps'] as List).map((x) => (x as num).toInt()).toList();
        } else if (score > 0) {
          rawWeekly[weekdayIndex] = score;
        }

        List<double> rates = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
        if (score > 0) {
          rates[weekdayIndex] = 1.0;
        }

        final username = e['username'] ?? 'Tapper';
        final rawAvatar = (e['avatar_url'] ?? '').toString().trim();
        final avatarUrl = rawAvatar.isNotEmpty
            ? rawAvatar
            : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(username)}&background=1A1A1E&color=FFFFFF&bold=true&size=256';

        return LeaderboardEntry(
          rank: e['rank'] ?? 1,
          username: username,
          avatarUrl: avatarUrl,
          score: score,
          level: e['level'] ?? 1,
          streakDays: e['streak_days'] ?? 1,
          joinedDate: '2026',
          activityRates: rates,
          rawWeeklyTaps: rawWeekly,
          rewardAmount: rewardAmount,
          rewardCurrency: currencySymbol,
          rewardMethod: method,
          isRewardEntry: isReward,
        );
      }).toList();

      if (_selectedTab == 0) {
        _globalEntries = fetched;
      } else {
        // Sort strictly in descending order of payout amount (highest payout at Rank 1)
        fetched.sort((a, b) {
          final amtA = a.rewardAmount ?? a.score.toDouble();
          final amtB = b.rewardAmount ?? b.score.toDouble();
          return amtB.compareTo(amtA);
        });
        for (int i = 0; i < fetched.length; i++) {
          fetched[i] = fetched[i].copyWith(rank: i + 1);
        }
        _rewardEntries = fetched.take(10).toList();
      }
    }

    if (!silent) {
      _isLoading = false;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}
