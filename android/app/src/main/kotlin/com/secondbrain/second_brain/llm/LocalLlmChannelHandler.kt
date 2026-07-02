package com.secondbrain.second_brain.llm

import android.content.Context
import android.os.Environment
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.net.URL

class LocalLlmChannelHandler {
    private val channelName = "com.secondbrain/llm"
    private var methodChannel: MethodChannel? = null
    private var activeDownload: Thread? = null

    fun register(engine: FlutterEngine, context: Context) {
        methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, channelName).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "downloadModel" -> {
                        val url = call.argument<String>("url") ?: ""
                        val filename = call.argument<String>("filename") ?: ""
                        downloadModel(context, url, filename, result)
                    }
                    "loadModel" -> {
                        val path = call.argument<String>("path") ?: ""
                        loadModel(context, path, result)
                    }
                    "generate" -> {
                        val prompt = call.argument<String>("prompt") ?: ""
                        val maxTokens = call.argument<Int>("maxTokens") ?: 256
                        val temperature = call.argument<Double>("temperature") ?: 0.3
                        generate(prompt, maxTokens, temperature, result)
                    }
                    "unloadModel" -> {
                        unloadModel()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    fun unregister() {
        activeDownload?.interrupt()
        methodChannel?.setMethodCallHandler(null)
    }

    private fun downloadModel(context: Context, url: String, filename: String, result: MethodChannel.Result) {
        activeDownload = Thread {
            try {
                val modelsDir = File(context.filesDir, "models")
                modelsDir.mkdirs()
                val file = File(modelsDir, filename)

                val connection = URL(url).openConnection()
                connection.connect()

                val input = connection.getInputStream()
                val output = FileOutputStream(file)
                val buffer = ByteArray(8192)
                var bytesRead: Int
                var totalBytes = 0L
                val contentLength = connection.contentLengthLong

                while (input.read(buffer).also { bytesRead = it } != -1) {
                    if (Thread.interrupted()) {
                        input.close()
                        output.close()
                        file.delete()
                        result.success(false)
                        return@Thread
                    }
                    output.write(buffer, 0, bytesRead)
                    totalBytes += bytesRead
                }

                input.close()
                output.close()
                result.success(true)
            } catch (e: Exception) {
                result.error("DOWNLOAD_ERROR", e.message, null)
            }
        }
        activeDownload?.start()
    }

    private fun loadModel(context: Context, path: String, result: MethodChannel.Result) {
        try {
            val resolvedPath = if (path.startsWith("/")) {
                path
            } else {
                File(context.filesDir, "models/$path").absolutePath
            }
            val success = LlmNative.loadModel(resolvedPath)
            result.success(success)
        } catch (e: Exception) {
            result.error("LOAD_ERROR", e.message, null)
        }
    }

    private fun generate(prompt: String, maxTokens: Int, temperature: Double, result: MethodChannel.Result) {
        try {
            val response = LlmNative.generate(prompt, maxTokens, temperature.toFloat())
            result.success(response)
        } catch (e: Exception) {
            result.error("GENERATE_ERROR", e.message, null)
        }
    }

    private fun unloadModel() {
        LlmNative.unloadModel()
    }
}
