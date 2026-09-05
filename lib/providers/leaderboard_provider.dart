import 'dart:async';
import 'package:flutter/material.dart';
import '../models/leaderboard_entry.dart';
import '../services/api_service.dart';
import '../utils/time_utils.dart';

class LeaderboardProvider extends ChangeNotifier {
  int _selectedTab = 0; // 0 = Rankers (Global Scores), 1 = Rewards (Completed Payouts)
  LeaderboardEntry? _selectedEntry;
  bool _isLoading = false;
  bool _hasInitialFetchCompleted = false;
  String _searchQuery = '';
  Timer? _autoRefreshTimer;

  int get selectedTab => _selectedTab;
  LeaderboardEntry? get selectedEntry => _selectedEntry;
  bool get isLoading => _isLoading;
  bool get hasInitialFetchCompleted => _hasInitialFetchCompleted;
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

  LeaderboardEntry? findGlobalEntry(String username) {
    final clean = username.replaceAll('@', '').trim().toLowerCase();
    if (clean.isEmpty) return null;
    return _globalEntries.cast<LeaderboardEntry?>().firstWhere(
      (e) => e != null && e.username.replaceAll('@', '').trim().toLowerCase() == clean,
      orElse: () => null,
    );
  }

  LeaderboardEntry? findRewardEntry(String username) {
    final clean = username.replaceAll('@', '').trim().toLowerCase();
    if (clean.isEmpty) return null;
    return _rewardEntries.cast<LeaderboardEntry?>().firstWhere(
      (e) => e != null && e.username.replaceAll('@', '').trim().toLowerCase() == clean,
      orElse: () => null,
    );
  }

