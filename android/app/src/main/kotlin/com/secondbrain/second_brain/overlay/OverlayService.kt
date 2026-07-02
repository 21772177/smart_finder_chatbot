package com.secondbrain.second_brain.overlay

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.secondbrain.second_brain.R

class OverlayAccessibilityService : AccessibilityService() {

    companion object {
        var isConnected = false
            private set
        var isShowing = false
            private set
        var flutterEngine: FlutterEngine? = null
        private var instance: OverlayAccessibilityService? = null

        fun showBubble(engine: FlutterEngine) {
            flutterEngine = engine
            instance?.let { svc ->
                svc.showFloatingBubble()
                isShowing = true
            }
        }

        fun hideBubble() {
            instance?.let { svc ->
                svc.hideFloatingBubble()
                isShowing = false
            }
        }
    }

    private var overlayView: View? = null
    private var windowManager: WindowManager? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                    AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                    AccessibilityEvent.TYPE_VIEW_CLICKED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 100
        }
        serviceInfo = info
        instance = this
        isConnected = true
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_VIEW_CLICKED) {
            notifyFlutter("onViewClicked", event.text?.joinToString(""))
        }
    }

    override fun onInterrupt() {}

    private fun showFloatingBubble() {
        if (overlayView != null) return

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutFlag,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 0
            y = 100
        }

        val inflater = LayoutInflater.from(this)
        overlayView = inflater.inflate(R.layout.overlay_bubble, null).apply {
            setOnClickListener {
                notifyFlutter("onOverlayTap", null)
            }
        }

        windowManager?.addView(overlayView, params)
    }

    private fun hideFloatingBubble() {
        overlayView?.let { view ->
            windowManager?.removeView(view)
            overlayView = null
        }
    }

    private fun notifyFlutter(method: String, args: Any?) {
        val engine = flutterEngine ?: return
        try {
            MethodChannel(engine.dartExecutor.binaryMessenger, "com.secondbrain/overlay")
                .invokeMethod(method, args)
        } catch (_: Exception) {}
    }

    override fun onDestroy() {
        hideFloatingBubble()
        instance = null
        isConnected = false
        super.onDestroy()
    }
}
