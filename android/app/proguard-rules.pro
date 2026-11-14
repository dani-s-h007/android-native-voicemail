# Flutter & AndroidX Core Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Native Application Classes & Telephony Services
-keep class com.dalsc.voicemail_assistant.** { *; }
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }

# Keep Telecom and System Services
-keep class android.telecom.** { *; }
-keep class android.telephony.** { *; }

# Keep Audio & Codec Classes (JustAudio / AudioSession)
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.audio_session.** { *; }

# Keep SQLite & Secure Storage
-keep class com.tekartik.sqflite.** { *; }
-keep class androidx.security.crypto.** { *; }

# Keep Diagnostic & Battery Helper Models
-keepclassmembers class com.dalsc.voicemail_assistant.DiagnosticLogger$* { *; }
-keepclassmembers class com.dalsc.voicemail_assistant.OemBatteryHelper$* { *; }

# Suppress Play Core Warnings for Unused Deferred Components
-dontwarn com.google.android.play.core.**
