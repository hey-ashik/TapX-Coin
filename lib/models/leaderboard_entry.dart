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
  final double? rewardAmount;
  final String rewardCurrency;
  final String? rewardMethod;
  final bool isRewardEntry;

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
    this.rewardAmount,
    this.rewardCurrency = '৳',
    this.rewardMethod,
    this.isRewardEntry = false,
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
    double? rewardAmount,
    String? rewardCurrency,
    String? rewardMethod,
    bool? isRewardEntry,
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
      rewardAmount: rewardAmount ?? this.rewardAmount,
      rewardCurrency: rewardCurrency ?? this.rewardCurrency,
      rewardMethod: rewardMethod ?? this.rewardMethod,
      isRewardEntry: isRewardEntry ?? this.isRewardEntry,
    );
  }
}
