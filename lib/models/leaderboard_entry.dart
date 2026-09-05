class LeaderboardEntry {
  final int rank;
  final String username;
  final String avatarUrl;
  final int score;
  final int level;
  final int streakDays;
  final String joinedDate;
  final String twitterHandle;
  final String discordUsername;
  final List<double> activityRates; // Monday to Sunday relative heights [0.0 - 1.0]
  final List<int>? rawWeeklyTaps;
  final List<double>? rawWeeklyRewards;
  final double? rewardAmount;
  final String rewardCurrency;
  final String? rewardMethod;
  final bool isRewardEntry;
  final int? coinsRank;
  final int? rewardRank;
  final int? coinsScore;

  const LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.avatarUrl,
    required this.score,
    this.level = 1,
    this.streakDays = 1,
    this.joinedDate = '2026',
    this.twitterHandle = '',
    this.discordUsername = '',
    this.activityRates = const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    this.rawWeeklyTaps,
    this.rawWeeklyRewards,
    this.rewardAmount,
    this.rewardCurrency = '৳',
    this.rewardMethod,
    this.isRewardEntry = false,
    this.coinsRank,
    this.rewardRank,
    this.coinsScore,
  });

  LeaderboardEntry copyWith({
    int? rank,
    String? username,
    String? avatarUrl,
    int? score,
    int? level,
    int? streakDays,
    String? joinedDate,
    String? twitterHandle,
    String? discordUsername,
    List<double>? activityRates,
    List<int>? rawWeeklyTaps,
    List<double>? rawWeeklyRewards,
    double? rewardAmount,
    String? rewardCurrency,
    String? rewardMethod,
    bool? isRewardEntry,
    int? coinsRank,
    int? rewardRank,
    int? coinsScore,
  }) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      score: score ?? this.score,
      level: level ?? this.level,
      streakDays: streakDays ?? this.streakDays,
      joinedDate: joinedDate ?? this.joinedDate,
      twitterHandle: twitterHandle ?? this.twitterHandle,
      discordUsername: discordUsername ?? this.discordUsername,
      activityRates: activityRates ?? this.activityRates,
      rawWeeklyTaps: rawWeeklyTaps ?? this.rawWeeklyTaps,
      rawWeeklyRewards: rawWeeklyRewards ?? this.rawWeeklyRewards,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      rewardCurrency: rewardCurrency ?? this.rewardCurrency,
      rewardMethod: rewardMethod ?? this.rewardMethod,
      isRewardEntry: isRewardEntry ?? this.isRewardEntry,
      coinsRank: coinsRank ?? this.coinsRank,
      rewardRank: rewardRank ?? this.rewardRank,
      coinsScore: coinsScore ?? this.coinsScore,
    );
  }

  String? get payoutMethod => rewardMethod;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final rawAvatar = (json['avatar_url'] ?? json['avatarUrl'] ?? '').toString().trim();
    final username = json['username']?.toString() ?? 'Tapper';
    final avatarUrl = rawAvatar.isNotEmpty
        ? rawAvatar
        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(username)}&background=1A1A1E&color=FFFFFF&bold=true&size=256';

    List<double> rates = const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    if (json['activity_rates'] is List) {
      rates = (json['activity_rates'] as List).map((e) => (e as num).toDouble()).toList();
    } else if (json['activityRates'] is List) {
      rates = (json['activityRates'] as List).map((e) => (e as num).toDouble()).toList();
    }

    List<int>? weeklyTaps;
    if (json['raw_weekly_taps'] is List) {
      weeklyTaps = (json['raw_weekly_taps'] as List).map((e) => (e as num).toInt()).toList();
    } else if (json['rawWeeklyTaps'] is List) {
      weeklyTaps = (json['rawWeeklyTaps'] as List).map((e) => (e as num).toInt()).toList();
    }

    List<double>? weeklyRewards;
    if (json['raw_weekly_rewards'] is List) {
      weeklyRewards = (json['raw_weekly_rewards'] as List).map((e) => (e as num).toDouble()).toList();
    } else if (json['rawWeeklyRewards'] is List) {
      weeklyRewards = (json['rawWeeklyRewards'] as List).map((e) => (e as num).toDouble()).toList();
    }

    return LeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 1,
      username: username,
      avatarUrl: avatarUrl,
      score: (json['score'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      streakDays: (json['streak_days'] as num?)?.toInt() ?? (json['streakDays'] as num?)?.toInt() ?? 1,
      joinedDate: (json['joined_date'] ?? json['joinedDate'] ?? '2026').toString(),
      twitterHandle: (json['twitter_handle'] ?? json['twitterHandle'] ?? '').toString(),
      discordUsername: (json['discord_username'] ?? json['discordUsername'] ?? '').toString(),
      activityRates: rates,
      rawWeeklyTaps: weeklyTaps,
      rawWeeklyRewards: weeklyRewards,
      rewardAmount: (json['reward_amount'] as num?)?.toDouble() ?? (json['rewardAmount'] as num?)?.toDouble(),
      rewardCurrency: (json['reward_currency'] ?? json['rewardCurrency'] ?? '৳').toString(),
      rewardMethod: json['reward_method']?.toString() ?? json['payout_method']?.toString() ?? json['rewardMethod']?.toString(),
      isRewardEntry: json['is_reward_entry'] == true || json['isRewardEntry'] == true,
      coinsRank: (json['coins_rank'] as num?)?.toInt() ?? (json['coinsRank'] as num?)?.toInt(),
      rewardRank: (json['reward_rank'] as num?)?.toInt() ?? (json['rewardRank'] as num?)?.toInt(),
      coinsScore: (json['coins_score'] as num?)?.toInt() ?? (json['coinsScore'] as num?)?.toInt(),
    );
  }
}
