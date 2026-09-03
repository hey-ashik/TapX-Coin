import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_update_info.dart';
import '../theme/app_colors.dart';
import 'app_toast.dart';

class UpdateDialogModal extends StatelessWidget {
  final AppUpdateInfo updateInfo;

  const UpdateDialogModal({
    super.key,
    required this.updateInfo,
  });

  static Future<void> show(BuildContext context, AppUpdateInfo updateInfo) async {
    await showModalBottomSheet(
      context: context,
      isDismissible: !updateInfo.isForceUpdate,
      enableDrag: !updateInfo.isForceUpdate,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99000000),
      builder: (context) => PopScope(
        canPop: !updateInfo.isForceUpdate,
        child: UpdateDialogModal(updateInfo: updateInfo),
      ),
    );
  }

  Future<void> _launchUpdateUrl(BuildContext context) async {
    if (updateInfo.apkUrl.isEmpty) {
      AppToast.show(context, message: 'Download URL not configured.', isError: true);
      return;
    }

    final uri = Uri.parse(updateInfo.apkUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        AppToast.show(context, message: 'Could not open ${updateInfo.apkUrl}', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: AppColors.borderStrong, width: 1.5),
        ),
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Handle bar (only if not forced)
            if (!updateInfo.isForceUpdate)
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

            // Icon Badge
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceCard,
                border: Border.all(color: AppColors.borderStrong, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.08),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.rocket_launch_rounded,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title & Version
            Text(
              'New Update Available',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                'v${updateInfo.latestVersion} (Current: v${updateInfo.currentVersion})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Release Notes Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.auto_awesome, size: 16, color: AppColors.textMuted),
                      SizedBox(width: 8),
                      Text(
                        'What\'s New',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    updateInfo.releaseNotes.isEmpty
                        ? '• Performance improvements and bug fixes.'
                        : updateInfo.releaseNotes,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Update CTA Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _launchUpdateUrl(context),
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
                    Icon(Icons.download_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Update Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Later button (if not mandatory)
            if (!updateInfo.isForceUpdate) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Later',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 14),
              const Text(
                'This is a required update to continue tapping.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
