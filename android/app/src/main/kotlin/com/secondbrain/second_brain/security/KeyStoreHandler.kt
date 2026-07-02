package com.secondbrain.second_brain.security

import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyStore
import java.util.Base64
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class KeyStoreHandler(private val context: Context) {

    private val sharedPrefs: SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private val keyStore: KeyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }

    companion object {
        private const val ANDROID_KEYSTORE = "AndroidKeyStore"
        private const val KEY_ALIAS = "second_brain_db_key_alias"
        private const val PREFS_NAME = "second_brain_keystore_prefs"
        private const val ENCRYPTED_KEY = "encrypted_db_key"
        private const val KEY_LENGTH = 32
        private const val GCM_TAG_LENGTH = 128
        private const val GCM_IV_LENGTH = 12
    }

    fun getOrCreateDbKey(): String {
        val encrypted = sharedPrefs.getString(ENCRYPTED_KEY, null)
        if (encrypted != null) {
            return decryptKey(encrypted)
        }

        val legacyKey = migrateFromSharedPreferences()
        if (legacyKey != null) {
            val encryptedKey = encryptKey(legacyKey)
            sharedPrefs.edit().putString(ENCRYPTED_KEY, encryptedKey).apply()
            return legacyKey
        }

        val newKey = generateRandomHexKey(64)
        val encryptedKey = encryptKey(newKey)
        sharedPrefs.edit().putString(ENCRYPTED_KEY, encryptedKey).apply()
        return newKey
    }

    private fun migrateFromSharedPreferences(): String? {
        val prefs = context.getSharedPreferences("flutter_shared_preferences", Context.MODE_PRIVATE)
        val oldKey = prefs.getString("second_brain_db_key", null)
        if (oldKey != null && oldKey.isNotEmpty()) {
            prefs.edit().remove("second_brain_db_key").apply()
            return oldKey
        }
        return null
    }

    private fun getOrCreateSecretKey(): SecretKey {
        val existing = keyStore.getEntry(KEY_ALIAS, null)
        if (existing != null) {
            return (existing as KeyStore.SecretKeyEntry).secretKey
        }

        val keyGenerator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            ANDROID_KEYSTORE
        )

        val spec = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(KEY_LENGTH * 8)
            .build()

        keyGenerator.init(spec)
        return keyGenerator.generateKey()
    }

    private fun encryptKey(plainText: String): String {
        val secretKey = getOrCreateSecretKey()
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, secretKey)
        val iv = cipher.iv
        val encrypted = cipher.doFinal(plainText.toByteArray(Charsets.UTF_8))
        val combined = ByteArray(GCM_IV_LENGTH + encrypted.size)
        System.arraycopy(iv, 0, combined, 0, GCM_IV_LENGTH)
        System.arraycopy(encrypted, 0, combined, GCM_IV_LENGTH, encrypted.size)
        return Base64.getEncoder().encodeToString(combined)
    }

    private fun decryptKey(encryptedBase64: String): String {
        val secretKey = getOrCreateSecretKey()
        val combined = Base64.getDecoder().decode(encryptedBase64)
        val iv = combined.copyOfRange(0, GCM_IV_LENGTH)
        val encrypted = combined.copyOfRange(GCM_IV_LENGTH, combined.size)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        val spec = GCMParameterSpec(GCM_TAG_LENGTH, iv)
        cipher.init(Cipher.DECRYPT_MODE, secretKey, spec)
        val decrypted = cipher.doFinal(encrypted)
        return String(decrypted, Charsets.UTF_8)
    }

    private fun generateRandomHexKey(length: Int): String {
        val hexChars = "0123456789abcdef"
        val seed = System.nanoTime()
        val random = java.util.Random(seed)
        return (1..length).map { hexChars[random.nextInt(16)] }.joinToString("")
    }
}
