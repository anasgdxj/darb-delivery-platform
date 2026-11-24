import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/darb_design_system.dart';

/// Minimalist dark-emerald abstract geometric architectural background with
/// subtle coordinate grid lines, glowing route vector path matching DARB's
/// brand curve, and pulsing origin/destination nodes. Uses zero city photos.
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
      duration: const Duration(milliseconds: 3200),
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
        color: Color(0xFF0E211A),
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

  static const _bgBase = Color(0xFF0E211A);
  static const _bgInnerGlow = Color(0xFF1A3C2F);
  static const _sagePrimary = Color(0xFF2D5544);
  static const _sageSecondary = Color(0xFF1F3D31);
  static const _sageBlock = Color(0xFF152D23);
  static const _mint = DarbColors.mint;
  static const _lime = DarbColors.lime;
  static const _pinCore = Color(0xFF0C1D16);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // 1. Deep Obsidian Emerald canvas with warm radial depth
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.5, h * 0.42),
          math.max(w, h) * 0.78,
          [_bgInnerGlow, _bgBase],
        ),
    );

    // Subtle secondary emerald ambient shimmer near top-end
    canvas.drawCircle(
      Offset(w * 0.82, h * 0.24),
      w * 0.34,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.82, h * 0.24),
          w * 0.34,
          [
            DarbColors.primaryGreen.withValues(alpha: 0.26),
            Colors.transparent,
          ],
        ),
    );

    // 2. Abstract architectural geometric planes
    final blockPaint = Paint()
      ..color = _sageBlock.withValues(alpha: 0.78)
      ..style = PaintingStyle.fill;
    final blocks = [
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.16, w * 0.15, h * 0.19),
        const Radius.circular(10),
      ),
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.25, h * 0.10, w * 0.20, h * 0.14),
        const Radius.circular(10),
      ),
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.56, h * 0.12, w * 0.18, h * 0.15),
        const Radius.circular(10),
      ),
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.77, h * 0.35, w * 0.18, h * 0.22),
        const Radius.circular(10),
      ),
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.06, h * 0.52, w * 0.14, h * 0.19),
        const Radius.circular(10),
      ),
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.58, h * 0.68, w * 0.20, h * 0.17),
        const Radius.circular(10),
      ),
    ];
    for (final block in blocks) {
      canvas.drawRRect(block, blockPaint);
    }

    // 3. Secondary coordinate grid lines
    final minorStreetPaint = Paint()
      ..color = _sageSecondary.withValues(alpha: 0.58)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final minorGrid = Path()
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

    // 4. Primary diagonal geometric vectors
    final majorStreetPaint = Paint()
      ..color = _sagePrimary.withValues(alpha: 0.62)
      ..strokeWidth = 1.75
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
      ..moveTo(w * 0.32, 0.0)
      ..lineTo(w * 0.18, h)
      ..moveTo(w * 0.82, 0.0)
      ..lineTo(w * 0.66, h);
    canvas.drawPath(majorRoads, majorStreetPaint);

    // Subtle geometric orbital junction rings
    final junctionPaint = Paint()
      ..color = _sagePrimary.withValues(alpha: 0.58)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(w * 0.24, h * 0.22), 7.5, junctionPaint);
    canvas.drawCircle(Offset(w * 0.74, h * 0.64), 9.0, junctionPaint);

    // 5. Glowing kinetic S-route path matching DARB brand identity
    final startPin = Offset(w * 0.14, h * 0.74);
    final endPin = Offset(w * 0.86, h * 0.26);

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

    canvas.drawPath(
      routePath,
      Paint()
        ..color = _mint.withValues(alpha: 0.22)
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawPath(
      routePath,
      Paint()
        ..color = _mint.withValues(alpha: 0.45)
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );
    canvas.drawPath(
      routePath,
      Paint()
        ..shader = ui.Gradient.linear(
          startPin,
          endPin,
          [
            _mint.withValues(alpha: 0.85),
            const Color(0xFFE6FFF3),
            _lime.withValues(alpha: 0.90),
          ],
          const [0.0, 0.5, 1.0],
        )
        ..strokeWidth = 2.3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Travelling light packet along curve
    if (!reducedMotion) {
      final metrics = routePath.computeMetrics().toList();
      if (metrics.isNotEmpty) {
        final metric = metrics.first;
        final total = metric.length;
        final segLen = total * 0.17;
        final startDist = (progress * (total + segLen)) - segLen;
        final s = math.max(0.0, startDist);
        final e = math.min(total, startDist + segLen);
        if (e > s) {
          canvas.drawPath(
            metric.extractPath(s, e),
            Paint()
              ..color = const Color(0xFFF6FFFA).withValues(alpha: 0.95)
              ..strokeWidth = 3.4
              ..strokeCap = StrokeCap.round
              ..style = PaintingStyle.stroke
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
          );
        }
      }
    }

    // 6. Center contrast vignette for crisp typography
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.5, h * 0.50),
          w * 0.46,
          [
            _bgBase.withValues(alpha: 0.74),
            _bgBase.withValues(alpha: 0.34),
            Colors.transparent,
          ],
          const [0.0, 0.56, 1.0],
        ),
    );

    // 7. Pulsing start & destination pins
    _drawPulsingNode(canvas, startPin, progress, _mint);
    _drawPulsingNode(canvas, endPin, (progress + 0.5) % 1.0, _lime);
  }

  void _drawPulsingNode(
    Canvas canvas,
    Offset center,
    double phase,
    Color tone,
  ) {
    final pulse = reducedMotion ? 0.45 : phase;
    final outerRadius = 10.0 + (pulse * 16.0);
    final outerAlpha = (1.0 - pulse).clamp(0.0, 1.0) * 0.42;

    canvas.drawCircle(
      center,
      outerRadius,
      Paint()..color = tone.withValues(alpha: outerAlpha),
    );
    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..color = tone.withValues(alpha: outerAlpha * 1.15)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      center,
      11.0,
      Paint()
        ..color = tone.withValues(alpha: 0.24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(center, 8.2, Paint()..color = _pinCore);
    canvas.drawCircle(
      center,
      8.2,
      Paint()
        ..color = tone
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      center,
      3.3,
      Paint()..color = const Color(0xFFF0FFF7),
    );
  }

  @override
  bool shouldRepaint(covariant _DarbVectorMapPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.reducedMotion != reducedMotion;
}
