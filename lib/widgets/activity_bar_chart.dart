import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ActivityBarChart extends StatelessWidget {
  final List<double> activityRates; // 7 normalized values (0.0 to 1.0)
  final List<int>? rawTapCounts;    // 7 actual integer tap counts
  final List<double>? rawRewardAmounts; // 7 actual double reward amounts
  final bool isReward;
  final String currencySymbol;

  const ActivityBarChart({
    super.key,
    this.activityRates = const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    this.rawTapCounts,
    this.rawRewardAmounts,
    this.isReward = false,
    this.currencySymbol = '৳',
  });

  static const List<String> weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    // Find the peak value index
    int peakIndex = 0;
    double maxAmount = 0.0;
    int maxCount = 0;

    if (isReward && rawRewardAmounts != null && rawRewardAmounts!.isNotEmpty) {
      for (int i = 0; i < rawRewardAmounts!.length; i++) {
        if (rawRewardAmounts![i] > maxAmount) {
          maxAmount = rawRewardAmounts![i];
          peakIndex = i;
        }
      }
    } else if (rawTapCounts != null && rawTapCounts!.isNotEmpty) {
      for (int i = 0; i < rawTapCounts!.length; i++) {
        if (rawTapCounts![i] > maxCount) {
          maxCount = rawTapCounts![i];
          peakIndex = i;
        }
      }
    } else {
      double maxRate = 0.0;
      for (int i = 0; i < activityRates.length; i++) {
        if (activityRates[i] > maxRate) {
          maxRate = activityRates[i];
          peakIndex = i;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '7-Day Activity',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  isReward ? '$currencySymbol Payout' : 'This Week',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 170,
            child: Stack(
              children: [
                // Horizontal grid lines
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    4,
                    (_) => Container(
                      height: 1,
                      color: AppColors.borderSubtle.withValues(alpha: 0.5),
                    ),
                  ),
                ),

                // Bars row with real digits / currency on top
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (index) {
                      final rewardAmt = (isReward && rawRewardAmounts != null && index < rawRewardAmounts!.length)
                          ? rawRewardAmounts![index]
                          : 0.0;
                      final count = (rawTapCounts != null && index < rawTapCounts!.length)
                          ? rawTapCounts![index]
                          : 0;
                      
                      final double rate;
                      if (isReward && maxAmount > 0) {
                        rate = (rewardAmt / maxAmount).clamp(0.0, 1.0);
                      } else if (maxCount > 0) {
                        rate = (count / maxCount).clamp(0.0, 1.0);
                      } else {
                        rate = index < activityRates.length ? activityRates[index] : 0.0;
                      }

                      final bool hasActivity = isReward ? rewardAmt > 0 : (count > 0 || rate > 0);
                      final isPeak = index == peakIndex && hasActivity;

                      String displayDigit;
                      if (isReward) {
                        if (rewardAmt > 0) {
                          final formattedAmt = rewardAmt % 1 == 0
                              ? rewardAmt.toInt().toString()
                              : rewardAmt.toStringAsFixed(2);
                          displayDigit = '$currencySymbol$formattedAmt';
                        } else {
                          displayDigit = '0';
                        }
                      } else {
                        displayDigit = rawTapCounts != null
                            ? '$count'
                            : (rate > 0 ? '${(rate * 100).toInt()}' : '0');
                      }

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Real digit / currency symbol on top of the bar
                              SizedBox(
                                height: 16,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    displayDigit,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isPeak ? FontWeight.w800 : FontWeight.w600,
                                      color: isPeak ? AppColors.primary : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Animated Bar
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: hasActivity ? rate.clamp(0.08, 1.0) : 0.04),
                                duration: Duration(milliseconds: 500 + (index * 60)),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Container(
                                    height: (100 * value).clamp(4.0, 100.0),
                                    decoration: BoxDecoration(
                                      color: isPeak
                                          ? AppColors.primary
                                          : (hasActivity
                                              ? AppColors.primary.withValues(alpha: 0.75)
                                              : AppColors.surfaceSubtle),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                      boxShadow: isPeak
                                          ? [
                                              BoxShadow(
                                                color: Colors.white.withValues(alpha: 0.35),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                              )
                                            ]
                                          : null,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                weekdays[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isPeak ? FontWeight.w700 : FontWeight.w500,
                                  color: isPeak ? AppColors.primary : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
