package com.dalsc.voicemail_assistant

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telecom.Call
import android.telecom.VideoProfile
import android.util.Log

class CallActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        val call = VoicemailInCallService.activeCall

        Log.i("CallActionReceiver", "Received action: $action, activeCall: $call")

        when (action) {
            VoicemailInCallService.ACTION_ANSWER -> {
                try {
                    call?.answer(VideoProfile.STATE_AUDIO_ONLY)
                    Log.i("CallActionReceiver", "Call answered via notification button")
                } catch (e: Exception) {
                    Log.e("CallActionReceiver", "Error answering call: ${e.message}")
                }
            }

            VoicemailInCallService.ACTION_DECLINE -> {
                try {
                    call?.reject(Call.REJECT_REASON_DECLINED)
                    Log.i("CallActionReceiver", "Call declined via notification button")
                } catch (e: Exception) {
                    Log.e("CallActionReceiver", "Error declining call: ${e.message}")
                }
            }
        }
    }
}

