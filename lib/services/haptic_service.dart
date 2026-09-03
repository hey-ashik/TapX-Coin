import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service for controlling device physical vibration and haptic feedback.
/// Uses native Android VibratorManager / Vibrator via MethodChannel to guarantee physical
/// motor activation across all Android phone manufacturers (Samsung, Xiaomi, Pixel, Vivo, Oppo, etc.)
/// and gracefully falls back to Flutter HapticFeedback on Web.
/// Automatically respects the global 'tapx_setting_haptics' preference.
class HapticService {
  static const String _keyHaptics = 'tapx_setting_haptics';
  static const MethodChannel _channel = MethodChannel('com.tapx.coin/haptics');
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

  /// Internal helper to invoke native hardware vibration with fallback
  static Future<void> _triggerHardwareVibration({
    required int durationMs,
    required int amplitude,
    required Future<void> Function() webFallback,
  }) async {
    if (!_hapticsEnabled) return;
    try {
      await _channel.invokeMethod('vibrate', {
        'duration': durationMs,
        'amplitude': amplitude,
      });
    } catch (_) {
      try {
        await webFallback();
      } catch (_) {}
    }
  }

  /// Light haptic pulse for buttons, segment switches, and list item taps.
  static Future<void> lightImpact() async {
    await _triggerHardwareVibration(
      durationMs: 32,
      amplitude: 140,
      webFallback: () => HapticFeedback.lightImpact(),
    );
  }

  /// Medium haptic pulse for actions with higher significance (claims, submissions, confirms).
  static Future<void> mediumImpact() async {
    await _triggerHardwareVibration(
      durationMs: 55,
      amplitude: 200,
      webFallback: () => HapticFeedback.mediumImpact(),
    );
  }

  /// Heavy haptic impact for major milestones or level ups.
  static Future<void> heavyImpact() async {
    await _triggerHardwareVibration(
      durationMs: 90,
      amplitude: 255,
      webFallback: () => HapticFeedback.heavyImpact(),
    );
  }

  /// Selection click feedback for toggles, switches, chips, and currency selectors.
  static Future<void> selectionClick() async {
    await _triggerHardwareVibration(
      durationMs: 22,
      amplitude: 100,
      webFallback: () => HapticFeedback.selectionClick(),
    );
  }

  /// Standard vibration pulse.
  static Future<void> vibrate() async {
    await _triggerHardwareVibration(
      durationMs: 120,
      amplitude: 220,
      webFallback: () => HapticFeedback.vibrate(),
    );
  }
}
