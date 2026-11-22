import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';

class DarbAnimatedMapHero extends StatefulWidget {
  const DarbAnimatedMapHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.localeCode,
    required this.onLocaleChanged,
  });

  final String title;
  final String subtitle;
  final String localeCode;
  final ValueChanged<String> onLocaleChanged;

  @override
  State<DarbAnimatedMapHero> createState() => _DarbAnimatedMapHeroState();
}

class _DarbAnimatedMapHeroState extends State<DarbAnimatedMapHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  int _focusedPin = -1;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DarbMotion.reduceMotion(context)) {
      _motion.stop();
      _motion.value = 0.58;
    } else if (!_motion.isAnimating) {
      _motion.repeat();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = DarbMotion.reduceMotion(context);

    return SizedBox(
      height: 365,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF11221B),
                    Color(0xFF0B1A15),
                    Color(0xFF102B26),
                  ],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _motion,
              builder: (context, _) => CustomPaint(
                painter: _DarbMapPainter(
                  progress: _motion.value,
                  focusedPin: _focusedPin,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            PositionedDirectional(
              top: 0,
              start: 0,
              end: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(18, 10, 18, 0),
                  child: Row(
                    children: [
                      const DarbBrandMark(size: 38),
                      const SizedBox(width: 9),
                      const Text(
                        'دَرْب · DARB',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const Spacer(),
                      DarbGlassSurface(
                        borderRadius: DarbRadius.pill,
                        blurSigma: 16,
                        tintColor: const Color(0xFF07150F).withValues(alpha: 0.58),
                        borderColor: DarbColors.mint.withValues(alpha: 0.30),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: widget.localeCode,
                            dropdownColor: const Color(0xFF132C23),
                            borderRadius: BorderRadius.circular(DarbRadius.md),
                            iconEnabledColor: DarbColors.mint,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'ar', child: Text('AR')),
                              DropdownMenuItem(value: 'en', child: Text('EN')),
                              DropdownMenuItem(value: 'tr', child: Text('TR')),
                            ],
                            onChanged: (code) {
                              if (code != null) widget.onLocaleChanged(code);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              start: 0,
              end: 0,
              top: 82,
              child: Column(
                children: [
                  DarbFadeSlide(
                    offsetY: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFB9E4D2), Color(0xFF42D6A3)],
                            ),
                            borderRadius: BorderRadius.circular(19),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF42D6A3).withValues(alpha: 0.26),
                                blurRadius: 30,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.route_rounded,
                            color: Color(0xFF102B26),
                            size: 35,
                          ),
                        ),
                        const SizedBox(width: 13),
                        const Text(
                          'DARB',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 31,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 19),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(color: Color(0x66000000), blurRadius: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD0DCD5),
                        fontSize: 13.5,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PositionedDirectional(
              start: 13,
              top: 174,
              child: _MapPinButton(
                selected: _focusedPin == 0,
                reduceMotion: reduceMotion,
                onTap: () => setState(() => _focusedPin = _focusedPin == 0 ? -1 : 0),
              ),
            ),
            PositionedDirectional(
              end: 13,
              top: 198,
              child: _MapPinButton(
                selected: _focusedPin == 1,
                reduceMotion: reduceMotion,
                onTap: () => setState(() => _focusedPin = _focusedPin == 1 ? -1 : 1),
              ),
            ),
            if (_focusedPin != -1)
              PositionedDirectional(
                bottom: 17,
                start: 0,
                end: 0,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: DarbMotion.effectiveDuration(
                      context,
                      const Duration(milliseconds: 220),
                    ),
                    child: DarbGlassSurface(
                      key: ValueKey(_focusedPin),
                      borderRadius: DarbRadius.pill,
                      blurSigma: 14,
                      tintColor: const Color(0xFF07150F).withValues(alpha: 0.72),
                      borderColor: DarbColors.mint.withValues(alpha: 0.35),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.storefront_rounded, color: DarbColors.mint, size: 15),
                          const SizedBox(width: 7),
                          Text(
                            _focusedPin == 0 ? 'نقطة المتجر' : 'وجهة التوصيل',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
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

class _MapPinButton extends StatelessWidget {
  const _MapPinButton({
    required this.selected,
    required this.reduceMotion,
    required this.onTap,
  });

  final bool selected;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'تحديد نقطة على مسار دَرْب',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.16 : 1,
          duration: DarbMotion.effectiveDuration(
            context,
            const Duration(milliseconds: 240),
          ),
          curve: Curves.easeOutBack,
          child: SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!reduceMotion)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 700),
                    width: selected ? 56 : 42,
                    height: selected ? 56 : 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DarbColors.mint.withValues(alpha: selected ? 0.58 : 0.24),
                        width: 1.2,
                      ),
                    ),
                  ),
                Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB9E4D2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF54E7B5).withValues(alpha: 0.72),
                        blurRadius: selected ? 25 : 16,
                        spreadRadius: selected ? 4 : 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 17,
                    color: Color(0xFF102B26),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DarbMapPainter extends CustomPainter {
  _DarbMapPainter({required this.progress, required this.focusedPin});

  final double progress;
  final int focusedPin;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final streetPaint = Paint()
      ..color = const Color(0xFF8BAF9C).withValues(alpha: 0.105)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round;

    for (var i = -2; i < 8; i++) {
      final offset = i * w / 5;
      final path = Path()
        ..moveTo(offset, 0)
        ..cubicTo(offset + w * 0.13, h * 0.24, offset - w * 0.08, h * 0.62, offset + w * 0.16, h);
      canvas.drawPath(path, streetPaint);
    }

    for (var i = -1; i < 7; i++) {
      final y = i * h / 5;
      final path = Path()
        ..moveTo(0, y + h * 0.12)
        ..cubicTo(w * 0.28, y - h * 0.10, w * 0.62, y + h * 0.22, w, y - h * 0.02);
      canvas.drawPath(path, streetPaint);
    }

    final blocksPaint = Paint()
      ..color = const Color(0xFFB9E4D2).withValues(alpha: 0.025)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 9; i++) {
      final x = (i * 83.0 + 27) % (w + 30) - 15;
      final y = (i * 61.0 + 42) % (h + 24) - 12;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((i % 3 - 1) * 0.12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 30 + (i % 3) * 9, height: 18 + (i % 2) * 8),
          const Radius.circular(3),
        ),
        blocksPaint,
      );
      canvas.restore();
    }

    final route = Path()
      ..moveTo(w * 0.12, h * 0.515)
      ..cubicTo(w * 0.31, h * 0.39, w * 0.34, h * 0.70, w * 0.51, h * 0.60)
      ..cubicTo(w * 0.69, h * 0.49, w * 0.76, h * 0.40, w * 0.88, h * 0.56);

    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xFF36D7A2).withValues(alpha: 0.13)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xFF68E9BA).withValues(alpha: 0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.1
        ..strokeCap = StrokeCap.round,
    );

    final metric = route.computeMetrics().first;
    final animatedPath = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(
      animatedPath,
      Paint()
        ..color = const Color(0xFF8FFFD1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    final glowPosition = metric.getTangentForOffset(metric.length * progress)?.position;
    if (glowPosition != null) {
      canvas.drawCircle(
        glowPosition,
        5.5 + math.sin(progress * math.pi * 2).abs() * 2.5,
        Paint()
          ..color = const Color(0xFFB9FFE1).withValues(alpha: 0.92)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    for (final point in [Offset(w * 0.12, h * 0.515), Offset(w * 0.88, h * 0.56)]) {
      final pulse = 0.5 + 0.5 * math.sin(progress * math.pi * 2);
      canvas.drawCircle(
        point,
        17 + pulse * 10,
        Paint()
          ..color = const Color(0xFF55E8B5).withValues(alpha: 0.10 + pulse * 0.09)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DarbMapPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.focusedPin != focusedPin;
}
