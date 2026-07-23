package com.secondbrain.second_brain.overlay

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import com.secondbrain.second_brain.R

class ResultOverlay(private val context: Context) {
    private var overlayView: View? = null
    private var windowManager: WindowManager? = null

    private fun isDarkMode(): Boolean {
        val nightModeFlags = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        return nightModeFlags == Configuration.UI_MODE_NIGHT_YES
    }

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

        val dark = isDarkMode()
        val bgColor = if (dark) Color.parseColor("#1E1E1E") else Color.WHITE
        val textColor = if (dark) Color.parseColor("#E0E0E0") else Color.parseColor("#212121")
        val subtitleColor = if (dark) Color.parseColor("#AAAAAA") else Color.parseColor("#757575")
        val btnBgColor = if (dark) Color.parseColor("#2C2C2C") else Color.parseColor("#F0F0F0")
        val btnTextColor = if (dark) Color.parseColor("#90CAF9") else Color.parseColor("#1565C0")
        val borderColor = if (dark) Color.parseColor("#333333") else Color.parseColor("#E0E0E0")
        val radius = 24f

        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20), dp(16), dp(20), dp(16))
            background = GradientDrawable().apply {
                setColor(bgColor)
                setStroke(dp(1), borderColor)
                this.cornerRadius = radius
            }
        }

        val titleView = TextView(context).apply {
            this.text = "Screen Content"
            setTextColor(subtitleColor)
            textSize = 14f
            setPadding(0, 0, 0, dp(8))
        }
        container.addView(titleView)

        val scrollView = android.widget.ScrollView(context)
        val resultView = TextView(context).apply {
            this.text = text
            setTextColor(textColor)
            textSize = 15f
            maxLines = 15
            setPadding(0, 0, 0, dp(12))
        }
        scrollView.addView(resultView)
        container.addView(scrollView, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ))

        val buttonRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.END
        }

        val dismissBtn = Button(context).apply {
            this.text = "Dismiss"
            setTextColor(btnTextColor)
            setBackgroundColor(Color.TRANSPARENT)
            isAllCaps = false
            textSize = 14f
            setPadding(dp(12), dp(8), dp(12), dp(8))
            setOnClickListener {
                onDismiss()
                hide()
            }
        }

        val saveBtn = Button(context).apply {
            this.text = "Save to Memory"
            setTextColor(btnTextColor)
            setBackgroundColor(Color.TRANSPARENT)
            isAllCaps = false
            textSize = 14f
            setPadding(dp(12), dp(8), dp(12), dp(8))
            setOnClickListener {
                onSave()
                hide()
            }
        }

        buttonRow.addView(dismissBtn)
        buttonRow.addView(saveBtn)
        container.addView(buttonRow)

        overlayView = container
        windowManager?.addView(overlayView, params)
    }

    private fun dp(value: Int): Int {
        return (value * context.resources.displayMetrics.density + 0.5f).toInt()
    }

    fun hide() {
        overlayView?.let { view ->
            try { windowManager?.removeView(view) } catch (_: Exception) {}
            overlayView = null
        }
    }
}
