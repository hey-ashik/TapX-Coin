import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/leaderboard_entry.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/tap_engine_provider.dart';
import '../theme/app_colors.dart';
import 'activity_bar_chart.dart';
import 'app_avatar.dart';

class UserProfileModal extends StatelessWidget {
  final LeaderboardEntry? entry;
  final UserModel? user;

  const UserProfileModal({
    super.key,
    this.entry,
    this.user,
  });

  static void show(BuildContext context, {LeaderboardEntry? entry, UserModel? user}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99000000),
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 360),
        reverseDuration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      builder: (context) => UserProfileModal(entry: entry, user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final numberFormatter = NumberFormat.decimalPattern();
    final rewardFormatter = NumberFormat('#,##0.##');
    final tapEngine = context.watch<TapEngineProvider>();

    final auth = context.watch<AuthProvider>();
    final currentClean = auth.currentUser.username.replaceAll('@', '').trim().toLowerCase();
    final currentNameClean = auth.currentUser.name.replaceAll('@', '').trim().toLowerCase();
    final entryClean = (entry?.username ?? user?.username ?? '').replaceAll('@', '').trim().toLowerCase();

    final isCurrentPlayer = (user != null && user?.id == auth.currentUser.id) || 
                           (entryClean.isNotEmpty && (entryClean == currentClean || entryClean == currentNameClean)) ||
                           (entry == null && user == null);
    final username = isCurrentPlayer ? auth.currentUser.username : (entry?.username ?? user?.username ?? 'Tapper');
    final avatarUrl = isCurrentPlayer 
        ? auth.currentUser.avatarUrl 
        : (entry?.avatarUrl ?? user?.avatarUrl ?? '');
    final isGuest = isCurrentPlayer ? auth.currentUser.isGuest : (user?.isGuest ?? false);
    final rank = isGuest ? 0 : (entry?.rank ?? user?.rank ?? 0);
    final totalTaps = isCurrentPlayer ? tapEngine.score : (entry?.score ?? user?.totalTaps ?? 0);
    final level = (entry?.isRewardEntry == true)
        ? entry!.level
        : (isCurrentPlayer ? tapEngine.level : (entry?.level ?? user?.level ?? 1));
    final streakDays = (entry?.isRewardEntry == true)
        ? entry!.streakDays
        : (isCurrentPlayer ? tapEngine.dailyBonusDay : (entry?.streakDays ?? user?.streakDays ?? 1));
    final joinedDate = entry?.joinedDate ?? user?.joinedDate ?? '2026';
    final activityRates = isCurrentPlayer 
        ? tapEngine.weeklyActivityRates 
        : (entry?.activityRates ?? const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 32),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Modal Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                  ),
                  Text(
                    'TapX Profile',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Profile Avatar
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.08),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    AppAvatar(
                      imageUrl: avatarUrl,
                      name: username,
                      size: 96,
                      borderWidth: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // User details
              Text(
                '@$username',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 22,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Level $level • Rank #$rank • Joined $joinedDate',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
              ),
              const SizedBox(height: 16),

              // Bento Stats Box
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry?.isRewardEntry == true ? 'TOTAL REWARD' : 'TOTAL SCORE',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            entry?.isRewardEntry == true
                                ? '${entry!.rewardCurrency}${rewardFormatter.format(entry!.rewardAmount ?? entry!.score)}'
                                : numberFormatter.format(totalTaps),
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  letterSpacing: -0.5,
                                  fontSize: 22,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CURRENT STREAK',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'Day $streakDays',
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                      letterSpacing: -0.5,
                                      fontSize: 20,
                                    ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.local_fire_department,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 7-Day Activity Chart
              ActivityBarChart(
                activityRates: activityRates,
                rawTapCounts: (entry?.isRewardEntry == true)
                    ? null
                    : (isCurrentPlayer
                        ? tapEngine.weeklyTaps
                        : (entry?.rawWeeklyTaps ?? _getAccurateWeeklyCounts(entry?.score ?? user?.totalTaps ?? 0))),
                rawRewardAmounts: (entry?.isRewardEntry == true)
                    ? _getAccurateWeeklyRewardAmounts(entry!.rewardAmount ?? entry!.score.toDouble())
                    : null,
                isReward: entry?.isRewardEntry ?? false,
                currencySymbol: entry?.rewardCurrency ?? '৳',
              ),
            ],
          ),
        ),
      ),
    );
  }

  static List<double> _getAccurateWeeklyRewardAmounts(double amount) {
    final list = List<double>.filled(7, 0.0);
    if (amount <= 0) return list;
    final now = DateTime.now();
    final todayIdx = (now.weekday - 1).clamp(0, 6);
    list[todayIdx] = amount;
    return list;
  }

  static List<int> _getAccurateWeeklyCounts(int score) {
    final list = List<int>.filled(7, 0);
    if (score <= 0) return list;
    final now = DateTime.now();
    final todayIdx = (now.weekday - 1).clamp(0, 6);
    list[todayIdx] = score;
    return list;
  }
}
