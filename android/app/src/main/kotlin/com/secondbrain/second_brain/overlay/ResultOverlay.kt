package com.secondbrain.second_brain.overlay

import android.content.Context
import android.graphics.PixelFormat
import android.os.Build
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import com.secondbrain.second_brain.R

class ResultOverlay(private val context: Context) {
    private var overlayView: View? = null
    private var windowManager: WindowManager? = null

    fun show(text: String, onSave: () -> Unit, onDismiss: () -> Unit) {
        hide()

        windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

        val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutFlag,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
            x = 0
            y = 0
            horizontalMargin = 0f
            dimAmount = 0.3f
        }

        val inflater = LayoutInflater.from(context)
        // We'll use a simple TextView-based layout programmatically for now
        overlayView = inflater.inflate(R.layout.overlay_result, null).apply {
            findViewById<TextView>(R.id.resultText).text = text
            findViewById<View>(R.id.saveButton).setOnClickListener {
                onSave()
                hide()
            }
            findViewById<View>(R.id.dismissButton).setOnClickListener {
                onDismiss()
                hide()
            }
        }

        windowManager?.addView(overlayView, params)
    }

    fun hide() {
        overlayView?.let { view ->
            try { windowManager?.removeView(view) } catch (_: Exception) {}
            overlayView = null
        }
    }
}
