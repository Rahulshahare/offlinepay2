package com.offlinepay.payapp

import android.os.Handler
import android.os.Looper
import android.telecom.Call
import android.telecom.Connection

object UssdSessionManager {

    // ── Session state ─────────────────────────────────────────────────────────
    private var activeCall: Call?       = null
    private var isActive:   Boolean     = false
    private var currentStep: String     = ""

    // ── Timeout — *99# network timeout is ~180 seconds ────────────────────────
    private val timeoutHandler  = Handler(Looper.getMainLooper())
    private const val TIMEOUT_MS = 175_000L  // 175 seconds — slightly before network cuts
    private val timeoutRunnable = Runnable {
        UssdBridge.onSessionTimeout()
        endSession()
    }

    // ── Called by UssdInCallService when a call is added ─────────────────────
    fun onCallAdded(call: Call) {
        activeCall = call
        isActive   = true

        // Register callback to receive USSD responses
        call.registerCallback(callCallback)

        // Start timeout countdown
        startTimeout()
    }

    // ── Called by UssdInCallService when call is removed ─────────────────────
    fun onCallRemoved(call: Call) {
        if (activeCall == call) {
            endSession()
        }
    }

    // ── Send reply into live USSD session ─────────────────────────────────────
    fun sendReply(text: String) {
        activeCall?.sendUssdMessage(text)
        // Reset timeout on each interaction
        resetTimeout()
    }

    // ── End session cleanly ───────────────────────────────────────────────────
    fun endSession() {
        stopTimeout()
        activeCall?.unregisterCallback(callCallback)
        activeCall?.disconnect()
        activeCall = null
        isActive   = false
        currentStep = ""
    }

    fun isSessionActive(): Boolean = isActive

    fun setCurrentStep(step: String) {
        currentStep = step
    }

    // ── Timeout helpers ───────────────────────────────────────────────────────
    private fun startTimeout() {
        timeoutHandler.removeCallbacks(timeoutRunnable)
        timeoutHandler.postDelayed(timeoutRunnable, TIMEOUT_MS)
    }

    private fun resetTimeout() {
        timeoutHandler.removeCallbacks(timeoutRunnable)
        timeoutHandler.postDelayed(timeoutRunnable, TIMEOUT_MS)
    }

    private fun stopTimeout() {
        timeoutHandler.removeCallbacks(timeoutRunnable)
    }

    // ── Call callback — receives USSD responses from network ──────────────────
    private val callCallback = object : Call.Callback() {

        override fun onStateChanged(call: Call, state: Int) {
            when (state) {
                Call.STATE_DISCONNECTED -> {
                    val finalMsg = call.details.statusHints?.label?.toString() ?: ""
                    UssdBridge.onSessionEnd(finalMsg)
                    endSession()
                }
                Call.STATE_ACTIVE -> {
                    // Call connected — session started
                }
            }
        }

        override fun onDetailsChanged(call: Call, details: Call.Details) {
            // USSD response arrives here as status hints
            val response = details.statusHints?.label?.toString()
            if (!response.isNullOrBlank()) {
                processResponse(response)
            }
        }
    }

    // ── Process and forward each USSD response to Flutter ────────────────────
    private fun processResponse(message: String) {
        // Detect if session expects input or is a final message
        val expectsInput = detectExpectsInput(message)

        // Detect My Details response and parse it
        if (isMyDetailsResponse(message)) {
            parseAndEmitMyDetails(message)
            return
        }

        UssdBridge.onSessionResponse(
            message      = message,
            expectsInput = expectsInput,
            step         = currentStep
        )

        if (!expectsInput) {
            UssdBridge.onSessionEnd(message)
            endSession()
        }
    }

    // ── Detect if response expects user input ─────────────────────────────────
    private fun detectExpectsInput(message: String): Boolean {
        val lower = message.lowercase()
        // Final messages typically contain these patterns
        val finalPatterns = listOf(
            "transaction successful",
            "transaction failed",
            "insufficient funds",
            "invalid",
            "declined",
            "approved",
            "your balance",
            "amount debited",
            "request sent",
            "thank you"
        )
        return finalPatterns.none { lower.contains(it) }
    }

    // ── Detect My Details response ────────────────────────────────────────────
    private fun isMyDetailsResponse(message: String): Boolean {
        val lower = message.lowercase()
        return lower.contains("upi id") &&
               lower.contains("bank") &&
               (lower.contains("set") || lower.contains("not set"))
    }

    // ── Parse My Details from *99# response ───────────────────────────────────
    private fun parseAndEmitMyDetails(message: String) {
        // *99# My Details response format:
        // Name: John Doe
        // UPI ID: johndoe@upi
        // Bank: State Bank of India - 5734
        // UPI PIN: Set

        val lines = message.lines().map { it.trim() }.filter { it.isNotBlank() }

        var fullName     = ""
        var upiId        = ""
        var bankName     = ""
        var accountLast4 = ""
        var pinStatus    = ""

        for (line in lines) {
            val lower = line.lowercase()
            when {
                lower.startsWith("name:") ->
                    fullName = line.substringAfter(":").trim()

                lower.startsWith("upi id:") ->
                    upiId = line.substringAfter(":").trim()

                lower.startsWith("bank:") -> {
                    val bankPart = line.substringAfter(":").trim()
                    // Extract last 4 digits — "State Bank of India - 5734"
                    val dashIndex = bankPart.lastIndexOf("-")
                    if (dashIndex != -1) {
                        bankName     = bankPart.substring(0, dashIndex).trim()
                        accountLast4 = bankPart.substring(dashIndex + 1).trim()
                    } else {
                        bankName = bankPart
                    }
                }

                lower.startsWith("upi pin:") ->
                    pinStatus = line.substringAfter(":").trim()
            }
        }

        UssdBridge.onMyDetailsFetched(
            fullName     = fullName,
            upiId        = upiId,
            bankName     = bankName,
            accountLast4 = accountLast4,
            pinStatus    = pinStatus
        )
    }
}