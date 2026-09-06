package com.example.voicemail

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews

class ClassModeWidget : AppWidgetProvider() {

    companion object {
        const val ACTION_TOGGLE_CLASS_MODE = "com.example.voicemail.ACTION_TOGGLE_CLASS_MODE"

        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isClassModeOld = prefs.getBoolean("flutter.flutter.class_mode", false)
            val isClassModeNew = prefs.getBoolean("flutter.class_mode", false)
            val isClassMode = isClassModeOld || isClassModeNew

            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            if (isClassMode) {
                views.setTextViewText(R.id.widget_text, "Class Mode: ON")
                views.setImageViewResource(R.id.widget_icon, R.drawable.ic_widget_on)
            } else {
                views.setTextViewText(R.id.widget_text, "Class Mode: OFF")
                views.setImageViewResource(R.id.widget_icon, R.drawable.ic_widget_off)
            }

            val intent = Intent(context, ClassModeWidget::class.java).apply {
                action = ACTION_TOGGLE_CLASS_MODE
            }
            
            val pendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.getBroadcast(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            } else {
                PendingIntent.getBroadcast(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)
            }
            
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TOGGLE_CLASS_MODE) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isClassModeOld = prefs.getBoolean("flutter.flutter.class_mode", false)
            val isClassModeNew = prefs.getBoolean("flutter.class_mode", false)
            val isClassMode = isClassModeOld || isClassModeNew
            
            val newState = !isClassMode
            
            // Update preferences
            prefs.edit().apply {
                putBoolean("flutter.class_mode", newState)
                // Clear old one to avoid conflict
                remove("flutter.flutter.class_mode")
                apply()
            }
            
            // Update DND mode
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && notificationManager.isNotificationPolicyAccessGranted) {
                if (newState) {
                    notificationManager.setInterruptionFilter(android.app.NotificationManager.INTERRUPTION_FILTER_ALARMS)
                } else {
                    notificationManager.setInterruptionFilter(android.app.NotificationManager.INTERRUPTION_FILTER_ALL)
                }
            }

            // Update all widgets
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(ComponentName(context, ClassModeWidget::class.java))
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }
}
