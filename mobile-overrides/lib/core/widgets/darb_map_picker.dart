import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/location_service.dart';
import '../theme/darb_design_system.dart';
import 'darb_glass.dart';
import 'darb_motion_components.dart';

typedef DarbMapPointCallback = void Function(double latitude, double longitude);

class DarbMapPicker extends StatefulWidget {
  const DarbMapPicker({
    super.key,
    this.selectedLatitude,
    this.selectedLongitude,
    this.cityName,
    required this.onPointSelected,
  });

  final double? selectedLatitude;
  final double? selectedLongitude;
  final String? cityName;
  final DarbMapPointCallback onPointSelected;

  @override
  State<DarbMapPicker> createState() => _DarbMapPickerState();
}

class _DarbMapPickerState extends State<DarbMapPicker> {
  static const LatLng _syriaCenter = LatLng(34.8, 38.8);

  final MapController _mapController = MapController();
  bool _mapReady = false;
  bool _locating = false;
  String? _locationError;

  LatLng get _selectedPoint {
    final latitude = widget.selectedLatitude;
    final longitude = widget.selectedLongitude;
    if (latitude == null || longitude == null) return _syriaCenter;
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      return _syriaCenter;
    }
    return LatLng(latitude, longitude);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _selectPoint(LatLng point) {
    DarbHaptics.selection();
    widget.onPointSelected(point.latitude, point.longitude);
    setState(() => _locationError = null);
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      final position = await DarbLocationService.getCurrentPosition();
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      _selectPoint(point);
      if (_mapReady) _mapController.move(point, 15.5);
    } on DarbLocationException catch (error) {
      if (mounted) setState(() => _locationError = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _locationError = dt(
            'تعذر تحديد موقعك الحالي. تحقق من إعدادات الموقع وحاول مجدداً.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final point = _selectedPoint;
    final hasSelection =
        widget.selectedLatitude != null && widget.selectedLongitude != null;
    final accent = DarbColors.primaryOf(context);
    final teal = DarbColors.violetOf(context);
    final isDark = DarbColors.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: DarbMotion.effectiveDuration(context, DarbMotion.fast),
          height: 256,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: DarbColors.softSurfaceOf(context),
            borderRadius: BorderRadius.circular(DarbRadius.xl),
            border: Border.all(
              color: hasSelection
                  ? (isDark ? DarbColors.lime : accent)
                  : DarbColors.borderOf(context),
              width: hasSelection ? 1.6 : 1.0,
            ),
            boxShadow: DarbElevation.card(isDark),
          ),
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: point,
                  initialZoom: hasSelection ? 15 : 6,
                  minZoom: 4,
                  maxZoom: 19,
                  onMapReady: () => _mapReady = true,
                  onTap: (_, tappedPoint) => _selectPoint(tappedPoint),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.darb.darb',
                    maxZoom: 19,
                  ),
                  if (hasSelection)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 54,
                          height: 62,
                          alignment: Alignment.topCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      DarbColors.forest,
                                      DarbColors.forestSoft,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: DarbColors.lime,
                                    width: 2.4,
                                  ),
                                  boxShadow: DarbElevation.floating(isDark),
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  size: 22,
                                  color: DarbColors.lime,
                                ),
                              ),
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  color: teal,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  RichAttributionWidget(
                    alignment: AttributionAlignment.bottomRight,
                    showFlutterMapAttribution: false,
                    attributions: [
                      TextSourceAttribution(
                        '© OpenStreetMap contributors',
                        onTap: () => launchUrl(
                          Uri.parse('https://www.openstreetmap.org/copyright'),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              PositionedDirectional(
                top: 10,
                end: 10,
                child: DarbGlassSurface(
                  borderRadius: DarbRadius.md,
                  blurSigma: 18,
                  padding: EdgeInsets.zero,
                  child: Column(
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
                        icon: Icon(
                          Icons.add_rounded,
                          color: DarbColors.inkOf(context),
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: DarbColors.borderOf(context),
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
                        icon: Icon(
                          Icons.remove_rounded,
                          color: DarbColors.inkOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!hasSelection)
                PositionedDirectional(
                  start: 12,
                  end: 62,
                  top: 10,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [DarbColors.darkCanvas, DarbColors.forest],
                        ),
                        borderRadius: BorderRadius.circular(DarbRadius.md),
                        border: Border.all(
                          color: DarbColors.lime.withValues(alpha: 0.42),
                        ),
                        boxShadow: DarbElevation.card(isDark),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            size: 16,
                            color: DarbColors.lime,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              dt('حرّك الخريطة واضغط لتحديد النقطة بدقة'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
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
        const SizedBox(height: 10),
        DarbGlassSurface(
          borderRadius: DarbRadius.md,
          elevated: false,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          borderColor: hasSelection
              ? teal.withValues(alpha: 0.35)
              : DarbColors.borderOf(context),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasSelection) ...[
                    DarbPulseDot(color: teal, size: 7.5),
                    const SizedBox(width: 6),
                  ] else ...[
                    Icon(
                      Icons.pin_drop_outlined,
                      size: 16,
                      color: DarbColors.mutedOf(context),
                    ),
                    const SizedBox(width: 6),
                  ],
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 185),
                    child: Text(
                      hasSelection
                          ? '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}'
                          : (widget.cityName == null
                              ? dt('لم يتم تحديد نقطة بعد')
                              : dt('حدد الموقع على خريطة ${widget.cityName}')),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasSelection
                            ? DarbColors.inkOf(context)
                            : DarbColors.mutedOf(context),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              DarbPressScale(
                borderRadius: DarbRadius.pill,
                onTap: _locating ? null : _useCurrentLocation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? DarbColors.lime : DarbColors.forest)
                        .withValues(alpha: isDark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(DarbRadius.pill),
                    border: Border.all(
                      color: (isDark ? DarbColors.lime : DarbColors.forest)
                          .withValues(alpha: 0.32),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_locating)
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? DarbColors.lime : DarbColors.forest,
                          ),
                        )
                      else
                        Icon(
                          Icons.my_location_rounded,
                          size: 15,
                          color: isDark ? DarbColors.lime : DarbColors.forest,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        _locating ? dt('جارٍ التحديد') : dt('موقعي الحالي'),
                        style: TextStyle(
                          color: isDark ? DarbColors.lime : DarbColors.forest,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_locationError != null) ...[
          const SizedBox(height: 6),
          Text(
            _locationError!,
            style: TextStyle(
              color: DarbColors.dangerOf(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
