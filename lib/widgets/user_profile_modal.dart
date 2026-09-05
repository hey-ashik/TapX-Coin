import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/leaderboard_entry.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/tap_engine_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/haptic_service.dart';
import '../theme/app_colors.dart';
import '../utils/time_utils.dart';
import 'activity_bar_chart.dart';
import 'app_avatar.dart';

class UserProfileModal extends StatefulWidget {
  final LeaderboardEntry? entry;
  final UserModel? user;
  final int initialTab;

  const UserProfileModal({
    super.key,
    this.entry,
    this.user,
    this.initialTab = 0,
  });

  static void show(BuildContext context, {LeaderboardEntry? entry, UserModel? user, int initialTab = 0}) {
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
      builder: (context) => UserProfileModal(
        entry: entry,
        user: user,
        initialTab: (entry?.isRewardEntry == true) ? 1 : initialTab,
      ),
    );
  }

  @override
  State<UserProfileModal> createState() => _UserProfileModalState();
}

class _UserProfileModalState extends State<UserProfileModal> {
  late int _selectedTab; // 0 = Coins, 1 = Rewards

  @override
  void initState() {
    super.initState();
    _selectedTab = (widget.entry?.isRewardEntry == true) ? 1 : widget.initialTab;
  }

  Widget _buildSlidingToggle() {
    return Container(
      width: 152,
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderStrong, width: 1),
      ),
      child: Stack(
        children: [
          // Liquid sliding pill indicator
          IgnorePointer(
            child: AnimatedAlign(
              alignment: _selectedTab == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOutCubic,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Clickable Labels
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_selectedTab != 0) {
                      HapticService.lightImpact();
                      setState(() {
                        _selectedTab = 0;
                      });
                    }
                  },
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _selectedTab == 0
                            ? AppColors.ctaText
                            : AppColors.textMuted,
                      ),
                      child: const Text('Coins'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_selectedTab != 1) {
                      HapticService.lightImpact();
                      setState(() {
                        _selectedTab = 1;
                      });
                    }
                  },
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _selectedTab == 1
                            ? AppColors.ctaText
                            : AppColors.textMuted,
                      ),
                      child: const Text('Rewards'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final numberFormatter = NumberFormat.decimalPattern();
    final rewardFormatter = NumberFormat('#,##0.##');
    final tapEngine = context.watch<TapEngineProvider>();
    final wallet = context.watch<WalletProvider>();
    final auth = context.watch<AuthProvider>();

    final entry = widget.entry;
    final user = widget.user;

    final currentClean = auth.currentUser.username.replaceAll('@', '').trim().toLowerCase();
    final currentNameClean = auth.currentUser.name.replaceAll('@', '').trim().toLowerCase();
    final entryClean = (entry?.username ?? user?.username ?? '').replaceAll('@', '').trim().toLowerCase();

    final isCurrentPlayer = (user != null && user.id == auth.currentUser.id) || 
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
        : (isCurrentPlayer ? tapEngine.activeStreakDays : (entry?.streakDays ?? user?.streakDays ?? 1));
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
              const SizedBox(height: 16),

              // Modal Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      HapticService.lightImpact();
                      Navigator.pop(context);
                    },
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

              // Sliding toggle positioned on top right below the 3 dots
              Padding(
                padding: const EdgeInsets.only(right: 6, top: 2, bottom: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _buildSlidingToggle(),
                ),
              ),

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

              // Animated Transition for Coins vs Rewards profile views
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                reverseDuration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final isRewards = child.key == const ValueKey('profile_rewards_view');
                  final inOffset = isRewards
                      ? const Offset(0.25, 0.0)
                      : const Offset(-0.25, 0.0);
                  final slideAnimation = Tween<Offset>(
                    begin: inOffset,
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  );
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    ),
                    child: SlideTransition(
                      position: slideAnimation,
                      child: child,
                    ),
                  );
                },
                child: _selectedTab == 0
                    ? _buildCoinsView(
                        key: const ValueKey('profile_coins_view'),
                        context: context,
                        numberFormatter: numberFormatter,
                        totalTaps: totalTaps,
                        streakDays: streakDays,
                        activityRates: activityRates,
                        isCurrentPlayer: isCurrentPlayer,
                        weeklyTaps: tapEngine.weeklyTaps,
                        rawWeeklyTaps: entry?.rawWeeklyTaps,
                        score: entry?.score ?? user?.totalTaps ?? 0,
                      )
                    : _buildRewardsView(
                        key: const ValueKey('profile_rewards_view'),
                        context: context,
                        rewardFormatter: rewardFormatter,
                        entry: entry,
                        isCurrentPlayer: isCurrentPlayer,
                        walletBalance: wallet.balance,
                        walletCurrencySymbol: wallet.currencySymbol,
                        walletTransactions: wallet.transactions,
                        score: entry?.score ?? user?.totalTaps ?? 0,
                        streakDays: streakDays,
                        activityRates: activityRates,
                        weeklyTaps: tapEngine.weeklyTaps,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoinsView({
    required Key key,
    required BuildContext context,
    required NumberFormat numberFormatter,
    required int totalTaps,
    required int streakDays,
    required List<double> activityRates,
    required bool isCurrentPlayer,
    required List<int> weeklyTaps,
    required List<int>? rawWeeklyTaps,
    required int score,
  }) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
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
                      'TOTAL COINS',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      numberFormatter.format(totalTaps),
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
          rawTapCounts: isCurrentPlayer
              ? weeklyTaps
              : (rawWeeklyTaps ?? _getAccurateWeeklyCounts(score)),
          rawRewardAmounts: null,
          isReward: false,
          currencySymbol: '৳',
        ),
      ],
    );
  }

  Widget _buildRewardsView({
    required Key key,
    required BuildContext context,
    required NumberFormat rewardFormatter,
    required LeaderboardEntry? entry,
    required bool isCurrentPlayer,
    required double walletBalance,
    required String walletCurrencySymbol,
    required List<dynamic> walletTransactions,
    required int score,
    required int streakDays,
    required List<double> activityRates,
    required List<int> weeklyTaps,
  }) {
    final String rewardCurrency = entry?.rewardCurrency ?? (isCurrentPlayer ? walletCurrencySymbol : '৳');
    
    // TOTAL REWARD: Strictly shows money received from completed/approved withdrawals (in BDT ৳)
    double totalWithdrawnMoney = 0.0;
    if (isCurrentPlayer) {
      for (final tx in walletTransactions) {
        final statusStr = tx.status.toString().toLowerCase();
        if (statusStr.contains('completed') || statusStr.contains('approved') || statusStr.contains('paid')) {
          totalWithdrawnMoney += (tx.amount as num).toDouble();
        }
      }
    }

    final double rewardVal = (entry?.rewardAmount != null)
        ? entry!.rewardAmount!
        : (isCurrentPlayer ? totalWithdrawnMoney : 0.0);

    // PAYOUT STATUS: Shows payment method from last payout (e.g. "bKash (Paid)" or "Nagad")
    String? latestMethod;
    bool isLatestPaid = false;

    if (entry?.rewardMethod != null && entry!.rewardMethod!.isNotEmpty) {
      latestMethod = entry.rewardMethod;
      isLatestPaid = true;
    } else if (isCurrentPlayer && walletTransactions.isNotEmpty) {
      final tx = walletTransactions.first;
      final method = tx.method.toString().trim();
      final statusStr = tx.status.toString().toLowerCase();
      isLatestPaid = statusStr.contains('completed') || statusStr.contains('paid') || statusStr.contains('approved');
      final isProcessing = statusStr.contains('processing') || statusStr.contains('pending');

      if (isLatestPaid) {
        latestMethod = '$method (Paid)';
      } else if (isProcessing) {
        latestMethod = '$method (Pending)';
      } else {
        latestMethod = method;
      }
    }

    final bool hasPayout = latestMethod != null && latestMethod.isNotEmpty;
    final String payoutText = hasPayout ? latestMethod : 'Day $streakDays';

    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
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
                      'TOTAL REWARD',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$rewardCurrency${rewardFormatter.format(rewardVal)}',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            letterSpacing: -0.5,
                            fontSize: 22,
                            color: const Color(0xFF22C55E),
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
                      hasPayout ? 'PAYOUT STATUS' : 'CURRENT STREAK',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (hasPayout) ...[
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF22C55E),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            payoutText,
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  letterSpacing: -0.5,
                                  fontSize: hasPayout ? 15 : 20,
                                  color: hasPayout ? const Color(0xFF22C55E) : null,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!hasPayout) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.local_fire_department,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 7-Day Rewards Chart
        ActivityBarChart(
          activityRates: activityRates,
          rawTapCounts: null,
          rawRewardAmounts: isCurrentPlayer
              ? weeklyTaps.map((c) => (c / 1000.0)).toList()
              : (entry?.isRewardEntry == true
                  ? _getAccurateWeeklyRewardAmounts(entry!.rewardAmount ?? entry.score.toDouble())
                  : _getAccurateWeeklyRewardAmounts(score / 1000.0)),
          isReward: true,
          currencySymbol: rewardCurrency,
        ),
      ],
    );
  }

  static List<double> _getAccurateWeeklyRewardAmounts(double amount) {
    final list = List<double>.filled(7, 0.0);
    if (amount <= 0) return list;
    final todayIdx = TimeUtils.currentWeekdayIndex();
    list[todayIdx] = amount;
    return list;
  }

  static List<int> _getAccurateWeeklyCounts(int score) {
    final list = List<int>.filled(7, 0);
    if (score <= 0) return list;
    final todayIdx = TimeUtils.currentWeekdayIndex();
    list[todayIdx] = (score / 7).round();
    return list;
  }
}
