package com.secondbrain.second_brain.llm

object LlmNative {
    private var loaded = false

    fun isLoaded(): Boolean = loaded

    fun loadModel(modelPath: String): Boolean {
        return try {
            if (!loaded) {
                System.loadLibrary("second_brain_llm")
                loaded = true
            }
            nativeLoadModel(modelPath)
        } catch (e: UnsatisfiedLinkError) {
            false
        }
    }

    fun generate(prompt: String, maxTokens: Int, temperature: Float): String? {
        if (!loaded) return null
        return try {
            nativeGenerate(prompt, maxTokens, temperature)
        } catch (e: Exception) {
            null
        }
    }

    fun unloadModel() {
        if (!loaded) return
        try {
            nativeUnloadModel()
        } catch (_: Exception) {}
    }

    private external fun nativeLoadModel(modelPath: String): Boolean
    private external fun nativeGenerate(prompt: String, maxTokens: Int, temperature: Float): String?
    private external fun nativeUnloadModel()
}