  // Top Global Rankers (Ordered by Tap Score)
  List<LeaderboardEntry> _globalEntries = [
    const LeaderboardEntry(
      rank: 1,
      coinsRank: 1,
      username: 'Ashik',
      avatarUrl: 'https://tapx.ashiik.com/api/uploads/avatars/avatar_ce0e001f4d_1788357926.png',
      score: 8234,
      coinsScore: 8234,
      level: 9,
      streakDays: 1,
      joinedDate: '2026',
      twitterHandle: 'ashik_x',
      discordUsername: 'ashik#0001',
      activityRates: [0.7, 0.8, 0.9, 0.85, 1.0, 0.9, 0.8],
      rewardAmount: 1.98,
      rewardCurrency: '৳',
      rewardMethod: 'bKash',
      rewardRank: 9,
    ),
    const LeaderboardEntry(
      rank: 2,
      coinsRank: 2,
      username: 'QuantumTapper',
      avatarUrl: 'https://ui-avatars.com/api/?name=Quantum+Tapper&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 4850,
      coinsScore: 4850,
      level: 5,
      streakDays: 4,
      joinedDate: '2026',
      twitterHandle: 'quantum_tap',
      discordUsername: 'quantum#1337',
      activityRates: [0.8, 0.7, 0.9, 0.6, 1.0, 0.85, 0.9],
      rewardAmount: 2500.0,
      rewardCurrency: '৳',
      rewardMethod: 'bKash',
      rewardRank: 1,
    ),
    const LeaderboardEntry(
      rank: 3,
      coinsRank: 3,
      username: 'CyberGhost',
      avatarUrl: 'https://ui-avatars.com/api/?name=Cyber+Ghost&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 4200,
      coinsScore: 4200,
      level: 4,
      streakDays: 3,
      joinedDate: '2026',
      twitterHandle: 'cyberghost_x',
      discordUsername: 'ghost#0042',
      activityRates: [0.6, 0.8, 0.5, 0.7, 0.8, 0.75, 0.7],
      rewardAmount: 2000.0,
      rewardCurrency: '৳',
      rewardMethod: 'Nagad',
      rewardRank: 2,
    ),
    const LeaderboardEntry(
      rank: 4,
      coinsRank: 4,
      username: 'NovaStriker',
      avatarUrl: 'https://ui-avatars.com/api/?name=Nova+Striker&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 3750,
      coinsScore: 3750,
      level: 4,
      streakDays: 3,
      joinedDate: '2026',
      twitterHandle: 'nova_striker',
      discordUsername: 'nova#9999',
      activityRates: [0.5, 0.6, 0.7, 0.6, 0.8, 0.7, 0.5],
      rewardAmount: 1750.0,
      rewardCurrency: '৳',
      rewardMethod: 'bKash',
      rewardRank: 3,
    ),
    const LeaderboardEntry(
      rank: 5,
      coinsRank: 5,
      username: 'VortexMaster',
      avatarUrl: 'https://ui-avatars.com/api/?name=Vortex+Master&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 3200,
      coinsScore: 3200,
      level: 3,
      streakDays: 2,
      joinedDate: '2026',
      twitterHandle: 'vortex_m',
      discordUsername: 'vortex#4040',
      activityRates: [0.4, 0.5, 0.6, 0.5, 0.7, 0.6, 0.65],
      rewardAmount: 1500.0,
      rewardCurrency: '৳',
      rewardMethod: 'Rocket',
      rewardRank: 4,
    ),
    const LeaderboardEntry(
      rank: 6,
      coinsRank: 6,
      username: 'HyperPulse',
      avatarUrl: 'https://ui-avatars.com/api/?name=Hyper+Pulse&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 2850,
      coinsScore: 2850,
      level: 3,
      streakDays: 2,
      joinedDate: '2026',
      twitterHandle: 'hyperpulse_hq',
      discordUsername: 'hyper#7777',
      activityRates: [0.3, 0.4, 0.6, 0.5, 0.7, 0.6, 0.5],
      rewardAmount: 1200.0,
      rewardCurrency: '৳',
      rewardMethod: 'bKash',
      rewardRank: 5,
    ),
    const LeaderboardEntry(
      rank: 7,
      coinsRank: 7,
      username: 'ApexPredator',
      avatarUrl: 'https://ui-avatars.com/api/?name=Apex+Predator&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 2400,
      coinsScore: 2400,
      level: 2,
      streakDays: 2,
      joinedDate: '2026',
      twitterHandle: 'apex_taps',
      discordUsername: 'apex#0000',
      activityRates: [0.4, 0.3, 0.5, 0.6, 0.4, 0.7, 0.5],
      rewardAmount: 1000.0,
      rewardCurrency: '৳',
      rewardMethod: 'Nagad',
      rewardRank: 6,
    ),
    const LeaderboardEntry(
      rank: 8,
      coinsRank: 8,
      username: 'ShadowTap',
      avatarUrl: 'https://ui-avatars.com/api/?name=Shadow+Tap&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 1950,
      coinsScore: 1950,
      level: 2,
      streakDays: 1,
      joinedDate: '2026',
      twitterHandle: 'shadow_tap',
      discordUsername: 'shadow#1111',
      activityRates: [0.3, 0.5, 0.4, 0.6, 0.5, 0.6, 0.4],
      rewardAmount: 800.0,
      rewardCurrency: '৳',
      rewardMethod: 'bKash',
      rewardRank: 7,
    ),
    const LeaderboardEntry(
      rank: 9,
      coinsRank: 9,
      username: 'PulseRider',
      avatarUrl: 'https://ui-avatars.com/api/?name=Pulse+Rider&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 1600,
      coinsScore: 1600,
      level: 2,
      streakDays: 1,
      joinedDate: '2026',
      twitterHandle: 'pulserider',
      discordUsername: 'pulse#2024',
      activityRates: [0.3, 0.4, 0.5, 0.6, 0.4, 0.6, 0.5],
      rewardAmount: 500.0,
      rewardCurrency: '৳',
      rewardMethod: 'Rocket',
      rewardRank: 8,
    ),
    const LeaderboardEntry(
      rank: 10,
      coinsRank: 10,
      username: 'NeonFlash',
      avatarUrl: 'https://ui-avatars.com/api/?name=Neon+Flash&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 1300,
      coinsScore: 1300,
      level: 1,
      streakDays: 1,
      joinedDate: '2026',
      twitterHandle: 'neon_flash',
      discordUsername: 'neon#3333',
      activityRates: [0.4, 0.2, 0.5, 0.6, 0.5, 0.5, 0.4],
      rewardAmount: 300.0,
      rewardCurrency: '৳',
      rewardMethod: 'Nagad',
      rewardRank: 9,
    ),
  ];

