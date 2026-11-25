package com.darb.darb

import android.app.DownloadManager
import android.content.ClipData
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "DarbUpdater"
        private const val CHANNEL = "com.darb/update"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "installApk" -> installFileApk(call.argument<String>("path"), result)
                        "startBackgroundDownload" -> {
                            val url = call.argument<String>("url")
                            val sha = call.argument<String>("sha256")?.lowercase()
                            val version = call.argument<Int>("versionCode")
                            if (url.isNullOrBlank() || !url.startsWith("https://") ||
                                sha == null || !sha.matches(Regex("^[a-f0-9]{64}$")) || version == null
                            ) {
                                result.error("INVALID_UPDATE", "Invalid background update metadata", null)
                                return@setMethodCallHandler
                            }
                            val prefs = getSharedPreferences(DarbUpdateDownloadReceiver.PREFS, MODE_PRIVATE)
                            val oldId = prefs.getLong(DarbUpdateDownloadReceiver.KEY_DOWNLOAD_ID, -1L)
                            if (oldId > 0L) (getSystemService(DOWNLOAD_SERVICE) as DownloadManager).remove(oldId)
                            val request = DownloadManager.Request(Uri.parse(url))
                                .setTitle("تحديث دازريفو")
                                .setDescription("جارٍ تنزيل الإصدار $version")
                                .setAllowedOverMetered(true)
                                .setAllowedOverRoaming(true)
                                // VISIBILITY_HIDDEN requires the privileged DOWNLOAD_WITHOUT_NOTIFICATION permission.
                                // Use a normal system notification so downloads work on standard Android devices.
                                .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
                                .setDestinationInExternalFilesDir(this, Environment.DIRECTORY_DOWNLOADS, "darb-update-$version.apk")
                            val id = (getSystemService(DOWNLOAD_SERVICE) as DownloadManager).enqueue(request)
                            prefs.edit().putLong(DarbUpdateDownloadReceiver.KEY_DOWNLOAD_ID, id)
                                .putString(DarbUpdateDownloadReceiver.KEY_SHA256, sha)
                                .putString(DarbUpdateDownloadReceiver.KEY_STATUS, "downloading")
                                .putString(DarbUpdateDownloadReceiver.KEY_ERROR, "")
                                .putInt("version_code", version).apply()
                            result.success(id)
                        }
                        "getBackgroundDownloadState" -> result.success(backgroundDownloadState())
                        "installBackgroundUpdate" -> installBackgroundUpdate(result)
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    Log.e(TAG, "Updater method ${call.method} failed", error)
                    result.error("UPDATER_ERROR", "${error.javaClass.simpleName}: ${error.message}", error.stackTraceToString())
                }
            }
    }

    private fun backgroundDownloadState(): Map<String, Any?> {
        val prefs = getSharedPreferences(DarbUpdateDownloadReceiver.PREFS, MODE_PRIVATE)
        val id = prefs.getLong(DarbUpdateDownloadReceiver.KEY_DOWNLOAD_ID, -1L)
        val status = prefs.getString(DarbUpdateDownloadReceiver.KEY_STATUS, "idle") ?: "idle"
        var progress = 0
        if (id > 0L && status == "downloading") {
            val query = DownloadManager.Query().setFilterById(id)
            (getSystemService(DOWNLOAD_SERVICE) as DownloadManager).query(query).use { cursor ->
                if (cursor.moveToFirst()) {
                    val total = cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES))
                    val downloaded = cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR))
                    if (total > 0) progress = ((downloaded * 100) / total).toInt().coerceIn(0, 100)
                }
            }
        }
        return mapOf("status" to status, "progress" to progress,
            "error" to prefs.getString(DarbUpdateDownloadReceiver.KEY_ERROR, ""),
            "versionCode" to prefs.getInt("version_code", 0))
    }

    private fun installBackgroundUpdate(result: MethodChannel.Result) {
        val prefs = getSharedPreferences(DarbUpdateDownloadReceiver.PREFS, MODE_PRIVATE)
        val uriText = prefs.getString(DarbUpdateDownloadReceiver.KEY_URI, null)
        if (prefs.getString(DarbUpdateDownloadReceiver.KEY_STATUS, "") != "ready" || uriText.isNullOrBlank()) {
            result.error("UPDATE_NOT_READY", "Verified background update is not ready", null)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !packageManager.canRequestPackageInstalls()) {
            startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName")))
            result.success("permission_required")
            return
        }
        val uri = Uri.parse(uriText)
        val installIntent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            clipData = ClipData.newUri(contentResolver, "DAZREVO APK update", uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(installIntent)
        result.success("opened")
    }

    private fun installFileApk(path: String?, result: MethodChannel.Result) {
        if (path.isNullOrBlank()) {
            result.error("INVALID_PATH", "APK path is missing", null)
            return
        }
        val apk = File(path)
        if (!apk.isFile || !apk.canRead() || apk.length() == 0L) {
            result.error("APK_NOT_FOUND", "APK is missing, unreadable, or empty: $path", null)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !packageManager.canRequestPackageInstalls()) {
            startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName")))
            result.success("permission_required")
            return
        }
        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", apk)
        val installIntent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            clipData = ClipData.newUri(contentResolver, "DAZREVO APK update", uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(installIntent)
        result.success("opened")
    }
}
