package com.dalsc.voicemail_assistant

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.TimeUnit

class WatchdogWorker(
    private val context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    companion object {
        private const val TAG = "WatchdogWorker"
        private const val WORK_NAME = "voicemail_assistant_watchdog"
        private const val WATCHDOG_CHANNEL_ID = "watchdog_alerts_channel"

        fun schedulePeriodicWatchdog(context: Context) {
            val request = PeriodicWorkRequestBuilder<WatchdogWorker>(4, TimeUnit.HOURS)
                .setInitialDelay(15, TimeUnit.MINUTES)
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request
            )
            Log.i(TAG, "Watchdog scheduled to audit device health every 4 hours.")
        }
    }

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        Log.i(TAG, "Running watchdog system audit...")
        val audit = OemBatteryHelper.getReliabilityAudit(context)

        val callScreeningRoleHeld = audit["callScreeningRoleHeld"] as? Boolean ?: true
        val batteryExempt = audit["batteryOptimizationExempt"] as? Boolean ?: true

        // 1. Audit Call Screening Role
        if (!callScreeningRoleHeld) {
            Log.w(TAG, "Call Screening Role is NOT held! Alerting user.")
            postHealthAlert(
                notificationId = 3001,
                title = "Voicemail Assistant Disabled",
                message = "Call screening permission was revoked. Tap to restore protection."
            )
        }

        // 2. Audit Battery Optimization
        if (!batteryExempt) {
            Log.w(TAG, "Battery optimization exemption is missing! Alerting user.")
            postHealthAlert(
                notificationId = 3002,
                title = "Background Calls Restricted",
                message = "Battery saver may silence voicemails. Tap to allow background activity."
            )
        }

        // 3. Audit Relay Backend Reachability (5s timeout)
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val relayBaseUrl = prefs.getString("flutter.relay_base_url", "https://danishk.web.app") ?: "https://danishk.web.app"
        val isServerReachable = pingHealthEndpoint(relayBaseUrl)
        if (!isServerReachable) {
            Log.w(TAG, "Relay health ping failed for $relayBaseUrl")
        }

        Result.success()
    }

    private fun pingHealthEndpoint(baseUrl: String): Boolean {
        return try {
            val url = URL(if (baseUrl.endsWith("/")) "${baseUrl}api/v1/health" else "$baseUrl/api/v1/health")
            val conn = (url.openConnection() as HttpURLConnection).apply {
                connectTimeout = 5000
                readTimeout = 5000
                requestMethod = "GET"
            }
            conn.responseCode in 200..299
        } catch (e: Exception) {
            false
        }
    }

    private fun postHealthAlert(notificationId: Int, title: String, message: String) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                WATCHDOG_CHANNEL_ID,
                "System Health Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Warns when system permissions or battery managers disrupt voicemail"
            }
            notificationManager.createNotificationChannel(channel)
        }

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, WATCHDOG_CHANNEL_ID)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        notificationManager.notify(notificationId, notification)
    }
}

