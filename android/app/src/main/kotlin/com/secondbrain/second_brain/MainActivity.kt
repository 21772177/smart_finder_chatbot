package com.secondbrain.second_brain

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.secondbrain.second_brain.overlay.OverlayChannelHandler
import com.secondbrain.second_brain.capture.CaptureChannelHandler
import com.secondbrain.second_brain.llm.LocalLlmChannelHandler
import com.secondbrain.second_brain.audio.AudioTranscriptionHandler
import com.secondbrain.second_brain.security.SecurityChannelHandler

class MainActivity : FlutterActivity() {
    private val overlayHandler = OverlayChannelHandler()
    private val captureHandler = CaptureChannelHandler()
    private val llmHandler = LocalLlmChannelHandler()
    private val audioHandler = AudioTranscriptionHandler()
    private val securityHandler = SecurityChannelHandler()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        overlayHandler.register(flutterEngine, this)
        captureHandler.register(flutterEngine, this)
        llmHandler.register(flutterEngine, this)
        audioHandler.register(flutterEngine, this)
        securityHandler.register(flutterEngine, this)
    }

    override fun onDestroy() {
        overlayHandler.unregister()
        captureHandler.unregister()
        llmHandler.unregister()
        audioHandler.unregister()
        securityHandler.unregister()
        super.onDestroy()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        captureHandler.handleActivityResult(requestCode, resultCode, data)
    }
}
