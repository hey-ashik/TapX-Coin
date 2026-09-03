import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service for controlling device haptic feedback and vibrations.
/// Automatically respects the global 'tapx_setting_haptics' preference.
class HapticService {
  static const String _keyHaptics = 'tapx_setting_haptics';
  static bool _hapticsEnabled = true;

  /// Returns whether haptic feedback is currently enabled.
  static bool get isEnabled => _hapticsEnabled;

  /// Initializes the haptic setting from local storage.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hapticsEnabled = prefs.getBool(_keyHaptics) ?? true;
    } catch (_) {
      _hapticsEnabled = true;
    }
  }

  /// Sets whether haptics are enabled globally.
  static void setEnabled(bool enabled) {
    _hapticsEnabled = enabled;
  }

  /// Light haptic pulse for buttons, segment switches, and list item taps.
  static Future<void> lightImpact() async {
    if (!_hapticsEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Medium haptic pulse for actions with higher significance (claims, submissions, confirms).
  static Future<void> mediumImpact() async {
    if (!_hapticsEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Heavy haptic impact for major milestones or level ups.
  static Future<void> heavyImpact() async {
    if (!_hapticsEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Selection click feedback for toggles, switches, chips, and currency selectors.
  static Future<void> selectionClick() async {
    if (!_hapticsEnabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Standard vibration pulse.
  static Future<void> vibrate() async {
    if (!_hapticsEnabled) return;
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }
}
