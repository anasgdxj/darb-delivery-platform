package com.darb.darb

import android.app.DownloadManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import java.security.MessageDigest

class DarbUpdateDownloadReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != DownloadManager.ACTION_DOWNLOAD_COMPLETE) return
        val id = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1L)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (id <= 0L || id != prefs.getLong(KEY_DOWNLOAD_ID, -2L)) return

        val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val query = DownloadManager.Query().setFilterById(id)
        manager.query(query).use { cursor ->
            if (!cursor.moveToFirst()) return
            val status = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
            if (status != DownloadManager.STATUS_SUCCESSFUL) {
                val reason = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON))
                prefs.edit().putString(KEY_STATUS, "failed").putString(KEY_ERROR, "DownloadManager reason=$reason").apply()
                notifyUser(context, "فشل تنزيل التحديث", "افتح دَرْب وحاول تنزيل التحديث مجدداً")
                return
            }
        }

        val uri = manager.getUriForDownloadedFile(id)
        if (uri == null) {
            prefs.edit().putString(KEY_STATUS, "failed").putString(KEY_ERROR, "Downloaded APK URI is missing").apply()
            notifyUser(context, "تعذر التحقق من التحديث", "افتح دَرْب وحاول مجدداً")
            return
        }

        try {
            val expected = prefs.getString(KEY_SHA256, "") ?: ""
            val actual = context.contentResolver.openInputStream(uri)?.use { input ->
                val digest = MessageDigest.getInstance("SHA-256")
                val buffer = ByteArray(64 * 1024)
                while (true) {
                    val count = input.read(buffer)
                    if (count < 0) break
                    digest.update(buffer, 0, count)
                }
                digest.digest().joinToString("") { "%02x".format(it) }
            } ?: throw IllegalStateException("Cannot read downloaded APK")
            if (!expected.matches(Regex("^[a-fA-F0-9]{64}$")) || !actual.equals(expected, true)) {
                manager.remove(id)
                prefs.edit().putString(KEY_STATUS, "failed").putString(KEY_ERROR, "SHA-256 mismatch").apply()
                notifyUser(context, "فشل التحقق من التحديث", "تم رفض الملف لحماية التطبيق")
                return
            }
            prefs.edit().putString(KEY_STATUS, "ready").putString(KEY_URI, uri.toString())
                .putString(KEY_ERROR, "").apply()
            notifyUser(context, "التحديث جاهز", "اضغط هنا لفتح مُثبّت أندرويد وإكمال التحديث", uri)
        } catch (error: Exception) {
            Log.e(TAG, "Background APK verification failed", error)
            prefs.edit().putString(KEY_STATUS, "failed").putString(KEY_ERROR, error.message ?: error.javaClass.simpleName).apply()
            notifyUser(context, "تعذر التحقق من التحديث", "افتح دَرْب وحاول مجدداً")
        }
    }

    private fun notifyUser(context: Context, title: String, message: String, installUri: Uri? = null) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(NotificationChannel(CHANNEL_ID, "تحديثات دَرْب", NotificationManager.IMPORTANCE_DEFAULT))
        }
        val tapIntent = if (installUri != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                !context.packageManager.canRequestPackageInstalls()
            ) {
                Intent(
                    android.provider.Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:${context.packageName}")
                )
            } else {
                Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(installUri, "application/vnd.android.package-archive")
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            }
        } else {
            context.packageManager.getLaunchIntentForPackage(context.packageName)
        }
        val pending = tapIntent?.let {
            PendingIntent.getActivity(
                context,
                NOTIFICATION_ID,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or
                    (if (Build.VERSION.SDK_INT >= 23) PendingIntent.FLAG_IMMUTABLE else 0)
            )
        }
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_download_done)
            .setContentTitle(title).setContentText(message).setAutoCancel(true)
            .setContentIntent(pending).build()
        manager.notify(NOTIFICATION_ID, notification)
    }

    companion object {
        const val PREFS = "darb_update_download"
        const val KEY_DOWNLOAD_ID = "download_id"
        const val KEY_SHA256 = "sha256"
        const val KEY_STATUS = "status"
        const val KEY_URI = "uri"
        const val KEY_ERROR = "error"
        const val CHANNEL_ID = "darb_updates"
        const val NOTIFICATION_ID = 7301
        private const val TAG = "DarbUpdateReceiver"
    }
}
