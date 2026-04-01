package com.offlinepay.payapp

import io.flutter.plugin.common.EventChannel

object UssdBridge {

    // ── Event types ───────────────────────────────────────────────────────────
    const val EVENT_SESSION_RESPONSE      = "session_response"
    const val EVENT_SESSION_END           = "session_end"
    const val EVENT_SESSION_ERROR         = "session_error"
    const val EVENT_SESSION_TIMEOUT       = "session_timeout"
    const val EVENT_INCOMING_CALL         = "incoming_call_during_session"
    const val EVENT_MY_DETAILS            = "my_details"

    // ── EventChannel sink — set by MainActivity ───────────────────────────────
    private var eventSink: EventChannel.EventSink? = null

    fun setSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    // ── Session events ────────────────────────────────────────────────────────

    fun onSessionResponse(message: String, expectsInput: Boolean, step: String) {
        emit(
            mapOf(
                "type"         to EVENT_SESSION_RESPONSE,
                "message"      to message,
                "expectsInput" to expectsInput,
                "step"         to step
            )
        )
    }

    fun onSessionEnd(finalMessage: String) {
        emit(
            mapOf(
                "type"    to EVENT_SESSION_END,
                "message" to finalMessage
            )
        )
    }

    fun onSessionError(reason: String) {
        emit(
            mapOf(
                "type"   to EVENT_SESSION_ERROR,
                "reason" to reason
            )
        )
    }

    fun onSessionTimeout() {
        emit(mapOf("type" to EVENT_SESSION_TIMEOUT))
    }

    fun onIncomingCallDuringSession() {
        emit(mapOf("type" to EVENT_INCOMING_CALL))
    }

    // ── My Details parsed from *99# response ──────────────────────────────────
    fun onMyDetailsFetched(
        fullName:     String,
        upiId:        String,
        bankName:     String,
        accountLast4: String,
        pinStatus:    String
    ) {
        emit(
            mapOf(
                "type"         to EVENT_MY_DETAILS,
                "fullName"     to fullName,
                "upiId"        to upiId,
                "bankName"     to bankName,
                "accountLast4" to accountLast4,
                "pinStatus"    to pinStatus
            )
        )
    }

    // ── Internal emit — always on main thread ─────────────────────────────────
    private fun emit(data: Any) {
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            eventSink?.success(data)
        }
    }
}