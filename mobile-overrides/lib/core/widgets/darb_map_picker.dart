import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/location_service.dart';
import '../theme/darb_design_system.dart';
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
      if (_mapReady) _mapController.move(point, 15);
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
    final hasSelection = widget.selectedLatitude != null &&
        widget.selectedLongitude != null;
    final accent = DarbColors.primaryOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: DarbMotion.effectiveDuration(context, DarbMotion.fast),
          height: 250,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: DarbColors.softSurfaceOf(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasSelection ? accent : DarbColors.borderOf(context),
              width: hasSelection ? 1.5 : 1.0,
            ),
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
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.darb.darb',
                    maxZoom: 19,
                  ),
                  if (hasSelection)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 48,
                          height: 58,
                          alignment: Alignment.topCenter,
                          child: Icon(
                            Icons.location_on_rounded,
                            size: 48,
                            color: accent,
                            shadows: const [
                              Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2)),
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
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(12),
                  elevation: 2,
                  child: Column(
                    children: [
                      IconButton(
                        tooltip: dt('تكبير الخريطة'),
                        visualDensity: VisualDensity.compact,
                        onPressed: _mapReady
                            ? () => _mapController.move(
                                  _mapController.camera.center,
                                  (_mapController.camera.zoom + 1).clamp(4, 19).toDouble(),
                                )
                            : null,
                        icon: const Icon(Icons.add_rounded),
                      ),
                      const Divider(height: 1),
                      IconButton(
                        tooltip: dt('تصغير الخريطة'),
                        visualDensity: VisualDensity.compact,
                        onPressed: _mapReady
                            ? () => _mapController.move(
                                  _mapController.camera.center,
                                  (_mapController.camera.zoom - 1).clamp(4, 19).toDouble(),
                                )
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              if (!hasSelection)
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          dt('حرّك الخريطة واضغط لتحديد النقطة بدقة'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (hasSelection) ...[
              DarbPulseDot(color: accent, size: 7.5),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                hasSelection
                    ? '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}'
                    : (widget.cityName == null
                        ? dt('لم يتم تحديد نقطة بعد')
                        : dt('حدد الموقع على خريطة ${widget.cityName}')),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: DarbColors.mutedOf(context),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: _locating ? null : _useCurrentLocation,
              icon: _locating
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded, size: 17),
              label: Text(_locating ? dt('جارٍ التحديد') : dt('موقعي الحالي')),
            ),
          ],
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
