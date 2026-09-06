package com.example.voicemail

import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.voicemail/channel"
    private val REQUEST_ID = 1

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "requestRole") {
                requestCallScreeningRole()
                result.success(true)
            } else if (call.method == "requestAnswerCalls") {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    if (checkSelfPermission(android.Manifest.permission.ANSWER_PHONE_CALLS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                        requestPermissions(arrayOf(android.Manifest.permission.ANSWER_PHONE_CALLS), 2)
                    }
                }
                result.success(true)
            } else if (call.method == "requestDndAccess") {
                requestDndAccess()
                result.success(true)

            } else if (call.method == "setDndMode") {
                val enable = call.argument<Boolean>("enable") ?: false
                setDndMode(enable)
                result.success(true)
            } else if (call.method == "setSchedule") {
                val start = call.argument<Number>("startTime")?.toLong() ?: 0L
                val end = call.argument<Number>("endTime")?.toLong() ?: 0L
                val repeating = call.argument<Boolean>("isRepeating") ?: false
                ScheduleReceiver.setSchedule(this, start, end, repeating)
                result.success(true)
            } else if (call.method == "cancelSchedule") {
                ScheduleReceiver.cancelSchedule(this)
                result.success(true)
            } else if (call.method == "isClassMode") {
                val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val isClassMode = prefs.getBoolean("flutter.class_mode", false)
                result.success(isClassMode)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun requestCallScreeningRole() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(Context.ROLE_SERVICE) as RoleManager
            if (!roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)) {
                val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING)
                startActivityForResult(intent, REQUEST_ID)
            }
        }
    }
    
    private fun requestDndAccess() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !notificationManager.isNotificationPolicyAccessGranted) {
            val intent = Intent(android.provider.Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            startActivity(intent)
        }
    }
    
    private fun setDndMode(enable: Boolean) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && notificationManager.isNotificationPolicyAccessGranted) {
            if (enable) {
                notificationManager.setInterruptionFilter(android.app.NotificationManager.INTERRUPTION_FILTER_ALARMS)
            } else {
                notificationManager.setInterruptionFilter(android.app.NotificationManager.INTERRUPTION_FILTER_ALL)
            }
        }
    }
}
