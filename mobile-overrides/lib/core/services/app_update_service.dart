import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/app_localizations.dart';
import '../storage/local_cache.dart';
import '../theme/darb_design_system.dart';
import '../widgets/darb_glass.dart';

const bool kDarbPlayStoreBuild = bool.fromEnvironment('DARB_PLAY_STORE');

class DarbUpdateInfo {
  final int versionCode;
  final String versionName;
  final String apkUrl;
  final String sha256;
  final String releaseNotes;

  const DarbUpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.apkUrl,
    required this.sha256,
    required this.releaseNotes,
  });

  factory DarbUpdateInfo.fromJson(Map<String, dynamic> json) => DarbUpdateInfo(
        versionCode: (json['versionCode'] as num).toInt(),
        versionName: json['versionName']?.toString() ?? '',
        apkUrl: json['apkUrl']?.toString() ?? '',
        sha256: json['sha256']?.toString().toLowerCase() ?? '',
        releaseNotes: json['releaseNotes']?.toString() ?? '',
      );
}

class DarbUpdater {
  DarbUpdater._();
  static final instance = DarbUpdater._();
  static const _channel = MethodChannel('com.darb/update');
  static const autoUpdatePrefKey = 'auto_update_enabled';
  static const wifiOnlyPrefKey = 'wifi_only';
  static const _releaseApi =
      'https://api.github.com/repos/anasgdxj/darb-delivery-platform/releases/tags/latest';
  static const _fallbackManifest =
      'https://github.com/anasgdxj/darb-delivery-platform/releases/download/latest/app-update.json';

  final availableUpdate = ValueNotifier<DarbUpdateInfo?>(null);
  final downloadProgress = ValueNotifier<double?>(null);
  final autoUpdateEnabledNotifier = ValueNotifier<bool>(true);
  final wifiOnlyNotifier = ValueNotifier<bool>(true);

  String? downloadedApkPath;
  Future<void>? _inFlightCheck;
  bool _inFlightForce = false;
  bool checkFailed = false;
  bool _preferencesRestored = false;
  int? _lastBackgroundVersionCode;

  @visibleForTesting
  http.Client? httpClientOverride;

  @visibleForTesting
  int? installedBuildOverride;

  @visibleForTesting
  String? supportDirPathOverride;

  bool get autoUpdateEnabled => autoUpdateEnabledNotifier.value;
  bool get wifiOnly => wifiOnlyNotifier.value;

  @visibleForTesting
  void debugResetForTest({
    bool autoUpdateEnabled = true,
    bool wifiOnly = true,
  }) {
    availableUpdate.value = null;
    downloadProgress.value = null;
    autoUpdateEnabledNotifier.value = autoUpdateEnabled;
    wifiOnlyNotifier.value = wifiOnly;
    downloadedApkPath = null;
    _inFlightCheck = null;
    _inFlightForce = false;
    checkFailed = false;
    _preferencesRestored = false;
    _lastBackgroundVersionCode = null;
    httpClientOverride = null;
    installedBuildOverride = null;
    supportDirPathOverride = null;
  }

  Future<void> restorePreferences({bool force = false}) async {
    if (_preferencesRestored && !force) return;
    var autoVal = autoUpdateEnabledNotifier.value;
    var wifiVal = wifiOnlyNotifier.value;
    var hasLocalAuto = false;
    var hasLocalWifi = false;

    try {
      final cachedAuto = await DarbLocalCache.instance.readJson(autoUpdatePrefKey);
      if (cachedAuto is bool) {
        autoVal = cachedAuto;
        hasLocalAuto = true;
      }
      final cachedWifi = await DarbLocalCache.instance.readJson(wifiOnlyPrefKey);
      if (cachedWifi is bool) {
        wifiVal = cachedWifi;
        hasLocalWifi = true;
      }
    } catch (_) {}

    if (!hasLocalAuto || !hasLocalWifi) {
      try {
        final nativePrefs =
            await _channel.invokeMapMethod<String, dynamic>('getUpdatePreferences');
        if (nativePrefs != null) {
          if (!hasLocalAuto && nativePrefs[autoUpdatePrefKey] is bool) {
            autoVal = nativePrefs[autoUpdatePrefKey] as bool;
          }
          if (!hasLocalWifi && nativePrefs[wifiOnlyPrefKey] is bool) {
            wifiVal = nativePrefs[wifiOnlyPrefKey] as bool;
          }
        }
      } catch (_) {}
    }

    autoUpdateEnabledNotifier.value = autoVal;
    wifiOnlyNotifier.value = wifiVal;
    _preferencesRestored = true;

    try {
      await _channel.invokeMethod<dynamic>('setUpdatePreferences', {
        autoUpdatePrefKey: autoVal,
        wifiOnlyPrefKey: wifiVal,
      });
    } catch (_) {}
  }