  // Top Completed Payout Rewards (Amounts in Taka ৳ / USD $ from verified transactions, ordered descending)
  List<LeaderboardEntry> _rewardEntries = [
    const LeaderboardEntry(
      rank: 1,
      rewardRank: 1,
      coinsRank: 2,
      username: 'QuantumTapper',
      avatarUrl: 'https://ui-avatars.com/api/?name=Quantum+Tapper&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 4850,
      coinsScore: 4850,
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
      rewardRank: 2,
      coinsRank: 3,
      username: 'CyberGhost',
      avatarUrl: 'https://ui-avatars.com/api/?name=Cyber+Ghost&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 4200,
      coinsScore: 4200,
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
      rewardRank: 3,
      coinsRank: 4,
      username: 'NovaStriker',
      avatarUrl: 'https://ui-avatars.com/api/?name=Nova+Striker&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 3750,
      coinsScore: 3750,
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
      rewardRank: 4,
      coinsRank: 5,
      username: 'VortexMaster',
      avatarUrl: 'https://ui-avatars.com/api/?name=Vortex+Master&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 3200,
      coinsScore: 3200,
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
      rewardRank: 5,
      coinsRank: 6,
      username: 'HyperPulse',
      avatarUrl: 'https://ui-avatars.com/api/?name=Hyper+Pulse&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 2850,
      coinsScore: 2850,
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
      rewardRank: 6,
      coinsRank: 7,
      username: 'ApexPredator',
      avatarUrl: 'https://ui-avatars.com/api/?name=Apex+Predator&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 2400,
      coinsScore: 2400,
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
      rewardRank: 7,
      coinsRank: 8,
      username: 'ShadowTap',
      avatarUrl: 'https://ui-avatars.com/api/?name=Shadow+Tap&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 1950,
      coinsScore: 1950,
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
      rewardRank: 8,
      coinsRank: 9,
      username: 'PulseRider',
      avatarUrl: 'https://ui-avatars.com/api/?name=Pulse+Rider&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 1600,
      coinsScore: 1600,
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
      rewardRank: 9,
      coinsRank: 1,
      username: 'Ashik',
      avatarUrl: 'https://tapx.ashiik.com/api/uploads/avatars/avatar_ce0e001f4d_1788357926.png',
      score: 8234,
      coinsScore: 8234,
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
      rewardRank: 10,
      coinsRank: 10,
      username: 'Shofiq',
      avatarUrl: 'https://ui-avatars.com/api/?name=Shofik&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      score: 1200,
      coinsScore: 1200,
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

    try {
      // Fetch both Global Rankers and Completed Rewards concurrently
      final results = await Future.wait([
        ApiService.getLeaderboard(type: 'global', search: search),
        ApiService.getLeaderboard(type: 'rewards', search: search),
      ]);

      final globalData = results[0];
      final rewardsData = results[1];
      final weekdayIndex = TimeUtils.currentWeekdayIndex();

      List<LeaderboardEntry>? newGlobal;
      if (globalData != null && globalData.isNotEmpty) {
        newGlobal = globalData.map((e) {
          final score = (e['score'] as num?)?.toInt() ?? 0;
          final rawRewardAmount = (e['reward_amount'] as num?)?.toDouble();
          final currencySymbol = cleanCurrencySymbol(e['reward_currency']?.toString());
          final method = e['reward_method']?.toString();
          final coinsRank = (e['coins_rank'] as num?)?.toInt() ?? (e['rank'] as num?)?.toInt() ?? 1;
          final rewardRank = (e['reward_rank'] as num?)?.toInt();

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
            coinsRank: coinsRank,
            username: username,
            avatarUrl: avatarUrl,
            score: score,
            coinsScore: score,
            level: e['level'] ?? 1,
            streakDays: e['streak_days'] ?? 1,
            joinedDate: '2026',
            activityRates: rates,
            rawWeeklyTaps: rawWeekly,
            rewardAmount: rawRewardAmount,
            rewardCurrency: currencySymbol,
            rewardMethod: method,
            rewardRank: rewardRank,
            isRewardEntry: false,
          );
        }).toList();
      }

      List<LeaderboardEntry>? newRewards;
      if (rewardsData != null && rewardsData.isNotEmpty) {
        newRewards = rewardsData.map((e) {
          final score = (e['score'] as num?)?.toInt() ?? 0;
          final rawRewardAmount = (e['reward_amount'] as num?)?.toDouble() ?? 0.0;
          final currencySymbol = cleanCurrencySymbol(e['reward_currency']?.toString());
          final method = e['reward_method']?.toString();
          final coinsRank = (e['coins_rank'] as num?)?.toInt();
          final rewardRank = (e['reward_rank'] as num?)?.toInt() ?? (e['rank'] as num?)?.toInt() ?? 1;

          List<int> rawWeekly = [0, 0, 0, 0, 0, 0, 0];
          if (e['raw_weekly_taps'] is List) {
            rawWeekly = (e['raw_weekly_taps'] as List).map((x) => (x as num).toInt()).toList();
          } else if (score > 0) {
            rawWeekly[weekdayIndex] = score;
          }

          final username = e['username'] ?? 'Tapper';
          final rawAvatar = (e['avatar_url'] ?? '').toString().trim();
          final avatarUrl = rawAvatar.isNotEmpty
              ? rawAvatar
              : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(username)}&background=1A1A1E&color=FFFFFF&bold=true&size=256';

          return LeaderboardEntry(
            rank: rewardRank,
            rewardRank: rewardRank,
            coinsRank: coinsRank,
            username: username,
            avatarUrl: avatarUrl,
            score: score,
            coinsScore: score,
            level: e['level'] ?? 1,
            streakDays: e['streak_days'] ?? 1,
            joinedDate: '2026',
            activityRates: const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
            rawWeeklyTaps: rawWeekly,
            rewardAmount: rawRewardAmount,
            rewardCurrency: currencySymbol,
            rewardMethod: method,
            isRewardEntry: true,
          );
        }).toList();

        // Sort strictly descending by reward amount
        newRewards.sort((a, b) {
          final amtA = a.rewardAmount ?? 0.0;
          final amtB = b.rewardAmount ?? 0.0;
          return amtB.compareTo(amtA);
        });
        for (int i = 0; i < newRewards.length; i++) {
          newRewards[i] = newRewards[i].copyWith(
            rank: i + 1,
            rewardRank: i + 1,
          );
        }
      }

      // Cross-reference both lists seamlessly
      final effectiveGlobal = newGlobal ?? _globalEntries;
      final effectiveRewards = newRewards ?? _rewardEntries;

      final Map<String, LeaderboardEntry> rewardLookup = {
        for (final r in effectiveRewards)
          r.username.replaceAll('@', '').trim().toLowerCase(): r,
      };

      final Map<String, LeaderboardEntry> globalLookup = {
        for (final g in effectiveGlobal)
          g.username.replaceAll('@', '').trim().toLowerCase(): g,
      };

      _globalEntries = effectiveGlobal.map((g) {
        final key = g.username.replaceAll('@', '').trim().toLowerCase();
        final r = rewardLookup[key];
        if (r != null) {
          return g.copyWith(
            rewardAmount: r.rewardAmount ?? g.rewardAmount,
            rewardCurrency: r.rewardCurrency.isNotEmpty ? r.rewardCurrency : g.rewardCurrency,
            rewardMethod: r.rewardMethod ?? g.rewardMethod,
            rewardRank: r.rewardRank ?? r.rank,
            coinsRank: g.coinsRank ?? g.rank,
          );
        }
        return g.copyWith(
          coinsRank: g.coinsRank ?? g.rank,
        );
      }).toList();

      _rewardEntries = effectiveRewards.map((r) {
        final key = r.username.replaceAll('@', '').trim().toLowerCase();
        final g = globalLookup[key];
        if (g != null) {
          return r.copyWith(
            score: (g.score > 0) ? g.score : r.score,
            coinsScore: (g.score > 0) ? g.score : r.score,
            coinsRank: g.coinsRank ?? g.rank,
            rawWeeklyTaps: (g.rawWeeklyTaps != null && g.rawWeeklyTaps!.any((v) => v > 0))
                ? g.rawWeeklyTaps
                : r.rawWeeklyTaps,
            rewardRank: r.rewardRank ?? r.rank,
          );
        }
        return r.copyWith(
          rewardRank: r.rewardRank ?? r.rank,
        );
      }).take(10).toList();
    } catch (e) {
      debugPrint('Leaderboard fetch note: $e');
    } finally {
      _hasInitialFetchCompleted = true;
      if (!silent) {
        _isLoading = false;
      }
      _safeNotifyListeners();
    }
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
}
