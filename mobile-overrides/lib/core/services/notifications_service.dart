import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../network/api_client.dart';

@pragma('vm:entry-point')
Future<void> darbFirebaseBackgroundHandler(RemoteMessage message) async {}

class DarbNotifications {
  static bool _ready = false;
  static String? lastError;
  static StreamSubscription<String>? _tokenSubscription;
  static String? _lastSyncedToken;
  static String? _lastSyncedSessionToken;
  static DateTime? _lastSyncedAt;
  static AuthorizationStatus? _authorizationStatus;
  static Map<String, dynamic>? _bufferedInitialData;
  static bool _initialCaptured = false;

  @visibleForTesting
  static Future<String?> Function()? tokenProviderOverride;

  @visibleForTesting
  static Future<void> Function(String token, String platform)?
      registerDeviceOverride;

  @visibleForTesting
  static Future<void> Function(String token, String platform)?
      unregisterDeviceOverride;

  @visibleForTesting
  static Future<Map<String, dynamic>?> Function()? initialMessageOverride;

  @visibleForTesting
  static Stream<Map<String, dynamic>>? openedMessageStreamOverride;

  static bool get isReady => _ready;
  static bool get hasSyncedToken =>
      _lastSyncedToken != null &&
      _lastSyncedToken!.isNotEmpty &&
      _lastSyncedSessionToken == Api.instance.accessToken;
  static DateTime? get lastSyncedAt => _lastSyncedAt;
  static String? get lastSyncedToken => _lastSyncedToken;
  static AuthorizationStatus? get authorizationStatus => _authorizationStatus;
  static bool get permissionGranted =>
      _authorizationStatus == AuthorizationStatus.authorized ||
      _authorizationStatus == AuthorizationStatus.provisional;

