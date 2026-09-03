import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tap_engine_provider.dart';
import '../theme/app_colors.dart';
import 'app_toast.dart';

class DailyBonusModal extends StatefulWidget {
  const DailyBonusModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99000000),
      builder: (context) => const DailyBonusModal(),
    );
  }

  @override
  State<DailyBonusModal> createState() => _DailyBonusModalState();
}

class _DailyBonusModalState extends State<DailyBonusModal> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Progressive bar height targets (scaled to avoid any overflow)
  static double _getBarHeight(int day) {
    switch (day) {
      case 1:
        return 32.0;
      case 2:
        return 44.0;
      case 3:
        return 58.0;
      case 4:
        return 72.0;
      case 5:
        return 86.0;
      case 6:
        return 100.0;
      case 7:
        return 116.0;
      default:
        return 36.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tapEngine = context.watch<TapEngineProvider>();
    final currentDay = tapEngine.dailyBonusDay;
    final isClaimed = tapEngine.isDailyBonusClaimed;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: const Border(top: BorderSide(color: AppColors.borderStrong, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.95),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title & Subtitle
              Text(
                'Streak Bonus',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Claim your daily bonus every day to build your streak.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
              ),
              const SizedBox(height: 18),

              // 7-Day Vertical Bar Chart Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Bar Chart Top Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bar_chart_rounded, size: 16, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            const Text(
                              '7-DAY PROGRESSION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMuted,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.trending_up, size: 12, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                '2x Daily',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Animated 7-Day Bar Chart Row (Height 175px completely prevents overflow)
                    SizedBox(
                      height: 175,
                      child: AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(7, (index) {
                              final day = index + 1;
                              final amount = TapEngineProvider.getBonusAmountForDay(day);
                              final isPast = day < currentDay;
                              final isCurrent = day == currentDay;
                              final isDayClaimed = isPast || (isCurrent && isClaimed);
                              final targetHeight = _getBarHeight(day);

                              // Staggered wave animation for opening
                              final curveProgress = CurvedAnimation(
                                parent: _animController,
                                curve: Interval(
                                  (index * 0.07).clamp(0.0, 0.6),
                                  (0.45 + index * 0.08).clamp(0.0, 1.0),
                                  curve: Curves.easeOutCubic,
                                ),
                              ).value;

                              final animatedHeight = (targetHeight * curveProgress).clamp(4.0, targetHeight);

                              return Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // 1. Reward Value Label at Top of Bar
                                    Opacity(
                                      opacity: curveProgress.clamp(0.0, 1.0),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '+$amount',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                                            color: isCurrent
                                                ? AppColors.primary
                                                : (isDayClaimed ? AppColors.textMuted : AppColors.textSecondary),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // 2. Slender, Ultra-Premium Bar Pillar (Narrow width: 22px)
                                    Container(
                                      height: animatedHeight,
                                      width: isCurrent ? 24.0 : 20.0,
                                      decoration: BoxDecoration(
                                        color: isCurrent
                                            ? (isClaimed ? AppColors.surfaceSubtle : Colors.white)
                                            : (isDayClaimed
                                                ? AppColors.surfaceSubtle.withValues(alpha: 0.7)
                                                : AppColors.surfaceSubtle.withValues(alpha: 0.3)),
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(7),
                                          bottom: Radius.circular(3),
                                        ),
                                        border: Border.all(
                                          color: isCurrent
                                              ? (isClaimed ? AppColors.primary : Colors.white)
                                              : (isDayClaimed ? AppColors.borderStrong : AppColors.borderSubtle),
                                          width: isCurrent ? 1.5 : 1.0,
                                        ),
                                        boxShadow: isCurrent && !isClaimed
                                            ? [
                                                BoxShadow(
                                                  color: Colors.white.withValues(alpha: 0.35),
                                                  blurRadius: 10,
                                                  spreadRadius: 1,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: animatedHeight > 24
                                          ? Center(
                                              child: isDayClaimed
                                                  ? const Icon(
                                                      Icons.check_rounded,
                                                      size: 12,
                                                      color: Color(0xFF22C55E),
                                                    )
                                                  : (isCurrent
                                                      ? const Icon(
                                                          Icons.bolt_rounded,
                                                          size: 14,
                                                          color: Colors.black,
                                                        )
                                                      : (day == 7
                                                          ? const Icon(
                                                              Icons.star_rounded,
                                                              size: 11,
                                                              color: AppColors.textMuted,
                                                            )
                                                          : Icon(
                                                              Icons.lock_outline_rounded,
                                                              size: 10,
                                                              color: AppColors.textMuted.withValues(alpha: 0.4),
                                                            ))),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(height: 8),

                                    // 3. Bottom Day Label
                                    Text(
                                      'D$day',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                                        color: isCurrent
                                            ? AppColors.primary
                                            : (isDayClaimed ? AppColors.textMuted : AppColors.textSecondary),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    if (isCurrent) ...[
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ] else ...[
                                      const SizedBox(height: 4),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Today's Reward Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isClaimed ? const Color(0xFF22C55E) : AppColors.borderStrong,
                        ),
                      ),
                      child: Icon(
                        isClaimed ? Icons.check_circle_rounded : Icons.bolt_rounded,
                        color: isClaimed ? const Color(0xFF22C55E) : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isClaimed
                                ? 'Day $currentDay Claimed (+${tapEngine.currentDayBonusAmount} Coins)'
                                : 'Today\'s Reward: +${tapEngine.currentDayBonusAmount} Coins',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isClaimed
                                ? 'Next: +${tapEngine.nextDayBonusAmount} Coins • Unlocks in ${tapEngine.timeUntilReset}'
                                : 'Day $currentDay of 7 Streak • Redeem before midnight',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Claim CTA Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isClaimed
                      ? null
                      : () {
                          final claimedAmount = tapEngine.currentDayBonusAmount;
                          tapEngine.claimDailyBonus();
                          Navigator.pop(context);
                          AppToast.show(
                            context,
                            message: 'Claimed +$claimedAmount Coins! Streak active for today.',
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.ctaText,
                    disabledBackgroundColor: AppColors.surfaceSubtle,
                    disabledForegroundColor: AppColors.textMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isClaimed
                        ? 'Claimed for Today (${tapEngine.timeUntilReset} left)'
                        : 'Claim +${tapEngine.currentDayBonusAmount} Coins',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Close TextButton
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
