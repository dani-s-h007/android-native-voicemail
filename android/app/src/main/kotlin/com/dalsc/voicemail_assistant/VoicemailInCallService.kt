package com.dalsc.voicemail_assistant

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract
import android.telecom.Call
import android.telecom.InCallService
import android.telecom.VideoProfile
import android.telephony.SmsManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import org.json.JSONArray

class VoicemailInCallService : InCallService() {

    companion object {
        private const val TAG = "VoicemailInCallService"
        private const val CHANNEL_ID = "incoming_call_ring_channel"
        private const val NOTIFICATION_ID = 5001

        const val ACTION_ANSWER = "com.dalsc.voicemail_assistant.ACTION_ANSWER"
        const val ACTION_DECLINE = "com.dalsc.voicemail_assistant.ACTION_DECLINE"

        var activeCall: Call? = null
    }

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        activeCall = call

        val state = call.state
        val details = call.details
        val handle = details?.handle
        val rawNumber = handle?.schemeSpecificPart ?: ""

        Log.i(TAG, "onCallAdded: number=$rawNumber, state=$state")

        val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isAssistantActive = prefs.getBoolean("flutter.assistant_active", true)
        val selectedMode = prefs.getString("flutter.call_handling_mode", "MODE_1_SERVER_RELAY") ?: "MODE_1_SERVER_RELAY"

        call.registerCallback(object : Call.Callback() {
            override fun onStateChanged(call: Call, newState: Int) {
                super.onStateChanged(call, newState)
                Log.d(TAG, "Call state changed: $newState")
                if (newState == Call.STATE_DISCONNECTED) {
                    cancelIncomingCallNotification()
                }
            }
        })

