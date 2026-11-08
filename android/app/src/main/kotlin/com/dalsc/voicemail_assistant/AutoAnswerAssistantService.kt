package com.dalsc.voicemail_assistant

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.database.sqlite.SQLiteDatabase
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.media.ToneGenerator
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.telecom.TelecomManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import java.io.File
import java.util.Locale

class AutoAnswerAssistantService : Service(), TextToSpeech.OnInitListener {

    companion object {
        private const val TAG = "AutoAnswerService"
        private const val CHANNEL_ID = "auto_answer_fg_channel"
        private const val NOTIFICATION_ID = 4001

        const val ACTION_START_ASSISTANT = "com.dalsc.voicemail_assistant.ACTION_START_ASSISTANT"
        const val EXTRA_CALLER_NUMBER = "extra_caller_number"

        fun start(context: Context, callerNumber: String) {
            val intent = Intent(context, AutoAnswerAssistantService::class.java).apply {
                action = ACTION_START_ASSISTANT
                putExtra(EXTRA_CALLER_NUMBER, callerNumber)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }

    private var mediaPlayer: MediaPlayer? = null
    private var textToSpeech: TextToSpeech? = null
    private var audioManager: AudioManager? = null
    private var toneGenerator: ToneGenerator? = null
    private var originalVolume: Int = 0
    private var originalMusicVolume: Int = 0
    private var originalAudioMode: Int = AudioManager.MODE_NORMAL
    private val handler = Handler(Looper.getMainLooper())

    // On-Device Live Voicemail Recorder state
    private var callerPhone: String = "Unknown"
    private var mediaRecorder: MediaRecorder? = null
    private var currentRecordingFile: File? = null
    private var recordingStartTime: Long = 0
    private var isRecordingSaved: Boolean = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val callerNumber = intent?.getStringExtra(EXTRA_CALLER_NUMBER) ?: "Unknown"
        startAsForeground()

        executeAutoAnswer(callerNumber)
        return START_NOT_STICKY
    }

    private fun startAsForeground() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Active Call Assistant",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Runs while on-device call assistant is answering incoming call"
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }

        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentTitle("Voicemail Assistant Active")
            .setContentText("Speaking greeting to caller over speakerphone...")
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun executeAutoAnswer(callerNumber: String) {
        callerPhone = callerNumber
        val telecomManager = getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
        if (telecomManager == null || ContextCompat.checkSelfPermission(this, android.Manifest.permission.ANSWER_PHONE_CALLS) != PackageManager.PERMISSION_GRANTED) {
            Log.e(TAG, "Missing ANSWER_PHONE_CALLS permission or TelecomManager unavailable")
            stopSelf()
            return
        }

        try {
            // 1. Answer call via TelecomManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                telecomManager.acceptRingingCall()
                Log.i(TAG, "acceptRingingCall invoked successfully.")
            } else {
                Log.e(TAG, "Auto-answering requires Android 8.0+")
                stopSelf()
                return
            }

            // 2. Setup acoustic route
            setupAudioRouteAndPlayGreeting()

        } catch (e: Exception) {
            Log.e(TAG, "Failed to auto-answer call: ${e.message}", e)
            cleanupAndStop()
        }
    }

    private fun setupAudioRouteAndPlayGreeting() {
        val am = audioManager ?: return
        originalAudioMode = am.mode
        originalVolume = am.getStreamVolume(AudioManager.STREAM_VOICE_CALL)
        originalMusicVolume = am.getStreamVolume(AudioManager.STREAM_MUSIC)

        // Lower incoming volume on earpiece
        am.setStreamVolume(AudioManager.STREAM_VOICE_CALL, 1, 0)

        // Maximize MEDIA loudspeaker volume so sound physically fires into the bottom microphone
        val maxMusicVol = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        am.setStreamVolume(AudioManager.STREAM_MUSIC, maxMusicVol, 0)

        am.mode = AudioManager.MODE_IN_COMMUNICATION
        enableSpeakerphone(am)

        // Explicitly ensure microphone is NOT muted so it picks up speaker output
        am.isMicrophoneMute = false

        // Wait 700ms for telecom baseband audio path to stabilize
        handler.postDelayed({
            playGreetingAudio()
        }, 700)
    }

    private fun enableSpeakerphone(am: AudioManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val speakerDevice = am.availableCommunicationDevices.firstOrNull {
                it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER
            }
            if (speakerDevice != null) {
                am.setCommunicationDevice(speakerDevice)
            } else {
                @Suppress("DEPRECATION")
                am.isSpeakerphoneOn = true
            }
        } else {
            @Suppress("DEPRECATION")
            am.isSpeakerphoneOn = true
        }
    }

    private fun playGreetingAudio() {
        try {
            val greetingFile = File(filesDir, "current_greeting.wav")
            if (greetingFile.exists()) {
                Log.i(TAG, "Playing custom greeting WAV file on STREAM_MUSIC at maximum volume.")
                mediaPlayer = MediaPlayer().apply {
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .setLegacyStreamType(AudioManager.STREAM_MUSIC)
                            .build()
                    )
                    setDataSource(greetingFile.absolutePath)
                    setVolume(1.0f, 1.0f)
                    setOnCompletionListener {
                        Log.i(TAG, "WAV greeting completed. Sounding beep tone.")
                        playBeepToneAndListen()
                    }
                    setOnErrorListener { _, what, extra ->
                        Log.e(TAG, "MediaPlayer error ($what, $extra)")
                        fallbackToTextToSpeech()
                        true
                    }
                    prepare()
                    start()
                }
            } else {
                Log.i(TAG, "No WAV file on disk. Initializing TextToSpeech on STREAM_MUSIC...")
                fallbackToTextToSpeech()
            }

            // Safety watchdog: stop after 30 seconds
            handler.postDelayed({
                cleanupAndStop()
            }, 30000)

        } catch (e: Exception) {
            Log.e(TAG, "Failed to play greeting: ${e.message}", e)
            fallbackToTextToSpeech()
        }
    }

    private fun fallbackToTextToSpeech() {
        textToSpeech = TextToSpeech(this, this)
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            val tts = textToSpeech ?: return
            tts.language = Locale.ENGLISH

            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val customMsg = prefs.getString("flutter.dnd_msg", null)
                ?: "Hello. I am currently in a meeting and cannot take your call. Please leave a message after the beep."

            tts.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) {
                    Log.i(TAG, "TTS utterance started on STREAM_MUSIC.")
                }

                override fun onDone(utteranceId: String?) {
                    Log.i(TAG, "TTS utterance completed. Sounding beep tone.")
                    handler.post { playBeepToneAndListen() }
                }

                override fun onError(utteranceId: String?) {
                    Log.e(TAG, "TTS error on utterance: $utteranceId")
                    handler.post { playBeepToneAndListen() }
                }
            })

            // STREAM_MUSIC: Loud media speaker directly next to microphone hole
            val params = android.os.Bundle().apply {
                putInt(TextToSpeech.Engine.KEY_PARAM_STREAM, AudioManager.STREAM_MUSIC)
                putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, 1.0f)
            }
            tts.speak(customMsg, TextToSpeech.QUEUE_FLUSH, params, "greeting_tts")
        } else {
            Log.e(TAG, "TextToSpeech init failed ($status). Sounding beep directly.")
            playBeepToneAndListen()
        }
    }

    private fun playBeepToneAndListen() {
        try {
            toneGenerator = ToneGenerator(AudioManager.STREAM_MUSIC, 100)
            toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP, 400)
        } catch (e: Exception) {
            Log.e(TAG, "ToneGenerator error: ${e.message}")
        }

        // Start recording caller message right after beep (iPhone style)
        handler.postDelayed({
            startRecordingCallerMessage()
        }, 450)

        // Allow up to 20 seconds for the caller to record their message
        handler.postDelayed({
            endCallAndFinish()
        }, 20500)
    }

    private fun startRecordingCallerMessage() {
        try {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                Log.w(TAG, "RECORD_AUDIO not granted, skipping caller audio recording")
                return
            }

            val timestamp = System.currentTimeMillis()
            val recFile = File(filesDir, "vm_${timestamp}.m4a")
            currentRecordingFile = recFile
            recordingStartTime = System.currentTimeMillis()
            isRecordingSaved = false

            val recorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(this)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }

            recorder.apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setAudioEncodingBitRate(64000)
                setAudioSamplingRate(16000)
                setOutputFile(recFile.absolutePath)
                prepare()
                start()
            }
            mediaRecorder = recorder
            Log.i(TAG, "Live Voicemail caller recording started: ${recFile.absolutePath}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start MediaRecorder: ${e.message}", e)
        }
    }

    private fun stopRecordingAndSaveVoicemail() {
        if (isRecordingSaved) return
        isRecordingSaved = true

        try {
            mediaRecorder?.apply {
                stop()
                release()
            }
            mediaRecorder = null

            val file = currentRecordingFile
            if (file != null && file.exists() && file.length() > 500) {
                val durationSec = ((System.currentTimeMillis() - recordingStartTime) / 1000).toInt().coerceAtLeast(1)
                saveVoicemailToLocalDatabase(callerPhone, file.absolutePath, durationSec)
                notifyNewVoicemail(callerPhone, durationSec)
                Log.i(TAG, "Live Voicemail saved: ${file.absolutePath} ($durationSec s)")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping recorder / saving voicemail: ${e.message}")
        }
    }

    private fun saveVoicemailToLocalDatabase(callerNumber: String, audioPath: String, durationSeconds: Int) {
        try {
            val dbPath = getDatabasePath("voicemail_app.db")
            if (dbPath.exists()) {
                val db = SQLiteDatabase.openDatabase(dbPath.absolutePath, null, SQLiteDatabase.OPEN_READWRITE)
                val values = ContentValues().apply {
                    put("id", "vm_${System.currentTimeMillis()}")
                    put("caller_number", callerNumber)
                    put("audio_local_path", audioPath)
                    put("duration_seconds", durationSeconds)
                    put("created_at", System.currentTimeMillis())
                    put("is_read", 0)
                    put("is_starred", 0)
                    put("transcript_text", "On-Device Live Voicemail from $callerNumber")
                    put("detected_language", "English")
                    put("transcription_status", "ready")
                }
                db.insert("voicemails", null, values)
                db.close()
                Log.i(TAG, "Inserted voicemail into local database for $callerNumber")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to insert into local database: ${e.message}")
        }
    }

    private fun notifyNewVoicemail(callerNumber: String, durationSeconds: Int) {
        try {
            val channelId = "new_voicemail_channel"
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    channelId,
                    "New Voicemail Alerts",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Notifies when a new on-device Live Voicemail is recorded"
                }
                nm.createNotificationChannel(channel)
            }

            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            val pendingIntent = PendingIntent.getActivity(
                this, 0, launchIntent,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
            )

            val notif = NotificationCompat.Builder(this, channelId)
                .setSmallIcon(R.mipmap.launcher_icon)
                .setContentTitle("New Live Voicemail ($durationSeconds s)")
                .setContentText("From $callerNumber — Tap to listen")
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)
                .build()

            nm.notify(System.currentTimeMillis().toInt(), notif)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to show voicemail notification: ${e.message}")
        }
    }

    private fun endCallAndFinish() {
        stopRecordingAndSaveVoicemail()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.ANSWER_PHONE_CALLS) == PackageManager.PERMISSION_GRANTED) {
                try {
                    val tm = getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
                    tm?.endCall()
                    Log.i(TAG, "Call ended via TelecomManager.")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to end call: ${e.message}")
                }
            }
        }
        cleanupAndStop()
    }

    private fun cleanupAndStop() {
        stopRecordingAndSaveVoicemail()
        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
            mediaPlayer = null

            toneGenerator?.release()
            toneGenerator = null

            textToSpeech?.stop()
            textToSpeech?.shutdown()
            textToSpeech = null

            audioManager?.let { am ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    am.clearCommunicationDevice()
                } else {
                    @Suppress("DEPRECATION")
                    am.isSpeakerphoneOn = false
                }
                am.mode = originalAudioMode
                am.setStreamVolume(AudioManager.STREAM_VOICE_CALL, originalVolume, 0)
                am.setStreamVolume(AudioManager.STREAM_MUSIC, originalMusicVolume, 0)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Cleanup exception: ${e.message}")
        } finally {
            stopForeground(true)
            stopSelf()
        }
    }

    override fun onDestroy() {
        cleanupAndStop()
        super.onDestroy()
    }
}
