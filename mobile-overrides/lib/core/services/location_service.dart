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
  static Timer? _timer;
  static bool _sending = false;
  static bool _refreshing = false;
  static bool _refreshRequested = false;
  static bool _enabled = false;
  static bool _observerRegistered = false;
  static int _generation = 0;

  static final WidgetsBindingObserver _lifecycleObserver =
      _DriverLocationLifecycleObserver();

  static void start() {
    _enabled = true;
    if (!_observerRegistered) {
      WidgetsBinding.instance.addObserver(_lifecycleObserver);
      _observerRegistered = true;
    }
    if (_timer != null || _refreshing) return;
    unawaited(refresh());
  }

  static Future<void> refresh() async {
    if (!_enabled) return;
    if (_refreshing) {
      _refreshRequested = true;
      return;
    }
    _refreshing = true;
    final generation = ++_generation;
    _timer?.cancel();
    _timer = null;
    try {
      final driver =
          Map<String, dynamic>.from(await Api.instance.get('/drivers/me') as Map);
      if (generation != _generation ||
          driver['status'] != 'APPROVED' ||
          driver['isOnline'] != true) {
        return;
      }
      await _sendLocation();
      if (generation != _generation) return;
      _timer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => unawaited(_sendLocation()),
      );
    } catch (_) {
      _timer?.cancel();
      _timer = null;
    } finally {
      _refreshing = false;
      if (_refreshRequested && _enabled) {
        _refreshRequested = false;
        unawaited(refresh());
      }
    }
  }

  static void pause() {
    _generation++;
    _refreshRequested = false;
    _timer?.cancel();
    _timer = null;
  }

  static void stop() {
    _enabled = false;
    pause();
    if (_observerRegistered) {
      WidgetsBinding.instance.removeObserver(_lifecycleObserver);
      _observerRegistered = false;
    }
  }

  static Future<void> _sendLocation() async {
    if (!_enabled || _sending) return;
    _sending = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!_enabled) return;
      await Api.instance.patch('/drivers/location', {
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    } catch (_) {
      // Location failures must not interrupt the driver's workflow.
    } finally {
      _sending = false;
    }
  }
}

class _DriverLocationLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(DriverLocationReporter.refresh());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      DriverLocationReporter.pause();
    }
  }
}
