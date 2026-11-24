import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/darb_design_system.dart';
import 'darb_glass.dart';
import 'darb_motion_components.dart';

/// Deterministic animated visual scene for the currently selected city ONLY.
/// Renders the local bundled scene asset matching [cityCode] (or a bespoke Neo
/// geometric city skyline painter if no asset exists for that city), with a
/// gentle Ken Burns motion loop that honors Reduce Motion and NEVER cycles
/// randomly between different cities.
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

  static String? resolveAssetPath(String cityCode, [String cityName = '']) {
    final code = cityCode.trim().toLowerCase();
    const known = {'damascus', 'aleppo', 'homs', 'hama', 'latakia'};
    if (known.contains(code)) return 'assets/cities/$code.jpg';

    final name = cityName.trim().toLowerCase();
    if (name.contains('دمشق') || name.contains('damascus') || name.contains('şam')) {
      return 'assets/cities/damascus.jpg';
    }
    if (name.contains('حلب') || name.contains('aleppo') || name.contains('halep')) {
      return 'assets/cities/aleppo.jpg';
    }
    if (name.contains('حمص') || name.contains('homs') || name.contains('humus')) {
      return 'assets/cities/homs.jpg';
    }
    if (name.contains('حماة') || name.contains('حماه') || name.contains('hama')) {
      return 'assets/cities/hama.jpg';
    }
    if (name.contains('اللاذقية') ||
        name.contains('لاذقية') ||
        name.contains('latakia') ||
        name.contains('lazkiye')) {
      return 'assets/cities/latakia.jpg';
    }
    return null;
  }

  @override
  State<DarbCitySceneCard> createState() => _DarbCitySceneCardState();
}

class _DarbCitySceneCardState extends State<DarbCitySceneCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _kenBurns;

  @override
  void initState() {
    super.initState();
    _kenBurns = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
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
      if (_kenBurns.isAnimating) _kenBurns.stop();
      _kenBurns.value = 0.0;
    } else if (!_kenBurns.isAnimating) {
      _kenBurns.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _kenBurns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetPath =
        DarbCitySceneCard.resolveAssetPath(widget.cityCode, widget.cityName);
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
                  animation: _kenBurns,
                  builder: (context, child) {
                    final t = reduced ? 0.0 : _kenBurns.value;
                    final scale = 1.0 + (t * 0.075);
                    final offsetX = math.sin(t * math.pi) * 8.0;
                    final offsetY = -t * 5.0;
                    return Transform.translate(
                      offset: Offset(offsetX, offsetY),
                      child: Transform.scale(
                        scale: scale,
                        child: child,
                      ),
                    );
                  },
                  child: assetPath != null
                      ? Image.asset(
                          assetPath,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          errorBuilder: (_, __, ___) =>
                              _NeoCityVectorBackdrop(cityCode: widget.cityCode),
                        )
                      : _NeoCityVectorBackdrop(cityCode: widget.cityCode),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x45091915),
                    Color(0xA612302A),
                    Color(0xEB12302A),
                  ],
                  stops: [0.0, 0.52, 1.0],
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
                        tintColor: DarbColors.forest.withValues(alpha: 0.72),
                        borderColor: DarbColors.mint.withValues(alpha: 0.35),
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
                          tintColor: DarbColors.forest.withValues(alpha: 0.72),
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
                                color: DarbColors.mint,
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
                            size: 18,
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
                                color: Colors.white.withValues(alpha: 0.20),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.home_outlined,
                                  size: 13.5,
                                  color: DarbColors.mint,
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

class _NeoCityVectorBackdrop extends StatelessWidget {
  const _NeoCityVectorBackdrop({required this.cityCode});
  final String cityCode;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NeoCitySkylinePainter(seed: cityCode.hashCode),
      size: Size.infinite,
    );
  }
}

class _NeoCitySkylinePainter extends CustomPainter {
  const _NeoCitySkylinePainter({required this.seed});
  final int seed;

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
            DarbColors.forest,
            DarbColors.forestSoft,
            DarbColors.primaryGreen,
          ],
        ).createShader(Offset.zero & size),
    );

    final gridPaint = Paint()
      ..color = DarbColors.mint.withValues(alpha: 0.14)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (var i = 1; i <= 4; i++) {
      final y = h * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
    for (var i = 1; i <= 6; i++) {
      final x = w * (i / 7);
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }

    final barPaint = Paint()..color = const Color(0xFF0E2620).withValues(alpha: 0.55);
    final rng = math.Random(seed);
    final count = 10;
    final barW = w / count;
    for (var i = 0; i < count; i++) {
      final barH = h * (0.28 + rng.nextDouble() * 0.38);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(i * barW + 3, h - barH, barW - 6, barH),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        ),
        barPaint,
      );
    }

    final route = Path()
      ..moveTo(w * 0.12, h * 0.72)
      ..cubicTo(
        w * 0.34,
        h * 0.32,
        w * 0.66,
        h * 0.68,
        w * 0.88,
        h * 0.30,
      );
    canvas.drawPath(
      route,
      Paint()
        ..color = DarbColors.mint.withValues(alpha: 0.72)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      Offset(w * 0.12, h * 0.72),
      4.5,
      Paint()..color = DarbColors.mint,
    );
    canvas.drawCircle(
      Offset(w * 0.88, h * 0.30),
      5.0,
      Paint()..color = DarbColors.lime,
    );
  }

  @override
  bool shouldRepaint(covariant _NeoCitySkylinePainter oldDelegate) =>
      oldDelegate.seed != seed;
}
