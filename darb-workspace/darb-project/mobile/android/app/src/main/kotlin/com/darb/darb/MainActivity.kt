package com.darb.darb

import android.app.DownloadManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ClipData
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.os.Build
import android.os.Bundle
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
        private const val HIGH_NOTIFICATION_CHANNEL_ID = "dazrevo_high_importance"
        private const val FALLBACK_NOTIFICATION_CHANNEL_ID = "fcm_fallback_notification_channel"
        const val ACTION_INSTALL_UPDATE = "com.darb.darb.ACTION_INSTALL_UPDATE"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
        handleInstallIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleInstallIntent(intent)
    }

    private fun handleInstallIntent(intent: Intent?) {
        if (intent?.action != ACTION_INSTALL_UPDATE) return
        launchReadyBackgroundInstall(null)
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NOTIFICATION_SERVICE) as? NotificationManager ?: return
        val highChannel = NotificationChannel(
            HIGH_NOTIFICATION_CHANNEL_ID,
            "إشعارات دازريفو الفورية",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "تنبيهات الطلبات وتحديثات المندوبين وإصدارات التطبيق"
            enableVibration(true)
            setShowBadge(true)
        }
        val fallbackChannel = NotificationChannel(
            FALLBACK_NOTIFICATION_CHANNEL_ID,
            "التنبيهات العامة",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "إشعارات النظام الفورية"
            enableVibration(true)
            setShowBadge(true)
        }
        val updatesChannel = NotificationChannel(
            DarbUpdateDownloadReceiver.CHANNEL_ID,
            "تحديثات دازريفو",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "إشعارات جاهزية التحديث وتثبيته لتطبيق دازريفو"
            enableVibration(true)
            setShowBadge(true)
        }
        manager.createNotificationChannel(highChannel)
        manager.createNotificationChannel(fallbackChannel)
        manager.createNotificationChannel(updatesChannel)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "installApk" -> installFileApk(call.argument<String>("path"), result)
                        "getUpdatePreferences" -> result.success(readUpdatePreferences())
                        "setUpdatePreferences" -> {
                            val autoEnabled = call.argument<Boolean>(DarbUpdateDownloadReceiver.KEY_AUTO_UPDATE_ENABLED)
                            val wifiOnly = call.argument<Boolean>(DarbUpdateDownloadReceiver.KEY_WIFI_ONLY)
                            result.success(saveUpdatePreferences(autoEnabled, wifiOnly))
                        }
                        "startBackgroundDownload" -> startBackgroundDownload(
                            url = call.argument<String>("url"),
                            sha = call.argument<String>("sha256")?.lowercase(),
                            version = call.argument<Int>("versionCode"),
                            autoTriggered = call.argument<Boolean>("autoTriggered") ?: false,
                            wifiOnlyOverride = call.argument<Boolean>("wifiOnly"),
                            result = result
                        )
                        "getBackgroundDownloadState" -> result.success(backgroundDownloadState())
                        "installBackgroundUpdate" -> launchReadyBackgroundInstall(result)
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    Log.e(TAG, "Updater method ${call.method} failed", error)
                    result.error(
                        "UPDATER_ERROR",
                        "${error.javaClass.simpleName}: ${error.message}",
                        error.stackTraceToString()
                    )
                }
            }
    }

    private fun readUpdatePreferences(): Map<String, Boolean> {
        val prefs = getSharedPreferences(DarbUpdateDownloadReceiver.PREFS, MODE_PRIVATE)
        return mapOf(
            DarbUpdateDownloadReceiver.KEY_AUTO_UPDATE_ENABLED to
                prefs.getBoolean(DarbUpdateDownloadReceiver.KEY_AUTO_UPDATE_ENABLED, true),
            DarbUpdateDownloadReceiver.KEY_WIFI_ONLY to
                prefs.getBoolean(DarbUpdateDownloadReceiver.KEY_WIFI_ONLY, true)
        )
    }

    private fun saveUpdatePreferences(
        autoEnabled: Boolean?,
        wifiOnly: Boolean?
    ): Map<String, Boolean> {
        val prefs = getSharedPreferences(DarbUpdateDownloadReceiver.PREFS, MODE_PRIVATE)
        val editor = prefs.edit()
        if (autoEnabled != null) {
            editor.putBoolean(DarbUpdateDownloadReceiver.KEY_AUTO_UPDATE_ENABLED, autoEnabled)
        }
        if (wifiOnly != null) {
            editor.putBoolean(DarbUpdateDownloadReceiver.KEY_WIFI_ONLY, wifiOnly)
        }
        editor.apply()
        return readUpdatePreferences()
    }

    private fun isReadableContentUri(uriText: String?): Boolean {
        if (uriText.isNullOrBlank()) return false
        return try {
            contentResolver.openInputStream(Uri.parse(uriText))?.use { true } ?: false
        } catch (_: Exception) {
            false
        }
    }

    private fun isDownloadActive(downloadId: Long): Boolean {
        if (downloadId <= 0L) return false
        return try {
            val manager = getSystemService(DOWNLOAD_SERVICE) as DownloadManager
            val query = DownloadManager.Query().setFilterById(downloadId)
            manager.query(query).use { cursor ->
                if (!cursor.moveToFirst()) return false
                val status = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
                status == DownloadManager.STATUS_PENDING ||
                    status == DownloadManager.STATUS_RUNNING ||
                    status == DownloadManager.STATUS_PAUSED
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun isMeteredOrCellularNetwork(): Boolean {
        return try {
            val cm = getSystemService(CONNECTIVITY_SERVICE) as? ConnectivityManager ?: return false
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val active = cm.activeNetwork ?: return false
                val caps = cm.getNetworkCapabilities(active) ?: return cm.isActiveNetworkMetered
                val hasUnmeteredTransport =
                    caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
                        caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)
                if (!hasUnmeteredTransport && caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) {
                    return true
                }
                !hasUnmeteredTransport || cm.isActiveNetworkMetered
            } else {
                cm.isActiveNetworkMetered
            }
        } catch (_: SecurityException) {
            false
        } catch (_: Exception) {
            false
        }
    }

    private fun startBackgroundDownload(
        url: String?,
        sha: String?,
        version: Int?,
        autoTriggered: Boolean,
        wifiOnlyOverride: Boolean?,
        result: MethodChannel.Result
    ) {
        if (url.isNullOrBlank() || !url.startsWith("https://") ||
            sha == null || !sha.matches(Regex("^[a-f0-9]{64}$")) || version == null
        ) {
            result.error("INVALID_UPDATE", "Invalid background update metadata", null)
            return
        }

        val prefs = getSharedPreferences(DarbUpdateDownloadReceiver.PREFS, MODE_PRIVATE)
        val autoEnabled = prefs.getBoolean(DarbUpdateDownloadReceiver.KEY_AUTO_UPDATE_ENABLED, true)
        if (autoTriggered && !autoEnabled) {
            result.error("AUTO_UPDATE_DISABLED", "Automatic updates are disabled", null)
            return
        }

        val oldId = prefs.getLong(DarbUpdateDownloadReceiver.KEY_DOWNLOAD_ID, -1L)
        val existingStatus = prefs.getString(DarbUpdateDownloadReceiver.KEY_STATUS, "idle") ?: "idle"
        val existingVersion = prefs.getInt(DarbUpdateDownloadReceiver.KEY_VERSION_CODE, 0)
        val existingSha = prefs.getString(DarbUpdateDownloadReceiver.KEY_SHA256, "") ?: ""
        val existingUri = prefs.getString(DarbUpdateDownloadReceiver.KEY_URI, null)

        // Prevent duplicate download of the exact same verified or active version.
        if (existingVersion == version && existingSha.equals(sha, true)) {
            if (existingStatus == "ready" && isReadableContentUri(existingUri)) {
                result.success(oldId)
                return
            }
            if (existingStatus == "downloading" && isDownloadActive(oldId)) {
                result.success(oldId)
                return
            }
        }

        val wifiOnly = wifiOnlyOverride ?: prefs.getBoolean(DarbUpdateDownloadReceiver.KEY_WIFI_ONLY, true)
        if (wifiOnly && isMeteredOrCellularNetwork()) {
            result.error("WIFI_REQUIRED", "Wi-Fi connection is required by update settings", null)
            return
        }

        val manager = getSystemService(DOWNLOAD_SERVICE) as DownloadManager
        if (oldId > 0L) manager.remove(oldId)

        val request = DownloadManager.Request(Uri.parse(url))
            .setTitle("تحديث دازريفو")
            .setDescription("جارٍ تنزيل الإصدار $version")
            .setAllowedOverMetered(!wifiOnly)
            .setAllowedOverRoaming(!wifiOnly)
            .setAllowedNetworkTypes(
                if (wifiOnly) DownloadManager.Request.NETWORK_WIFI
                else (DownloadManager.Request.NETWORK_WIFI or DownloadManager.Request.NETWORK_MOBILE)
            )
            // VISIBILITY_HIDDEN requires the privileged DOWNLOAD_WITHOUT_NOTIFICATION permission.
            // Use VISIBILITY_VISIBLE during download so only our SHA-256-verified completion
            // notification triggers Package Installer on tap.
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE)
            .setDestinationInExternalFilesDir(this, Environment.DIRECTORY_DOWNLOADS, "darb-update-$version.apk")

        val id = manager.enqueue(request)
        prefs.edit()
            .putLong(DarbUpdateDownloadReceiver.KEY_DOWNLOAD_ID, id)
            .putString(DarbUpdateDownloadReceiver.KEY_SHA256, sha)
            .putString(DarbUpdateDownloadReceiver.KEY_STATUS, "downloading")
            .putString(DarbUpdateDownloadReceiver.KEY_ERROR, "")
            .putString(DarbUpdateDownloadReceiver.KEY_URI, "")
            .putInt(DarbUpdateDownloadReceiver.KEY_VERSION_CODE, version)
            .apply()
        result.success(id)
    }

    private fun backgroundDownloadState(): Map<String, Any?> {
        val prefs = getSharedPreferences(DarbUpdateDownloadReceiver.PREFS, MODE_PRIVATE)
        val id = prefs.getLong(DarbUpdateDownloadReceiver.KEY_DOWNLOAD_ID, -1L)
        var status = prefs.getString(DarbUpdateDownloadReceiver.KEY_STATUS, "idle") ?: "idle"
        var progress = 0
        if (status == "ready" && !isReadableContentUri(prefs.getString(DarbUpdateDownloadReceiver.KEY_URI, null))) {
            prefs.edit().putString(DarbUpdateDownloadReceiver.KEY_STATUS, "idle").putString(DarbUpdateDownloadReceiver.KEY_URI, "").apply()
            status = "idle"
        }
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
        return mapOf(
            "status" to status,
            "progress" to progress,
            "error" to prefs.getString(DarbUpdateDownloadReceiver.KEY_ERROR, ""),
            "versionCode" to prefs.getInt(DarbUpdateDownloadReceiver.KEY_VERSION_CODE, 0)
        )
    }

    private fun launchReadyBackgroundInstall(result: MethodChannel.Result?) {
        val prefs = getSharedPreferences(DarbUpdateDownloadReceiver.PREFS, MODE_PRIVATE)
        val uriText = prefs.getString(DarbUpdateDownloadReceiver.KEY_URI, null)
        if (prefs.getString(DarbUpdateDownloadReceiver.KEY_STATUS, "") != "ready" || uriText.isNullOrBlank()) {
            result?.error("UPDATE_NOT_READY", "Verified background update is not ready", null)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !packageManager.canRequestPackageInstalls()) {
            startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName")))
            result?.success("permission_required")
            return
        }
        val uri = Uri.parse(uriText)
        val installIntent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            clipData = ClipData.newUri(contentResolver, "DAZREVO APK update", uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(installIntent)
        result?.success("opened")
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
