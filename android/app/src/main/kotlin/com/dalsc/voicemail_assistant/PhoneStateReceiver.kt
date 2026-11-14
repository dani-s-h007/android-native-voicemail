package com.dalsc.voicemail_assistant

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.util.Log

class PhoneStateReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "PhoneStateReceiver"
        private var lastState = TelephonyManager.EXTRA_STATE_IDLE
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) return

        val stateStr = intent.getStringExtra(TelephonyManager.EXTRA_STATE) ?: return
        val incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER) ?: ""

        Log.i(TAG, "PhoneState: $stateStr, incomingNumber: $incomingNumber")

        if (stateStr == TelephonyManager.EXTRA_STATE_RINGING && lastState != TelephonyManager.EXTRA_STATE_RINGING) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isAssistantActive = prefs.getBoolean("flutter.assistant_active", true)
            val selectedMode = prefs.getString("flutter.call_handling_mode", "MODE_1_SERVER_RELAY") ?: "MODE_1_SERVER_RELAY"

            if (isAssistantActive) {
                if (selectedMode == "MODE_3_AUTO_ANSWER") {
                    Log.i(TAG, "Mode 3 detected in PhoneStateReceiver. Starting AutoAnswerAssistantService.")
                    AutoAnswerAssistantService.start(context, incomingNumber)
                }
            }
        }
        lastState = stateStr
    }
}

