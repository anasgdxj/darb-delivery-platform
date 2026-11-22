import 'dart:ui';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/darb_design_system.dart';

class DarbMapPicker extends StatelessWidget {
  const DarbMapPicker({
    super.key,
    required this.onPointSelected,
    this.selectedLatitude,
    this.selectedLongitude,
    this.cityName,
    this.height = 232,
  });

  final double? selectedLatitude;
  final double? selectedLongitude;
  final String? cityName;
  final void Function(double latitude, double longitude) onPointSelected;
  final double height;

  static const LatLng _syriaCenter = LatLng(35.0, 38.5);

  static LatLng _centerForCity(String? cityName) {
    final name = (cityName ?? '').trim().toLowerCase();
    if (name.contains('حلب') || name.contains('aleppo')) return const LatLng(36.2021, 37.1343);
    if (name.contains('دمشق') || name.contains('damascus')) return const LatLng(33.5138, 36.2765);
    if (name.contains('حمص') || name.contains('homs')) return const LatLng(34.7324, 36.7137);
    if (name.contains('حماة') || name.contains('hama')) return const LatLng(35.1318, 36.7515);
    if (name.contains('اللاذقية') || name.contains('latakia')) return const LatLng(35.5317, 35.7901);
    if (name.contains('طرطوس') || name.contains('tartus')) return const LatLng(34.8890, 35.8866);
    if (name.contains('الرقة') || name.contains('raqqa')) return const LatLng(35.9528, 39.0079);
    if (name.contains('دير الزور') || name.contains('deir')) return const LatLng(35.3359, 40.1408);
    if (name.contains('درعا') || name.contains('daraa')) return const LatLng(32.6189, 36.1021);
    return _syriaCenter;
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedLatitude != null && selectedLongitude != null;
    final selectedPoint = hasSelection
        ? LatLng(selectedLatitude!, selectedLongitude!)
        : null;
    final center = selectedPoint ?? _centerForCity(cityName);
    final isDark = DarbColors.isDark(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(DarbRadius.lg),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: hasSelection ? 15 : 6.2,
                minZoom: 4,
                maxZoom: 19,
                onTap: (tapPosition, point) {
                  onPointSelected(point.latitude, point.longitude);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.darb.darb',
                  maxZoom: 19,
                ),
                if (selectedPoint != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: selectedPoint,
                        width: 48,
                        height: 56,
                        child: Icon(
                          Icons.location_pin,
                          size: 48,
                          color: DarbColors.dangerOf(context),
                          shadows: const [
                            Shadow(color: Colors.white, blurRadius: 5),
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
                          Uri.parse('https://www.openstreetmap.org/copyright'),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            PositionedDirectional(
              top: 10,
              start: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: (isDark ? DarbColors.darkSurface : Colors.white)
                      .withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(DarbRadius.sm),
                  border: Border.all(
                    color: DarbColors.borderOf(context).withValues(alpha: 0.7),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 15,
                        color: DarbColors.primaryOf(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasSelection
                            ? dt('حرّك العلامة بالضغط على الخريطة')
                            : dt('اضغط على الخريطة لتحديد الموقع'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: DarbColors.inkOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (selectedPoint != null)
              PositionedDirectional(
                bottom: 10,
                start: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: (isDark ? DarbColors.darkSurface : Colors.white)
                        .withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(DarbRadius.sm),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    child: Text(
                      '${selectedPoint.latitude.toStringAsFixed(5)}, '
                      '${selectedPoint.longitude.toStringAsFixed(5)}',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: DarbColors.inkOf(context),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
