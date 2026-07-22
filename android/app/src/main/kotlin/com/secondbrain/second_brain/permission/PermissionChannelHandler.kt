package com.secondbrain.second_brain.permission

import android.Manifest
import android.app.Activity
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat
import com.secondbrain.second_brain.capture.CaptureChannelHandler
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class PermissionChannelHandler {
    private val channelName = "com.secondbrain/permissions"

    fun register(flutterEngine: FlutterEngine, activity: Activity) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkAll" -> {
                        result.success(checkAllPermissions(activity))
                    }
                    "openOverlaySettings" -> {
                        val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                        intent.data = android.net.Uri.parse("package:${activity.packageName}")
                        activity.startActivity(intent)
                        result.success(true)
                    }
                    "openAccessibilitySettings" -> {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        activity.startActivity(intent)
                        result.success(true)
                    }
                    "openNotificationSettings" -> {
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                                putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName)
                            }
                        } else {
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = android.net.Uri.parse("package:${activity.packageName}")
                            }
                        }
                        activity.startActivity(intent)
                        result.success(true)
                    }
                    "openAppSettings" -> {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = android.net.Uri.parse("package:${activity.packageName}")
                        }
                        activity.startActivity(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    fun unregister() {}

    private fun checkAllPermissions(activity: Activity): Map<String, Any> {
        return mapOf(
            "overlay" to Settings.canDrawOverlays(activity),
            "accessibility" to isAccessibilityEnabled(activity),
            "notifications" to areNotificationsEnabled(activity),
            "audio" to hasPermission(activity, Manifest.permission.RECORD_AUDIO),
            "media_projection" to (CaptureChannelHandler.projectionIntent != null),
        )
    }

    private fun isAccessibilityEnabled(context: Context): Boolean {
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

    private fun areNotificationsEnabled(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.areNotificationsEnabled()
        } else true
    }

    private fun hasPermission(context: Context, permission: String): Boolean {
        return ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
    }
}
