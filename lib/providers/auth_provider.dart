import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  static const String _keyUser = 'tapx_user_session';
  static const String _keyAuth = 'tapx_is_authenticated';
  static const String _keyActiveTab = 'tapx_active_tab';

  bool _isAuthenticated = false;
  bool _isLoading = false;
  int _activeTab = 1; // Default to Tap Engine tab (index 1)

  // Callbacks for multi-account isolation and state synchronization
  void Function(UserModel user)? onUserLoggedIn;
  void Function()? onUserLoggedOut;
  void Function()? onGuestMode;

  UserModel _currentUser = UserModel(
    id: 'usr_init',
    username: 'New Tapper',
    email: '',
    avatarUrl: 'https://ui-avatars.com/api/?name=New+Tapper&background=1A1A1E&color=FFFFFF&bold=true&size=256',
    rank: 0,
    level: 1,
    streakDays: 1,
    totalTaps: 0,
    joinedDate: '2026',
    phone: '',
    twitterHandle: '',
    discordUsername: '',
    weeklyActivity: const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
  );

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  int get activeTab => _activeTab;
  UserModel get currentUser => _currentUser;

  // Session-scoped dismissals (persist until user logs out)
  bool _isLeaderboardBannerDismissed = false;
  bool _isNotificationTipBannerDismissed = false;
  final Set<int> _dismissedNotificationIds = <int>{};

  bool get isLeaderboardBannerDismissed => _isLeaderboardBannerDismissed;
  bool get isNotificationTipBannerDismissed => _isNotificationTipBannerDismissed;
  Set<int> get dismissedNotificationIds => Set.unmodifiable(_dismissedNotificationIds);

  void dismissLeaderboardBanner() {
    _isLeaderboardBannerDismissed = true;
    notifyListeners();
  }

  void dismissNotificationTipBanner() {
    _isNotificationTipBannerDismissed = true;
    notifyListeners();
  }

  void dismissNotification(int id) {
    _dismissedNotificationIds.add(id);
    notifyListeners();
  }

  bool isNotificationDismissed(int id) => _dismissedNotificationIds.contains(id);

  // Restore session from local storage on startup and verify fresh DB state
  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAuth = prefs.getBool(_keyAuth) ?? false;
      final userJson = prefs.getString(_keyUser);
      final savedTab = prefs.getInt(_keyActiveTab);

      if (savedTab != null) {
        _activeTab = savedTab;
      }

      if (isAuth && userJson != null) {
        final decoded = jsonDecode(userJson);
        _currentUser = UserModel.fromJson(decoded);
        _isAuthenticated = true;

        // Fetch fresh database values directly from server to eliminate caching collisions
        if (ApiService.hasToken) {
          final freshMe = await ApiService.getMe();
          if (freshMe != null && freshMe['success'] == true && freshMe['data']?['user'] != null) {
            final u = freshMe['data']['user'];
            _currentUser = _currentUser.copyWith(
              id: u['id'] ?? _currentUser.id,
              name: u['name'] ?? _currentUser.name,
              username: u['username'] ?? _currentUser.username,
              avatarUrl: u['avatar_url'] ?? _currentUser.avatarUrl,
              totalTaps: u['score'] ?? _currentUser.totalTaps,
              level: u['level'] ?? _currentUser.level,
              rank: u['rank'] ?? _currentUser.rank,
              streakDays: u['streak_days'] ?? _currentUser.streakDays,
              phone: u['phone'] ?? _currentUser.phone,
              twitterHandle: u['twitter_handle'] ?? _currentUser.twitterHandle,
              discordUsername: u['discord_username'] ?? _currentUser.discordUsername,
            );
            await _persistSession();
          }
        }

        onUserLoggedIn?.call(_currentUser);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Restore session note: $e');
    }
  }

  Future<void> _persistSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAuth, _isAuthenticated);
      await prefs.setString(_keyUser, jsonEncode(_currentUser.toJson()));
      await prefs.setInt(_keyActiveTab, _activeTab);
    } catch (e) {
      debugPrint('Persist session note: $e');
    }
  }

  void setActiveTab(int index) {
    _activeTab = index;
    _persistSession();
    notifyListeners();
  }

  // Generate initial avatar URL if not uploaded
  static String generateInitialAvatar(String name) {
    final encoded = Uri.encodeComponent(name.isNotEmpty ? name : 'User');
    return 'https://ui-avatars.com/api/?name=$encoded&background=1A1A1E&color=FFFFFF&bold=true&size=256';
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiService.login(email: email, password: password);
    _isLoading = false;

    if (res['success'] == true && res['data']?['user'] != null) {
      final u = res['data']['user'];
      final name = u['name'] ?? (email.contains('@') ? email.split('@').first : 'Tapper');
      final avatar = u['avatar_url'] ?? generateInitialAvatar(name);

      _currentUser = _currentUser.copyWith(
        id: u['id'] ?? _currentUser.id,
        name: name,
        username: u['username'] ?? (email.contains('@') ? email.split('@').first : name),
        email: u['email'] ?? email,
        avatarUrl: avatar,
        rank: u['rank'] ?? 1,
        level: u['level'] ?? 1,
        totalTaps: u['score'] ?? 0,
        streakDays: u['streak_days'] ?? 1,
        phone: u['phone'] ?? '',
        twitterHandle: u['twitter_handle'] ?? '',
        discordUsername: u['discord_username'] ?? '',
      );
      _isAuthenticated = true;
      await _persistSession();
      onUserLoggedIn?.call(_currentUser);
      notifyListeners();
      return {
        'success': true,
        'message': res['message'] ?? 'Login successful',
      };
    }

    // Check if account requires email OTP verification first
    if (res['data']?['needs_verification'] == true) {
      _currentUser = _currentUser.copyWith(
        email: email,
        username: email.contains('@') ? email.split('@').first : 'Tapper',
      );
      notifyListeners();
      return {
        'success': false,
        'needs_verification': true,
        'message': res['message'] ?? 'Please verify your email with the OTP code first.',
      };
    }

    notifyListeners();
    return {
      'success': false,
      'needs_verification': false,
      'message': res['message'] ?? 'Invalid email or password credentials.',
    };
  }

  void loginAsGuest() {
    final randId = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    _currentUser = UserModel(
      id: 'guest_$randId',
      name: 'Guest Tapper',
      username: 'Guest Tapper #$randId',
      email: 'guest_$randId@tapx.com',
      avatarUrl: 'https://ui-avatars.com/api/?name=Guest+$randId&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      rank: 0,
      level: 1,
      streakDays: 1,
      totalTaps: 0,
      joinedDate: 'Today',
      phone: '',
      twitterHandle: '',
      discordUsername: '',
      weeklyActivity: const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    );
    _isAuthenticated = true;
    _persistSession();
    onGuestMode?.call();
    notifyListeners();
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiService.register(name: name, email: email, password: password);
    _isLoading = false;

    final initialAvatar = generateInitialAvatar(name);
    _currentUser = _currentUser.copyWith(
      name: name,
      username: name.isNotEmpty ? name : (email.contains('@') ? email.split('@').first : 'new_tapper'),
      email: email.isNotEmpty ? email : 'new_user@tapx.ashiik.com',
      avatarUrl: initialAvatar,
      totalTaps: 0,
      level: 1,
      rank: 1,
      streakDays: 1,
    );

    notifyListeners();
    return {
      'success': res['success'] == true,
      'message': res['message'] ?? 'Verification code sent.',
    };
  }

  Future<Map<String, dynamic>> verifyOtp(String code) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiService.verifyOtp(email: _currentUser.email, code: code);
    _isLoading = false;

    if (res['success'] == true) {
      if (res['data']?['user'] != null) {
        final u = res['data']['user'];
        _currentUser = _currentUser.copyWith(
          id: u['id'] ?? _currentUser.id,
          name: u['name'] ?? _currentUser.name,
          username: u['username'] ?? _currentUser.username,
          avatarUrl: u['avatar_url'] ?? _currentUser.avatarUrl,
          totalTaps: u['score'] ?? 0,
          level: u['level'] ?? 1,
          rank: u['rank'] ?? 1,
          streakDays: u['streak_days'] ?? 1,
        );
      }
      _isAuthenticated = true;
      await _persistSession();
      onUserLoggedIn?.call(_currentUser);
      notifyListeners();
      return {
        'success': true,
        'message': 'Account verified successfully! Welcome to TapX.',
      };
    }

    notifyListeners();
    return {
      'success': false,
      'message': res['message'] ?? 'Invalid 6-digit code. Please try again.',
    };
  }

  Future<bool> resendOtp() async {
    final res = await ApiService.resendOtp(email: _currentUser.email);
    return res['success'] == true;
  }

  Future<bool> uploadAvatar(List<int> bytes, String filename) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiService.uploadAvatar(bytes, filename);
    _isLoading = false;

    if (res['success'] == true && res['data']?['avatar_url'] != null) {
      _currentUser = _currentUser.copyWith(
        avatarUrl: res['data']['avatar_url'],
      );
      await _persistSession();
      notifyListeners();
      return true;
    }

    notifyListeners();
    return false;
  }

  Future<void> updateProfile({
    String? name,
    String? username,
    String? phone,
    String? twitter,
    String? discord,
    String? facebook,
    String? instagram,
    String? avatarUrl,
  }) async {
    _currentUser = _currentUser.copyWith(
      name: name ?? _currentUser.name,
      username: username ?? _currentUser.username,
      phone: phone ?? _currentUser.phone,
      twitterHandle: twitter ?? _currentUser.twitterHandle,
      discordUsername: discord ?? _currentUser.discordUsername,
      facebookUrl: facebook ?? _currentUser.facebookUrl,
      instagramUrl: instagram ?? _currentUser.instagramUrl,
      avatarUrl: avatarUrl ?? _currentUser.avatarUrl,
    );
    _persistSession();
    notifyListeners();

    final res = await ApiService.updateProfile(
      name: name,
      username: username,
      phone: phone,
      twitter: twitter,
      discord: discord,
      avatarUrl: avatarUrl,
    );

    if (res['success'] == true && res['data']?['avatar_url'] != null) {
      _currentUser = _currentUser.copyWith(
        avatarUrl: res['data']['avatar_url'],
      );
      await _persistSession();
      notifyListeners();
    }
  }

  void logout() async {
    _isLeaderboardBannerDismissed = false;
    _isNotificationTipBannerDismissed = false;
    _dismissedNotificationIds.clear();
    ApiService.clearToken();
    _isAuthenticated = false;
    _activeTab = 1;
    _currentUser = UserModel(
      id: 'usr_init',
      username: 'Guest Tapper',
      email: '',
      avatarUrl: 'https://ui-avatars.com/api/?name=Guest+Tapper&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      rank: 0,
      level: 1,
      streakDays: 1,
      totalTaps: 0,
      joinedDate: '2026',
      phone: '',
      twitterHandle: '',
      discordUsername: '',
      weeklyActivity: const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAuth);
      await prefs.remove(_keyUser);
      await prefs.remove(_keyActiveTab);
    } catch (e) {
      debugPrint('Logout clear prefs: $e');
    }
    onUserLoggedOut?.call();
    notifyListeners();
  }
}
