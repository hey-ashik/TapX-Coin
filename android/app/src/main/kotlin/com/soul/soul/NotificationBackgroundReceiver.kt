package com.soul.soul

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.os.Build
import android.os.SystemClock
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread

/**
 * Android BroadcastReceiver that periodically checks for new announcements
 * from the TapX backend API and displays native system notifications
 * outside of the app (when the app is closed or in the background).
 */
class NotificationBackgroundReceiver : BroadcastReceiver() {

    companion object {
        const val CHANNEL_ID = "tapx_announcements"
        const val CHANNEL_NAME = "TapX Announcements & Alerts"
        const val PREFS_NAME = "FlutterSharedPreferences"
        const val PREF_NOTIFIED_KEY = "flutter.tapx_notified_ids"
        const val PREF_ENABLED_KEY = "flutter.tapx_setting_notifications"
        const val DEFAULT_API_URL = "https://tapx.ashiik.com/api/v1/user/notifications.php"
        private const val REQUEST_CODE = 8801

        fun scheduleAlarm(context: Context) {
            try {
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
                val intent = Intent(context, NotificationBackgroundReceiver::class.java)
                val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                        (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
                val pendingIntent = PendingIntent.getBroadcast(context, REQUEST_CODE, intent, flags)

                // Periodic check every 5 minutes
                val intervalMs = 5 * 60 * 1000L
                val triggerAtMs = SystemClock.elapsedRealtime() + intervalMs

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.ELAPSED_REALTIME_WAKEUP,
                        triggerAtMs,
                        pendingIntent
                    )
                } else {
                    alarmManager.setInexactRepeating(
                        AlarmManager.ELAPSED_REALTIME_WAKEUP,
                        triggerAtMs,
                        intervalMs,
                        pendingIntent
                    )
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent?) {
        // Schedule next check so background polling continues reliably
        scheduleAlarm(context)

        // Perform HTTP check on a background thread
        thread {
            checkNotifications(context)
        }
    }

    private fun checkNotifications(context: Context) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val enabled = prefs.getBoolean(PREF_ENABLED_KEY, true)
            if (!enabled) return

            val notifiedJson = prefs.getString(PREF_NOTIFIED_KEY, null)
            val notifiedSet = mutableSetOf<String>()
            if (!notifiedJson.isNullOrEmpty()) {
                try {
                    if (notifiedJson.startsWith("[")) {
                        val arr = JSONArray(notifiedJson)
                        for (i in 0 until arr.length()) {
                            notifiedSet.add(arr.getString(i))
                        }
                    } else {
                        val set = prefs.getStringSet(PREF_NOTIFIED_KEY, null)
                        if (set != null) notifiedSet.addAll(set)
                    }
                } catch (_: Exception) {
                    val set = prefs.getStringSet(PREF_NOTIFIED_KEY, null)
                    if (set != null) notifiedSet.addAll(set)
                }
            }

            val url = URL(DEFAULT_API_URL)
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "GET"
            conn.connectTimeout = 10000
            conn.readTimeout = 10000
            conn.setRequestProperty("Accept", "application/json")
            conn.connect()

            if (conn.responseCode == 200) {
                val reader = BufferedReader(InputStreamReader(conn.inputStream))
                val sb = StringBuilder()
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    sb.append(line)
                }
                reader.close()

                val root = JSONObject(sb.toString())
                if (root.optBoolean("success")) {
                    val data = root.optJSONObject("data")
                    val notifs = data?.optJSONArray("notifications")
                    if (notifs != null && notifs.length() > 0) {
                        var updated = false

                        for (i in 0 until notifs.length()) {
                            val notifObj = notifs.getJSONObject(i)
                            val id = notifObj.optInt("id")
                            val idStr = id.toString()

                            if (id > 0 && !notifiedSet.contains(idStr)) {
                                val title = notifObj.optString("title", "TapX Announcement")
                                val message = notifObj.optString("message", "")

                                showSystemNotification(context, id, title, message)
                                notifiedSet.add(idStr)
                                updated = true
                            }
                        }

                        if (updated) {
                            val newArr = JSONArray()
                            notifiedSet.toList().takeLast(100).forEach { idStr -> newArr.put(idStr) }
                            prefs.edit().putString(PREF_NOTIFIED_KEY, newArr.toString()).apply()
                        }
                    }
                }
            }
            conn.disconnect()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun showSystemNotification(context: Context, id: Int, title: String, message: String) {
        try {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Real-time announcements, bonus alerts, and system notifications from TapX"
                    enableLights(true)
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 300, 200, 300)
                }
                notificationManager.createNotificationChannel(channel)
            }

            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("notification_id", id)
            }

            val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            val pendingIntent = PendingIntent.getActivity(context, id, launchIntent, flags)

            val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

            val builder = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(message)
                .setStyle(NotificationCompat.BigTextStyle().bigText(message).setSummaryText("TapX Announcement"))
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_MESSAGE)
                .setColor(0xFFFBBF24.toInt())
                .setAutoCancel(true)
                .setSound(soundUri)
                .setVibrate(longArrayOf(0, 300, 200, 300))
                .setContentIntent(pendingIntent)

            notificationManager.notify(id, builder.build())
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
