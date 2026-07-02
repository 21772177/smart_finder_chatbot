package com.secondbrain.second_brain.capture

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.secondbrain.second_brain.MainActivity

class CaptureChannelHandler {
    private val channel = "com.secondbrain/capture"
    private var methodChannel: MethodChannel? = null
    private var mediaProjectionManager: MediaProjectionManager? = null
    private var pendingResult: MethodChannel.Result? = null

    companion object {
        const val REQUEST_MEDIA_PROJECTION = 1001
        var projectionIntent: Intent? = null
            private set
        var projectionResultCode: Int = Activity.RESULT_CANCELED
            private set
    }

    fun register(engine: FlutterEngine, activity: MainActivity) {
        mediaProjectionManager = activity.getSystemService(Activity.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager

        methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, channel).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "captureScreen" -> {
                        if (projectionIntent != null) {
                            ScreenCaptureService.capture(activity) { path ->
                                if (path != null) result.success(path)
                                else result.error("CAPTURE_FAILED", "Failed to capture screen", null)
                            }
                        } else {
                            result.error("NO_PERMISSION", "MediaProjection permission not granted", null)
                        }
                    }
                    "requestMediaProjection" -> {
                        pendingResult = result
                        val intent = mediaProjectionManager?.createScreenCaptureIntent()
                        if (intent != null) {
                            activity.startActivityForResult(intent, REQUEST_MEDIA_PROJECTION)
                        } else {
                            result.success(false)
                        }
                    }
                    "hasMediaProjectionPermission" -> {
                        result.success(projectionIntent != null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    fun unregister() {
        methodChannel?.setMethodCallHandler(null)
    }

    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQUEST_MEDIA_PROJECTION) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                projectionIntent = data
                projectionResultCode = resultCode
                pendingResult?.success(true)
            } else {
                pendingResult?.success(false)
            }
            pendingResult = null
        }
    }
}
