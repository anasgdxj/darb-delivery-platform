package com.darb.darb

import android.app.DownloadManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.ClipData
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
                notifyAppFallback(context, "فشل تنزيل التحديث", "افتح دازريفو وحاول تنزيل التحديث مجدداً")
                return
            }
        }

        val uri = manager.getUriForDownloadedFile(id)
        if (uri == null) {
            prefs.edit().putString(KEY_STATUS, "failed").putString(KEY_ERROR, "Downloaded APK URI is missing").apply()
            notifyAppFallback(context, "تعذر التحقق من التحديث", "افتح دازريفو وحاول مجدداً")
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
                notifyAppFallback(context, "فشل التحقق من التحديث", "تم رفض الملف لحماية دازريفو")
                return
            }
            prefs.edit()
                .putString(KEY_STATUS, "ready")
                .putString(KEY_URI, uri.toString())
                .putString(KEY_ERROR, "")
                .apply()
            notifyReadyToInstall(context, uri)
        } catch (error: Exception) {
            Log.e(TAG, "Background APK verification failed", error)
            prefs.edit().putString(KEY_STATUS, "failed").putString(KEY_ERROR, error.message ?: error.javaClass.simpleName).apply()
            notifyAppFallback(context, "تعذر التحقق من التحديث", "افتح دازريفو وحاول مجدداً")
        }
    }

    private fun ensureChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "تحديثات دازريفو",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "إشعارات جاهزية التحديث وتثبيته لتطبيق دازريفو"
                enableVibration(true)
                setShowBadge(true)
            }
            manager.createNotificationChannel(channel)
        }
    }

    private fun resolveSmallIcon(context: Context): Int {
        val iconId = context.resources.getIdentifier("ic_notification", "drawable", context.packageName)
        return if (iconId != 0) iconId else android.R.drawable.stat_sys_download_done
    }

    private fun pendingIntentFlags(): Int {
        return PendingIntent.FLAG_UPDATE_CURRENT or
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
    }

    private fun notifyReadyToInstall(context: Context, uri: Uri) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        ensureChannel(manager)
        val canInstallDirectly =
            Build.VERSION.SDK_INT < Build.VERSION_CODES.O || context.packageManager.canRequestPackageInstalls()
        val targetIntent: Intent = if (canInstallDirectly) {
            Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                clipData = ClipData.newUri(context.contentResolver, "DAZREVO APK update", uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        } else {
            Intent(context, MainActivity::class.java).apply {
                action = MainActivity.ACTION_INSTALL_UPDATE
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP
                )
            }
        }
        val pending = PendingIntent.getActivity(
            context,
            NOTIFICATION_ID,
            targetIntent,
            pendingIntentFlags()
        )
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(resolveSmallIcon(context))
            .setContentTitle("التحديث جاهز للتثبيت")
            .setContentText("اضغط لتثبيت تحديث دازريفو مباشرة")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pending)
            .build()
        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun notifyAppFallback(context: Context, title: String, message: String) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        ensureChannel(manager)
        val openApp = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pending = openApp?.let {
            PendingIntent.getActivity(context, NOTIFICATION_ID + 1, it, pendingIntentFlags())
        }
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(resolveSmallIcon(context))
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pending)
            .build()
        manager.notify(NOTIFICATION_ID, notification)
    }

    companion object {
        const val PREFS = "darb_update_download"
        const val KEY_DOWNLOAD_ID = "download_id"
        const val KEY_SHA256 = "sha256"
        const val KEY_STATUS = "status"
        const val KEY_URI = "uri"
        const val KEY_ERROR = "error"
        const val KEY_VERSION_CODE = "version_code"
        const val KEY_AUTO_UPDATE_ENABLED = "auto_update_enabled"
        const val KEY_WIFI_ONLY = "wifi_only"
        const val CHANNEL_ID = "dazrevo_updates"
        const val NOTIFICATION_ID = 7301
        private const val TAG = "DarbUpdateReceiver"
    }
}
