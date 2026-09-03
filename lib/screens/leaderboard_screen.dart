import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../providers/tap_engine_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_pull_to_refresh.dart';
import '../widgets/app_skeleton.dart';
import '../widgets/leaderboard_search_modal.dart';
import '../widgets/user_profile_modal.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _isUserRowVisibleOnScreen = false;
  final GlobalKey _userRowKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkUserRowVisibility();
    });
  }

  void _checkUserRowVisibility() {
    final userCtx = _userRowKey.currentContext;
    if (userCtx != null) {
      final renderBox = userCtx.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize && renderBox.attached) {
        final position = renderBox.localToGlobal(Offset.zero);
        final screenHeight = MediaQuery.of(context).size.height;
        // The user row is considered visible if it is on-screen between the header and the bottom bar area
        final isVisible = position.dy >= 60 && position.dy <= (screenHeight - 110);
        if (_isUserRowVisibleOnScreen != isVisible) {
          setState(() {
            _isUserRowVisibleOnScreen = isVisible;
          });
        }
        return;
      }
    }
    if (_isUserRowVisibleOnScreen) {
      setState(() {
        _isUserRowVisibleOnScreen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaderboard = context.watch<LeaderboardProvider>();
    final auth = context.watch<AuthProvider>();
    final tapEngine = context.watch<TapEngineProvider>();
    final numberFormatter = NumberFormat('#,###');
    final rewardFormatter = NumberFormat('#,##0.##');

    final entries = leaderboard.selectedTab == 1
        ? leaderboard.currentList.take(10).toList()
        : leaderboard.currentList;

    final isGuest = auth.currentUser.isGuest;
    final cleanUsername = auth.currentUser.username.replaceAll('@', '').toLowerCase().trim();
    final cleanName = auth.currentUser.name.replaceAll('@', '').toLowerCase().trim();

    // Check if the registered user is currently present in the active leaderboard list
    final userIndexInList = isGuest
        ? -1
        : entries.indexWhere((e) {
            final eClean = e.username.replaceAll('@', '').toLowerCase().trim();
            return eClean == cleanUsername || eClean == cleanName;
          });

    final bool userIsInList = userIndexInList != -1;

    // Calculate real rank: Guest is always #0, otherwise use official list rank or account rank
    final int displayRank;
    if (isGuest) {
      displayRank = 0;
    } else if (userIsInList) {
      displayRank = entries[userIndexInList].rank;
    } else if (auth.currentUser.rank > 0) {
      displayRank = auth.currentUser.rank;
    } else {
      int calculated = entries.length + 1;
      for (int i = 0; i < entries.length; i++) {
        if (tapEngine.score >= entries[i].score) {
          calculated = entries[i].rank;
          break;
        }
      }
      displayRank = calculated;
    }

    // Sticky bottom card is visible if the user is a guest, or if their row in the list is currently off-screen
    final bool shouldShowStickyBar =
        auth.isAuthenticated && (!userIsInList || !_isUserRowVisibleOnScreen);

    // After build cycle, verify if scroll position changed visibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkUserRowVisibility();
    });

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            _checkUserRowVisibility();
            return false;
          },
          child: AppPullToRefresh(
            onRefresh: () => leaderboard.fetchLeaderboard(silent: false),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 100, // Ample bottom padding so the last item is never hidden behind sticky bar
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header: Left Aligned Title + Right Aligned Search Icon (Opens Bottom-to-Top Modal)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Global Rankings',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          LeaderboardSearchModal.show(
                            context,
                            initialTab: leaderboard.selectedTab,
                          );
                        },
                        splashRadius: 20,
                        icon: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: const Icon(
                            Icons.search_rounded,
                            color: AppColors.primary,
                            size: 19,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Liquid / Water-drop Tab Selector (Rankers vs Rewards)
                  Container(
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderStrong, width: 1),
                    ),
                    child: Stack(
                      children: [
                        // Smooth Water-Drop Sliding Pill Indicator
                        IgnorePointer(
                          child: AnimatedAlign(
                            alignment: leaderboard.selectedTab == 0
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
                                  borderRadius: BorderRadius.circular(12),
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

                        // Interactive labels with instant tap feedback
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  if (leaderboard.selectedTab != 0) {
                                    HapticFeedback.lightImpact();
                                    leaderboard.setSelectedTab(0);
                                  }
                                },
                                child: Center(
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 220),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: leaderboard.selectedTab == 0
                                          ? AppColors.ctaText
                                          : AppColors.textMuted,
                                    ),
                                    child: const Text('Rankers'),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  if (leaderboard.selectedTab != 1) {
                                    HapticFeedback.lightImpact();
                                    leaderboard.setSelectedTab(1);
                                  }
                                },
                                child: Center(
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 220),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: leaderboard.selectedTab == 1
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
                  ),
                  const SizedBox(height: 16),

                  // 3. Dynamic Incentive Banner
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    child: !auth.isLeaderboardBannerDismissed
                        ? Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceDim,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  leaderboard.selectedTab == 0
                                      ? Icons.info_outline
                                      : Icons.verified_outlined,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        leaderboard.selectedTab == 0
                                            ? 'Cash Payout Eligibility'
                                            : 'Verified Payout Rewards',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        leaderboard.selectedTab == 0
                                            ? 'The top 10 users globally at the end of the month are eligible for cash payouts. Keep tapping.'
                                            : 'Showing top players with verified cash withdrawals. Request withdrawals anytime from the wallet.',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    auth.dismissLeaderboardBanner();
                                  },
                                  icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  splashRadius: 18,
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // 4. Leaderboard items or Skeleton Loader
                  if (leaderboard.isLoading && entries.isEmpty) ...[
                    const AppSkeletonLeaderboardList(itemCount: 6),
                  ] else ...[
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: ListView.separated(
                        key: ValueKey<int>(leaderboard.selectedTab),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: entries.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = entries[index];
                          final isTopThree = item.rank <= 3;
                          final isCurrentUserItem = userIsInList && index == userIndexInList;

                          return InkWell(
                            key: isCurrentUserItem ? _userRowKey : null,
                            onTap: () {
                              UserProfileModal.show(context, entry: item);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isCurrentUserItem
                                      ? AppColors.borderStrong
                                      : (item.username.contains('(You)')
                                          ? AppColors.borderStrong
                                          : AppColors.borderSubtle),
                                  width: isCurrentUserItem ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Rank Badge
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isTopThree ? AppColors.primary : Colors.transparent,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${item.rank}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: isTopThree
                                              ? AppColors.ctaText
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Avatar with instant initials fallback
                                  AppAvatar(
                                    imageUrl: item.avatarUrl,
                                    name: item.username,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 12),

                                  // Username & Subtitle (Level, Streak)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                item.username,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: (isCurrentUserItem || item.username.contains('(You)'))
                                                      ? AppColors.primary
                                                      : AppColors.onSurface,
                                                ),
                                              ),
                                            ),
                                            if (isCurrentUserItem) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'YOU',
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.w900,
                                                    color: AppColors.ctaText,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.isRewardEntry
                                              ? 'Lvl ${item.level} • ${item.streakDays}d streak'
                                              : 'Lvl ${item.level} • ${item.streakDays}d streak',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Score or Verified Payout Amount
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item.isRewardEntry
                                            ? '${item.rewardCurrency}${rewardFormatter.format(item.rewardAmount ?? 0)}'
                                            : numberFormatter.format(item.score),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                          fontFeatures: [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      if (item.isRewardEntry) ...[
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF22C55E)),
                                            const SizedBox(width: 3),
                                            Text(
                                              item.rewardMethod != null ? 'Paid (${item.rewardMethod})' : 'Paid',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF22C55E),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ] else ...[
                                        const Text(
                                          'Taps',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textMuted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),

        // Intelligent Sticky Bottom User Ranking Bar (Blends seamlessly with scrolling)
        Positioned(
          left: 20,
          right: 20,
          bottom: 12,
          child: AnimatedSlide(
            offset: shouldShowStickyBar ? Offset.zero : const Offset(0, 1.3),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOutCubic,
            child: AnimatedOpacity(
              opacity: shouldShowStickyBar ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: IgnorePointer(
                ignoring: !shouldShowStickyBar,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (userIsInList && _userRowKey.currentContext != null) {
                        Scrollable.ensureVisible(
                          _userRowKey.currentContext!,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                          alignment: 0.5,
                        );
                      } else {
                        UserProfileModal.show(context, user: auth.currentUser);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderStrong, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.85),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Rank Badge: #0 for Guest, #Rank for registered
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isGuest ? const Color(0xFF1E1E22) : AppColors.surfaceSubtle,
                              border: isGuest ? Border.all(color: AppColors.borderSubtle, width: 1.0) : null,
                            ),
                            child: Center(
                              child: Text(
                                '#$displayRank',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isGuest ? AppColors.textMuted : AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Avatar with initials fallback
                          AppAvatar(
                            imageUrl: auth.currentUser.avatarUrl,
                            name: auth.currentUser.name.isNotEmpty
                                ? auth.currentUser.name
                                : auth.currentUser.username,
                            size: 36,
                          ),
                          const SizedBox(width: 10),

                          // Username, Badge & Stats
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        auth.currentUser.username,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'YOU',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.ctaText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Lvl ${tapEngine.level} • ${tapEngine.dailyBonusDay}d streak',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),

                          // Score or Verified Payout Stat
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                leaderboard.selectedTab == 1
                                    ? (userIsInList && entries[userIndexInList].isRewardEntry
                                        ? '${entries[userIndexInList].rewardCurrency}${rewardFormatter.format(entries[userIndexInList].rewardAmount ?? 0)}'
                                        : '৳0')
                                    : numberFormatter.format(tapEngine.score),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                leaderboard.selectedTab == 1 ? 'Reward' : 'Taps',
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
