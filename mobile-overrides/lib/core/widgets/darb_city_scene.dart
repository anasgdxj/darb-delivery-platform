import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/darb_design_system.dart';
import 'darb_glass.dart';
import 'darb_motion_components.dart';

/// Bespoke abstract geometric Neo backdrop card for the currently active city.
/// Uses pure layered gradients, isometric grid lines, radar beacons, and a
/// kinetic route curve — never displays city photographs.
class DarbCitySceneCard extends StatefulWidget {
  const DarbCitySceneCard({
    super.key,
    required this.cityCode,
    required this.cityName,
    this.vendorCount = 0,
    this.activeAddressLabel,
    this.onTapAddresses,
  });

  final String cityCode;
  final String cityName;
  final int vendorCount;
  final String? activeAddressLabel;
  final VoidCallback? onTapAddresses;

  @override
  State<DarbCitySceneCard> createState() => _DarbCitySceneCardState();
}

class _DarbCitySceneCardState extends State<DarbCitySceneCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  void _syncAnimation() {
    final reduced = DarbMotion.reduceMotion(context);
    if (reduced) {
      if (_pulseController.isAnimating) _pulseController.stop();
      _pulseController.value = 0.35;
    } else if (!_pulseController.isAnimating) {
      _pulseController.repeat();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = DarbMotion.reduceMotion(context);
    final duration = DarbMotion.effectiveDuration(context, DarbMotion.expressive);
    final sceneKey = ValueKey('${widget.cityCode}_${widget.cityName}');

    return ClipRRect(
      borderRadius: BorderRadius.circular(DarbRadius.xl),
      child: SizedBox(
        height: 176,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: duration,
              switchInCurve: DarbMotion.enter,
              switchOutCurve: DarbMotion.exit,
              child: SizedBox.expand(
                key: sceneKey,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) => CustomPaint(
                    painter: _AbstractCityNetworkPainter(
                      seed: widget.cityCode.hashCode ^ widget.cityName.hashCode,
                      progress: reduced ? 0.35 : _pulseController.value,
                      reducedMotion: reduced,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x280C0D0F),
                    Color(0x8814171D),
                    Color(0xE814171D),
                  ],
                  stops: [0.0, 0.56, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      DarbGlassSurface(
                        borderRadius: DarbRadius.pill,
                        blurSigma: 14,
                        elevated: false,
                        tintColor: DarbColors.forest.withValues(alpha: 0.78),
                        borderColor: DarbColors.lime.withValues(alpha: 0.38),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const DarbPulseDot(
                              color: DarbColors.lime,
                              size: 7,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dt('شبكة التوصيل المباشر'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (widget.vendorCount > 0)
                        DarbGlassSurface(
                          borderRadius: DarbRadius.pill,
                          blurSigma: 14,
                          elevated: false,
                          tintColor: DarbColors.forest.withValues(alpha: 0.78),
                          borderColor: Colors.white.withValues(alpha: 0.22),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.storefront_rounded,
                                size: 13.5,
                                color: DarbColors.lime,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${widget.vendorCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 19,
                            color: DarbColors.lime,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.cityName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (widget.activeAddressLabel != null &&
                          widget.activeAddressLabel!.trim().isNotEmpty)
                        InkWell(
                          onTap: widget.onTapAddresses,
                          borderRadius: BorderRadius.circular(DarbRadius.pill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius:
                                  BorderRadius.circular(DarbRadius.pill),
                              border: Border.all(
                                color: DarbColors.lime.withValues(alpha: 0.30),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.home_outlined,
                                  size: 13.5,
                                  color: DarbColors.lime,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    widget.activeAddressLabel!,
                                    maxLines: 1,
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
                        )
                      else
                        Text(
                          dt('اختر متجرك أو أرسل غرضاً سريعاً داخل مدينتك'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: DarbColors.mint.withValues(alpha: 0.94),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AbstractCityNetworkPainter extends CustomPainter {
  const _AbstractCityNetworkPainter({
    required this.seed,
    required this.progress,
    required this.reducedMotion,
  });

  final int seed;
  final double progress;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DarbColors.darkCanvas,
            DarbColors.forest,
            DarbColors.forestSoft,
          ],
        ).createShader(Offset.zero & size),
    );

    final bloomX = w * (0.72 + math.sin(progress * math.pi * 2) * 0.04);
    canvas.drawCircle(
      Offset(bloomX, h * 0.34),
      w * 0.42,
      Paint()
        ..shader = RadialGradient(
          colors: [
            DarbColors.primaryGreen.withValues(alpha: 0.40),
            DarbColors.violet.withValues(alpha: 0.14),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(
          center: Offset(bloomX, h * 0.34),
          radius: w * 0.42,
        )),
    );

    final gridPaint = Paint()
      ..color = DarbColors.mint.withValues(alpha: 0.09)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (var i = 1; i <= 4; i++) {
      final y = h * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
    for (var i = 1; i <= 7; i++) {
      final x = w * (i / 8);
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }

    final rng = math.Random(seed);
    final facetPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 4; i++) {
      final rx = w * (0.14 + rng.nextDouble() * 0.72);
      final ry = h * (0.14 + rng.nextDouble() * 0.52);
      final rw = 34.0 + rng.nextDouble() * 44.0;
      final rh = 24.0 + rng.nextDouble() * 34.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(rx, ry), width: rw, height: rh),
          const Radius.circular(10),
        ),
        facetPaint,
      );
    }

    final ringCenter = Offset(w * 0.78, h * 0.34);
    final ringPaint = Paint()
      ..color = DarbColors.mint.withValues(alpha: 0.16)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(ringCenter, 36, ringPaint);
    canvas.drawCircle(ringCenter, 62, ringPaint);
    canvas.drawCircle(
      ringCenter,
      92,
      Paint()
        ..color = DarbColors.violet.withValues(alpha: 0.16)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    final start = Offset(w * 0.14, h * 0.66);
    final end = Offset(w * 0.86, h * 0.30);
    final route = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        w * 0.34,
        h * 0.24,
        w * 0.62,
        h * 0.70,
        end.dx,
        end.dy,
      );

    canvas.drawPath(
      route,
      Paint()
        ..color = DarbColors.lime.withValues(alpha: 0.16)
        ..strokeWidth = 7.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      route,
      Paint()
        ..color = DarbColors.mint.withValues(alpha: 0.55)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    if (!reducedMotion) {
      final metrics = route.computeMetrics().toList();
      if (metrics.isNotEmpty) {
        final metric = metrics.first;
        final total = metric.length;
        final segLen = total * 0.18;
        final s = math.max(0.0, (progress * (total + segLen)) - segLen);
        final e = math.min(total, s + segLen);
        if (e > s) {
          canvas.drawPath(
            metric.extractPath(s, e),
            Paint()
              ..color = DarbColors.lime.withValues(alpha: 0.92)
              ..strokeWidth = 2.8
              ..strokeCap = StrokeCap.round
              ..style = PaintingStyle.stroke,
          );
        }
      }
    }

    canvas.drawCircle(start, 4.5, Paint()..color = DarbColors.violet);
    canvas.drawCircle(end, 5.2, Paint()..color = DarbColors.lime);
  }

  @override
  bool shouldRepaint(covariant _AbstractCityNetworkPainter oldDelegate) =>
      oldDelegate.seed != seed ||
      oldDelegate.progress != progress ||
      oldDelegate.reducedMotion != reducedMotion;
}
