import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_colors.dart';
import 'app_toast.dart';

class PayoutConfirmationSheet extends StatefulWidget {
  final double amount;
  final String method;
  final String accountName;
  final String destination;
  final CurrencyType currency;

  const PayoutConfirmationSheet({
    super.key,
    required this.amount,
    required this.method,
    required this.accountName,
    required this.destination,
    required this.currency,
  });

  static void show(
    BuildContext context, {
    required double amount,
    required String method,
    required String accountName,
    required String destination,
    required CurrencyType currency,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99000000),
      builder: (context) => PayoutConfirmationSheet(
        amount: amount,
        method: method,
        accountName: accountName,
        destination: destination,
        currency: currency,
      ),
    );
  }

  @override
  State<PayoutConfirmationSheet> createState() => _PayoutConfirmationSheetState();
}

class _PayoutConfirmationSheetState extends State<PayoutConfirmationSheet> {
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  PayoutTransaction? _completedTransaction;

  void _onConfirm() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    final wallet = context.read<WalletProvider>();
    final success = wallet.requestPayout(
      amount: widget.amount,
      method: widget.method,
      accountName: widget.accountName,
      destination: widget.destination,
    );

    if (mounted) {
      if (success) {
        final latestTx = wallet.transactions.isNotEmpty ? wallet.transactions.first : null;
        setState(() {
          _isSubmitting = false;
          _isSubmitted = true;
          _completedTransaction = latestTx;
        });
      } else {
        setState(() => _isSubmitting = false);
        AppToast.show(context, message: 'Failed to submit payout request.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = widget.currency == CurrencyType.bdt ? '৳' : '\$';
    final formattedAmount = '$currencySymbol${widget.amount.toStringAsFixed(2)}';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SafeArea(
        top: false,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Animated Status Icon (Monochrome style)
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceSubtle,
                  border: Border.all(color: AppColors.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.08),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Icon(
                  _isSubmitted ? Icons.check : Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                _isSubmitted ? 'Payout Request Submitted' : 'Confirm Payout Details',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),

              // Subtitle Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  _isSubmitted
                      ? 'Awaiting Confirmation • Processing (1–24h)'
                      : 'Please Review • Double check your info',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: 'Amount',
                      value: formattedAmount,
                      isHighlight: true,
                    ),
                    const Divider(height: 20),
                    _SummaryRow(
                      label: 'Method',
                      value: widget.method,
                    ),
                    if (widget.accountName.isNotEmpty) ...[
                      const Divider(height: 20),
                      _SummaryRow(
                        label: 'Account Name',
                        value: widget.accountName,
                      ),
                    ],
                    const Divider(height: 20),
                    _SummaryRow(
                      label: 'Recipient Account',
                      value: widget.destination,
                    ),
                    if (_isSubmitted && _completedTransaction != null) ...[
                      const Divider(height: 20),
                      _SummaryRow(
                        label: 'Transaction ID',
                        value: _completedTransaction!.id,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // CTA Button (Confirm on Step 1, Done on Step 2)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          if (_isSubmitted) {
                            Navigator.pop(context);
                          } else {
                            _onConfirm();
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
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(AppColors.ctaText),
                          ),
                        )
                      : Text(
                          _isSubmitted ? 'Done' : 'Confirm',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 16 : 14,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            color: isHighlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
