package com.secondbrain.second_brain.service

import android.app.Activity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class WorkerChannelHandler {
    private val channelName = "com.secondbrain/worker"
    private var methodChannel: MethodChannel? = null

    fun register(flutterEngine: FlutterEngine, activity: Activity) {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "scheduleCleanup" -> {
                        CleanupWorker.schedule(activity.applicationContext)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    fun unregister() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
    }
}
