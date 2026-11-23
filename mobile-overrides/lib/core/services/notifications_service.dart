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

  static String get _platform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.android || TargetPlatform.fuchsia => 'android',
    };
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
      lastError = null;
    } catch (error) {
      _ready = false;
      lastError = 'تعذر تهيئة Firebase: $error';
    }
  }

  static StreamSubscription<RemoteMessage>? listenForeground(
    void Function(String? title, String? body, Map<String, dynamic> data) onMessage,
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

  static StreamSubscription<RemoteMessage>? listenOpened(
    void Function(Map<String, dynamic> data) onOpened,
  ) {
    if (!_ready) return null;
    return FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => onOpened(Map<String, dynamic>.from(message.data)),
    );
  }

  static Future<Map<String, dynamic>?> initialMessageData() async {
    if (!_ready) return null;
    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      return message == null ? null : Map<String, dynamic>.from(message.data);
    } catch (error) {
      lastError = 'تعذر قراءة الإشعار الأولي: $error';
      return null;
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
      if (token == null || token.isEmpty) {
        throw StateError('Firebase لم يُرجع رمز الجهاز');
      }
      await Api.instance.post('/notifications/device', {
        'token': token,
        'platform': _platform,
      });
      lastError = null;
      _tokenSubscription ??= FirebaseMessaging.instance.onTokenRefresh.listen(
        (token) {
          Api.instance.post('/notifications/device', {
            'token': token,
            'platform': _platform,
          }).catchError((error) {
            lastError = 'تعذر تحديث رمز الإشعارات: $error';
          });
        },
        onError: (Object error) {
          lastError = 'فشل تحديث رمز الإشعارات: $error';
        },
      );
    } catch (error) {
      lastError = 'تعذر تسجيل هذا الجهاز للإشعارات: $error';
    }
  }

  static Future<void> unregister() async {
    if (!_ready) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await Api.instance.delete('/notifications/device', {
          'token': token,
          'platform': _platform,
        });
      }
    } catch (error) {
      lastError = 'تعذر إلغاء تسجيل الجهاز: $error';
    }
  }
}