  @visibleForTesting
  static String resolvePlatform(
    TargetPlatform target, {
    bool isWeb = kIsWeb,
  }) {
    if (isWeb) return 'web';
    return switch (target) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android || TargetPlatform.fuchsia => 'android',
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux =>
        'web',
    };
  }

  static String get _platform => resolvePlatform(defaultTargetPlatform);

  @visibleForTesting
  static void debugResetForTest({bool ready = false}) {
    _ready = ready;
    lastError = null;
    _lastSyncedToken = null;
    _lastSyncedSessionToken = null;
    _lastSyncedAt = null;
    _authorizationStatus = null;
    _bufferedInitialData = null;
    _initialCaptured = false;
    unawaited(_tokenSubscription?.cancel());
    _tokenSubscription = null;
    tokenProviderOverride = null;
    registerDeviceOverride = null;
    unregisterDeviceOverride = null;
    initialMessageOverride = null;
    openedMessageStreamOverride = null;
  }

  static Future<void> initialize() async {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    if ([apiKey, appId, senderId, projectId].any((x) => x.isEmpty)) {
      lastError = 'إعدادات Firebase غير مكتملة';
      return;
    }
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: apiKey,
            appId: appId,
            messagingSenderId: senderId,
            projectId: projectId,
          ),
        );
      }
      FirebaseMessaging.onBackgroundMessage(darbFirebaseBackgroundHandler);
      _ready = true;
      lastError = null;
    } catch (error) {
      _ready = false;
      lastError = 'تعذر تهيئة Firebase: $error';
    }
  }

  static Future<void> captureInitialMessage() async {
    if (_initialCaptured) return;
    _initialCaptured = true;
    try {
      if (initialMessageOverride != null) {
        final data = await initialMessageOverride!();
        if (data != null) {
          _bufferedInitialData = Map<String, dynamic>.from(data);
        }
        return;
      }
      if (!_ready) return;
      final message = await FirebaseMessaging.instance.getInitialMessage();
      if (message != null) {
        _bufferedInitialData = Map<String, dynamic>.from(message.data);
      }
    } catch (error) {
      lastError = 'تعذر قراءة الإشعار الأولي: $error';
    }
  }

  static StreamSubscription<RemoteMessage>? listenForeground(
    void Function(String? title, String? body, Map<String, dynamic> data)
        onMessage,
  ) {
    if (!_ready) return null;
    return FirebaseMessaging.onMessage.listen((message) {
      final data = Map<String, dynamic>.from(message.data);
      onMessage(
        message.notification?.title ?? data['title']?.toString(),
        message.notification?.body ?? data['body']?.toString(),
        data,
      );
    });
  }

  static StreamSubscription<dynamic>? listenOpened(
    void Function(Map<String, dynamic> data) onOpened,
  ) {
    if (openedMessageStreamOverride != null) {
      return openedMessageStreamOverride!.listen(
        (data) => onOpened(Map<String, dynamic>.from(data)),
      );
    }
    if (!_ready) return null;
    return FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => onOpened(Map<String, dynamic>.from(message.data)),
    );
  }

  static Future<Map<String, dynamic>?> initialMessageData() async {
    final buffered = _bufferedInitialData;
    if (buffered != null) {
      _bufferedInitialData = null;
      return Map<String, dynamic>.from(buffered);
    }
    if (initialMessageOverride != null) {
      try {
        final data = await initialMessageOverride!();
        return data == null ? null : Map<String, dynamic>.from(data);
      } catch (error) {
        lastError = 'تعذر قراءة الإشعار الأولي: $error';
        return null;
      }
    }
    if (!_ready) return null;
    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      return message == null ? null : Map<String, dynamic>.from(message.data);
    } catch (error) {
      lastError = 'تعذر قراءة الإشعار الأولي: $error';
      return null;
    }
  }

  static void _ensureRefreshListener() {
    if (!_ready || _tokenSubscription != null) return;
    _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
      (refreshedToken) {
        if (refreshedToken.isEmpty || Api.instance.accessToken == null) return;
        unawaited(_postDeviceToken(refreshedToken));
      },
      onError: (Object error) {
        lastError = 'فشل تحديث رمز الإشعارات: $error';
      },
    );
  }

  static Future<void> _postDeviceToken(String token) async {
    final platform = _platform;
    if (registerDeviceOverride != null) {
      await registerDeviceOverride!(token, platform);
    } else {
      await Api.instance.post('/notifications/device', {
        'token': token,
        'platform': platform,
      });
    }
    _lastSyncedToken = token;
    _lastSyncedSessionToken = Api.instance.accessToken;
    _lastSyncedAt = DateTime.now();
    lastError = null;
  }

  static Future<void> register({bool force = false}) async {
    final hasTestHooks =
        tokenProviderOverride != null || registerDeviceOverride != null;
    if ((!_ready && !hasTestHooks) || Api.instance.accessToken == null) return;

    if (_ready) {
      _ensureRefreshListener();
    }

    try {
      String? token;
      if (tokenProviderOverride != null) {
        _authorizationStatus ??= AuthorizationStatus.authorized;
        token = await tokenProviderOverride!();
      } else {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        _authorizationStatus = settings.authorizationStatus;
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          lastError = 'تم رفض إذن الإشعارات من إعدادات الجهاز';
          return;
        }
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        token = await FirebaseMessaging.instance.getToken();
      }

      if (token == null || token.isEmpty) {
        throw StateError('Firebase لم يُرجع رمز الجهاز');
      }

      final alreadySynced = !force &&
          _lastSyncedToken == token &&
          _lastSyncedSessionToken == Api.instance.accessToken &&
          lastError == null;
      if (alreadySynced) return;

      try {
        await _postDeviceToken(token);
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
        await _postDeviceToken(token);
      }
    } catch (error) {
      lastError = 'تعذر تسجيل هذا الجهاز للإشعارات: $error';
    }
  }

  static Future<void> unregister() async {
    final activeToken = _lastSyncedToken;
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    _lastSyncedToken = null;
    _lastSyncedSessionToken = null;
    _lastSyncedAt = null;

    final hasTestHooks =
        tokenProviderOverride != null || unregisterDeviceOverride != null;
    if (!_ready && !hasTestHooks) return;

    try {
      final token = activeToken ??
          (tokenProviderOverride != null
              ? await tokenProviderOverride!()
              : await FirebaseMessaging.instance.getToken());
      if (token != null && token.isNotEmpty) {
        final platform = _platform;
        if (unregisterDeviceOverride != null) {
          await unregisterDeviceOverride!(token, platform);
        } else {
          await Api.instance.delete('/notifications/device', {
            'token': token,
            'platform': platform,
          });
        }
      }
    } catch (error) {
      lastError = 'تعذر إلغاء تسجيل الجهاز: $error';
    }
  }
}
