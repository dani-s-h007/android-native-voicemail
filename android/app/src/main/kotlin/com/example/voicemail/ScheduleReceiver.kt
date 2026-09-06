package com.example.voicemail

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build

class ScheduleReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_START_SCHEDULE = "com.example.voicemail.ACTION_START_SCHEDULE"
        const val ACTION_END_SCHEDULE = "com.example.voicemail.ACTION_END_SCHEDULE"
        const val EXTRA_IS_REPEATING = "is_repeating"
        
        fun setSchedule(context: Context, startTimeMillis: Long, endTimeMillis: Long, isRepeating: Boolean) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            // Start Intent
            val startIntent = Intent(context, ScheduleReceiver::class.java).apply {
                action = ACTION_START_SCHEDULE
                putExtra(EXTRA_IS_REPEATING, isRepeating)
            }
            val startPending = getPendingIntent(context, 1, startIntent)
            
            // End Intent
            val endIntent = Intent(context, ScheduleReceiver::class.java).apply {
                action = ACTION_END_SCHEDULE
                putExtra(EXTRA_IS_REPEATING, isRepeating)
            }
            val endPending = getPendingIntent(context, 2, endIntent)
            
            if (isRepeating) {
                alarmManager.setRepeating(AlarmManager.RTC_WAKEUP, startTimeMillis, AlarmManager.INTERVAL_DAY, startPending)
                alarmManager.setRepeating(AlarmManager.RTC_WAKEUP, endTimeMillis, AlarmManager.INTERVAL_DAY, endPending)
            } else {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, startTimeMillis, startPending)
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, endTimeMillis, endPending)
                } else {
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, startTimeMillis, startPending)
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, endTimeMillis, endPending)
                }
            }
        }
        
        fun cancelSchedule(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            val startIntent = Intent(context, ScheduleReceiver::class.java).apply { action = ACTION_START_SCHEDULE }
            alarmManager.cancel(getPendingIntent(context, 1, startIntent))
            
            val endIntent = Intent(context, ScheduleReceiver::class.java).apply { action = ACTION_END_SCHEDULE }
            alarmManager.cancel(getPendingIntent(context, 2, endIntent))
        }
        
        private fun getPendingIntent(context: Context, requestCode: Int, intent: Intent): PendingIntent {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.getBroadcast(context, requestCode, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            } else {
                PendingIntent.getBroadcast(context, requestCode, intent, PendingIntent.FLAG_UPDATE_CURRENT)
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        
        val isStart = intent.action == ACTION_START_SCHEDULE
        
        // Update SharedPreferences
        prefs.edit().apply {
            putBoolean("flutter.class_mode", isStart)
            remove("flutter.flutter.class_mode")
            apply()
        }
        
        // Update DND mode
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && notificationManager.isNotificationPolicyAccessGranted) {
            if (isStart) {
                notificationManager.setInterruptionFilter(android.app.NotificationManager.INTERRUPTION_FILTER_ALARMS)
            } else {
                notificationManager.setInterruptionFilter(android.app.NotificationManager.INTERRUPTION_FILTER_ALL)
            }
        }
        
        // Update Widgets
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(ComponentName(context, ClassModeWidget::class.java))
        for (appWidgetId in appWidgetIds) {
            ClassModeWidget.updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }
}
