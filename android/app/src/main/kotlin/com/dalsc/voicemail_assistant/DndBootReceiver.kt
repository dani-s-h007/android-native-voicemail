package com.dalsc.voicemail_assistant

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class DndBootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "DndBootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.i(TAG, "Device reboot completed. Checking DND status...")
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isDndActive = prefs.getBoolean("flutter.dnd_active", false)
            val expiryEpoch = prefs.getLong("flutter.dnd_expires_at", 0L)
            val currentEpoch = System.currentTimeMillis() / 1000

            if (isDndActive) {
                if (expiryEpoch > 0 && currentEpoch >= expiryEpoch) {
                    Log.i(TAG, "DND expired during device restart. Deactivating.")
                    prefs.edit()
                        .putBoolean("flutter.dnd_active", false)
                        .remove("flutter.dnd_expires_at")
                        .apply()
                } else {
                    Log.i(TAG, "DND still active after reboot. Restoring persistent notification.")
                    DndNotificationHelper.showDndActiveNotification(
                        context,
                        "Calls diverted to custom voicemail greeting."
                    )
                }
            }
        }
    }
}

