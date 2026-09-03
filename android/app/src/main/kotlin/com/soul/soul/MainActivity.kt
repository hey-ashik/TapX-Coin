package com.soul.soul

import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val HAPTIC_CHANNEL = "com.tapx.coin/haptics"
    private val NOTIFICATION_CHANNEL = "com.tapx.coin/notifications"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Ensure background notification alarm is scheduled when app launches
        NotificationBackgroundReceiver.scheduleAlarm(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Native Hardware Vibration Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HAPTIC_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "vibrate") {
                val duration = (call.argument<Number>("duration") ?: 30).toLong()
                val amplitude = (call.argument<Number>("amplitude") ?: 120).toInt()
                triggerHardwareVibration(duration, amplitude)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }

        // Native Background Notification Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleBackgroundCheck" -> {
                    NotificationBackgroundReceiver.scheduleAlarm(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Directly triggers Android hardware vibrator motor.
     * Works on all OEM devices (Samsung, Xiaomi, Pixel, Vivo, Oppo, OnePlus)
     * regardless of whether system touch feedback is toggled down.
     */
    private fun triggerHardwareVibration(durationMs: Long, amplitude: Int) {
        try {
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vibratorManager?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }

            if (vibrator != null && vibrator.hasVibrator()) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val amp = if (amplitude in 1..255) amplitude else VibrationEffect.DEFAULT_AMPLITUDE
                    vibrator.vibrate(VibrationEffect.createOneShot(durationMs, amp))
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(durationMs)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
