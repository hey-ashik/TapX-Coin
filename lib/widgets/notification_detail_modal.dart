import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../theme/app_colors.dart';

class NotificationDetailModal extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onDelete;

  const NotificationDetailModal({
    super.key,
    required this.notification,
    this.onDelete,
  });

  static void show(
    BuildContext context, {
    required AppNotification notification,
    VoidCallback? onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99000000),
      builder: (context) => NotificationDetailModal(
        notification: notification,
        onDelete: onDelete,
      ),
    );
  }

  IconData _getIconForType(String type, [String title = '']) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('update') || lowerTitle.contains('version') || type == 'update') {
      return Icons.system_update_rounded;
    }
    switch (type) {
      case 'payout_completed':
        return Icons.verified_rounded;
      case 'payout_rejected':
        return Icons.error_outline_rounded;
      case 'announcement':
        return Icons.campaign_rounded;
      case 'bonus':
      case 'reward':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  String _getTypeLabel(String type, [String title = '']) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('update') || lowerTitle.contains('version') || type == 'update') {
      return 'App Update';
    }
    switch (type) {
      case 'payout_completed':
        return 'Payout Confirmed';
      case 'payout_rejected':
        return 'Payout Notice';
      case 'announcement':
        return 'Global Announcement';
      case 'bonus':
      case 'reward':
        return 'Bonus Reward';
      default:
        return 'System Notification';
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getIconForType(notification.type, notification.title);
    final typeLabel = _getTypeLabel(notification.type, notification.title);
    final timeStr = DateFormat('EEEE, MMMM d, y • h:mm a').format(notification.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: const Border(
          top: BorderSide(color: AppColors.borderStrong, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.95),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Top Bar with Monochrome Type Badge & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          typeLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Large Title
              Text(
                notification.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      height: 1.25,
                    ),
              ),
              const SizedBox(height: 8),

              // Timestamp
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 5),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Message Body Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  notification.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.5,
                    letterSpacing: 0.2,
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
