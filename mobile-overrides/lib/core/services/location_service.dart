import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

import '../l10n/app_localizations.dart';
import '../network/api_client.dart';

class DarbCoordinates {
  const DarbCoordinates(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

class DarbLocationException implements Exception {
  const DarbLocationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class DarbLocationService {
  DarbLocationService._();

  static Future<DarbCoordinates> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw DarbLocationException(dt('فعّل خدمة الموقع في هاتفك أولاً'));
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw DarbLocationException(dt('يلزم السماح للتطبيق بالوصول إلى موقعك'));
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return DarbCoordinates(pos.latitude, pos.longitude);
  }
}

class DriverLocationReporter {
  static StreamSubscription<Position>? _positionSubscription;
  static bool _enabled = false;
  static bool _starting = false;
  static bool _sending = false;
  static bool _observerRegistered = false;
  static int _generation = 0;
  static DateTime? _lastSentAt;

  static final WidgetsBindingObserver _lifecycleObserver =
      _DriverLocationLifecycleObserver();

  static void start() {
    _enabled = true;
    if (!_observerRegistered) {
      WidgetsBinding.instance.addObserver(_lifecycleObserver);
      _observerRegistered = true;
    }
    if (_positionSubscription == null && !_starting) {
      unawaited(_startStream());
    }
  }

  static Future<void> refresh() async {
    _enabled = true;
    if (!_observerRegistered) {
      WidgetsBinding.instance.addObserver(_lifecycleObserver);
      _observerRegistered = true;
    }
    final current = _positionSubscription;
    _positionSubscription = null;
    if (current != null) await current.cancel();
    if (_enabled) await _startStream();
  }

  static Future<void> _startStream() async {
    if (!_enabled || _starting) return;
    _starting = true;
    final generation = ++_generation;
    try {
      final driver =
          Map<String, dynamic>.from(await Api.instance.get('/drivers/me') as Map);
      if (!_enabled ||
          generation != _generation ||
          driver['status'] != 'APPROVED' ||
          driver['isOnline'] != true) {
        return;
      }

      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
        intervalDuration: const Duration(seconds: 30),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'دَرْب - مشاركة موقع المندوب',
          notificationText: 'يتم تحديث موقعك أثناء تنفيذ التوصيل',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );

      await _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(
        (position) {
          if (_enabled && generation == _generation) {
            unawaited(_sendPosition(position));
          }
        },
        onError: (_) {
          _positionSubscription = null;
          if (_enabled && generation == _generation) {
            unawaited(_restartAfterDelay());
          }
        },
        cancelOnError: true,
      );
    } catch (_) {
      if (_enabled && generation == _generation) {
        unawaited(_restartAfterDelay());
      }
    } finally {
      _starting = false;
    }
  }

  static Future<void> _sendPosition(Position position) async {
    if (!_enabled || _sending) return;
    final now = DateTime.now();
    if (_lastSentAt != null &&
        now.difference(_lastSentAt!) < const Duration(seconds: 20)) {
      return;
    }
    _sending = true;
    try {
      await Api.instance.patch('/drivers/location', {
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
      _lastSentAt = now;
    } catch (_) {
      // A later position event retries after transient network failures.
    } finally {
      _sending = false;
    }
  }

  static Future<void> _restartAfterDelay() async {
    await Future<void>.delayed(const Duration(seconds: 15));
    if (_enabled && _positionSubscription == null && !_starting) {
      await _startStream();
    }
  }

  static void pause() {
    _generation++;
    final subscription = _positionSubscription;
    _positionSubscription = null;
    if (subscription != null) unawaited(subscription.cancel());
  }

  static void stop() {
    _enabled = false;
    pause();
    if (_observerRegistered) {
      WidgetsBinding.instance.removeObserver(_lifecycleObserver);
      _observerRegistered = false;
    }
  }
}

class _DriverLocationLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      DriverLocationReporter.start();
    }
  }
}
