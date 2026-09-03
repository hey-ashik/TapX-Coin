import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/haptic_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import 'app_skeleton.dart';
import 'app_toast.dart';
import 'notification_detail_modal.dart';

class NotificationModal extends StatefulWidget {
  const NotificationModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99000000),
      builder: (context) => const NotificationModal(),
    );
  }

  @override
  State<NotificationModal> createState() => _NotificationModalState();
}

class _NotificationModalState extends State<NotificationModal> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final res = await ApiService.getNotifications();
    if (res['success'] == true && res['data']?['notifications'] is List) {
      final list = (res['data']['notifications'] as List)
          .map((n) => AppNotification.fromJson(n))
          .toList();
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
      NotificationService.checkForNewAnnouncements();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    HapticService.lightImpact();
    await ApiService.markNotificationRead();
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
    if (mounted) {
      AppToast.show(context, message: 'All notifications marked as read');
    }
  }

  void _deleteNotification(AppNotification notif) {
    HapticService.lightImpact();
    final auth = context.read<AuthProvider>();
    auth.dismissNotification(notif.id);
    setState(() {
      _notifications.removeWhere((n) => n.id == notif.id);
    });
    ApiService.deleteNotification(notif.id);
    AppToast.show(context, message: 'Notification removed');
  }

  void _openNotificationDetail(AppNotification notif) {
    HapticService.lightImpact();
    if (!notif.isRead) {
      ApiService.markNotificationRead(notif.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notif.id);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
        }
      });
    }

    NotificationDetailModal.show(
      context,
      notification: notif,
      onDelete: () => _deleteNotification(notif),
    );
  }

  void _confirmDeleteDialog(AppNotification notif) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        title: const Text(
          'Delete Notification',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.primary),
        ),
        content: Text(
          'Are you sure you want to remove "${notif.title}"?',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteNotification(notif);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
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
        return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final visibleNotifications = _notifications
        .where((n) => !auth.isNotificationDismissed(n.id))
        .toList();
    final unreadCount = visibleNotifications.where((n) => !n.isRead).length;

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
      padding: const EdgeInsets.only(left: 20, right: 20, top: 14, bottom: 28),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unreadCount NEW',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ctaText,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (visibleNotifications.isNotEmpty)
                  TextButton(
                    onPressed: _markAllRead,
                    child: const Text(
                      'Mark All Read',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Tip banner (Dismissible with cross button & smooth AnimatedSize collapse, persisted per session)
            if (visibleNotifications.isNotEmpty)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: !auth.isNotificationTipBannerDismissed
                    ? Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.swipe_left_rounded, size: 16, color: AppColors.textMuted),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Swipe left or tap ✕ to delete • Tap to view full notice',
                                style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                auth.dismissNotificationTipBanner();
                              },
                              icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              splashRadius: 16,
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

            // Content
            Expanded(
              child: _isLoading
                  ? const SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: AppSkeletonNotificationList(itemCount: 4),
                    )
                  : visibleNotifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_off_outlined,
                                size: 48,
                                color: AppColors.textMuted.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No notifications yet',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Withdrawal confirmations and announcements will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: visibleNotifications.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final notif = visibleNotifications[index];
                            final icon = _getIconForType(notif.type, notif.title);
                            final timeStr = DateFormat('MMM d, h:mm a').format(notif.createdAt);

                            return Dismissible(
                              key: ValueKey('notif_${notif.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: const [
                                    Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onDismissed: (_) {
                                _deleteNotification(notif);
                              },
                              child: InkWell(
                                onTap: () => _openNotificationDetail(notif),
                                onLongPress: () => _confirmDeleteDialog(notif),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: notif.isRead
                                        ? AppColors.surfaceSubtle.withValues(alpha: 0.4)
                                        : AppColors.surfaceCard,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: notif.isRead ? AppColors.borderSubtle : AppColors.borderStrong,
                                      width: notif.isRead ? 1.0 : 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.surfaceSubtle,
                                          border: Border.all(
                                            color: AppColors.borderSubtle,
                                          ),
                                        ),
                                        child: Icon(icon, size: 18, color: AppColors.primary),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    notif.title,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                                if (!notif.isRead) ...[
                                                  Container(
                                                    width: 7,
                                                    height: 7,
                                                    margin: const EdgeInsets.only(right: 8),
                                                    decoration: const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ],
                                                SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: IconButton(
                                                    onPressed: () => _deleteNotification(notif),
                                                    icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    splashRadius: 16,
                                                    tooltip: 'Dismiss',
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              notif.message,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                                height: 1.35,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  timeStr,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textMuted,
                                                  ),
                                                ),
                                                const Text(
                                                  'View details →',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
