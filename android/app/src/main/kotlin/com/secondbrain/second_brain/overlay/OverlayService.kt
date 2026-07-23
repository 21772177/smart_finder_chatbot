package com.secondbrain.second_brain.overlay

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.PixelFormat
import android.os.Build
import android.util.DisplayMetrics
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.secondbrain.second_brain.R

class OverlayAccessibilityService : AccessibilityService() {

    companion object {
        var isConnected = false
            private set
        var isShowing = false
            private set
        var currentPackage: String? = null
            private set
        var flutterEngine: FlutterEngine? = null
        private var instance: OverlayAccessibilityService? = null
        private var lastUiText: String? = null

        // Settings
        var scanOnLike = true
        var scanOnSave = true
        var enableBuffer = true

        private val settingsListener = object : SharedPreferences.OnSharedPreferenceChangeListener {
            override fun onSharedPreferenceChanged(prefs: SharedPreferences?, key: String?) {
                when (key) {
                    "flutter.scan_on_like" -> scanOnLike = prefs?.getBoolean("flutter.scan_on_like", true) ?: true
                    "flutter.scan_on_save" -> scanOnSave = prefs?.getBoolean("flutter.scan_on_save", true) ?: true
                    "flutter.enable_buffer" -> enableBuffer = prefs?.getBoolean("flutter.enable_buffer", true) ?: true
                }
            }
        }

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

        fun extractUiTextFromInstance(): String? {
            return instance?.extractUiText()
        }

        fun getBufferFromInstance(): String? {
            return instance?.getBuffer()
        }

        fun clearBufferFromInstance() {
            instance?.clearBuffer()
        }

        private fun loadSettings(context: Context) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            scanOnLike = prefs.getBoolean("flutter.scan_on_like", true)
            scanOnSave = prefs.getBoolean("flutter.scan_on_save", true)
            enableBuffer = prefs.getBoolean("flutter.enable_buffer", true)
        }
    }

    private var overlayView: View? = null
    private var overlayParams: WindowManager.LayoutParams? = null
    private var windowManager: WindowManager? = null
    private var instanceLastUiText: String? = null
    private var textBuffer = mutableListOf<String>()

    override fun onServiceConnected() {
        super.onServiceConnected()
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                    AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                    AccessibilityEvent.TYPE_VIEW_CLICKED or
                    AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 100
        }
        serviceInfo = info
        instance = this
        isConnected = true
        loadSettings(this)

        // Listen for live setting changes from the Flutter side
        getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .registerOnSharedPreferenceChangeListener(settingsListener)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        when (event?.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                event.packageName?.let { pkg ->
                    currentPackage = pkg.toString()
                    notifyFlutter("onAppChanged", pkg.toString())
                }
            }
            AccessibilityEvent.TYPE_VIEW_CLICKED -> {
                val text = event.text?.joinToString("")
                notifyFlutter("onViewClicked", text)
                checkLikeSaveClick(event)
            }
            AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED -> {
                if (enableBuffer) {
                    handleTextChange(event)
                }
            }
        }
    }

    override fun onInterrupt() {}

    private fun checkLikeSaveClick(event: AccessibilityEvent) {
        val source = event.source ?: return
        val className = source.className?.toString() ?: ""
        val text = event.text?.joinToString("")?.lowercase() ?: ""
        val contentDesc = source.contentDescription?.toString()?.lowercase() ?: ""

        val isLike = text.contains("like") || contentDesc.contains("like") ||
            className.contains("Like") || className.contains("like")
        val isSave = text.contains("save") || contentDesc.contains("save") ||
            className.contains("Save") || className.contains("save")

        if ((isLike && scanOnLike) || (isSave && scanOnSave)) {
            notifyFlutter("onOverlayTap", null)
        }
        source.recycle()
    }

    private fun handleTextChange(event: AccessibilityEvent) {
        val source = event.source ?: return
        val textList = event.text
        if (textList == null) {
            source.recycle()
            return
        }
        val text = textList.joinToString("").trim()
        if (text.isNotEmpty()) {
            textBuffer.add(text)
            if (textBuffer.size > 50) textBuffer.removeAt(0)
        }
        source.recycle()
    }

    fun getBuffer(): String {
        return textBuffer.joinToString(" ")
    }

    fun clearBuffer() {
        textBuffer.clear()
    }

    fun extractUiText(): String? {
        val root = rootInActiveWindow ?: return instanceLastUiText ?: lastUiText
        val texts = mutableListOf<String>()
        collectText(root, texts)
        root.recycle()
        val result = texts.joinToString("\n").trim()
        if (result.isNotEmpty()) {
            instanceLastUiText = result
            lastUiText = result
        }
        return result.ifEmpty { instanceLastUiText ?: lastUiText }
    }

    private fun collectText(node: AccessibilityNodeInfo, texts: MutableList<String>) {
        if (!node.isVisibleToUser) return

        val text = node.text?.toString()?.trim()
        if (!text.isNullOrEmpty()) {
            texts.add(text)
        }

        val contentDesc = node.contentDescription?.toString()?.trim()
        if (!contentDesc.isNullOrEmpty()) {
            texts.add(contentDesc)
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                collectText(child, texts)
                child.recycle()
            }
        }
    }

    private fun showFloatingBubble() {
        if (overlayView != null) return

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val savedX = prefs.getInt("flutter.overlay_x", 0)
        val savedY = prefs.getInt("flutter.overlay_y", 100)

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutFlag,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = savedX
            y = savedY
        }
        overlayParams = params

        val density = resources.displayMetrics.density
        val clickThreshold = (10 * density + 0.5f).toInt()

        val inflater = LayoutInflater.from(this)
        overlayView = inflater.inflate(R.layout.overlay_bubble, null).apply {
            var initialX = 0
            var initialY = 0
            var initialTouchX = 0f
            var initialTouchY = 0f
            var moved = false

            setOnTouchListener { _, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = params.x
                        initialY = params.y
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        moved = false
                        true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val dx = (event.rawX - initialTouchX).toInt()
                        val dy = (event.rawY - initialTouchY).toInt()
                        if (dx * dx + dy * dy > clickThreshold * clickThreshold) {
                            moved = true
                        }
                        params.x = initialX + dx
                        params.y = initialY + dy
                        try {
                            windowManager?.updateViewLayout(this@apply, params)
                        } catch (_: Exception) {}
                        true
                    }
                    MotionEvent.ACTION_UP -> {
                        if (!moved) {
                            notifyFlutter("onOverlayTap", null)
                        } else {
                            prefs.edit()
                                .putInt("flutter.overlay_x", params.x)
                                .putInt("flutter.overlay_y", params.y)
                                .apply()
                        }
                        true
                    }
                    else -> false
                }
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