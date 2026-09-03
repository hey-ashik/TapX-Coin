import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Centralized service handling native Android & iOS system tray / heads-up pop-up notifications.
/// Works both when user is inside the app and when app is in the background or newly received.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static Timer? _syncTimer;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String _channelId = 'tapx_announcements';
  static const String _channelName = 'TapX Announcements & Alerts';
  static const String _channelDesc = 'Real-time announcements, bonus alerts, and system notifications from TapX';
  static const String _prefKeyNotifiedIds = 'tapx_notified_ids';
  static const String _prefKeyNotificationsEnabled = 'tapx_setting_notifications';
  static const String _prefKeyFirstLaunch = 'tapx_notif_first_launch_done';

  /// Initialize notifications plugin, create notification channel, and request permissions
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[NotificationService] User tapped notification: ${response.payload}');
          // Future expansion: deep-link into notification modal if context available
        },
      );

      // Create Android Notification Channel with MAX importance for heads-up banner display
      final androidPlatform = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );
        await androidPlatform.createNotificationChannel(channel);

        // Request runtime notification permission on Android 13+ (API 33+)
        await androidPlatform.requestNotificationsPermission();
      }

      _isInitialized = true;
      debugPrint('[NotificationService] Initialized successfully');

      // Start periodic sync for new announcements from admin
      startPeriodicSync();

      // Check for welcome or first-time notification
      _handleFirstLaunch();
    } catch (e) {
      debugPrint('[NotificationService] Initialization error: $e');
    }
  }

  /// Request runtime permission explicitly (e.g. from Settings or on first login)
  static Future<bool> requestPermission() async {
    try {
      final androidPlatform = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        final granted = await androidPlatform.requestNotificationsPermission();
        return granted ?? true;
      }
      final iosPlatform = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosPlatform != null) {
        final granted = await iosPlatform.requestPermissions(alert: true, badge: true, sound: true);
        return granted ?? true;
      }
    } catch (e) {
      debugPrint('[NotificationService] requestPermission error: $e');
    }
    return true;
  }

  /// Shows a native heads-up system notification in the phone's notification tray
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_prefKeyNotificationsEnabled) ?? true;
      if (!enabled) {
        debugPrint('[NotificationService] Notifications are disabled in Settings. Skipping.');
        return;
      }

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'TapX Announcement',
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFFBBF24), // TapX Gold brand color
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'TapX Announcement',
        ),
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] showNotification error: $e');
    }
  }

  /// Send an immediate test notification to verify status bar & banner delivery
  static Future<void> showTestNotification() async {
    await showNotification(
      id: 99999,
      title: 'TapX System Notification ⚡',
      body: 'Push notifications are fully active! You will receive admin announcements & reward alerts right on your phone.',
    );
  }

  /// First launch welcome notification
  static Future<void> _handleFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getBool(_prefKeyFirstLaunch) ?? false;
      if (!done) {
        await prefs.setBool(_prefKeyFirstLaunch, true);
        // Delay slightly so UI loads first
        Future.delayed(const Duration(seconds: 3), () async {
          await showNotification(
            id: 10001,
            title: 'Welcome to TapX - Coin! ⚡',
            body: 'Tap to mine coins, claim daily streaks, and withdraw real money directly to bKash, Nagad, and USDT!',
          );
        });
      }
    } catch (e) {
      debugPrint('[NotificationService] first launch error: $e');
    }
  }

  /// Starts background sync timer to periodically poll for new announcements from admin
  static void startPeriodicSync() {
    _syncTimer?.cancel();
    // Run an initial check after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      checkForNewAnnouncements();
    });

    // Check every 25 seconds while app is running
    _syncTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      checkForNewAnnouncements();
    });
  }

  /// Cancels background sync
  static void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Fetches notifications from backend and triggers native phone popup for newly posted admin announcements
  static Future<void> checkForNewAnnouncements() async {
    try {
      final res = await ApiService.getNotifications();
      if (res['success'] != true || res['data'] == null) return;

      final List notifs = res['data']['notifications'] ?? [];
      if (notifs.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final List<String> notifiedIds = prefs.getStringList(_prefKeyNotifiedIds) ?? [];

      bool updated = false;

      for (final item in notifs) {
        final int id = item['id'] is int ? item['id'] : int.tryParse('${item['id']}') ?? 0;
        final String idStr = id.toString();

        if (id > 0 && !notifiedIds.contains(idStr)) {
          // This is a brand-new notification from the backend/admin!
          final String title = item['title'] ?? 'TapX Announcement';
          final String message = item['message'] ?? '';

          await showNotification(
            id: id,
            title: title,
            body: message,
            payload: idStr,
          );

          notifiedIds.add(idStr);
          updated = true;
        }
      }

      if (updated) {
        // Keep last 100 notified IDs to avoid unbounded growth
        if (notifiedIds.length > 100) {
          notifiedIds.removeRange(0, notifiedIds.length - 100);
        }
        await prefs.setStringList(_prefKeyNotifiedIds, notifiedIds);
      }
    } catch (e) {
      debugPrint('[NotificationService] checkForNewAnnouncements error: $e');
    }
  }
}
