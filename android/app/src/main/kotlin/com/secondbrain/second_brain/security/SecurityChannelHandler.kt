package com.secondbrain.second_brain.security

import android.app.Activity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class SecurityChannelHandler {
    private var keyStoreHandler: KeyStoreHandler? = null
    private val channelName = "com.secondbrain/secure_key"

    fun register(flutterEngine: FlutterEngine, activity: Activity) {
        keyStoreHandler = KeyStoreHandler(activity.applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDbKey" -> {
                        try {
                            val key = keyStoreHandler?.getOrCreateDbKey()
                            if (key != null) {
                                result.success(key)
                            } else {
                                result.error("KEY_ERROR", "Failed to get database key", null)
                            }
                        } catch (e: Exception) {
                            result.error("KEY_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    fun unregister() {
        keyStoreHandler = null
    }
}
