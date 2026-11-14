package com.dalsc.voicemail_assistant

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.File
import java.io.FileReader
import java.io.FileWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.UUID
import java.util.concurrent.Executors

object DiagnosticLogger {
    private const val MAX_LOG_SIZE_BYTES = 2 * 1024 * 1024L // 2 MB
    private const val LOG_FILE_NAME = "call_diagnostics.jsonl"
    private const val OLD_LOG_FILE_NAME = "call_diagnostics.old.jsonl"

    private val executor = Executors.newSingleThreadExecutor()
    private val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
        timeZone = TimeZone.getTimeZone("UTC")
    }

    data class CallEvent(
        val callId: String = UUID.randomUUID().toString(),
        val rawNumber: String,
        val carrier: String,
        val dndActive: Boolean,
        val selectedMode: String,
        val ruleMatched: String,
        val decision: String,
        val fallbackChain: List<String> = emptyList(),
        val latencyMs: Long,
        val success: Boolean,
        val error: String? = null
    )

    fun logCall(context: Context, event: CallEvent) {
        val appContext = context.applicationContext
        executor.execute {
            try {
                val logDir = File(appContext.filesDir, "diagnostics")
                if (!logDir.exists()) logDir.mkdirs()

                val logFile = File(logDir, LOG_FILE_NAME)

                // Rotate if file exceeds maximum size
                if (logFile.exists() && logFile.length() > MAX_LOG_SIZE_BYTES) {
                    val oldFile = File(logDir, OLD_LOG_FILE_NAME)
                    if (oldFile.exists()) oldFile.delete()
                    logFile.renameTo(oldFile)
                }

                val json = JSONObject().apply {
                    put("call_id", event.callId)
                    put("timestamp", isoFormat.format(Date()))
                    put("caller_masked", maskPhoneNumber(event.rawNumber))
                    put("carrier", event.carrier)
                    put("dnd_active", event.dndActive)
                    put("selected_mode", event.selectedMode)
                    put("rule_matched", event.ruleMatched)
                    put("decision", event.decision)
                    put("fallback_chain", JSONArray(event.fallbackChain))
                    put("latency_ms", event.latencyMs)
                    put("success", event.success)
                    if (event.error != null) {
                        put("error", event.error)
                    }
                }

                FileWriter(logFile, true).use { writer ->
                    writer.write(json.toString())
                    writer.write("\n")
                }
            } catch (e: Exception) {
                // Failsafe: Never crash or bubble up errors to telephony binder
            }
        }
    }

    fun getRecentLogs(context: Context, limit: Int = 50): List<Map<String, Any>> {
        val list = mutableListOf<Map<String, Any>>()
        try {
            val logFile = File(File(context.filesDir, "diagnostics"), LOG_FILE_NAME)
            if (!logFile.exists()) return list

            val lines = mutableListOf<String>()
            BufferedReader(FileReader(logFile)).use { reader ->
                var line = reader.readLine()
                while (line != null) {
                    if (line.isNotBlank()) lines.add(line)
                    line = reader.readLine()
                }
            }

            // Return latest entries first
            val targetLines = lines.takeLast(limit).reversed()
            for (line in targetLines) {
                try {
                    val json = JSONObject(line)
                    val map = mutableMapOf<String, Any>()
                    val keys = json.keys()
                    while (keys.hasNext()) {
                        val key = keys.next()
                        if (key == "fallback_chain") {
                            val arr = json.getJSONArray(key)
                            val fallbacks = mutableListOf<String>()
                            for (i in 0 until arr.length()) fallbacks.add(arr.getString(i))
                            map[key] = fallbacks
                        } else {
                            map[key] = json.get(key)
                        }
                    }
                    list.add(map)
                } catch (_: Exception) {}
            }
        } catch (e: Exception) {
            // Failsafe
        }
        return list
    }

    fun exportLogs(context: Context): File? {
        return try {
            val logDir = File(context.filesDir, "diagnostics")
            val currentFile = File(logDir, LOG_FILE_NAME)
            if (currentFile.exists()) currentFile else null
        } catch (e: Exception) {
            null
        }
    }

    fun clearLogs(context: Context): Boolean {
        return try {
            val logDir = File(context.filesDir, "diagnostics")
            val currentFile = File(logDir, LOG_FILE_NAME)
            val oldFile = File(logDir, OLD_LOG_FILE_NAME)
            if (currentFile.exists()) currentFile.delete()
            if (oldFile.exists()) oldFile.delete()
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun maskPhoneNumber(phone: String): String {
        val digits = phone.filter { it.isDigit() }
        if (digits.length < 5) return "***"
        val last4 = digits.takeLast(4)
        val prefix = if (phone.startsWith("+91")) "+91 " else ""
        return "${prefix}****** $last4"
    }
}