  Future<Map<String, bool>> getAutomaticUpdateSettings() async {
    await restorePreferences(force: true);
    return <String, bool>{
      autoUpdatePrefKey: autoUpdateEnabled,
      wifiOnlyPrefKey: wifiOnly,
    };
  }

  Future<void> saveAutomaticUpdateSettings({
    required bool enabled,
    required bool wifiOnly,
  }) async {
    await setAutoUpdateEnabled(enabled);
    await setWifiOnly(wifiOnly);
  }

  Future<void> runAutomaticUpdateCheck({bool force = false}) async {
    await restorePreferences();
    if (!autoUpdateEnabled && !force) return;
    await checkForUpdate(force: force);
  }

  Future<void> setAutoUpdateEnabled(bool enabled) async {
    autoUpdateEnabledNotifier.value = enabled;
    _preferencesRestored = true;
    try {
      await DarbLocalCache.instance.writeJson(autoUpdatePrefKey, enabled);
    } catch (_) {}
    try {
      await _channel.invokeMethod<dynamic>('setUpdatePreferences', {
        autoUpdatePrefKey: enabled,
      });
    } catch (_) {}
  }

  Future<void> setWifiOnly(bool wifiOnly) async {
    wifiOnlyNotifier.value = wifiOnly;
    _preferencesRestored = true;
    try {
      await DarbLocalCache.instance.writeJson(wifiOnlyPrefKey, wifiOnly);
    } catch (_) {}
    try {
      await _channel.invokeMethod<dynamic>('setUpdatePreferences', {
        wifiOnlyPrefKey: wifiOnly,
      });
    } catch (_) {}
  }

  Uri _cacheBustedUri(String value) {
    final uri = Uri.parse(value);
    final query = Map<String, String>.from(uri.queryParameters);
    query['_dazrevo_cache_bust'] =
        DateTime.now().microsecondsSinceEpoch.toString();
    return uri.replace(queryParameters: query);
  }

  Future<void> checkForUpdate({bool force = false}) async {
    if (kDarbPlayStoreBuild) {
      availableUpdate.value = null;
      checkFailed = false;
      return;
    }
    if (_inFlightCheck != null) {
      _inFlightForce = _inFlightForce || force;
      await _inFlightCheck;
      return;
    }
    _inFlightForce = force;
    final future = _runCheckForUpdate();
    _inFlightCheck = future;
    try {
      await future;
    } finally {
      _inFlightCheck = null;
      _inFlightForce = false;
    }
  }

  Future<void> _runCheckForUpdate() async {
    checkFailed = false;
    final ownsClient = httpClientOverride == null;
    final client = httpClientOverride ?? http.Client();
    try {
      await restorePreferences();
      Map<String, dynamic>? decoded;
      try {
        final response = await client.get(
          _cacheBustedUri(_releaseApi),
          headers: const {
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
            'Cache-Control': 'no-cache, no-store, max-age=0',
            'Pragma': 'no-cache',
          },
        ).timeout(const Duration(seconds: 12));
        if (response.statusCode == 200) {
          final release = jsonDecode(utf8.decode(response.bodyBytes));
          if (release is Map<String, dynamic> && release['assets'] is List) {
            final assets =
                (release['assets'] as List).whereType<Map<String, dynamic>>();
            Map<String, dynamic>? manifest;
            for (final asset in assets) {
              if (asset['name'] == 'app-update.json') {
                manifest = asset;
                break;
              }
            }
            final url = manifest?['browser_download_url']?.toString();
            if (url != null && url.startsWith('https://')) {
              final manifestResponse = await client
                  .get(
                    _cacheBustedUri(url),
                    headers: const {
                      'Cache-Control': 'no-cache, no-store, max-age=0',
                      'Pragma': 'no-cache',
                    },
                  )
                  .timeout(const Duration(seconds: 12));
              if (manifestResponse.statusCode == 200) {
                final value =
                    jsonDecode(utf8.decode(manifestResponse.bodyBytes));
                if (value is Map<String, dynamic>) decoded = value;
              }
            }
          }
        }
      } catch (_) {}
      if (decoded == null) {
        final fallback = await client.get(
          _cacheBustedUri(_fallbackManifest),
          headers: const {
            'Cache-Control': 'no-cache, no-store, max-age=0',
            'Pragma': 'no-cache',
          },
        ).timeout(const Duration(seconds: 12));
        if (fallback.statusCode != 200) {
          throw Exception('Update manifest unavailable');
        }
        final value = jsonDecode(utf8.decode(fallback.bodyBytes));
        if (value is! Map<String, dynamic>) {
          throw const FormatException('Invalid update manifest');
        }
        decoded = value;
      }
      final info = DarbUpdateInfo.fromJson(decoded);
      if (info.versionCode <= 0 ||
          !info.apkUrl.startsWith('https://') ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(info.sha256)) {
        throw const FormatException('Invalid update metadata');
      }
      final int installedBuild;
      if (installedBuildOverride != null) {
        installedBuild = installedBuildOverride!;
      } else {
        final package = await PackageInfo.fromPlatform();
        installedBuild = int.tryParse(package.buildNumber) ?? 0;
      }
      final newer = info.versionCode > installedBuild ? info : null;
      availableUpdate.value = newer;
      checkFailed = false;
      if (newer != null && !_inFlightForce && autoUpdateEnabled) {
        unawaited(maybeAutoDownload(newer));
      }
    } catch (_) {
      if (_inFlightForce) checkFailed = true;
    } finally {
      if (ownsClient) client.close();
    }
  }

