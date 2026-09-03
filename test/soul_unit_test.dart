import 'package:flutter/material.dart';
import 'package:soul/models/notification_model.dart';
import 'package:soul/models/transaction_model.dart';
import 'package:soul/providers/auth_provider.dart';
import 'package:soul/providers/leaderboard_provider.dart';
import 'package:soul/providers/settings_provider.dart';
import 'package:soul/providers/tap_engine_provider.dart';
import 'package:soul/providers/wallet_provider.dart';
import 'package:test/test.dart';

void main() {
  group('TapX App Core Unit Tests', () {
    test('TapEngineProvider initial score starts at 0 and increments with level progress', () {
      final tapEngine = TapEngineProvider();
      expect(tapEngine.score, 0);
      expect(tapEngine.level, 1);
      expect(tapEngine.currentEnergy, 0);

      tapEngine.handleTap(const Offset(150, 150), hapticsEnabled: false);

      expect(tapEngine.score, 1);
      expect(tapEngine.currentEnergy, 1);
      expect(tapEngine.particles.length, 1);
      expect(tapEngine.particles.first.text, '+1');

      tapEngine.dispose();
    });

    test('TapEngineProvider 7-day bonus starts at +10 and doubles each day', () {
      final tapEngine = TapEngineProvider();
      expect(tapEngine.dailyBonusDay, 1);
      expect(tapEngine.currentDayBonusAmount, 10);
      expect(tapEngine.isDailyBonusClaimed, isFalse);

      final success = tapEngine.claimDailyBonus();
      expect(success, isTrue);
      expect(tapEngine.isDailyBonusClaimed, isTrue);
      expect(tapEngine.score, 10);
      expect(tapEngine.dailyBonusDay, 1); // Marked as Day 1 claimed
      expect(tapEngine.nextStreakDay, 2); // Next is Day 2
      expect(tapEngine.nextDayBonusAmount, 20); // 2x on Day 2

      // Cannot claim twice in the same 24h cycle
      final secondTry = tapEngine.claimDailyBonus();
      expect(secondTry, isFalse);

      tapEngine.dispose();
    });

    test('WalletProvider calculates milestones, conversions, and processes payouts', () {
      final wallet = WalletProvider();
      expect(wallet.balance, 0.0);
      expect(wallet.currency, CurrencyType.bdt);
      expect(wallet.isTierUnlocked(50.0), isFalse);

      // Add taps from game engine
      wallet.syncWithTapScore(1550000); // 1,550,000 taps = ৳1,550.00
      expect(wallet.balance, 1550.0);
      expect(wallet.isTierUnlocked(50.0), isTrue);
      expect(wallet.isTierUnlocked(100.0), isTrue);
      expect(wallet.isTierUnlocked(2000.0), isFalse);

      // Payout request
      final success = wallet.requestPayout(
        amount: 500.0,
        method: 'bKash',
        accountName: 'Alex Rahman',
        destination: '01712-345678',
      );

      expect(success, isTrue);
      expect(wallet.balance, 1050.0);
      expect(wallet.transactions.first.amount, 500.0);
      expect(wallet.transactions.first.tapsDeducted, 500000);

      // Attempt to withdraw more than available
      final overdraw = wallet.requestPayout(
        amount: 2000.0,
        method: 'Nagad',
        accountName: 'Alex Rahman',
        destination: '01912-987654',
      );
      expect(overdraw, isFalse);
    });

    test('LeaderboardProvider lists entries and toggles tabs', () {
      final leaderboard = LeaderboardProvider();
      expect(leaderboard.selectedTab, 0);
      expect(leaderboard.currentList.isNotEmpty, isTrue);

      leaderboard.setSelectedTab(1);
      expect(leaderboard.selectedTab, 1);
      expect(leaderboard.currentList.isNotEmpty, isTrue);

      leaderboard.dispose();
    });

    test('AuthProvider profile updating and login simulation', () async {
      final auth = AuthProvider();
      expect(auth.isAuthenticated, isFalse); // Starts unauthenticated on launch

      auth.loginAsGuest();
      expect(auth.isAuthenticated, isTrue);

      auth.updateProfile(
        username: 'master_tapper',
        twitter: 'master_tap',
      );

      expect(auth.currentUser.username, 'master_tapper');
      expect(auth.currentUser.twitterHandle, 'master_tap');

      auth.logout();
      expect(auth.isAuthenticated, isFalse);

      await auth.register(name: 'Ashik', email: 'ashik@tapx.app', password: 'password123');
      expect(auth.currentUser.username, 'Ashik');
      expect(auth.currentUser.email, 'ashik@tapx.app');

      await auth.verifyOtp('749201');
      expect(auth.isAuthenticated, isTrue);
    });

    test('SettingsProvider toggles preferences', () {
      final settings = SettingsProvider();
      expect(settings.hapticsEnabled, isTrue);

      settings.toggleHaptics(false);
      expect(settings.hapticsEnabled, isFalse);

      settings.toggleSound(false);
      expect(settings.soundEnabled, isFalse);

      settings.toggleLowPowerMode(true);
      expect(settings.lowPowerMode, isTrue);
    });

    test('AppNotification sanitizes emojis from title and message', () {
      final notif = AppNotification.fromJson({
        'id': 1,
        'title': '🚀 New Update Available (v1.0.2)!',
        'message': '🔥 TapX v1.0.2 is now live! ⚡ Update now!',
        'type': 'announcement',
        'is_read': 0,
        'created_at': '2026-09-02 12:00:00',
      });

      expect(notif.title, 'New Update Available (v1.0.2)!');
      expect(notif.message, 'TapX v1.0.2 is now live!  Update now!');
    });
  });
}
