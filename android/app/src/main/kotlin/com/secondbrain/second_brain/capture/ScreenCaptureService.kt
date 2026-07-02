package com.secondbrain.second_brain.capture

import android.app.Activity
import android.content.Context
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Handler
import android.os.Looper
import java.io.File
import java.io.FileOutputStream

object ScreenCaptureService {
    private var mediaProjection: MediaProjection? = null

    fun initialize(context: Context) {
        val manager = context.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val intent = CaptureChannelHandler.projectionIntent
        val resultCode = CaptureChannelHandler.projectionResultCode
        if (intent != null) {
            mediaProjection = manager.getMediaProjection(resultCode, intent)
        }
    }

    fun capture(context: Context, callback: (String?) -> Unit) {
        val projection = mediaProjection
        if (projection == null) {
            initialize(context)
            if (mediaProjection == null) {
                callback(null)
                return
            }
        }

        val projectionNonNull = mediaProjection ?: run {
            callback(null)
            return
        }

        val displayMetrics = context.resources.displayMetrics
        val density = displayMetrics.densityDpi
        val width = displayMetrics.widthPixels
        val height = displayMetrics.heightPixels

        val imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)

        val virtualDisplay: VirtualDisplay? = projectionNonNull.createVirtualDisplay(
            "ScreenCapture",
            width, height, density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader.surface, null, null
        )

        val handler = Handler(Looper.getMainLooper())

        imageReader.setOnImageAvailableListener({ reader ->
            val image = reader.acquireLatestImage()
            if (image != null) {
                val planes = image.planes
                val buffer = planes[0].buffer
                val pixelStride = planes[0].pixelStride
                val rowStride = planes[0].rowStride
                val rowPadding = rowStride - pixelStride * width

                val bitmap = Bitmap.createBitmap(width + rowPadding / pixelStride, height, Bitmap.Config.ARGB_8888)
                bitmap.copyPixelsFromBuffer(buffer)

                val cropBitmap = Bitmap.createBitmap(bitmap, 0, 0, width, height)

                val file = File(context.cacheDir, "capture_${System.currentTimeMillis()}.png")
                FileOutputStream(file).use { out ->
                    cropBitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
                }

                cropBitmap.recycle()
                bitmap.recycle()
                image.close()

                handler.post {
                    virtualDisplay?.release()
                    imageReader.close()
                    callback(file.absolutePath)
                }
            } else {
                handler.post {
                    virtualDisplay?.release()
                    imageReader.close()
                    callback(null)
                }
            }
        }, handler)

        handler.postDelayed({
            virtualDisplay?.release()
            imageReader.close()
            callback(null)
        }, 5000)
    }
}
