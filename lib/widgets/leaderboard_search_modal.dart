import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/leaderboard_provider.dart';
import '../theme/app_colors.dart';
import 'app_avatar.dart';
import 'app_skeleton.dart';
import 'user_profile_modal.dart';

class LeaderboardSearchModal extends StatefulWidget {
  final int initialTab;

  const LeaderboardSearchModal({super.key, this.initialTab = 0});

  static void show(BuildContext context, {int initialTab = 0}) {
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
      builder: (context) => LeaderboardSearchModal(initialTab: initialTab),
    );
  }

  @override
  State<LeaderboardSearchModal> createState() => _LeaderboardSearchModalState();
}

class _LeaderboardSearchModalState extends State<LeaderboardSearchModal> {
  late int _activeTab;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  Timer? _debounce;
  bool _isDebouncing = false;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _focusNode.addListener(_onFocusChange);
    // Request focus smoothly once the bottom-to-top sheet animation settles
    // so virtual keyboard and layout recalculations do not interrupt the smooth entrance
    Future.delayed(const Duration(milliseconds: 360), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    setState(() {
      _isDebouncing = true;
    });
    _debounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() {
        _query = text.trim().toLowerCase();
        _isDebouncing = false;
      });
    });
  }

  String _formatCurrency(String currency) {
    final c = currency.trim().toUpperCase();
    if (c == 'USD' || c == r'$') return r'$';
    return '৳';
  }

  @override
  Widget build(BuildContext context) {
    final leaderboard = context.watch<LeaderboardProvider>();
    final numberFormatter = NumberFormat('#,###');
    final rewardFormatter = NumberFormat('#,##0.##');

    // Filter based on active tab in search modal
    final sourceList = _activeTab == 0
        ? leaderboard.globalEntriesList
        : leaderboard.rewardEntriesList;

    final filteredList = _query.isEmpty
        ? sourceList
        : sourceList.where((e) {
            final u = e.username.toLowerCase();
            return u.contains(_query);
          }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 16 * (1.0 - value)),
              child: child,
            ),
          );
        },
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: const Border(
            top: BorderSide(color: AppColors.borderStrong, width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.95),
              blurRadius: 36,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(top: 14, bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 2. Modal Header with Close Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Search Players',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                    ),
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      icon: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. Search Input Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _focusNode.hasFocus
                          ? AppColors.primary.withValues(alpha: 0.6)
                          : AppColors.borderStrong,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          style: const TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: _activeTab == 0
                                ? 'Search rankers by username...'
                                : 'Search rewards by username...',
                            hintStyle: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            filled: false,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _query = '';
                            });
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 4. Liquid Sliding Tab Selector (Rankers vs Rewards)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Stack(
                    children: [
                      // Smooth Liquid Sliding Pill Indicator
                      IgnorePointer(
                        child: AnimatedAlign(
                          alignment: _activeTab == 0 ? Alignment.centerLeft : Alignment.centerRight,
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeInOutCubic,
                          child: FractionallySizedBox(
                            widthFactor: 0.5,
                            heightFactor: 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
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

                      // Interactive labels
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (_activeTab != 0) {
                                  HapticFeedback.lightImpact();
                                  setState(() => _activeTab = 0);
                                }
                              },
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 220),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _activeTab == 0 ? AppColors.ctaText : AppColors.textMuted,
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
                                if (_activeTab != 1) {
                                  HapticFeedback.lightImpact();
                                  setState(() => _activeTab = 1);
                                }
                              },
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 220),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _activeTab == 1 ? AppColors.ctaText : AppColors.textMuted,
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
              ),
              const SizedBox(height: 12),

              // 5. Results Count or Debouncing Skeleton
              Expanded(
                child: _isDebouncing
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: AppSkeletonLeaderboardList(itemCount: 5),
                      )
                    : filteredList.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 44,
                                    color: AppColors.textMuted.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No ${_activeTab == 0 ? "rankers" : "rewards"} found',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _query.isNotEmpty
                                        ? 'No players matching "$_query"'
                                        : 'No entries available in this category',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: filteredList.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = filteredList[index];
                              final isTopThree = item.rank <= 3;
                              final currencySymbol = _formatCurrency(item.rewardCurrency);

                              return InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  UserProfileModal.show(context, entry: item);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceCard,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.borderSubtle),
                                  ),
                                  child: Row(
                                    children: [
                                      // Rank Badge
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isTopThree ? AppColors.primary : Colors.transparent,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${item.rank}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: isTopThree ? AppColors.ctaText : AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // Avatar
                                      AppAvatar(
                                        imageUrl: item.avatarUrl,
                                        name: item.username,
                                        size: 38,
                                      ),
                                      const SizedBox(width: 10),

                                      // Name & Stats
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.username,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.isRewardEntry
                                                  ? 'Lvl ${item.level} • ${item.streakDays}d streak'
                                                  : 'Lvl ${item.level} • ${item.streakDays}d streak',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Score or Payout Amount
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            item.isRewardEntry
                                                ? '$currencySymbol${rewardFormatter.format(item.rewardAmount ?? item.score)}'
                                                : numberFormatter.format(item.score),
                                            style: const TextStyle(
                                              fontSize: 15,
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
                                              'Coins',
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
          ),
        ),
      ),
    ),
  );
}
}
