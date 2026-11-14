package com.dalsc.voicemail_assistant

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class DndStopReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "DndStopReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.i(TAG, "Turn Off DND action triggered from notification.")

        // Update SharedPreferences so CallScreeningService stops declining calls immediately
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean("flutter.dnd_active", false)
            .remove("flutter.dnd_expires_at")
            .apply()

        // Cancel persistent notification
        DndNotificationHelper.cancelDndNotification(context)

        Log.i(TAG, "DND state cleared locally. Normal voicemail routing active.")
    }
}

