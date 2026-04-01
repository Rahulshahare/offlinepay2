package com.offlinepay.payapp

import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.telecom.TelecomManager
import android.telephony.SubscriptionManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val METHOD_CHANNEL = "com.offlinepay.payapp/ussd"
    private val EVENT_CHANNEL  = "com.offlinepay.payapp/events"

    private val REQUEST_DEFAULT_DIALER = 1001

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        IncomingCallManager.appContext = applicationContext
        UssdSessionManager
    }

    override fun onResume() {
        super.onResume()
        // Silently become default dialer when app is active
        // (after first-time permission already granted)
        acquireDefaultDialerSilently()
    }

    override fun onPause() {
        super.onPause()
        // Do not restore here — only restore on explicit app exit
        // to avoid dialog spam on Android 10+
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_DEFAULT_DIALER) {
            val granted = isDefaultDialer()
            defaultDialerResultCallback?.invoke(granted)
            defaultDialerResultCallback = null
        }
    }

    private var defaultDialerResultCallback: ((Boolean) -> Unit)? = null

    // ── Flutter engine setup ──────────────────────────────────────────────────

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── EventChannel ──────────────────────────────────────────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    UssdBridge.setSink(events)
                }
                override fun onCancel(arguments: Any?) {
                    UssdBridge.setSink(null)
                }
            })

        // ── MethodChannel ─────────────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // ── Dialer role ───────────────────────────────────────────
                    "isDefaultDialer" -> {
                        result.success(isDefaultDialer())
                    }

                    "requestDefaultDialer" -> {
                        requestDefaultDialer { granted ->
                            result.success(granted)
                        }
                    }

                    // ── SIM slots ─────────────────────────────────────────────
                    "getSimSlots" -> {
                        result.success(getSimSlots())
                    }

                    // ── USSD session ──────────────────────────────────────────
                    "dialUssd" -> {
                        val code  = call.argument<String>("code")
                        val subId = call.argument<Int>("subscriptionId")
                        if (code == null) {
                            result.error("INVALID_ARG", "No USSD code", null)
                        } else {
                            dialUssd(code, subId, result)
                        }
                    }

                    "sendReply" -> {
                        val text = call.argument<String>("text") ?: ""
                        UssdSessionManager.sendReply(text)
                        result.success(null)
                    }

                    "endSession" -> {
                        UssdSessionManager.endSession()
                        result.success(null)
                    }

                    "setCurrentStep" -> {
                        val step = call.argument<String>("step") ?: ""
                        UssdSessionManager.setCurrentStep(step)
                        result.success(null)
                    }

                    "isSessionActive" -> {
                        result.success(UssdSessionManager.isSessionActive())
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // ── Default dialer helpers ────────────────────────────────────────────────

    private fun isDefaultDialer(): Boolean {
        val telecom = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
        return telecom.defaultDialerPackage == packageName
    }

    private fun acquireDefaultDialerSilently() {
        if (isDefaultDialer()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(RoleManager::class.java)
            if (roleManager.isRoleAvailable(RoleManager.ROLE_DIALER) &&
                !roleManager.isRoleHeld(RoleManager.ROLE_DIALER)
            ) {
                // Only request silently if previously granted
                // Full request happens during onboarding
            }
        }
    }

    private fun requestDefaultDialer(callback: (Boolean) -> Unit) {
        defaultDialerResultCallback = callback

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(RoleManager::class.java)
            if (roleManager.isRoleHeld(RoleManager.ROLE_DIALER)) {
                callback(true)
                defaultDialerResultCallback = null
                return
            }
            val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_DIALER)
            startActivityForResult(intent, REQUEST_DEFAULT_DIALER)
        } else {
            // Android 8-9 fallback
            val intent = Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER).apply {
                putExtra(
                    TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME,
                    packageName
                )
            }
            startActivityForResult(intent, REQUEST_DEFAULT_DIALER)
        }
    }

    // ── SIM slots ─────────────────────────────────────────────────────────────

    @Suppress("MissingPermission")
    private fun getSimSlots(): List<Map<String, Any>> {
        val sm = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE)
                as SubscriptionManager
        return (sm.activeSubscriptionInfoList ?: emptyList()).map { info ->
            mapOf(
                "subscriptionId" to info.subscriptionId,
                "simSlotIndex"   to info.simSlotIndex,
                "displayName"    to (info.displayName?.toString()
                    ?: "SIM ${info.simSlotIndex + 1}"),
                "carrierName"    to (info.carrierName?.toString() ?: "Unknown"),
                "number"         to (info.number ?: "")
            )
        }
    }

    // ── Dial USSD via TelecomManager ──────────────────────────────────────────

    @Suppress("MissingPermission")
    private fun dialUssd(
        code: String,
        subscriptionId: Int?,
        result: MethodChannel.Result
    ) {
        try {
            val telecom = getSystemService(Context.TELECOM_SERVICE) as TelecomManager

            // Build tel: URI with encoded USSD code
            val encoded = code.replace("#", "%23")
            val uri     = android.net.Uri.parse("tel:$encoded")

            // Build extras for SIM selection
            val extras = android.os.Bundle()
            if (subscriptionId != null) {
                extras.putInt(
                    "android.telecom.extra.SUBSCRIPTION_ID",
                    subscriptionId
                )
            }

            // Place the call — InCallService will receive it
            telecom.placeCall(uri, extras)

            result.success(null)
        } catch (e: Exception) {
            result.error("DIAL_ERROR", e.message, null)
        }
    }
}