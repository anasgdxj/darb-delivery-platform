import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'core/api.dart';

@pragma('vm:entry-point')
Future<void> darbFirebaseBackgroundHandler(RemoteMessage message) async {}

class DarbNotifications {
  static bool _ready = false;
  static StreamSubscription<String>? _tokenSubscription;
  static StreamSubscription<RemoteMessage>? _openedMessageSubscription;
  static final ValueNotifier<bool> updateNotificationTapped =
      ValueNotifier<bool>(false);

  static bool _isReleaseNotification(RemoteMessage message) {
    final data = message.data;
    return data['releaseTag'] == 'latest' ||
        data['type'] == 'app_update' ||
        data['type'] == 'release_update' ||
        (data.containsKey('versionCode') &&
            (data.containsKey('apkUrl') || data.containsKey('releaseTag')));
  }

  static void _handleOpenedMessage(RemoteMessage message) {
    if (_isReleaseNotification(message)) {
      updateNotificationTapped.value = true;
    }
  }

  static Future<void> initialize() async {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    if ([apiKey, appId, senderId, projectId].any((x) => x.isEmpty)) return;
    try {
      await Firebase.initializeApp(options: const FirebaseOptions(
        apiKey: apiKey, appId: appId, messagingSenderId: senderId, projectId: projectId,
      ));
      FirebaseMessaging.onBackgroundMessage(darbFirebaseBackgroundHandler);
      _openedMessageSubscription ??=
          FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleOpenedMessage(initialMessage);
      }
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  static Future<void> register() async {
    if (!_ready || Api.instance.accessToken == null) return;
    try {
      await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await Api.instance.post('/notifications/device', {'token': token, 'platform': 'android'});
      _tokenSubscription ??= FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        Api.instance.post('/notifications/device', {'token': token, 'platform': 'android'}).catchError((_) {});
      });
    } catch (_) {}
  }

  static Future<void> unregister() async {
    if (!_ready) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await Api.instance.delete('/notifications/device', {'token': token, 'platform': 'android'});
    } catch (_) {}
  }
}
