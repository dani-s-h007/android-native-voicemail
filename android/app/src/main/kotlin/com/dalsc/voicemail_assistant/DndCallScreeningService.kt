package com.dalsc.voicemail_assistant

import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract
import android.telecom.Call
import android.telecom.CallScreeningService
import android.telephony.SmsManager
import android.telephony.TelephonyManager
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import org.json.JSONArray
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException

@RequiresApi(Build.VERSION_CODES.Q)
class DndCallScreeningService : CallScreeningService() {

    companion object {
        private const val TAG = "DndCallScreening"
        private val emergencyNumbers = setOf("112", "100", "101", "102", "108", "1091", "181", "911")

        // In-memory cache to detect repeat callers within 3 minutes (180,000 ms)
        private val recentCallsMap = ConcurrentHashMap<String, Long>()
        private const val REPEAT_WINDOW_MS = 3 * 60 * 1000L

        // Rate limiter for Mode 2 SMS: maximum 5 SMS per hour per recipient number
        private val smsSentHistory = ConcurrentHashMap<String, MutableList<Long>>()
        private const val MAX_SMS_PER_HOUR = 5
        private const val SMS_WINDOW_MS = 60 * 60 * 1000L

        private val backgroundPool = Executors.newCachedThreadPool()
    }

    override fun onScreenCall(callDetails: Call.Details) {
        val startTime = System.currentTimeMillis()
        val handle = callDetails.handle
        val rawNumber = handle?.schemeSpecificPart ?: ""
        val normalizedNumber = normalizePhoneNumber(rawNumber)
        val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
        val carrier = telephonyManager?.simOperatorName?.ifEmpty { telephonyManager.networkOperatorName } ?: "Unknown"

        Log.d(TAG, "Incoming call screened: $normalizedNumber on $carrier")

        // 1. Emergency Numbers check - NEVER decline or silence emergency services
        if (isEmergencyNumber(normalizedNumber)) {
            Log.i(TAG, "Emergency number detected ($normalizedNumber). Allowing call through immediately.")
            allowCall(callDetails)
            logEvent(rawNumber, carrier, false, "MODE_1_SERVER_RELAY", "EMERGENCY_OVERRIDE", "ALLOW", emptyList(), startTime, true)
            return
        }

        // 2. Read state from FlutterSharedPreferences
        val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isAssistantActive = prefs.getBoolean("flutter.assistant_active", true)
        val isDndActive = prefs.getBoolean("flutter.dnd_active", false)
        val expiryEpoch = prefs.getLong("flutter.dnd_expires_at", 0L)
        val currentEpoch = System.currentTimeMillis() / 1000
        val selectedMode = prefs.getString("flutter.call_handling_mode", "MODE_1_SERVER_RELAY") ?: "MODE_1_SERVER_RELAY"

        val dndEffectivelyActive = isDndActive && (expiryEpoch == 0L || currentEpoch <= expiryEpoch)

        // If neither the Call Assistant nor DND is active, pass call through to the default dialer (Google Phone)
        if (!isAssistantActive && !dndEffectivelyActive) {
            Log.d(TAG, "Call Assistant and DND are both INACTIVE. Passing call to default dialer.")
            allowCall(callDetails)
            logEvent(rawNumber, carrier, false, selectedMode, "PASS_THROUGH_ASSISTANT_OFF", "ALLOW", emptyList(), startTime, true)
            return
        }

        // 3. Repeat Caller / Emergency 2-Call Breakthrough (Bypasses all screening)
        val allowRepeat = prefs.getBoolean("flutter.dnd_allow_repeat", true)
        if (allowRepeat && isRepeatCaller(normalizedNumber, System.currentTimeMillis())) {
            Log.i(TAG, "Caller is a REPEAT caller within 3 mins ($normalizedNumber). Bypassing screening to allow call.")
            allowCall(callDetails)
            logEvent(rawNumber, carrier, true, selectedMode, "REPEAT_CALLER_EMERGENCY_OVERRIDE", "ALLOW", emptyList(), startTime, true)
            return
        }

        // Starred Contact Exception (Only if DND schedule active)
        if (dndEffectivelyActive) {
            val allowStarred = prefs.getBoolean("flutter.dnd_allow_starred", true)
            if (allowStarred && isStarredContact(normalizedNumber)) {
                Log.i(TAG, "Caller is a STARRED contact ($normalizedNumber). Bypassing DND.")
                allowCall(callDetails)
                logEvent(rawNumber, carrier, true, selectedMode, "STARRED_CONTACT", "ALLOW", emptyList(), startTime, true)
                return
            }
        }

        // Record timestamp for future repeat detection
        if (normalizedNumber.isNotEmpty()) {
            recentCallsMap[normalizedNumber] = System.currentTimeMillis()
            cleanupOldRecentCalls(System.currentTimeMillis())
        }

        // 4. Execute Configured Call Handling Mode with Layered Fallback Chain
        executeCallHandlingMode(callDetails, rawNumber, normalizedNumber, carrier, selectedMode, prefs, startTime)
    }

