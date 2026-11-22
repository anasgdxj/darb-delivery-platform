import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../network/api_client.dart';

@pragma('vm:entry-point')
Future<void> darbFirebaseBackgroundHandler(RemoteMessage message) async {}

class DarbNotifications {
  static bool _ready = false;
  static StreamSubscription<String>? _tokenSubscription;

  static Future<void> initialize() async {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    if ([apiKey, appId, senderId, projectId].any((x) => x.isEmpty)) return;
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: senderId,
          projectId: projectId,
        ),
      );
      FirebaseMessaging.onBackgroundMessage(darbFirebaseBackgroundHandler);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  static StreamSubscription<RemoteMessage>? listenForeground(
    void Function(String? title, String? body, Map<String, dynamic> data) onMessage,
  ) {
    if (!_ready) return null;
    return FirebaseMessaging.onMessage.listen((message) {
      onMessage(
        message.notification?.title,
        message.notification?.body,
        Map<String, dynamic>.from(message.data),
      );
    });
  }

  static StreamSubscription<RemoteMessage>? listenOpened(
    void Function() onOpened,
  ) {
    if (!_ready) return null;
    return FirebaseMessaging.onMessageOpenedApp.listen((_) => onOpened());
  }

  static Future<bool> wasOpenedFromTerminated() async {
    if (!_ready) return false;
    try {
      return await FirebaseMessaging.instance.getInitialMessage() != null;
    } catch (_) {
      return false;
    }
  }

  static Future<void> register() async {
    if (!_ready || Api.instance.accessToken == null) return;
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await Api.instance.post('/notifications/device', {
          'token': token,
          'platform': 'android',
        });
      }
      _tokenSubscription ??= FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        Api.instance.post('/notifications/device', {
          'token': token,
          'platform': 'android',
        }).catchError((_) {});
      });
    } catch (_) {}
  }

  static Future<void> unregister() async {
    if (!_ready) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await Api.instance.delete('/notifications/device', {
          'token': token,
          'platform': 'android',
        });
      }
    } catch (_) {}
  }
}
