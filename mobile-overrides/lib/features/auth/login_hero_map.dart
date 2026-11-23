import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/darb_design_system.dart';

/// Minimalist dark-green architectural vector map hero background with
/// geometric sage-green street lines, two pulsing store location pins,
/// and a glowing mint-green curved route path mimicking the DARB logo.
class DarbLoginVectorMap extends StatefulWidget {
  const DarbLoginVectorMap({super.key});

  @override
  State<DarbLoginVectorMap> createState() => _DarbLoginVectorMapState();
}

class _DarbLoginVectorMapState extends State<DarbLoginVectorMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = DarbMotion.reduceMotion(context);
    if (reduced) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
      _controller.value = 0.35;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF11221B),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _DarbVectorMapPainter(
              progress: _controller.value,
              reducedMotion: DarbMotion.reduceMotion(context),
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _DarbVectorMapPainter extends CustomPainter {
  const _DarbVectorMapPainter({
    required this.progress,
    required this.reducedMotion,
  });

  final double progress;
  final bool reducedMotion;

  static const _bgBase = Color(0xFF11221B);
  static const _bgInnerGlow = Color(0xFF183227);
  static const _sagePrimary = Color(0xFF2D4F40);
  static const _sageSecondary = Color(0xFF213D31);
  static const _sageBlock = Color(0xFF172D24);
  static const _mint = DarbColors.mint;
  static const _pinCore = Color(0xFF0E1F18);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // 1. Deep minimalist dark-green canvas with soft center-ambient depth
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.5, h * 0.45),
          math.max(w, h) * 0.72,
          [_bgInnerGlow, _bgBase],
        ),
    );

    // 2. Subtle geometric urban parcel blocks
    final blockPaint = Paint()
      ..color = _sageBlock.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    final blocks = [
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.16, w * 0.16, h * 0.20),
        const Radius.circular(8),
      ),
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.26, h * 0.10, w * 0.20, h * 0.15),
        const Radius.circular(8),
      ),
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.56, h * 0.12, w * 0.18, h * 0.16),
        const Radius.circular(8),
      ),
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.77, h * 0.36, w * 0.18, h * 0.22),
        const Radius.circular(8),
      ),
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.06, h * 0.52, w * 0.15, h * 0.20),
        const Radius.circular(8),
      ),
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.58, h * 0.68, w * 0.20, h * 0.18),
        const Radius.circular(8),
      ),
    ];
    for (final block in blocks) {
      canvas.drawRRect(block, blockPaint);
    }

    // 3. Secondary geometric street grid in muted sage green
    final minorStreetPaint = Paint()
      ..color = _sageSecondary.withValues(alpha: 0.55)
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final minorGrid = Path()
      // Horizontal architectural streets
      ..moveTo(0, h * 0.22)
      ..lineTo(w, h * 0.22)
      ..moveTo(0, h * 0.44)
      ..lineTo(w * 0.42, h * 0.44)
      ..moveTo(w * 0.62, h * 0.44)
      ..lineTo(w, h * 0.44)
      ..moveTo(0, h * 0.64)
      ..lineTo(w, h * 0.64)
      ..moveTo(0, h * 0.84)
      ..lineTo(w, h * 0.84)
      // Vertical architectural streets
      ..moveTo(w * 0.12, 0)
      ..lineTo(w * 0.12, h)
      ..moveTo(w * 0.24, 0)
      ..lineTo(w * 0.24, h * 0.70)
      ..moveTo(w * 0.48, 0)
      ..lineTo(w * 0.48, h * 0.28)
      ..moveTo(w * 0.54, h * 0.64)
      ..lineTo(w * 0.54, h)
      ..moveTo(w * 0.74, 0)
      ..lineTo(w * 0.74, h)
      ..moveTo(w * 0.89, 0)
      ..lineTo(w * 0.89, h);
    canvas.drawPath(minorGrid, minorStreetPaint);

    // 4. Primary clean diagonal & arterial roads in muted sage green
    final majorStreetPaint = Paint()
      ..color = _sagePrimary.withValues(alpha: 0.58)
      ..strokeWidth = 1.85
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final majorRoads = Path()
      ..moveTo(-w * 0.04, h * 0.34)
      ..lineTo(w * 0.32, h * 0.14)
      ..lineTo(w * 0.68, h * 0.14)
      ..lineTo(w * 1.04, h * 0.32)
      ..moveTo(-w * 0.02, h * 0.78)
      ..lineTo(w * 0.26, h * 0.54)
      ..moveTo(w * 0.72, h * 0.58)
      ..lineTo(w * 1.02, h * 0.78)
      ..moveTo(w * 0.32, h * 0.0)
      ..lineTo(w * 0.18, h * 1.0)
      ..moveTo(w * 0.82, h * 0.0)
      ..lineTo(w * 0.66, h * 1.0);
    canvas.drawPath(majorRoads, majorStreetPaint);

    // Subtle geometric roundabout rings at intersections
    final junctionPaint = Paint()
      ..color = _sagePrimary.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(w * 0.24, h * 0.22), 7.5, junctionPaint);
    canvas.drawCircle(Offset(w * 0.74, h * 0.64), 9.0, junctionPaint);

    // 5. Glowing mint-green curved route path mimicking DARB's curved S-route
    final startPin = Offset(w * 0.15, h * 0.73);
    final endPin = Offset(w * 0.85, h * 0.27);

    final routePath = Path()
      ..moveTo(startPin.dx, startPin.dy)
      ..cubicTo(
        w * 0.08,
        h * 0.28,
        w * 0.44,
        h * 0.34,
        w * 0.50,
        h * 0.50,
      )
      ..cubicTo(
        w * 0.56,
        h * 0.66,
        w * 0.92,
        h * 0.72,
        endPin.dx,
        endPin.dy,
      );

    // Outer ambient bloom
    canvas.drawPath(
      routePath,
      Paint()
        ..color = _mint.withValues(alpha: 0.24)
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    // Mid luminous halo
    canvas.drawPath(
      routePath,
      Paint()
        ..color = _mint.withValues(alpha: 0.46)
        ..strokeWidth = 5.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );

    // Crisp mint route core
    canvas.drawPath(
      routePath,
      Paint()
        ..shader = ui.Gradient.linear(
          startPin,
          endPin,
          [
            _mint.withValues(alpha: 0.88),
            const Color(0xFFE2FAEF),
            _mint.withValues(alpha: 0.92),
          ],
          const [0.0, 0.5, 1.0],
        )
        ..strokeWidth = 2.3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Traveling light pulse along the curved path when motion is enabled
    if (!reducedMotion) {
      final metrics = routePath.computeMetrics().toList();
      if (metrics.isNotEmpty) {
        final metric = metrics.first;
        final total = metric.length;
        final segLen = total * 0.16;
        final startDist = (progress * (total + segLen)) - segLen;
        final s = math.max(0.0, startDist);
        final e = math.min(total, startDist + segLen);
        if (e > s) {
          final pulseSegment = metric.extractPath(s, e);
          canvas.drawPath(
            pulseSegment,
            Paint()
              ..color = const Color(0xFFF1FFF8).withValues(alpha: 0.92)
              ..strokeWidth = 3.2
              ..strokeCap = StrokeCap.round
              ..style = PaintingStyle.stroke
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
          );
        }
      }
    }

    // 6. Soft center vignette so centered logo, white headline, and light-gray
    // subtitle maintain crisp contrast over the vector lines & curve.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.5, h * 0.52),
          w * 0.44,
          [
            _bgBase.withValues(alpha: 0.72),
            _bgBase.withValues(alpha: 0.30),
            Colors.transparent,
          ],
          const [0.0, 0.55, 1.0],
        ),
    );

    // 7. Two pulsing store location pins at start & end of the curved route
    _drawPulsingStorePin(canvas, startPin, progress);
    _drawPulsingStorePin(canvas, endPin, (progress + 0.5) % 1.0);
  }

  void _drawPulsingStorePin(Canvas canvas, Offset center, double phase) {
    final pulse = reducedMotion ? 0.45 : phase;
    final outerRadius = 10.0 + (pulse * 16.0);
    final outerAlpha = (1.0 - pulse).clamp(0.0, 1.0) * 0.45;

    // Expanding pulse ring
    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..color = _mint.withValues(alpha: outerAlpha)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..color = _mint.withValues(alpha: outerAlpha * 1.15)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );

    // Secondary soft inner glow
    canvas.drawCircle(
      center,
      11.5,
      Paint()
        ..color = _mint.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Store pin circular badge
    canvas.drawCircle(center, 8.5, Paint()..color = _pinCore);
    canvas.drawCircle(
      center,
      8.5,
      Paint()
        ..color = _mint
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );

    // Inner bright mint beacon
    canvas.drawCircle(
      center,
      3.4,
      Paint()..color = const Color(0xFFE6FFF4),
    );
  }

  @override
  bool shouldRepaint(covariant _DarbVectorMapPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.reducedMotion != reducedMotion;
}
