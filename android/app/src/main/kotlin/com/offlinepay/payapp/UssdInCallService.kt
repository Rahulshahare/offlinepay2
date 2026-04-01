package com.offlinepay.payapp

import android.telecom.Call
import android.telecom.InCallService

class UssdInCallService : InCallService() {

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)

        // Check if this is a USSD call
        if (call.details.hasProperty(Call.Details.PROPERTY_GENERIC_CONFERENCE)) {
            // USSD call — hand off to session manager
            UssdSessionManager.onCallAdded(call)
            return
        }

        // Regular incoming/outgoing call — hand off to incoming call handler
        IncomingCallManager.onCallAdded(call)
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
        UssdSessionManager.onCallRemoved(call)
        IncomingCallManager.onCallRemoved(call)
    }
}