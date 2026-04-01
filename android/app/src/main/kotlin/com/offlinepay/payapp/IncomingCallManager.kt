package com.offlinepay.payapp

import android.content.Context
import android.content.Intent
import android.telecom.Call

object IncomingCallManager {

    private var activeCall: Call? = null
    var appContext: Context? = null

    fun onCallAdded(call: Call) {
        activeCall = call

        // If USSD session is active — notify Flutter to show warning
        if (UssdSessionManager.isSessionActive()) {
            UssdBridge.onIncomingCallDuringSession()
            return
        }

        // No active USSD session — show normal incoming call screen
        val context = appContext ?: return
        val intent = Intent(context, IncomingCallActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            putExtra("caller_name", call.details.callerDisplayName ?: "Unknown")
            putExtra(
                "caller_number",
                call.details.handle?.schemeSpecificPart ?: ""
            )
        }
        context.startActivity(intent)
    }

    fun onCallRemoved(call: Call) {
        if (activeCall == call) activeCall = null
    }

    fun answerCall() {
        activeCall?.answer(android.telecom.VideoProfile.STATE_AUDIO_ONLY)
    }

    fun rejectCall() {
        activeCall?.disconnect()
        activeCall = null
    }

    fun getActiveCall(): Call? = activeCall
}