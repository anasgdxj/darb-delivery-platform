import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_glass.dart';

class DriverTrackingScreen extends StatefulWidget {
  const DriverTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends State<DriverTrackingScreen>
    with WidgetsBindingObserver {
  static const LatLng _syriaCenter = LatLng(35.0, 38.5);

  Timer? _refreshTimer;
  LatLng? _driverPoint;
  DateTime? _lastUpdatedAt;
  bool _loading = true;
  bool _requesting = false;
  bool _stale = false;
  bool _mapTilesUnavailable = false;
  String? _message;
  String? _error;
  int _mapRevision = 0;

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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
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
        if (latitude == null ||
            longitude == null ||
            latitude < -90 ||
            latitude > 90 ||
            longitude < -180 ||
            longitude > 180) {
          setState(() => _error = dt('إحداثيات موقع المندوب غير صالحة'));
          return;
        }

        setState(() {
          if (_driverPoint == null) _mapRevision++;
          _driverPoint = LatLng(latitude, longitude);
          _lastUpdatedAt = DateTime.tryParse(
            response['updatedAt']?.toString() ?? '',
          );
          _stale = false;
          _message = null;
          _error = null;
        });
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
    final isDark = DarbColors.isDark(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DarbAmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 12),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: dt('رجوع'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dt('تتبع المندوب'),
                            style: TextStyle(
                              color: DarbColors.inkOf(context),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            dt('يتحدث الموقع تلقائياً كل 30 ثانية'),
                            style: TextStyle(
                              color: DarbColors.mutedOf(context),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (point != null)
                      IconButton(
                        onPressed: () => launchUrl(
                          Uri.parse(
                            'https://www.openstreetmap.org/?mlat=\${point.latitude}'
                            '&mlon=\${point.longitude}#map=16/\${point.latitude}/\${point.longitude}',
                          ),
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.open_in_new_rounded),
                        tooltip: dt('فتح موقع المندوب خارج التطبيق'),
                      ),
                    IconButton(
                      onPressed: _requesting
                          ? null
                          : () => _refreshLocation(),
                      icon: _requesting
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded),
                      tooltip: dt('تحديث الموقع'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DarbGlassSurface(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  elevated: false,
                  child: Row(
                    children: [
                      Icon(
                        _stale
                            ? Icons.location_disabled_rounded
                            : point == null
                                ? Icons.location_searching_rounded
                                : Icons.my_location_rounded,
                        color: _stale
                            ? DarbColors.warningOf(context)
                            : point == null
                                ? DarbColors.mutedOf(context)
                                : DarbColors.successOf(context),
                        size: 18,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          _error ?? _message ?? _updatedAtLabel(),
                          style: TextStyle(
                            color: _error != null
                                ? DarbColors.dangerOf(context)
                                : DarbColors.inkOf(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_loading || _requesting)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(DarbRadius.xl),
                    child: Stack(
                      children: [
                        FlutterMap(
                          key: ValueKey('driver-map-$_mapRevision'),
                          options: MapOptions(
                            initialCenter: point ?? _syriaCenter,
                            initialZoom: point == null ? 6.2 : 15,
                            minZoom: 4,
                            maxZoom: 19,
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
                            if (point != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: point,
                                    width: 70,
                                    height: 76,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: DarbColors.primaryOf(context),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 3,
                                            ),
                                            boxShadow: DarbElevation.floating(
                                              isDark,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.delivery_dining_rounded,
                                            color: DarbColors.onPrimaryOf(context),
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dt('المندوب'),
                                          style: TextStyle(
                                            color: DarbColors.inkOf(context),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            shadows: const [
                                              Shadow(
                                                color: Colors.white,
                                                blurRadius: 5,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            RichAttributionWidget(
                              alignment: AttributionAlignment.bottomRight,
                              attributions: [
                                TextSourceAttribution(
                                  '© OpenStreetMap contributors',
                                  onTap: () {
                                    launchUrl(
                                      Uri.parse(
                                        'https://www.openstreetmap.org/copyright',
                                      ),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (_mapTilesUnavailable)
                          PositionedDirectional(
                            top: 12,
                            start: 12,
                            end: 12,
                            child: DarbGlassSurface(
                              elevated: false,
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.signal_wifi_connected_no_internet_4_rounded,
                                    size: 18,
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
                          ),
                        PositionedDirectional(
                          end: 12,
                          bottom: 12,
                          child: Column(
                            children: [
                              if (point != null)
                                FloatingActionButton.small(
                                  heroTag: 'center-driver-location',
                                  onPressed: () {
                                    setState(() => _mapRevision++);
                                  },
                                  tooltip: dt('توسيط على المندوب'),
                                  child: const Icon(Icons.my_location_rounded),
                                ),
                              if (point == null && _loading)
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(),
                                ),
                            ],
                          ),
                        ),
                        if (point == null && !_loading)
                          PositionedDirectional(
                            top: 12,
                            start: 12,
                            end: 12,
                            child: DarbGlassSurface(
                              elevated: false,
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                _error ?? _message ?? dt('لم يشارك السائق موقعه بعد'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: DarbColors.inkOf(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