    private fun executeCallHandlingMode(
        callDetails: Call.Details,
        rawNumber: String,
        normalizedNumber: String,
        carrier: String,
        selectedMode: String,
        prefs: android.content.SharedPreferences,
        startTime: Long
    ) {
        val fallbackChain = mutableListOf<String>()

        when (selectedMode) {
            "MODE_3_AUTO_ANSWER" -> {
                // Tier 1: Try on-device Auto-Answer
                fallbackChain.add("MODE_3_ATTEMPTED")
                val hasAnswerPerm = ContextCompat.checkSelfPermission(this, android.Manifest.permission.ANSWER_PHONE_CALLS) == PackageManager.PERMISSION_GRANTED
                if (hasAnswerPerm && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    try {
                        Log.i(TAG, "Mode 3: Launching AutoAnswerAssistantService")
                        allowCall(callDetails) // Handset answers; service manages speaker & TTS
                        AutoAnswerAssistantService.start(applicationContext, normalizedNumber)
                        logEvent(rawNumber, carrier, true, selectedMode, "DND_AUTO_ANSWER", "AUTO_ANSWER", fallbackChain, startTime, true)
                        return
                    } catch (e: Exception) {
                        Log.e(TAG, "Mode 3 failed: ${e.message}. Triggering fallback to Mode 2.")
                        fallbackChain.add("M3_FAILED_FALLBACK_TO_M2")
                    }
                } else {
                    Log.w(TAG, "ANSWER_PHONE_CALLS permission not granted. Falling back to Mode 2.")
                    fallbackChain.add("M3_NO_PERMISSION_FALLBACK_TO_M2")
                }

                // Fallback to auto-decline
                rejectCall(callDetails)
                logEvent(rawNumber, carrier, true, selectedMode, "DND_FALLBACK_REJECT", "REJECT", fallbackChain, startTime, true)
            }

            "MODE_2_AUTO_DECLINE", "MODE_2_AUTO_DECLINE_SMS" -> {
                // Tier 2: Auto-decline + selective SMS response with WhatsApp & Emergency features
                rejectCall(callDetails)
                val targetMode = prefs.getString("flutter.auto_msg_target_mode", "ALL") ?: "ALL"
                val shouldSend = checkAutoMsgAudience(targetMode, normalizedNumber, prefs)
                if (shouldSend) {
                    val autoReplyMsg = getEffectiveAutoReplyMessage(prefs)
                    val smsSent = sendAutoReplySms(rawNumber, autoReplyMsg)
                    val rule = if (smsSent) "AUTO_MSG_SENT" else "AUTO_MSG_RATE_LIMITED"
                    logEvent(rawNumber, carrier, true, selectedMode, rule, "REJECT", fallbackChain, startTime, true)
                } else {
                    Log.i(TAG, "Caller $normalizedNumber excluded by audience filter ($targetMode). SMS skipped.")
                    logEvent(rawNumber, carrier, true, selectedMode, "AUTO_MSG_AUDIENCE_FILTERED ($targetMode)", "REJECT", fallbackChain, startTime, true)
                }
            }

            "MODE_4_SILENT", "MODE_4_SILENT_DND" -> {
                // Tier 4: Ring silently without heads-up or vibration
                silentCall(callDetails)
                logEvent(rawNumber, carrier, true, selectedMode, "DND_SILENT_MODE", "SILENT", fallbackChain, startTime, true)
            }

            else -> {
                // Default Tier: Mode 1 - Server Greeting & Voicemail Relay
                Log.i(TAG, "Mode 1: Rejecting call to trigger carrier conditional forward (*67*/*403*)")
                rejectCall(callDetails)
                logEvent(rawNumber, carrier, true, "MODE_1_SERVER_RELAY", "DND_CARRIER_FORWARD", "REJECT", fallbackChain, startTime, true)
            }
        }
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
                // If contact is saved in phone contacts, skip SMS. Only auto-reply to unsaved callers!
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
            msg = "Hello. I am currently unavailable. Please leave a voicemail or send a message."
        }

        // Feature 1: Click-to-chat direct link (only if user enabled and configured)
        val includeWa = prefs.getBoolean("flutter.auto_msg_include_whatsapp", false)
        val waNumber = prefs.getString("flutter.auto_msg_whatsapp_number", "") ?: ""
        val cleanWa = waNumber.filter { it.isDigit() }
        if (includeWa && cleanWa.isNotEmpty() && !msg.contains("wa.me")) {
            msg += "\n\nChat: https://wa.me/$cleanWa"
        }