        if (state == Call.STATE_RINGING) {
            if (isAssistantActive) {
                when (selectedMode) {
                    "MODE_1_SERVER_RELAY" -> {
                        Log.i(TAG, "Mode 1: Rejecting call to deflect to voicemail server")
                        call.reject(Call.REJECT_REASON_DECLINED)
                    }

                    "MODE_2_AUTO_DECLINE", "MODE_2_AUTO_DECLINE_SMS" -> {
                        Log.i(TAG, "Mode 2: Rejecting call and sending selective auto-reply SMS")
                        call.reject(Call.REJECT_REASON_DECLINED)
                        val targetMode = prefs.getString("flutter.auto_msg_target_mode", "ALL") ?: "ALL"
                        val normalizedNumber = normalizePhoneNumber(rawNumber)
                        if (checkAutoMsgAudience(targetMode, normalizedNumber, prefs)) {
                            val autoReplyMsg = getEffectiveAutoReplyMessage(prefs)
                            sendAutoReplySms(rawNumber, autoReplyMsg)
                        } else {
                            Log.i(TAG, "Caller $normalizedNumber excluded by audience filter ($targetMode). SMS skipped.")
                        }
                    }

                    "MODE_3_AUTO_ANSWER" -> {
                        Log.i(TAG, "Mode 3: Answering call directly via InCallService")
                        call.answer(VideoProfile.STATE_AUDIO_ONLY)
                        AutoAnswerAssistantService.start(applicationContext, rawNumber)
                    }

                    "MODE_4_SILENT", "MODE_4_SILENT_DND" -> {
                        Log.i(TAG, "Mode 4: Ringing silently. Showing Answer/Decline banner.")
                        showIncomingCallNotification(rawNumber)
                    }

                    else -> {
                        showIncomingCallNotification(rawNumber)
                    }
                }
            } else {
                // Assistant is OFF -> Always show standard Answer / Decline notification!
                Log.i(TAG, "Assistant OFF -> Showing standard Answer/Decline notification.")
                showIncomingCallNotification(rawNumber)
            }
        }
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
        Log.i(TAG, "onCallRemoved: ${call.details}")
        if (activeCall == call) {
            activeCall = null
        }
        cancelIncomingCallNotification()
    }

    private fun showIncomingCallNotification(callerNumber: String) {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Incoming Calls",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Incoming call alerts with Accept and Decline buttons"
                enableVibration(true)
            }
            nm.createNotificationChannel(channel)
        }

        // Decline Intent
        val declineIntent = Intent(this, CallActionReceiver::class.java).apply {
            action = ACTION_DECLINE
        }
        val declinePendingIntent = PendingIntent.getBroadcast(
            this, 101, declineIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Answer Intent
        val answerIntent = Intent(this, CallActionReceiver::class.java).apply {
            action = ACTION_ANSWER
        }
        val answerPendingIntent = PendingIntent.getBroadcast(
            this, 102, answerIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentTitle("Incoming Call")
            .setContentText(callerNumber.ifEmpty { "Unknown Caller" })
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setOngoing(true)
            .setAutoCancel(false)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Decline", declinePendingIntent)
            .addAction(android.R.drawable.ic_menu_call, "Answer", answerPendingIntent)
            .build()

        nm.notify(NOTIFICATION_ID, notification)
    }

    private fun cancelIncomingCallNotification() {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.cancel(NOTIFICATION_ID)
    }

    private fun checkAutoMsgAudience(
        targetMode: String,
        normalizedNumber: String,
        prefs: android.content.SharedPreferences
    ): Boolean {
        if (normalizedNumber.isEmpty()) return false
        return when (targetMode) {
            "ALL" -> true

            "SELECTED_ONLY" -> {
                val selectedNumbersJson = prefs.getString("flutter.auto_msg_selected_numbers", "[]") ?: "[]"
                try {
                    val arr = JSONArray(selectedNumbersJson)
                    for (i in 0 until arr.length()) {
                        val num = normalizePhoneNumber(arr.getString(i))
                        if (num == normalizedNumber) return true
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error parsing selected numbers: ${e.message}")
                }
                false
            }

            "UNSAVED_ONLY" -> {
                !isContactSaved(normalizedNumber)
            }

            "EXCLUDE_SELECTED" -> {
                val selectedNumbersJson = prefs.getString("flutter.auto_msg_selected_numbers", "[]") ?: "[]"
                try {
                    val arr = JSONArray(selectedNumbersJson)
                    for (i in 0 until arr.length()) {
                        val num = normalizePhoneNumber(arr.getString(i))
                        if (num == normalizedNumber) return false
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error parsing excluded numbers: ${e.message}")
                }
                true
            }

            else -> true
        }
    }

    private fun isContactSaved(number: String): Boolean {
        if (number.isEmpty()) return false
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
            return false
        }
        return try {
            val uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(number))
            val projection = arrayOf(ContactsContract.PhoneLookup._ID)
            contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                cursor.moveToFirst()
            } ?: false
        } catch (e: Exception) {
            false
        }
    }

    private fun getEffectiveAutoReplyMessage(prefs: android.content.SharedPreferences): String {
        var msg = prefs.getString("flutter.active_greeting_text", null)
        if (msg.isNullOrBlank()) {
            msg = prefs.getString("flutter.dnd_msg", null)
        }
        if (msg.isNullOrBlank()) {
            msg = "Hi, Danish here. I'm unable to take your call right now. Please message me on WhatsApp or SMS. Thanks!"
        }

        val includeWa = prefs.getBoolean("flutter.auto_msg_include_whatsapp", true)
        val waNumber = prefs.getString("flutter.auto_msg_whatsapp_number", "7907338556") ?: "7907338556"
        val cleanWa = waNumber.filter { it.isDigit() }.let { if (it.length == 10) "91$it" else it }
        if (includeWa && cleanWa.isNotEmpty() && !msg.contains("wa.me")) {
            msg += "\n\nWhatsApp: https://wa.me/$cleanWa"
        }

        val allowRepeat = prefs.getBoolean("flutter.dnd_allow_repeat", true)
        if (allowRepeat && !msg.contains("urgent") && !msg.contains("emergency")) {
            msg += "\n(If urgent, call back within 3 mins to ring through)"
        }

        return msg
    }

    private fun normalizePhoneNumber(phone: String): String {
        val digits = phone.filter { it.isDigit() }
        return if (digits.length >= 10) digits.takeLast(10) else digits
    }

    private fun sendAutoReplySms(recipientNumber: String, messageText: String) {
        if (recipientNumber.isEmpty()) return
        try {
            val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                getSystemService(SmsManager::class.java)
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }
            val parts = smsManager.divideMessage(messageText)
            smsManager.sendMultipartTextMessage(recipientNumber, null, parts, null, null)
            Log.i(TAG, "Auto-reply SMS sent to $recipientNumber")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send auto-reply SMS: ${e.message}")
        }
    }
}
