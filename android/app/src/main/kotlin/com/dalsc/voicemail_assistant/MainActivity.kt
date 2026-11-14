package com.dalsc.voicemail_assistant

import android.Manifest
import android.app.Activity
import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.telephony.SubscriptionInfo
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import android.telecom.TelecomManager
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val TELEPHONY_CHANNEL = "com.dalsc.voicemail_assistant/telephony"
    private val DND_CHANNEL = "com.dalsc.voicemail_assistant/dnd"
    private val RELIABILITY_CHANNEL = "com.dalsc.voicemail_assistant/reliability"

    private val REQUEST_CODE_CALL_SCREENING = 1002
    private var rolePendingResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            // Ensure background health watchdog is active across app runs
            WatchdogWorker.schedulePeriodicWatchdog(applicationContext)
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Safe startup: Watchdog initialization deferred: ${e.message}")
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Telephony Channel (SIM detection & USSD)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TELEPHONY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getActiveSims" -> {
                    val simList = getActiveSubscriptions()
                    result.success(simList)
                }
                "getCarrierName" -> {
                    val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
                    val carrierName = telephonyManager.simOperatorName.ifEmpty {
                        telephonyManager.networkOperatorName
                    }
                    result.success(carrierName)
                }
                "sendUssdRequest" -> {
                    val ussdCode = call.argument<String>("ussdCode")
                    val subId = call.argument<Int>("subId") ?: -1

                    if (ussdCode.isNullOrEmpty()) {
                        result.error("INVALID_CODE", "USSD code is required", null)
                        return@setMethodCallHandler
                    }

                    if (ActivityCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED) {
                        result.error("PERMISSION_DENIED", "CALL_PHONE permission is required to dial MMI codes", null)
                        return@setMethodCallHandler
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val baseTelephony = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
                        val telephonyManager = if (subId != -1) {
                            baseTelephony.createForSubscriptionId(subId)
                        } else {
                            baseTelephony
                        }

                        val handler = Handler(Looper.getMainLooper())
                        val isCompleted = java.util.concurrent.atomic.AtomicBoolean(false)

                        val timeoutRunnable = Runnable {
                            if (isCompleted.compareAndSet(false, true)) {
                                launchDialerFallback(ussdCode, subId)
                                result.success(mapOf(
                                    "status" to "FALLBACK_DIALER",
                                    "message" to "Background USSD timed out after 3.5s (typical for VoLTE Supplementary Services). Forwarded via phone dialer."
                                ))
                            }
                        }

                        handler.postDelayed(timeoutRunnable, 3500)

                        try {
                            telephonyManager.sendUssdRequest(ussdCode, object : TelephonyManager.UssdResponseCallback() {
                                override fun onReceiveUssdResponse(
                                    telephony: TelephonyManager,
                                    request: String,
                                    response: CharSequence
                                ) {
                                    handler.removeCallbacks(timeoutRunnable)
                                    if (isCompleted.compareAndSet(false, true)) {
                                        result.success(mapOf(
                                            "status" to "SUCCESS",
                                            "message" to response.toString()
                                        ))
                                    }
                                }

                                override fun onReceiveUssdResponseFailed(
                                    telephony: TelephonyManager,
                                    request: String,
                                    failureCode: Int
                                ) {
                                    handler.removeCallbacks(timeoutRunnable)
                                    if (isCompleted.compareAndSet(false, true)) {
                                        launchDialerFallback(ussdCode, subId)
                                        result.success(mapOf(
                                            "status" to "FALLBACK_DIALER",
                                            "message" to "Direct USSD code failed ($failureCode). Dispatched to phone dialer."
                                        ))
                                    }
                                }
                            }, handler)
                        } catch (e: Exception) {
                            handler.removeCallbacks(timeoutRunnable)
                            if (isCompleted.compareAndSet(false, true)) {
                                launchDialerFallback(ussdCode, subId)
                                result.success(mapOf(
                                    "status" to "FALLBACK_DIALER",
                                    "message" to "Exception: ${e.message}. Dialed via intent."
                                ))
                            }
                        }
                    } else {
                        launchDialerFallback(ussdCode, subId)
                        result.success(mapOf("status" to "FALLBACK_DIALER", "message" to "Pre-Oreo dialer dispatched"))
                    }
                }
                "dialMmiDirect" -> {
                    val ussdCode = call.argument<String>("ussdCode")
                    val subId = call.argument<Int>("subId") ?: -1

                    if (ussdCode.isNullOrEmpty()) {
                        result.error("INVALID_CODE", "USSD code is required", null)
                        return@setMethodCallHandler
                    }

                    launchDialerFallback(ussdCode, subId)
                    result.success(mapOf(
                        "status" to "SUCCESS",
                        "message" to "Dialed $ussdCode via system phone dialer."
                    ))
                }
                else -> result.notImplemented()
            }
        }

        // 2. DND & Call Screening Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DND_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isCallScreeningRoleHeld" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val roleManager = getSystemService(Context.ROLE_SERVICE) as? RoleManager
                        val isHeld = roleManager?.isRoleHeld(RoleManager.ROLE_CALL_SCREENING) ?: false
                        result.success(isHeld)
                    } else {
                        result.success(true)
                    }
                }
                "isDefaultDialer" -> {
                    val telecomManager = getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
                    val isDefault = telecomManager?.defaultDialerPackage == packageName
                    result.success(isDefault)
                }
                "requestDefaultDialerRole" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val roleManager = getSystemService(Context.ROLE_SERVICE) as? RoleManager
                        if (roleManager != null && !roleManager.isRoleHeld(RoleManager.ROLE_DIALER)) {
                            val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_DIALER)
                            startActivityForResult(intent, 1004)
                            result.success(true)
                        } else {
                            result.success(true)
                        }
                    } else {
                        val intent = Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER).apply {
                            putExtra(TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, packageName)
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                }
                "requestCallScreeningRole" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val roleManager = getSystemService(Context.ROLE_SERVICE) as? RoleManager
                        if (roleManager != null && !roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)) {
                            rolePendingResult = result
                            val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING)
                            startActivityForResult(intent, REQUEST_CODE_CALL_SCREENING)
                        } else {
                            result.success(true)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "showDndNotification" -> {
                    val statusText = call.argument<String>("statusText") ?: "DND active: Calls routed to custom voicemail"
                    DndNotificationHelper.showDndActiveNotification(applicationContext, statusText)
                    result.success(true)
                }
                "cancelDndNotification" -> {
                    DndNotificationHelper.cancelDndNotification(applicationContext)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 3. Reliability, OEM Diagnostics & Logs Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RELIABILITY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getReliabilityAudit" -> {
                    val audit = OemBatteryHelper.getReliabilityAudit(this)
                    result.success(audit)
                }
                "openOemSetting" -> {
                    val target = call.argument<String>("target") ?: "app_details"
                    val intent = OemBatteryHelper.getOemSettingIntent(this, target)
                    try {
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", "Unable to open OEM setting: ${e.message}", null)
                    }
                }
                "getDiagnosticLogs" -> {
                    val limit = call.argument<Int>("limit") ?: 50
                    val logs = DiagnosticLogger.getRecentLogs(this, limit)
                    result.success(logs)
                }
                "clearDiagnosticLogs" -> {
                    val cleared = DiagnosticLogger.clearLogs(this)
                    result.success(cleared)
                }
                "exportDiagnosticLogs" -> {
                    val file = DiagnosticLogger.exportLogs(this)
                    result.success(file?.absolutePath)
                }
                "setCallHandlingMode" -> {
                    val mode = call.argument<String>("mode") ?: "MODE_1_SERVER_RELAY"
                    val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    prefs.edit().putString("flutter.call_handling_mode", mode).apply()
                    result.success(true)
                }
                "setAssistantActive" -> {
                    val active = call.argument<Boolean>("active") ?: true
                    val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    prefs.edit().putBoolean("flutter.assistant_active", active).apply()
                    result.success(true)
                }
                "getAssistantActive" -> {
                    val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val active = prefs.getBoolean("flutter.assistant_active", true)
                    result.success(active)
                }
                "requestIgnoreBatteryOptimizations" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val intent = Intent(android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:$packageName")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            try {
                                val fallbackIntent = Intent(android.provider.Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                }
                                startActivity(fallbackIntent)
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("BATTERY_ERROR", e2.message, null)
                            }
                        }
                    } else {
                        result.success(true)
                    }
                }
                "requestAllCorePermissions" -> {
                    val perms = mutableListOf(
                        Manifest.permission.CALL_PHONE,
                        Manifest.permission.READ_PHONE_STATE,
                        Manifest.permission.READ_CONTACTS,
                        Manifest.permission.SEND_SMS
                    )
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        perms.add(Manifest.permission.ANSWER_PHONE_CALLS)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        perms.add(Manifest.permission.POST_NOTIFICATIONS)
                    }
                    ActivityCompat.requestPermissions(this, perms.toTypedArray(), 1003)
                    result.success(true)
                }
                "triggerWatchdog" -> {
                    WatchdogWorker.schedulePeriodicWatchdog(applicationContext)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_CALL_SCREENING) {
            val granted = (resultCode == Activity.RESULT_OK)
            rolePendingResult?.success(granted)
            rolePendingResult = null
        }
    }

    private fun getActiveSubscriptions(): List<Map<String, Any>> {
        val list = mutableListOf<Map<String, Any>>()
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED) {
            val sm = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as? SubscriptionManager
            sm?.activeSubscriptionInfoList?.forEach { info: SubscriptionInfo ->
                list.add(mapOf(
                    "subId" to info.subscriptionId,
                    "simSlotIndex" to info.simSlotIndex,
                    "carrierName" to (info.carrierName?.toString() ?: "Unknown"),
                    "displayName" to (info.displayName?.toString() ?: "SIM ${info.simSlotIndex + 1}")
                ))
            }
        }
        return list
    }

    private fun launchDialerFallback(ussdCode: String, subId: Int) {
        val encodedHash = ussdCode.replace("#", Uri.encode("#"))
        val uri = Uri.parse("tel:$encodedHash")
        val intent = Intent(Intent.ACTION_CALL, uri).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
            if (subId != -1) {
                putExtra("android.telephony.extra.SUBSCRIPTION_INDEX", subId)
            }
        }

        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) == PackageManager.PERMISSION_GRANTED) {
            startActivity(intent)
        } else {
            val dialIntent = Intent(Intent.ACTION_DIAL, uri)
            startActivity(dialIntent)
        }
    }
}
