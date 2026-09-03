import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_pull_to_refresh.dart';
import '../widgets/withdrawal_modal.dart';

class WithdrawalsScreen extends StatefulWidget {
  const WithdrawalsScreen({super.key});

  @override
  State<WithdrawalsScreen> createState() => _WithdrawalsScreenState();
}

class _WithdrawalsScreenState extends State<WithdrawalsScreen> {
  void _showGuestWithdrawalNotice(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99000000),
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: const Border(top: BorderSide(color: AppColors.borderStrong, width: 1.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.9),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceSubtle,
                border: Border.all(color: AppColors.borderStrong),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Guest Account Notice',
              style: Theme.of(ctx).textTheme.headlineMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Guest rewards can’t be withdrawn.\nCreate an account to unlock withdrawals.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<AuthProvider>().logout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.ctaText,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create Free Account',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
                child: const Text(
                  'Continue Playing',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final numberFormatter = NumberFormat('#,##0.00');
    final dateFormatter = DateFormat('MMM dd, yyyy');

    return AppPullToRefresh(
      onRefresh: () => wallet.fetchTransactions(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Currency Switcher Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Rewards',
                style: Theme.of(context).textTheme.headlineMedium,
              ),

              // Sleek liquid smooth currency selector with real-time responsive touch
              Container(
                width: 148,
                height: 38,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderStrong, width: 1),
                ),
                child: Stack(
                  children: [
                    // Liquid sliding pill indicator (IgnorePointer so it never intercepts touch)
                    IgnorePointer(
                      child: AnimatedAlign(
                        alignment: wallet.currency == CurrencyType.bdt
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

                    // Labels with guaranteed instant tap response
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (wallet.currency != CurrencyType.bdt) {
                                HapticFeedback.lightImpact();
                                wallet.setCurrency(CurrencyType.bdt);
                                setState(() {});
                              }
                            },
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 220),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: wallet.currency == CurrencyType.bdt
                                      ? AppColors.ctaText
                                      : AppColors.textMuted,
                                ),
                                child: const Text('৳ BDT'),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (wallet.currency != CurrencyType.usd) {
                                HapticFeedback.lightImpact();
                                wallet.setCurrency(CurrencyType.usd);
                                setState(() {});
                              }
                            },
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 220),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: wallet.currency == CurrencyType.usd
                                      ? AppColors.ctaText
                                      : AppColors.textMuted,
                                ),
                                child: const Text('\$ USD'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Balance Hero Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'BALANCE',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${wallet.currencySymbol}${numberFormatter.format(wallet.balance)}',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 44,
                        letterSpacing: -1.5,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),

                // Rate badge (10,000 taps = 10 BDT)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderStrong),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info, color: AppColors.textMuted, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        wallet.conversionRateText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Progress to milestone
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${wallet.currencySymbol}${wallet.milestoneTarget.toInt()} Milestone',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '${(wallet.milestoneProgress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: wallet.milestoneProgress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceSubtle,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),

          // Payout Milestones Grid
          Text(
            'Milestones',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 17,
                ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            childAspectRatio: 1.35,
            physics: const NeverScrollableScrollPhysics(),
            children: wallet.currency == CurrencyType.bdt
                ? [
                    _MilestoneCard(
                      amount: '৳50',
                      tapsRequired: '50,000 taps',
                      isUnlocked: wallet.isTierUnlocked(50.0),
                    ),
                    _MilestoneCard(
                      amount: '৳100',
                      tapsRequired: '100,000 taps',
                      isUnlocked: wallet.isTierUnlocked(100.0),
                    ),
                    _MilestoneCard(
                      amount: '৳250',
                      tapsRequired: '250,000 taps',
                      isUnlocked: wallet.isTierUnlocked(250.0),
                    ),
                    _MilestoneCard(
                      amount: '৳500',
                      tapsRequired: '500,000 taps',
                      isUnlocked: wallet.isTierUnlocked(500.0),
                    ),
                  ]
                : [
                    _MilestoneCard(
                      amount: '\$5',
                      tapsRequired: '50,000 taps',
                      isUnlocked: wallet.isTierUnlocked(5.0),
                    ),
                    _MilestoneCard(
                      amount: '\$10',
                      tapsRequired: '100,000 taps',
                      isUnlocked: wallet.isTierUnlocked(10.0),
                    ),
                    _MilestoneCard(
                      amount: '\$25',
                      tapsRequired: '250,000 taps',
                      isUnlocked: wallet.isTierUnlocked(25.0),
                    ),
                    _MilestoneCard(
                      amount: '\$50',
                      tapsRequired: '500,000 taps',
                      isUnlocked: wallet.isTierUnlocked(50.0),
                    ),
                  ],
          ),
          const SizedBox(height: 24),

          // Request Payout CTA
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                final auth = context.read<AuthProvider>();
                if (auth.currentUser.isGuest) {
                  _showGuestWithdrawalNotice(context);
                } else {
                  WithdrawalModal.show(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.ctaText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.account_balance_wallet_outlined, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Withdrawal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Recent Payout Transactions
          Text(
            'History',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 17,
                ),
          ),
          const SizedBox(height: 12),
          if (wallet.transactions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 32,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No payout history yet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Reach 50,000 taps (৳50) to make your first withdrawal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: wallet.transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final tx = wallet.transactions[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: const Icon(
                          Icons.arrow_upward,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.method,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${tx.destination} • ${dateFormatter.format(tx.timestamp)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '-${tx.formattedAmount}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tx.status == TransactionStatus.completed
                                ? 'Completed'
                                : (tx.status == TransactionStatus.rejected ? 'Rejected' : 'Processing'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: tx.status == TransactionStatus.completed
                                  ? AppColors.success
                                  : (tx.status == TransactionStatus.rejected
                                      ? AppColors.error
                                      : AppColors.accentGold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final String amount;
  final String tapsRequired;
  final bool isUnlocked;

  const _MilestoneCard({
    required this.amount,
    required this.tapsRequired,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? AppColors.surfaceCard : AppColors.surfaceSubtle.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnlocked ? AppColors.borderStrong : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                isUnlocked ? Icons.lock_open : Icons.lock_outline,
                size: 20,
                color: isUnlocked ? AppColors.primary : AppColors.textMuted,
              ),
              if (isUnlocked)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white,
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isUnlocked ? AppColors.primary : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tapsRequired,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