  Future<bool> isVersionReadyOrDownloading(DarbUpdateInfo info) async {
    try {
      final state = await backgroundDownloadState();
      final status = state['status']?.toString();
      final version = (state['versionCode'] as num?)?.toInt() ?? 0;
      if (version == info.versionCode &&
          (status == 'ready' || status == 'downloading')) {
        return true;
      }
    } catch (_) {}

    try {
      final path = await _expectedApkPath(info.versionCode);
      final file = File(path);
      if (await file.exists()) {
        final hash = (await sha256.bind(file.openRead()).first).toString();
        if (hash == info.sha256) {
          downloadedApkPath = file.path;
          downloadProgress.value = 1;
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<bool> maybeAutoDownload(DarbUpdateInfo info) async {
    if (kDarbPlayStoreBuild) return false;
    await restorePreferences();
    if (!autoUpdateEnabled) return false;
    if (_lastBackgroundVersionCode == info.versionCode) return false;
    if (await isVersionReadyOrDownloading(info)) {
      _lastBackgroundVersionCode = info.versionCode;
      return false;
    }
    try {
      await startBackgroundDownload(info, autoTriggered: true);
      _lastBackgroundVersionCode = info.versionCode;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> _expectedApkPath(int versionCode) async {
    final base = supportDirPathOverride ??
        (await getApplicationSupportDirectory()).path;
    final updateDir = Directory('$base/updates');
    if (!await updateDir.exists()) await updateDir.create(recursive: true);
    return '${updateDir.path}/darb-update-$versionCode.apk';
  }

  Future<String> downloadUpdate(DarbUpdateInfo info) async {
    if (kDarbPlayStoreBuild) {
      throw StateError('APK self-update is disabled for Google Play builds');
    }
    final targetPath = await _expectedApkPath(info.versionCode);
    final file = File(targetPath);
    if (await file.exists()) {
      final existingHash = (await sha256.bind(file.openRead()).first).toString();
      if (existingHash == info.sha256) {
        downloadedApkPath = file.path;
        downloadProgress.value = 1;
        return file.path;
      }
    }

    downloadProgress.value = 0;
    final ownsClient = httpClientOverride == null;
    final client = httpClientOverride ?? http.Client();
    try {
      final partial = File('${file.path}.part');
      var completed = false;

      for (var attempt = 0; attempt < 4 && !completed; attempt++) {
        try {
          final existing = await partial.exists() ? await partial.length() : 0;
          final request = http.Request('GET', Uri.parse(info.apkUrl));
          if (existing > 0) request.headers['Range'] = 'bytes=$existing-';
          final response =
              await client.send(request).timeout(const Duration(seconds: 30));

          if (existing > 0 && response.statusCode == 200) {
            await partial.writeAsBytes(const [], flush: true);
          } else if (existing > 0 && response.statusCode != 206) {
            throw HttpException(
                'Server cannot resume download (HTTP ${response.statusCode})');
          } else if (existing == 0 && response.statusCode != 200) {
            throw HttpException('Download failed (HTTP ${response.statusCode})');
          }

          final append = existing > 0 && response.statusCode == 206;
          final startAt = append ? existing : 0;
          final contentRange = response.headers['content-range'];
          int? total;
          if (response.statusCode == 206 && contentRange != null) {
            final match =
                RegExp(r'^bytes \d+-\d+/(\d+)$').firstMatch(contentRange);
            if (match != null) total = int.tryParse(match.group(1)!);
            if (total == null) throw const FormatException('Invalid Content-Range');
          } else if (response.statusCode == 200) {
            total = response.contentLength;
          }

          var received = startAt;
          final sink =
              partial.openWrite(mode: append ? FileMode.append : FileMode.write);
          try {
            await for (final chunk
                in response.stream.timeout(const Duration(seconds: 45))) {
              sink.add(chunk);
              received += chunk.length;
              if (total != null && total > 0) {
                downloadProgress.value = (received / total).clamp(0.0, 1.0);
              }
            }
            await sink.flush();
          } finally {
            await sink.close();
          }

          if (total != null && received < total) {
            if (attempt == 3) {
              throw const SocketException('Download interrupted repeatedly');
            }
            continue;
          }
          if (total != null && received > total) {
            await partial.delete();
            throw const FormatException('Downloaded file size is invalid');
          }
          final actualHash =
              (await sha256.bind(partial.openRead()).first).toString();
          if (actualHash != info.sha256) {
            await partial.delete();
            throw const FormatException('APK checksum mismatch');
          }
          if (await file.exists()) await file.delete();
          await partial.rename(file.path);
          completed = true;
        } catch (_) {
          if (attempt == 3) rethrow;
          await Future<void>.delayed(
              Duration(milliseconds: 500 * (attempt + 1)));
        }
      }
      if (!completed) throw const SocketException('Download did not complete');
      downloadedApkPath = file.path;
      downloadProgress.value = 1;
      return file.path;
    } catch (_) {
      downloadProgress.value = null;
      rethrow;
    } finally {
      if (ownsClient) client.close();
    }
  }

  Future<String> installDownloadedApk() async {
    if (kDarbPlayStoreBuild) {
      throw StateError('APK self-update is disabled for Google Play builds');
    }
    final path = downloadedApkPath;
    if (path == null || !await File(path).exists()) {
      throw StateError('No downloaded update');
    }
    return await _channel.invokeMethod<String>('installApk', {'path': path}) ??
        'unknown';
  }

  Future<void> startBackgroundDownload(
    DarbUpdateInfo info, {
    bool autoTriggered = false,
  }) async {
    if (kDarbPlayStoreBuild) {
      throw StateError('APK self-update is disabled for Google Play builds');
    }
    await restorePreferences();
    if (autoTriggered && !autoUpdateEnabled) {
      return;
    }
    await _channel.invokeMethod<int>('startBackgroundDownload', {
      'url': info.apkUrl,
      'sha256': info.sha256,
      'versionCode': info.versionCode,
      'autoTriggered': autoTriggered,
      'wifiOnly': wifiOnly,
    });
    _lastBackgroundVersionCode = info.versionCode;
  }

  Future<Map<String, dynamic>> backgroundDownloadState() async {
    try {
      final value = await _channel
          .invokeMapMethod<String, dynamic>('getBackgroundDownloadState');
      return value ?? <String, dynamic>{'status': 'idle', 'progress': 0};
    } on MissingPluginException {
      return <String, dynamic>{'status': 'idle', 'progress': 0};
    }
  }

  Future<String> installBackgroundUpdate() async {
    return await _channel.invokeMethod<String>('installBackgroundUpdate') ??
        'unknown';
  }
}

class DarbUpdateDialog extends StatefulWidget {
  final DarbUpdateInfo info;
  const DarbUpdateDialog({super.key, required this.info});

  @override
  State<DarbUpdateDialog> createState() => _DarbUpdateDialogState();
}

class _DarbUpdateDialogState extends State<DarbUpdateDialog> {
  bool _busy = false;
  bool _backgroundReady = false;
  Timer? _backgroundPoll;
  String? _error;

  bool get _downloaded =>
      _backgroundReady ||
      (DarbUpdater.instance.downloadedApkPath != null &&
          DarbUpdater.instance.downloadedApkPath!
              .endsWith('darb-update-${widget.info.versionCode}.apk') &&
          File(DarbUpdater.instance.downloadedApkPath!).existsSync());

  @override
  void initState() {
    super.initState();
    _restoreBackgroundState();
  }

  @override
  void dispose() {
    _backgroundPoll?.cancel();
    super.dispose();
  }

  bool _matchesVersion(Map<String, dynamic> state) {
    final ver = (state['versionCode'] as num?)?.toInt() ?? 0;
    return ver == 0 || ver == widget.info.versionCode;
  }

  Future<void> _restoreBackgroundState() async {
    try {
      final state = await DarbUpdater.instance.backgroundDownloadState();
      if (!mounted || !_matchesVersion(state)) return;
      final status = state['status']?.toString();
      if (status == 'ready') {
        setState(() => _backgroundReady = true);
      } else if (status == 'downloading') {
        _watchBackgroundDownload();
      } else if (status == 'failed') {
        setState(() => _error = '${dt('فشل التنزيل')}: ${state['error'] ?? ''}');
      }
    } catch (_) {}
  }

  void _watchBackgroundDownload() {
    _backgroundPoll?.cancel();
    _backgroundPoll = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final state = await DarbUpdater.instance.backgroundDownloadState();
        if (!_matchesVersion(state)) return;
        final status = state['status']?.toString();
        final progress = (state['progress'] as num?)?.toDouble() ?? 0;
        DarbUpdater.instance.downloadProgress.value = progress / 100;
        if (!mounted) return;
        if (status == 'ready') {
          _backgroundPoll?.cancel();
          setState(() {
            _backgroundReady = true;
            _error = null;
          });
        } else if (status == 'failed') {
          _backgroundPoll?.cancel();
          setState(
              () => _error = '${dt('فشل التنزيل')}: ${state['error'] ?? ''}');
        }
      } catch (_) {}
    });
  }

  Future<void> _download() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await DarbUpdater.instance.startBackgroundDownload(widget.info);
      final state = await DarbUpdater.instance.backgroundDownloadState();
      if (!mounted) return;
      if (_matchesVersion(state) && state['status']?.toString() == 'ready') {
        setState(() {
          _backgroundReady = true;
          _error = null;
        });
        return;
      }
      setState(() => _error = dt('سيستمر التنزيل في الخلفية ويمكنك إغلاق التطبيق'));
      _watchBackgroundDownload();
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.code == 'WIFI_REQUIRED'
              ? dt('التنزيل مقيّد بشبكة Wi-Fi فقط من الإعدادات')
              : '${dt('تعذر تنزيل التحديث')}: ${error.message ?? error.code}',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = '${dt('تعذر تنزيل التحديث')}: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _install() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = _backgroundReady
          ? await DarbUpdater.instance.installBackgroundUpdate()
          : await DarbUpdater.instance.installDownloadedApk();
      if (result == 'permission_required' && mounted) {
        setState(() => _error =
            dt('اسمح لدازريفو بتثبيت التحديثات من إعدادات أندرويد ثم ارجع واضغط تثبيت'));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = '${dt('فشل فتح مُثبّت أندرويد')}: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: DarbGlassSurface(
        borderRadius: DarbRadius.xl,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        DarbColors.primaryOf(context).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.system_update_rounded,
                      color: DarbColors.primaryOf(context)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dt('يتوفر تحديث جديد'),
                    style: TextStyle(
                      color: DarbColors.inkOf(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(dt('الإصدار الجديد'),
                      style: TextStyle(color: DarbColors.mutedOf(context))),
                ),
                Text(
                  info.versionName,
                  style: TextStyle(
                      color: DarbColors.inkOf(context),
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
            if (info.releaseNotes.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                dt('ما الجديد في هذا التحديث؟'),
                style: TextStyle(
                    color: DarbColors.inkOf(context),
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ...info.releaseNotes
                  .split(RegExp(r'\r?\n'))
                  .map((line) => line.trim())
                  .where((line) => line.isNotEmpty)
                  .map((line) {
                final note = line.replaceFirst(RegExp(r'^[-•]\s*'), '');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Icon(Icons.check_circle_rounded,
                            size: 15, color: DarbColors.primaryOf(context)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note,
                          style: TextStyle(
                              color: DarbColors.mutedOf(context), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 12),
            Text(
              dt('يتطلب تثبيت التحديث موافقة نظام أندرويد عند الفتح'),
              style: TextStyle(
                color: DarbColors.mutedOf(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<double?>(
              valueListenable: DarbUpdater.instance.downloadProgress,
              builder: (context, progress, _) => progress == null
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(DarbRadius.pill),
                          child: LinearProgressIndicator(value: progress),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: TextStyle(
                      color: DarbColors.dangerOf(context), fontSize: 12.5)),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: Text(dt('لاحقاً')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _busy ? null : (_downloaded ? _install : _download),
                    child: Text(
                      _busy
                          ? dt('جارٍ تجهيز التحديث')
                          : (_downloaded
                              ? dt('تثبيت التحديث')
                              : dt('تنزيل التحديث')),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
