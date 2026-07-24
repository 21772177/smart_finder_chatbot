package com.secondbrain.second_brain.service

import android.content.Context
import android.content.SharedPreferences
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import java.io.File
import java.util.concurrent.TimeUnit

class CleanupWorker(
    appContext: Context,
    params: WorkerParameters
) : CoroutineWorker(appContext, params) {

    companion object {
        private const val WORK_NAME = "second_brain_cleanup"
        private const val DEFAULT_RETENTION_DAYS = 30L
        private const val INTERVAL_HOURS = 24L

        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<CleanupWorker>(
                INTERVAL_HOURS, TimeUnit.HOURS
            ).build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request
            )
        }
    }

    private fun getRetentionDays(): Long {
        val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        return prefs.getInt("flutter.data_retention_days", DEFAULT_RETENTION_DAYS.toInt()).toLong()
    }

    override suspend fun doWork(): Result {
        return try {
            val retentionDays = getRetentionDays()
            cleanupOldCacheFiles(retentionDays)
            cleanupOldDbBackups(retentionDays)
            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }

    private fun cleanupOldCacheFiles(retentionDays: Long) {
        val cacheDir = applicationContext.cacheDir
        val cutoff = System.currentTimeMillis() - retentionDays * 24 * 60 * 60 * 1000
        cacheDir.listFiles()?.forEach { file ->
            if (file.lastModified() < cutoff) {
                file.delete()
            }
        }
    }

    private fun cleanupOldDbBackups(retentionDays: Long) {
        val backupDir = File(applicationContext.filesDir, "db_backups")
        if (!backupDir.exists()) return
        val cutoff = System.currentTimeMillis() - retentionDays * 24 * 60 * 60 * 1000
        backupDir.listFiles()?.forEach { file ->
            if (file.lastModified() < cutoff) {
                file.delete()
            }
        }
    }
}
