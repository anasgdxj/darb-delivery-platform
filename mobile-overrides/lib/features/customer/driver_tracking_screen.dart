import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_motion_components.dart';

class DriverTrackingScreen extends StatefulWidget {
  const DriverTrackingScreen({
    super.key,
    required this.orderId,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffLatitude,
    this.dropoffLongitude,
  });

  final String orderId;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropoffLatitude;
  final double? dropoffLongitude;

  @override
  State<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends State<DriverTrackingScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const LatLng _syriaCenter = LatLng(35.0, 38.5);

  final MapController _mapController = MapController();
  AnimationController? _panController;
  Timer? _refreshTimer;
  LatLng? _driverPoint;
  DateTime? _lastUpdatedAt;
  bool _loading = true;
  bool _requesting = false;
  bool _stale = false;
  bool _mapTilesUnavailable = false;
  bool _mapReady = false;
  bool _followDriver = true;
  String? _message;
  String? _error;

  LatLng? _validPoint(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return LatLng(lat, lng);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshLocation();
    _startPolling();
  }

  void _startPolling() {
    if (_refreshTimer != null) return;
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 25),
      (_) => _refreshLocation(silent: true),
    );
  }

  void _stopPolling() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
      _refreshLocation(silent: true);
    } else {
      _stopPolling();
    }
  }

  void _animateMapTo(LatLng destLocation, double destZoom) {
    if (!_mapReady) return;
    if (DarbMotion.reduceMotion(context)) {
      _mapController.move(destLocation, destZoom);
      return;
    }
    _panController?.stop();
    _panController?.dispose();
    final startCenter = _mapController.camera.center;
    final startZoom = _mapController.camera.zoom;
    final controller = AnimationController(
      vsync: this,
      duration: DarbMotion.expressive,
    );
    _panController = controller;
    final curve = CurvedAnimation(parent: controller, curve: DarbMotion.enter);
    final latTween = Tween<double>(
      begin: startCenter.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: startCenter.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(begin: startZoom, end: destZoom);
    controller.addListener(() {
      if (!mounted) return;
      _mapController.move(
        LatLng(latTween.evaluate(curve), lngTween.evaluate(curve)),
        zoomTween.evaluate(curve),
      );
    });
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if (_panController == controller) {
          _panController = null;
        }
        controller.dispose();
      }
    });
    controller.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    _panController?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _refreshLocation({bool silent = false}) async {
    if (_requesting) return;
    _requesting = true;
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await Api.instance.get(
        '/orders/${widget.orderId}/driver-location',
      );
      if (!mounted) return;

      if (response is Map && response['available'] == true) {
        final latitude = (response['latitude'] as num?)?.toDouble();
        final longitude = (response['longitude'] as num?)?.toDouble();
        final nextPoint = _validPoint(latitude, longitude);
        if (nextPoint == null) {
          setState(() => _error = dt('إحداثيات موقع المندوب غير صالحة'));
          return;
        }

        final hadPoint = _driverPoint != null;
        setState(() {
          _driverPoint = nextPoint;
          _lastUpdatedAt = DateTime.tryParse(
            response['updatedAt']?.toString() ?? '',
          );
          _stale = false;
          _message = null;
          _error = null;
        });
        if (_mapReady && _followDriver) {
          _animateMapTo(
            nextPoint,
            hadPoint ? _mapController.camera.zoom : 15.5,
          );
        }
      } else {
        setState(() {
          _error = null;
          _stale = response is Map && response['reason'] == 'STALE';
          _message = _stale
              ? dt('آخر موقع للمندوب قديم، ننتظر تحديثه')
              : dt('لم يشارك السائق موقعه بعد');
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = dt('تعذر تحديث موقع المندوب'));
    } finally {
      _requesting = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  String _updatedAtLabel() {
    final value = _lastUpdatedAt;
    if (value == null) return dt('بانتظار أول تحديث للموقع');
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '${dt('آخر تحديث')}: $hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    final point = _driverPoint;
    final pickupPoint =
        _validPoint(widget.pickupLatitude, widget.pickupLongitude);
    final dropoffPoint =
        _validPoint(widget.dropoffLatitude, widget.dropoffLongitude);
    final fallbackCenter = dropoffPoint ?? pickupPoint ?? _syriaCenter;
    final isDark = DarbColors.isDark(context);
    final primary = DarbColors.primaryOf(context);
    final teal = DarbColors.violetOf(context);
    final live = point != null && !_stale && _error == null;

    final markers = <Marker>[
      if (pickupPoint != null)
        Marker(
          point: pickupPoint,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: DarbColors.infoOf(context),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: DarbElevation.card(isDark),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      if (dropoffPoint != null)
        Marker(
          point: dropoffPoint,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: DarbColors.successOf(context),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: DarbElevation.card(isDark),
            ),
            child: const Icon(
              Icons.home_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      if (point != null)
        Marker(
          point: point,
          width: 88,
          height: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [DarbColors.forest, DarbColors.forestSoft],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DarbColors.lime,
                    width: 2.8,
                  ),
                  boxShadow: DarbElevation.floating(isDark),
                ),
                child: const Icon(
                  Icons.delivery_dining_rounded,
                  color: DarbColors.lime,
                  size: 23,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: DarbColors.forest.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(DarbRadius.pill),
                  border: Border.all(
                    color: DarbColors.lime.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  dt('المندوب'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: DarbColors.canvasOf(context),
      body: Stack(
        children: [
          // Full-bleed edge-to-edge spatial live map canvas
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: point ?? fallbackCenter,
                initialZoom: point != null
                    ? 15.5
                    : (dropoffPoint != null || pickupPoint != null ? 14 : 6.2),
                minZoom: 4,
                maxZoom: 19,
                onMapReady: () {
                  _mapReady = true;
                  if (_driverPoint != null && _followDriver) {
                    _mapController.move(_driverPoint!, 15.5);
                  }
                },
                onPositionChanged: (_, hasGesture) {
                  if (hasGesture && _followDriver) {
                    setState(() => _followDriver = false);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.darb.darb',
                  maxZoom: 19,
                  keepBuffer: 4,
                  panBuffer: 2,
                  errorTileCallback: (tile, error, stackTrace) {
                    if (mounted && !_mapTilesUnavailable) {
                      setState(() => _mapTilesUnavailable = true);
                    }
                  },
                ),
                if (pickupPoint != null || dropoffPoint != null)
                  PolylineLayer(
                    polylines: [
                      if (pickupPoint != null && point != null)
                        Polyline(
                          points: [pickupPoint, point],
                          color: DarbColors.infoOf(context).withValues(alpha: 0.78),
                          strokeWidth: 3.6,
                        ),
                      if (point != null && dropoffPoint != null)
                        Polyline(
                          points: [point, dropoffPoint],
                          color: primary,
                          strokeWidth: 4.8,
                        ),
                      if (point == null &&
                          pickupPoint != null &&
                          dropoffPoint != null)
                        Polyline(
                          points: [pickupPoint, dropoffPoint],
                          color: primary.withValues(alpha: 0.60),
                          strokeWidth: 3.6,
                        ),
                    ],
                  ),
                if (markers.isNotEmpty) MarkerLayer(markers: markers),
                RichAttributionWidget(
                  alignment: AttributionAlignment.bottomRight,
                  attributions: [
                    TextSourceAttribution(
                      '© OpenStreetMap contributors',
                      onTap: () {
                        launchUrl(
                          Uri.parse('https://www.openstreetmap.org/copyright'),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Top Floating Translucent Obsidian/Glass Command Bar
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DarbGlassSurface(
                      borderRadius: DarbRadius.xl,
                      blurSigma: 24,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          _MapGlassIconBtn(
                            tooltip: dt('رجوع'),
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    if (live) ...[
                                      DarbPulseDot(color: teal, size: 7.5),
                                      const SizedBox(width: 6),
                                    ],
                                    Flexible(
                                      child: Text(
                                        dt('تتبع المندوب'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: DarbColors.inkOf(context),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dt('يتحدث الموقع تلقائياً كل 25 ثانية'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: DarbColors.mutedOf(context),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (point != null) ...[
                            const SizedBox(width: 6),
                            _MapGlassIconBtn(
                              tooltip: dt('فتح موقع المندوب خارج التطبيق'),
                              icon: Icons.open_in_new_rounded,
                              onTap: () => launchUrl(
                                Uri.parse(
                                  'https://www.openstreetmap.org/?mlat=${point.latitude}'
                                  '&mlon=${point.longitude}#map=16/${point.latitude}/${point.longitude}',
                                ),
                                mode: LaunchMode.externalApplication,
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                          _MapGlassIconBtn(
                            tooltip: dt('تحديث الموقع'),
                            icon: Icons.refresh_rounded,
                            loading: _requesting,
                            onTap: _requesting ? null : () => _refreshLocation(),
                          ),
                        ],
                      ),
                    ),
                    if (_mapTilesUnavailable) ...[
                      const SizedBox(height: 8),
                      DarbGlassSurface(
                        borderRadius: DarbRadius.md,
                        elevated: false,
                        tintColor: DarbColors.warningSoftOf(context),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.signal_wifi_connected_no_internet_4_rounded,
                              size: 17,
                              color: DarbColors.warningOf(context),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dt('تعذر تحميل بلاطات الخريطة. احتفظنا بآخر موقع معروف ويمكنك فتحه خارج التطبيق عند توفر الإنترنت.'),
                                style: TextStyle(
                                  color: DarbColors.inkOf(context),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Bottom Floating Spatial Route & Live Telemetry Sheet
          PositionedDirectional(
            bottom: 0,
            start: 0,
            end: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Floating map controls & recenter dock
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (point != null)
                          Tooltip(
                            message: dt('توسيط على المندوب'),
                            child: DarbPressScale(
                              borderRadius: DarbRadius.pill,
                              onTap: () {
                                DarbHaptics.selection();
                                setState(() => _followDriver = true);
                                if (_mapReady) {
                                  _animateMapTo(point, 15.5);
                                }
                              },
                              child: DarbGlassSurface(
                                borderRadius: DarbRadius.pill,
                                tintColor: _followDriver
                                    ? DarbColors.forest
                                    : null,
                                borderColor: _followDriver
                                    ? DarbColors.lime.withValues(alpha: 0.5)
                                    : null,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 9,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.my_location_rounded,
                                      size: 17,
                                      color: _followDriver
                                          ? DarbColors.lime
                                          : primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      dt('توسيط على المندوب'),
                                      style: TextStyle(
                                        color: _followDriver
                                            ? Colors.white
                                            : DarbColors.inkOf(context),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        DarbGlassSurface(
                          borderRadius: DarbRadius.pill,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: dt('تكبير الخريطة'),
                                visualDensity: VisualDensity.compact,
                                onPressed: _mapReady
                                    ? () {
                                        DarbHaptics.selection();
                                        _mapController.move(
                                          _mapController.camera.center,
                                          (_mapController.camera.zoom + 1)
                                              .clamp(4, 19)
                                              .toDouble(),
                                        );
                                      }
                                    : null,
                                icon: const Icon(Icons.add_rounded, size: 18),
                              ),
                              IconButton(
                                tooltip: dt('تصغير الخريطة'),
                                visualDensity: VisualDensity.compact,
                                onPressed: _mapReady
                                    ? () {
                                        DarbHaptics.selection();
                                        _mapController.move(
                                          _mapController.camera.center,
                                          (_mapController.camera.zoom - 1)
                                              .clamp(4, 19)
                                              .toDouble(),
                                        );
                                      }
                                    : null,
                                icon:
                                    const Icon(Icons.remove_rounded, size: 18),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DarbGlassSurface(
                      borderRadius: DarbRadius.xl,
                      blurSigma: 26,
                      padding: const EdgeInsets.all(14),
                      borderColor: live
                          ? teal.withValues(alpha: 0.35)
                          : (_error != null
                              ? DarbColors.dangerOf(context)
                                  .withValues(alpha: 0.35)
                              : null),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: (_error != null
                                          ? DarbColors.dangerOf(context)
                                          : (live ? teal : primary))
                                      .withValues(alpha: isDark ? 0.22 : 0.12),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: live
                                    ? Center(
                                        child: DarbPulseDot(
                                          color: teal,
                                          size: 9,
                                        ),
                                      )
                                    : Icon(
                                        _error != null
                                            ? Icons.error_outline_rounded
                                            : (_stale
                                                ? Icons.location_disabled_rounded
                                                : Icons.location_searching_rounded),
                                        size: 18,
                                        color: _error != null
                                            ? DarbColors.dangerOf(context)
                                            : (_stale
                                                ? DarbColors.warningOf(context)
                                                : primary),
                                      ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: DarbMotion.effectiveDuration(
                                    context,
                                    DarbMotion.standard,
                                  ),
                                  child: Text(
                                    _error ?? _message ?? _updatedAtLabel(),
                                    key: ValueKey(
                                      _error ?? _message ?? _updatedAtLabel(),
                                    ),
                                    style: TextStyle(
                                      color: _error != null
                                          ? DarbColors.dangerOf(context)
                                          : DarbColors.inkOf(context),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              if (_loading || _requesting)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                            ],
                          ),
                          if (pickupPoint != null ||
                              dropoffPoint != null ||
                              point != null) ...[
                            const SizedBox(height: 10),
                            Divider(
                              height: 1,
                              color: DarbColors.borderOf(context),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                if (pickupPoint != null)
                                  _MapLegendItem(
                                    color: DarbColors.infoOf(context),
                                    label: dt('الاستلام'),
                                  ),
                                if (point != null)
                                  _MapLegendItem(
                                    color: primary,
                                    label: dt('المندوب'),
                                  ),
                                if (dropoffPoint != null)
                                  _MapLegendItem(
                                    color: DarbColors.successOf(context),
                                    label: dt('التسليم'),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGlassIconBtn extends StatelessWidget {
  const _MapGlassIconBtn({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: DarbColors.softSurfaceOf(context).withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: DarbColors.borderOf(context)),
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon, size: 19, color: DarbColors.inkOf(context)),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapLegendItem extends StatelessWidget {
  const _MapLegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: DarbColors.inkOf(context),
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
