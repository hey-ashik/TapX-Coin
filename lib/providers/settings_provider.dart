import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/haptic_service.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyHaptics = 'tapx_setting_haptics';
  static const String _keySound = 'tapx_setting_sound';
  static const String _keyLowPower = 'tapx_setting_low_power';

  bool _hapticsEnabled = true;
  bool _soundEnabled = true;
  bool _lowPowerMode = false;
  bool _notificationsEnabled = true;

  bool get hapticsEnabled => _hapticsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get lowPowerMode => _lowPowerMode;
  bool get notificationsEnabled => _notificationsEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hapticsEnabled = prefs.getBool(_keyHaptics) ?? true;
      _soundEnabled = prefs.getBool(_keySound) ?? true;
      _lowPowerMode = prefs.getBool(_keyLowPower) ?? false;
      HapticService.setEnabled(_hapticsEnabled);
      notifyListeners();
    } catch (_) {}
  }

  void toggleHaptics(bool value) async {
    _hapticsEnabled = value;
    HapticService.setEnabled(value);
    notifyListeners();
    if (value) {
      HapticService.selectionClick();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHaptics, value);
    } catch (_) {}
  }

  void toggleSound(bool value) async {
    _soundEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySound, value);
    } catch (_) {}
  }

  void toggleLowPowerMode(bool value) async {
    _lowPowerMode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyLowPower, value);
    } catch (_) {}
  }

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }
}