        // Feature 2: Emergency 2-Call Breakthrough Hint
        val allowRepeat = prefs.getBoolean("flutter.dnd_allow_repeat", true)
        if (allowRepeat && !msg.contains("urgent") && !msg.contains("emergency")) {
            msg += "\n(If urgent, call back within 3 mins to ring through)"
        }

        return msg
    }

    private fun sendAutoReplySms(recipientNumber: String, messageText: String): Boolean {
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.SEND_SMS) != PackageManager.PERMISSION_GRANTED) {
            Log.w(TAG, "SEND_SMS permission not granted. Skipping SMS auto-reply.")
            return false
        }

        val now = System.currentTimeMillis()
        val history = smsSentHistory.getOrPut(recipientNumber) { mutableListOf() }
        synchronized(history) {
            history.removeAll { now - it > SMS_WINDOW_MS }
            if (history.size >= MAX_SMS_PER_HOUR) {
                Log.w(TAG, "SMS rate limit reached for $recipientNumber ($MAX_SMS_PER_HOUR/hr). Skipping.")
                return false
            }
            history.add(now)
        }

        return try {
            val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                getSystemService(SmsManager::class.java)
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }
            val parts = smsManager.divideMessage(messageText)
            smsManager.sendMultipartTextMessage(recipientNumber, null, parts, null, null)
            Log.i(TAG, "Auto-reply SMS dispatched to $recipientNumber")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send auto-reply SMS: ${e.message}")
            false
        }
    }

    private fun allowCall(callDetails: Call.Details) {
        val response = CallResponse.Builder()
            .setDisallowCall(false)
            .setRejectCall(false)
            .setSkipCallLog(false)
            .setSkipNotification(false)
            .build()
        respondToCall(callDetails, response)
    }

    private fun rejectCall(callDetails: Call.Details) {
        val response = CallResponse.Builder()
            .setDisallowCall(true)
            .setRejectCall(true)            // Declines at telephony layer (User Busy -> triggers *67*/*403*)
            .setSkipCallLog(false)           // Keeps call in Android call logs
            .setSkipNotification(true)       // Silences ringing and heads-up banner
            .build()
        respondToCall(callDetails, response)
    }

    private fun silentCall(callDetails: Call.Details) {
        val response = CallResponse.Builder()
            .setDisallowCall(false)
            .setRejectCall(false)
            .setSilenceCall(true)            // Suppresses ringer
            .setSkipNotification(true)       // Suppresses heads-up banner
            .setSkipCallLog(false)
            .build()
        respondToCall(callDetails, response)
    }

    private fun isEmergencyNumber(number: String): Boolean {
        if (number.isEmpty()) return false
        val digitsOnly = number.filter { it.isDigit() }
        return emergencyNumbers.contains(digitsOnly)
    }

    private fun isStarredContact(number: String): Boolean {
        if (number.isEmpty()) return false
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
            return false
        }

        try {
            val uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(number))
            val projection = arrayOf(ContactsContract.PhoneLookup.STARRED)
            contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val starredIndex = cursor.getColumnIndex(ContactsContract.PhoneLookup.STARRED)
                    if (starredIndex >= 0) {
                        return cursor.getInt(starredIndex) == 1
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to query contact starred status: ${e.message}")
        }
        return false
    }

    private fun isRepeatCaller(number: String, currentTime: Long): Boolean {
        if (number.isEmpty()) return false
        val lastSeen = recentCallsMap[number] ?: return false
        return (currentTime - lastSeen) <= REPEAT_WINDOW_MS
    }

    private fun cleanupOldRecentCalls(currentTime: Long) {
        recentCallsMap.entries.removeIf { (currentTime - it.value) > REPEAT_WINDOW_MS }
    }

    private fun normalizePhoneNumber(phone: String): String {
        val digits = phone.filter { it.isDigit() }
        return if (digits.length >= 10) digits.takeLast(10) else digits
    }

    private fun logEvent(
        rawNumber: String,
        carrier: String,
        dndActive: Boolean,
        selectedMode: String,
        ruleMatched: String,
        decision: String,
        fallbackChain: List<String>,
        startTime: Long,
        success: Boolean,
        error: String? = null
    ) {
        val latency = System.currentTimeMillis() - startTime
        DiagnosticLogger.logCall(
            applicationContext,
            DiagnosticLogger.CallEvent(
                rawNumber = rawNumber,
                carrier = carrier,
                dndActive = dndActive,
                selectedMode = selectedMode,
                ruleMatched = ruleMatched,
                decision = decision,
                fallbackChain = fallbackChain,
                latencyMs = latency,
                success = success,
                error = error
            )
        )
    }
}
