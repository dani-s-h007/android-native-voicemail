package com.example.voicemail

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.telecom.TelecomManager
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import java.util.Locale

class CallHandlerService : Service(), TextToSpeech.OnInitListener {

    private var tts: TextToSpeech? = null
    private var pendingTtsMessage: String? = null
    private var pendingPhoneNumber: String? = null
    private var sendSmsAfterTts: Boolean = false
    private var audioManager: AudioManager? = null

    private var originalSpeakerphoneState: Boolean = false
    private var originalMode: Int = AudioManager.MODE_NORMAL

    companion object {
        const val CHANNEL_ID = "CallHandlerServiceChannel"
        const val NOTIFICATION_ID = 101
        
        const val EXTRA_PHONE_NUMBER = "phone_number"
        const val EXTRA_MESSAGE = "message"
        const val EXTRA_SEND_SMS = "send_sms"
    }

    override fun onCreate() {
        super.onCreate()
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
        
        tts = TextToSpeech(this, this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        pendingPhoneNumber = intent?.getStringExtra(EXTRA_PHONE_NUMBER)
        pendingTtsMessage = intent?.getStringExtra(EXTRA_MESSAGE)
        sendSmsAfterTts = intent?.getBooleanExtra(EXTRA_SEND_SMS, false) ?: false

        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            tts?.language = Locale.US
            
            // Wait 2.5 seconds to allow the telecom call to fully connect
            Handler(Looper.getMainLooper()).postDelayed({
                startSpeakingAndHangup()
            }, 2500)
        } else {
            hangUpCall()
            stopSelf()
        }
    }

    private fun startSpeakingAndHangup() {
        val message = pendingTtsMessage ?: return

        originalSpeakerphoneState = audioManager?.isSpeakerphoneOn ?: false
        originalMode = audioManager?.mode ?: AudioManager.MODE_NORMAL

        audioManager?.mode = AudioManager.MODE_IN_CALL
        audioManager?.isSpeakerphoneOn = true

        val maxVolume = audioManager?.getStreamMaxVolume(AudioManager.STREAM_VOICE_CALL) ?: 5
        audioManager?.setStreamVolume(AudioManager.STREAM_VOICE_CALL, maxVolume, 0)

        val params = android.os.Bundle()
        params.putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, "voicemail_tts")

        tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(utteranceId: String?) {}

            override fun onDone(utteranceId: String?) {
                finishCall()
            }

            @Deprecated("Deprecated in Java")
            override fun onError(utteranceId: String?) {
                finishCall()
            }
        })

        tts?.speak(message, TextToSpeech.QUEUE_FLUSH, params, "voicemail_tts")
    }

    private fun finishCall() {
        hangUpCall()
        restoreAudioState()

        if (sendSmsAfterTts && pendingPhoneNumber != null) {
            sendAutomatedSms(pendingPhoneNumber!!, pendingTtsMessage ?: "")
        }
        
        stopSelf()
    }

    private fun hangUpCall() {
        val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ANSWER_PHONE_CALLS) == PackageManager.PERMISSION_GRANTED) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    telecomManager.endCall()
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun restoreAudioState() {
        audioManager?.isSpeakerphoneOn = originalSpeakerphoneState
        audioManager?.mode = originalMode
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

    override fun onDestroy() {
        tts?.stop()
        tts?.shutdown()
        super.onDestroy()
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Call Handler Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(serviceChannel)
        }
    }
    
    private fun buildNotification(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        
        return builder
            .setContentTitle("Auto-Answering Call")
            .setContentText("Class Mode is responding to an incoming call...")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .build()
    }
}
