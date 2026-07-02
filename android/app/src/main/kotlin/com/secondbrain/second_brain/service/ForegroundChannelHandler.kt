package com.secondbrain.second_brain.service

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class ForegroundChannelHandler {
    private val channelName = "com.secondbrain/foreground_service"

    fun register(flutterEngine: FlutterEngine, activity: Activity) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            if (ContextCompat.checkSelfPermission(
                                    activity, Manifest.permission.POST_NOTIFICATIONS
                                ) != PackageManager.PERMISSION_GRANTED
                            ) {
                                result.error("PERMISSION_DENIED", "Notification permission not granted", null)
                                return@setMethodCallHandler
                            }
                        }
                        ForegroundService.start(activity.applicationContext)
                        result.success(true)
                    }
                    "stopService" -> {
                        ForegroundService.stop(activity.applicationContext)
                        result.success(true)
                    }
                    "isRunning" -> {
                        result.success(false)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    fun unregister() {}
}
