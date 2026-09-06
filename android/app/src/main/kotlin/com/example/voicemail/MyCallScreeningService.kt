package com.example.voicemail

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract
import android.telecom.Call
import android.telecom.CallScreeningService
import android.telecom.TelecomManager
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat

class MyCallScreeningService : CallScreeningService() {

    override fun onScreenCall(callDetails: Call.Details) {
        if (callDetails.callDirection == Call.Details.DIRECTION_INCOMING) {
            val phoneNumber = callDetails.handle?.schemeSpecificPart ?: ""

            if (isImportantContact(phoneNumber)) {
                // Bypass for important contacts
                respondToCall(callDetails, CallResponse.Builder().build())
                return
            }

            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            
            // Handle both old and new keys to prevent stale data issues
            val isClassModeOld = prefs.getBoolean("flutter.flutter.class_mode", false)
            val isClassModeNew = prefs.getBoolean("flutter.class_mode", false)
            val isClassMode = isClassModeOld || isClassModeNew
            
            val selectedMethod = prefs.getInt("flutter.selected_method", 1)
            val autoReplyMessage = prefs.getString("flutter.auto_reply", "I am in class right now. Please text me.") ?: "I am in class right now."
            val sendSmsAfterTts = prefs.getBoolean("flutter.send_sms_after_tts", false)
            
            // Check custom Important Contacts list saved from Flutter UI
            val importantContacts = prefs.getString("flutter.important_contacts", "") ?: ""
            if (isCustomImportantContact(phoneNumber, importantContacts)) {
                respondToCall(callDetails, CallResponse.Builder().build())
                return
            }

            if (isClassMode) {
                if (selectedMethod == 1) {
                    // Method 1: Reject call silently and send SMS
                    val response = CallResponse.Builder()
                        .setDisallowCall(true)
                        .setRejectCall(true)
                        .setSkipCallLog(false)
                        .setSkipNotification(true)
                        .build()

                    respondToCall(callDetails, response)
                    sendAutomatedSms(phoneNumber, autoReplyMessage)
                } else if (selectedMethod == 2) {
                    // Method 2: Allow call, auto-answer, speak TTS, and hang up
                    val response = CallResponse.Builder()
                        .setDisallowCall(false)
                        .setRejectCall(false)
                        .build()
                    respondToCall(callDetails, response)

                    val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
                    if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ANSWER_PHONE_CALLS) == PackageManager.PERMISSION_GRANTED) {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                telecomManager.acceptRingingCall()
                            }
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    }
                    
                    // Start Foreground Service to handle TTS and Call termination
                    val serviceIntent = Intent(this, CallHandlerService::class.java).apply {
                        putExtra(CallHandlerService.EXTRA_PHONE_NUMBER, phoneNumber)
                        putExtra(CallHandlerService.EXTRA_MESSAGE, autoReplyMessage)
                        putExtra(CallHandlerService.EXTRA_SEND_SMS, sendSmsAfterTts)
                    }
                    
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                }
            } else {
                // Not in class mode, just allow normal ringing
                respondToCall(callDetails, CallResponse.Builder().build())
            }
        }
    }

    private fun isImportantContact(phoneNumber: String): Boolean {
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
            return false
        }
        
        var isImportant = false
        val uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(phoneNumber))
        val projection = arrayOf(ContactsContract.PhoneLookup.STARRED)
        
        try {
            contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val starredIndex = cursor.getColumnIndex(ContactsContract.PhoneLookup.STARRED)
                    if (starredIndex != -1) {
                        isImportant = cursor.getInt(starredIndex) == 1
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        return isImportant
    }
    
    private fun isCustomImportantContact(incomingNumber: String, importantContactsJson: String): Boolean {
        if (importantContactsJson.isEmpty()) return false
        
        // simple parsing of the comma separated or json array string
        // We'll assume the Flutter app saves it as a comma-separated string for simplicity
        val cleanIncoming = incomingNumber.replace(Regex("[^0-9+]"), "")
        val contactsList = importantContactsJson.split(",")
        
        for (contact in contactsList) {
            val cleanContact = contact.replace(Regex("[^0-9+]"), "")
            if (cleanContact.isNotEmpty()) {
                if (cleanIncoming.endsWith(cleanContact) || cleanContact.endsWith(cleanIncoming)) {
                    return true
                }
            }
        }
        return false
    }

    private fun sendAutomatedSms(phoneNumber: String, message: String) {
        try {
            val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                applicationContext.getSystemService(SmsManager::class.java)
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }
            smsManager.sendTextMessage(phoneNumber, null, message, null, null)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
