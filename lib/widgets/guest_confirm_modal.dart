import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GuestConfirmModal extends StatelessWidget {
  final VoidCallback onConfirmGuest;
  final VoidCallback onSwitchToRegister;

  const GuestConfirmModal({
    super.key,
    required this.onConfirmGuest,
    required this.onSwitchToRegister,
  });

  static void show(
    BuildContext context, {
    required VoidCallback onConfirmGuest,
    required VoidCallback onSwitchToRegister,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99000000),
      isScrollControlled: true,
      builder: (context) => GuestConfirmModal(
        onConfirmGuest: onConfirmGuest,
        onSwitchToRegister: onSwitchToRegister,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag Handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Icon Badge (Monochrome)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceSubtle,
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: const Icon(
              Icons.sports_esports_outlined,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Guest Account',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),

          const Text(
            'Explore Guest Mode with demo coins.\nWithdrawals are available after creating an account.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Button 1: Create Account
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onSwitchToRegister();
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
                    'Create Account',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Button 2: Continue as Guest
          SizedBox(
            width: double.infinity,
            height: 46,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onConfirmGuest();
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              child: const Text(
                'Continue as Guest',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
