package com.dalsc.voicemail_assistant

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

object DndNotificationHelper {
    private const val CHANNEL_ID = "dnd_active_channel"
    private const val NOTIFICATION_ID = 2001

    fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "DND Active Alerts"
            val descriptionText = "Shows persistent status while Do Not Disturb voicemail is active"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                setShowBadge(false)
            }
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    fun showDndActiveNotification(context: Context, statusText: String) {
        createNotificationChannel(context)

        // Intent to launch the app when tapping the notification body
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentPendingIntent = PendingIntent.getActivity(
            context,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Intent for the "Turn Off" action button
        val stopIntent = Intent(context, DndStopReceiver::class.java).apply {
            action = "com.dalsc.voicemail_assistant.ACTION_STOP_DND"
        }
        val stopPendingIntent = PendingIntent.getBroadcast(
            context,
            1,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentTitle("Voicemail DND Active")
            .setContentText(statusText)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(contentPendingIntent)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Turn Off DND", stopPendingIntent)
            .build()

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    fun cancelDndNotification(context: Context) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(NOTIFICATION_ID)
    }
}

