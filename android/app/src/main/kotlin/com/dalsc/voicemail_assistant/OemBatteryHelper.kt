package com.dalsc.voicemail_assistant

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.role.RoleManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat

object OemBatteryHelper {

    enum class OemBrand {
        XIAOMI,
        OPPO,
        REALME,
        ONEPLUS,
        VIVO,
        SAMSUNG,
        GOOGLE,
        OTHER
    }

    fun getDeviceBrand(): OemBrand {
        val manufacturer = Build.MANUFACTURER.lowercase()
        return when {
            manufacturer.contains("xiaomi") || manufacturer.contains("redmi") || manufacturer.contains("poco") -> OemBrand.XIAOMI
            manufacturer.contains("realme") -> OemBrand.REALME
            manufacturer.contains("oppo") -> OemBrand.OPPO
            manufacturer.contains("oneplus") -> OemBrand.ONEPLUS
            manufacturer.contains("vivo") || manufacturer.contains("iqoo") -> OemBrand.VIVO
            manufacturer.contains("samsung") -> OemBrand.SAMSUNG
            manufacturer.contains("google") -> OemBrand.GOOGLE
            else -> OemBrand.OTHER
        }
    }

    fun getReliabilityAudit(context: Context): Map<String, Any> {
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val isIgnoringBatteryOptimizations = pm.isIgnoringBatteryOptimizations(context.packageName)

        val isCallScreeningRoleHeld = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val rm = context.getSystemService(Context.ROLE_SERVICE) as? RoleManager
            rm?.isRoleHeld(RoleManager.ROLE_CALL_SCREENING) ?: false
        } else {
            true
        }

        val areNotificationsEnabled = NotificationManagerCompat.from(context).areNotificationsEnabled()

        val canScheduleExactAlarms = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.canScheduleExactAlarms()
        } else {
            true
        }

        val brand = getDeviceBrand()

        return mapOf(
            "brand" to brand.name,
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "androidVersion" to Build.VERSION.RELEASE,
            "sdkInt" to Build.VERSION.SDK_INT,
            "batteryOptimizationExempt" to isIgnoringBatteryOptimizations,
            "callScreeningRoleHeld" to isCallScreeningRoleHeld,
            "notificationsEnabled" to areNotificationsEnabled,
            "exactAlarmAllowed" to canScheduleExactAlarms,
            "needsAutostartWarning" to (brand == OemBrand.XIAOMI || brand == OemBrand.OPPO || brand == OemBrand.REALME || brand == OemBrand.VIVO)
        )
    }

    fun getOemSettingIntent(context: Context, target: String): Intent {
        val brand = getDeviceBrand()
        val packageName = context.packageName

        return when (target.lowercase()) {
            "autostart" -> getAutostartIntent(context, brand)
            "battery" -> getBatteryOptimizationIntent(packageName)
            "exact_alarm" -> getExactAlarmIntent(packageName)
            "app_details" -> getAppDetailsIntent(packageName)
            else -> getAppDetailsIntent(packageName)
        }
    }

    private fun getAutostartIntent(context: Context, brand: OemBrand): Intent {
        val intentList = when (brand) {
            OemBrand.XIAOMI -> listOf(
                Intent().setComponent(ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")),
                Intent("miui.intent.action.OP_AUTO_START").addCategory(Intent.CATEGORY_DEFAULT)
            )
            OemBrand.OPPO, OemBrand.REALME -> listOf(
                Intent().setComponent(ComponentName("com.oplus.battery", "com.oplus.battery.AppBatteryUseActivity")).apply {
                    data = Uri.parse("package:${context.packageName}")
                },
                Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")),
                Intent().setComponent(ComponentName("com.oplus.safecenter", "com.oplus.safecenter.permission.startup.StartupAppListActivity")),
                Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity")),
                Intent().setComponent(ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity")),
                Intent().setComponent(ComponentName("com.oplus.safecenter", "com.oplus.safecenter.startupapp.StartupAppListActivity")),
                Intent().setComponent(ComponentName("com.coloros.oppoguardelf", "com.coloros.powermanager.fuelgaue.PowerUsageModelActivity")),
                Intent("com.coloros.safecenter.permission.startup")
            )
            OemBrand.VIVO -> listOf(
                Intent().setComponent(ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.PurviewTabActivity")),
                Intent().setComponent(ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")),
                Intent().setComponent(ComponentName("com.iqoo.secure", "com.iqoo.secure.MainGuideActivity"))
            )
            OemBrand.SAMSUNG -> listOf(
                Intent().setComponent(ComponentName("com.samsung.android.lool", "com.samsung.android.sm.battery.ui.BatteryActivity")),
                Intent().setComponent(ComponentName("com.samsung.android.sm", "com.samsung.android.sm.ui.battery.BatteryActivity"))
            )
            OemBrand.ONEPLUS -> listOf(
                Intent().setComponent(ComponentName("com.oneplus.security", "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity"))
            )
            else -> emptyList()
        }

        for (intent in intentList) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (context.packageManager.resolveActivity(intent, 0) != null) {
                return intent
            }
        }

        // Fallback to Application Details
        return getAppDetailsIntent(context.packageName)
    }

    private fun getBatteryOptimizationIntent(packageName: String): Intent {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        } else {
            getAppDetailsIntent(packageName)
        }
    }

    private fun getExactAlarmIntent(packageName: String): Intent {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        } else {
            getAppDetailsIntent(packageName)
        }
    }

    private fun getAppDetailsIntent(packageName: String): Intent {
        return Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:$packageName")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    }
}

