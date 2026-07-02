package com.secondbrain.second_brain.overlay

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.secondbrain.second_brain.MainActivity

class OverlayChannelHandler {
    private val channel = "com.secondbrain/overlay"
    private var methodChannel: MethodChannel? = null
    private var resultOverlay: ResultOverlay? = null

    fun register(engine: FlutterEngine, activity: MainActivity) {
        OverlayAccessibilityService.flutterEngine = engine

        methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, channel).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "startOverlay" -> {
                        if (hasOverlayPermission(activity)) {
                            if (OverlayAccessibilityService.isConnected) {
                                OverlayAccessibilityService.showBubble(engine)
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        } else {
                            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                            intent.data = android.net.Uri.parse("package:${activity.packageName}")
                            activity.startActivity(intent)
                            result.success(false)
                        }
                    }
                    "stopOverlay" -> {
                        OverlayAccessibilityService.hideBubble()
                        resultOverlay?.hide()
                        result.success(true)
                    }
                    "isOverlayActive" -> {
                        result.success(OverlayAccessibilityService.isShowing)
                    }
                    "requestAccessibilityPermission" -> {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        activity.startActivity(intent)
                        result.success(true)
                    }
                    "isAccessibilityEnabled" -> {
                        result.success(isAccessibilityServiceEnabled(activity))
                    }
                    "showResult" -> {
                        val text = call.argument<String>("text") ?: ""
                        showResultOverlay(activity, text, engine)
                        result.success(true)
                    }
                    "hideResult" -> {
                        resultOverlay?.hide()
                        result.success(true)
                    }
                    "getCurrentApp" -> {
                        result.success(OverlayAccessibilityService.currentPackage)
                    }
                    "getInstalledApps" -> {
                        result.success(getInstalledApps(activity))
                    }
                    "extractUiText" -> {
                        result.success(OverlayAccessibilityService.extractUiTextFromInstance())
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun getInstalledApps(activity: MainActivity): List<Map<String, String>> {
        val pm = activity.packageManager
        val intent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val apps = mutableListOf<Map<String, String>>()
        val resolved = pm.queryIntentActivities(intent, 0)
        for (info in resolved) {
            apps.add(mapOf(
                "package" to info.activityInfo.packageName,
                "name" to info.loadLabel(pm).toString()
            ))
        }
        apps.sortBy { it["name"]?.lowercase() }
        return apps
    }

    fun unregister() {
        methodChannel?.setMethodCallHandler(null)
        resultOverlay?.hide()
    }

    private fun showResultOverlay(activity: MainActivity, text: String, engine: FlutterEngine) {
        resultOverlay?.hide()
        resultOverlay = ResultOverlay(activity)

        val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.secondbrain/overlay")

        resultOverlay?.show(
            text = text,
            onSave = {
                channel.invokeMethod("onSaveCapture", null)
            },
            onDismiss = {
                channel.invokeMethod("onDismissCapture", null)
            }
        )
    }

    private fun hasOverlayPermission(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(context)
        } else true
    }

    private fun isAccessibilityServiceEnabled(context: Context): Boolean {
        val service = "${context.packageName}/.overlay.OverlayAccessibilityService"
        return try {
            val enabledServices = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            enabledServices?.contains(service) == true
        } catch (_: Exception) {
            false
        }
    }
}
