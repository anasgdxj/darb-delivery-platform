import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/darb_design_system.dart';
import 'darb_glass.dart';
import 'darb_motion_components.dart';

class DarbBrandMark extends StatelessWidget {
  const DarbBrandMark({
    super.key,
    this.size = 44,
    this.animatePulse = false,
  });
  final double size;
  final bool animatePulse;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.28);
    final emblem = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DarbColors.darkCanvas,
            DarbColors.forest,
            DarbColors.forestSoft,
          ],
        ),
        borderRadius: radius,
        border: Border.all(
          color: DarbColors.lime.withValues(alpha: 0.52),
          width: size >= 56 ? 1.5 : 1.05,
        ),
        boxShadow: [
          BoxShadow(
            color: DarbColors.darkCanvas.withValues(alpha: 0.42),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: CustomPaint(
          painter: const _DarbBrandMarkPainter(),
          size: Size.square(size),
        ),
      ),
    );

    if (!animatePulse) return emblem;
    return DarbBeaconRing(
      active: true,
      color: DarbColors.lime,
      maxScale: 1.24,
      borderRadius: radius,
      child: emblem,
    );
  }
}

class _DarbBrandMarkPainter extends CustomPainter {
  const _DarbBrandMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.save();
    canvas.scale(s / 108.0);

    // Subtle warm Champagne Brass radial sheen behind the monogram
    final glowRect = Rect.fromCircle(center: const Offset(56, 52), radius: 44);
    canvas.drawCircle(
      const Offset(56, 52),
      44,
      Paint()
        ..shader = RadialGradient(
          colors: [
            DarbColors.lime.withValues(alpha: 0.22),
            DarbColors.darkViolet.withValues(alpha: 0.12),
            Colors.transparent,
          ],
          stops: const [0.0, 0.56, 1.0],
        ).createShader(glowRect),
    );

    // Architectural calibration rings matching adaptive launcher emblem
    canvas.drawCircle(
      const Offset(54, 54),
      36.5,
      Paint()
        ..color = DarbColors.mint.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15,
    );
    canvas.drawCircle(
      const Offset(54, 54),
      30.5,
      Paint()
        ..color = DarbColors.mint.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.05,
    );

    // Architectural chamfered ivory "D" crest
    final d = Path()
      ..moveTo(34, 25.5)
      ..lineTo(57, 25.5)
      ..lineTo(79.5, 42)
      ..lineTo(79.5, 66)
      ..lineTo(57, 82.5)
      ..lineTo(34, 82.5)
      ..lineTo(43, 71.5)
      ..lineTo(54.5, 71.5)
      ..lineTo(68, 61.5)
      ..lineTo(68, 46.5)
      ..lineTo(54.5, 36.5)
      ..lineTo(43, 36.5)
      ..close();
    canvas.drawPath(d, Paint()..color = const Color(0xFFF8F5EE));

    // Double-bevel Champagne Brass route vector cutting through the crest
    final upperBevel = Path()
      ..moveTo(28, 36)
      ..lineTo(52, 54)
      ..lineTo(28, 72);
    canvas.drawPath(
      upperBevel,
      Paint()
        ..color = DarbColors.lime
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Subtle secondary champagne speed line
    final innerEcho = Path()
      ..moveTo(34.5, 45)
      ..lineTo(45.5, 54)
      ..lineTo(34.5, 63);
    canvas.drawPath(
      innerEcho,
      Paint()
        ..color = const Color(0xD8F2DFB4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Champagne origin/destination anchor pins with ivory specular highlights
    final pinPaint = Paint()..color = DarbColors.lime;
    final specPaint = Paint()..color = const Color(0xE6FFF7E6);
    canvas.drawCircle(const Offset(28, 36), 4.2, pinPaint);
    canvas.drawCircle(const Offset(28, 36), 1.35, specPaint);
    canvas.drawCircle(const Offset(28, 72), 4.2, pinPaint);
    canvas.drawCircle(const Offset(28, 72), 1.35, specPaint);

    // Mineral Teal live telemetry core inside the Brass nexus
    canvas.drawCircle(
      const Offset(53, 54),
      9.8,
      Paint()..color = DarbColors.darkViolet.withValues(alpha: 0.28),
    );
    canvas.drawCircle(
      const Offset(53, 54),
      5.8,
      Paint()..color = DarbColors.darkViolet,
    );
    canvas.drawCircle(
      const Offset(53, 54),
      2.2,
      Paint()..color = DarbColors.darkCanvas,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DarbBrandMarkPainter oldDelegate) => false;
}

class DarbSectionHeader extends StatelessWidget {
  const DarbSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ink = DarbColors.inkOf(context);
    final muted = DarbColors.mutedOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      color: muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class DarbMetricCard extends StatelessWidget {
  const DarbMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accentColor,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? accentColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = DarbColors.isDark(context);
    final color = accentColor ?? DarbColors.primaryOf(context);
    return DarbGlassSurface(
      padding: const EdgeInsets.all(14),
      borderRadius: DarbRadius.md,
      borderColor: color.withValues(alpha: isDark ? 0.30 : 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: isDark ? 0.26 : 0.18),
                        color.withValues(alpha: isDark ? 0.10 : 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: color.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.80),
                  shape: BoxShape.circle,
                  boxShadow: DarbElevation.glow(color, isDark: isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: DarbColors.inkOf(context),
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: DarbColors.mutedOf(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DarbStatusBadge extends StatelessWidget {
  const DarbStatusBadge({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final isDark = DarbColors.isDark(context);

    final (Color fg, Color bg, String label) = switch (normalized) {
      'DELIVERED' || 'APPROVED' || 'OPEN' || 'ONLINE' || 'ACCEPTED' => (
          isDark ? DarbColors.lime : DarbColors.success,
          isDark
              ? DarbColors.forestSoft.withValues(alpha: 0.94)
              : DarbColors.mintTint,
          _translateStatus(normalized),
        ),
      'CANCELLED' || 'REJECTED' || 'SUSPENDED' || 'CLOSED' || 'OFFLINE' => (
          DarbColors.dangerOf(context),
          DarbColors.dangerOf(context).withValues(alpha: isDark ? 0.22 : 0.11),
          _translateStatus(normalized),
        ),
      'PICKED_UP' || 'ASSIGNED' || 'READY' || 'PREPARING' => (
          DarbColors.infoOf(context),
          DarbColors.infoOf(context).withValues(alpha: isDark ? 0.24 : 0.12),
          _translateStatus(normalized),
        ),
      'WITHDRAWN' => (
          DarbColors.mutedOf(context),
          DarbColors.softSurfaceOf(context),
          _translateStatus(normalized),
        ),
      _ => (
          DarbColors.warningOf(context),
          DarbColors.warningOf(context).withValues(alpha: isDark ? 0.24 : 0.13),
          _translateStatus(normalized),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DarbRadius.pill),
        border: Border.all(color: fg.withValues(alpha: isDark ? 0.36 : 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static String _translateStatus(String status) => switch (status) {
        'PENDING' => dt('قيد الانتظار'),
        'ACCEPTED' => dt('مقبول'),
        'PREPARING' => dt('قيد التحضير'),
        'READY' => dt('جاهز للاستلام'),
        'ASSIGNED' => dt('تم تعيين مندوب'),
        'PICKED_UP' => dt('في الطريق إليك'),
        'DELIVERED' => dt('تم التسليم'),
        'CANCELLED' => dt('ملغى'),
        'APPROVED' => dt('معتمد'),
        'REJECTED' => dt('مرفوض'),
        'SUSPENDED' => dt('موقوف'),
        'WITHDRAWN' => dt('مسحوب'),
        'OPEN' => dt('مفتوح'),
        'CLOSED' => dt('مغلق'),
        'ONLINE' => dt('متصل'),
        'OFFLINE' => dt('غير متصل'),
        _ => status,
      };
}

class DarbStateView extends StatelessWidget {
  const DarbStateView.loading({super.key, this.message})
      : _kind = _StateKind.loading,
        icon = Icons.hourglass_top_rounded,
        onRetry = null;

  const DarbStateView.empty({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onRetry,
  }) : _kind = _StateKind.empty;

  const DarbStateView.error({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon = Icons.wifi_off_rounded,
  }) : _kind = _StateKind.error;

  final _StateKind _kind;
  final String? message;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (_kind == _StateKind.loading) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, _) => const _DarbSkeletonCard(),
      );
    }

    final isError = _kind == _StateKind.error;
    final tint =
        isError ? DarbColors.dangerOf(context) : DarbColors.primaryOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DarbGlassSurface(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: tint.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, size: 28, color: tint),
              ),
              const SizedBox(height: 14),
              Text(
                message ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DarbColors.inkOf(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(dt('إعادة المحاولة')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _StateKind { loading, empty, error }

class _DarbSkeletonCard extends StatelessWidget {
  const _DarbSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final fill = DarbColors.softSurfaceOf(context);
    return DarbGlassSurface(
      padding: const EdgeInsets.all(16),
      child: DarbShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        height: 13,
                        decoration: BoxDecoration(
                          color: fill,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        width: 90,
                        height: 10,
                        decoration: BoxDecoration(
                          color: fill,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 24,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(DarbRadius.pill),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              height: 11,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 210,
              height: 11,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DarbRadioOptionTile extends StatelessWidget {
  const DarbRadioOptionTile({
    super.key,
    required this.selected,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = DarbColors.primaryOf(context);
    final onPrimary = DarbColors.onPrimaryOf(context);
    final isDark = DarbColors.isDark(context);

    return InkWell(
      borderRadius: BorderRadius.circular(DarbRadius.md),
      onTap: onTap,
      child: AnimatedContainer(
        duration: DarbMotion.effectiveDuration(context, DarbMotion.fast),
        curve: DarbMotion.enter,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DarbRadius.md),
          color: selected
              ? (isDark
                  ? DarbColors.forestSoft.withValues(alpha: 0.78)
                  : DarbColors.mintTint.withValues(alpha: 0.78))
              : DarbColors.softSurfaceOf(context).withValues(alpha: 0.60),
          border: Border.all(
            color: selected ? primary : DarbColors.borderOf(context),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: DarbMotion.effectiveDuration(context, DarbMotion.fast),
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? primary : Colors.transparent,
                border: Border.all(
                  color: selected ? primary : DarbColors.mutedOf(context),
                  width: 1.6,
                ),
              ),
              child: selected
                  ? Icon(Icons.check_rounded, size: 14, color: onPrimary)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: DarbColors.inkOf(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: DarbColors.mutedOf(context),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DarbOrderTimeline extends StatelessWidget {
  const DarbOrderTimeline({
    super.key,
    required this.status,
    this.isPeer = false,
    this.compact = false,
  });

  final String status;
  final bool isPeer;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final isCancelled = normalized == 'CANCELLED' || normalized == 'REJECTED';
    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: DarbColors.dangerSoftOf(context),
          borderRadius: BorderRadius.circular(DarbRadius.sm),
          border: Border.all(
            color: DarbColors.dangerOf(context).withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cancel_outlined,
              size: 16,
              color: DarbColors.dangerOf(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                dt('تم إلغاء هذا الطلب'),
                style: TextStyle(
                  color: DarbColors.dangerOf(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final steps = isPeer
        ? <(String, String, IconData)>[
            ('PENDING', dt('قيد الانتظار'), Icons.schedule_rounded),
            ('ASSIGNED', dt('تم التعيين'), Icons.person_pin_circle_outlined),
            ('PICKED_UP', dt('في الطريق'), Icons.delivery_dining_rounded),
            ('DELIVERED', dt('تم التسليم'), Icons.verified_rounded),
          ]
        : <(String, String, IconData)>[
            ('PENDING', dt('جديد'), Icons.receipt_outlined),
            ('PREPARING', dt('التحضير'), Icons.storefront_rounded),
            ('ASSIGNED', dt('المندوب'), Icons.delivery_dining_rounded),
            ('DELIVERED', dt('التسليم'), Icons.verified_rounded),
          ];

    final activeIndex = switch (normalized) {
      'PENDING' => 0,
      'ACCEPTED' || 'PREPARING' || 'READY' => isPeer ? 0 : 1,
      'ASSIGNED' => isPeer ? 1 : 2,
      'PICKED_UP' => isPeer ? 2 : 2,
      'DELIVERED' => steps.length - 1,
      _ => 0,
    };

    final primary = DarbColors.primaryOf(context);
    final success = DarbColors.successOf(context);
    final muted = DarbColors.mutedOf(context);
    final border = DarbColors.borderOf(context);
    final isDone = normalized == 'DELIVERED';
    final activeTone = isDone ? success : primary;
    final duration = DarbMotion.effectiveDuration(context, DarbMotion.standard);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(steps.length * 2 - 1, (idx) {
            if (idx.isOdd) {
              final stepIdx = idx ~/ 2;
              final filled = stepIdx < activeIndex || isDone;
              return Expanded(
                child: AnimatedContainer(
                  duration: duration,
                  curve: DarbMotion.enter,
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: filled ? activeTone : border,
                    borderRadius: BorderRadius.circular(DarbRadius.pill),
                  ),
                ),
              );
            }
            final stepIdx = idx ~/ 2;
            final reached = stepIdx <= activeIndex;
            final current = stepIdx == activeIndex && !isDone;
            final node = AnimatedContainer(
              duration: duration,
              curve: DarbMotion.enter,
              width: compact ? 24 : 28,
              height: compact ? 24 : 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: reached
                    ? (current
                        ? activeTone
                        : activeTone.withValues(alpha: 0.16))
                    : DarbColors.softSurfaceOf(context),
                border: Border.all(
                  color: reached ? activeTone : border,
                  width: current ? 0 : 1.3,
                ),
                boxShadow: current
                    ? [
                        BoxShadow(
                          color: activeTone.withValues(alpha: 0.36),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                steps[stepIdx].$3,
                size: compact ? 13 : 15,
                color: current
                    ? DarbColors.onPrimaryOf(context)
                    : (reached ? activeTone : muted),
              ),
            );
            if (!current) return node;
            return DarbBeaconRing(
              active: true,
              color: activeTone,
              maxScale: 1.42,
              child: node,
            );
          }),
        ),
        if (!compact) ...[
          const SizedBox(height: 6),
          Row(
            children: List.generate(steps.length, (i) {
              final reached = i <= activeIndex;
              return Expanded(
                child: Text(
                  steps[i].$2,
                  textAlign: i == 0
                      ? TextAlign.start
                      : (i == steps.length - 1
                          ? TextAlign.end
                          : TextAlign.center),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight:
                        i == activeIndex ? FontWeight.w900 : FontWeight.w600,
                    color: reached ? DarbColors.inkOf(context) : muted,
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class DarbSearchBar extends StatelessWidget {
  const DarbSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(
          Icons.search_rounded,
          color: DarbColors.primaryOf(context),
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close_rounded, size: 19),
              )
            : null,
      ),
    );
  }
}

class DarbRouteConnector extends StatelessWidget {
  const DarbRouteConnector({
    super.key,
    required this.pickupLabel,
    required this.pickupAddress,
    required this.dropoffLabel,
    required this.dropoffAddress,
    this.badgeText,
  });

  final String pickupLabel;
  final String pickupAddress;
  final String dropoffLabel;
  final String dropoffAddress;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final isDark = DarbColors.isDark(context);
    final primary = DarbColors.primaryOf(context);
    final dropoffColor = isDark ? DarbColors.lime : DarbColors.forest;
    final ink = DarbColors.inkOf(context);
    final muted = DarbColors.mutedOf(context);
    final border = DarbColors.borderOf(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DarbColors.softSurfaceOf(context).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(DarbRadius.md),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(color: primary, width: 2),
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 24,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [primary, dropoffColor],
                      ),
                      borderRadius: BorderRadius.circular(DarbRadius.pill),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          pickupLabel,
                          style: TextStyle(
                            color: primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (badgeText != null && badgeText!.isNotEmpty) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: DarbColors.surfaceElevatedOf(context),
                              borderRadius:
                                  BorderRadius.circular(DarbRadius.pill),
                              border: Border.all(color: border),
                            ),
                            child: Text(
                              badgeText!,
                              style: TextStyle(
                                color: ink,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pickupAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: dropoffColor.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: dropoffColor, width: 1.8),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 12,
                  color: dropoffColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dropoffLabel,
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dropoffAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DarbBentoActionCard extends StatelessWidget {
  const DarbBentoActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.badge,
    this.isHeroDark = false,
    this.accentColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;
  final bool isHeroDark;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = DarbColors.isDark(context);
    final accent = accentColor ??
        (isHeroDark ? DarbColors.lime : DarbColors.primaryOf(context));

    if (isHeroDark) {
      return DarbPressScale(
        onTap: onTap,
        borderRadius: DarbRadius.lg,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [DarbColors.forest, DarbColors.forestSoft],
            ),
            borderRadius: BorderRadius.circular(DarbRadius.lg),
            border: Border.all(
              color: accent.withValues(alpha: 0.34),
            ),
            boxShadow: DarbElevation.floating(isDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Icon(icon, color: accent, size: 21),
                  ),
                  const Spacer(),
                  if (badge != null && badge!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(DarbRadius.pill),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: DarbColors.forest,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: DarbColors.mint.withValues(alpha: 0.88),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: DarbColors.mint.withValues(alpha: 0.86),
                  fontSize: 11.8,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DarbInteractiveCard(
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      borderRadius: DarbRadius.lg,
      borderColor: accent.withValues(alpha: isDark ? 0.30 : 0.24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: accent, size: 21),
              ),
              const Spacer(),
              if (badge != null && badge!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(DarbRadius.pill),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: accent,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: DarbColors.mutedOf(context),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: DarbColors.inkOf(context),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: DarbColors.mutedOf(context),
              fontSize: 11.8,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// Real financial & operational activity strip driven strictly by live backend
/// aggregations (never synthetic balances).
class DarbActivityLedgerStrip extends StatelessWidget {
  const DarbActivityLedgerStrip({
    super.key,
    required this.title,
    required this.primaryLabel,
    required this.primaryValue,
    required this.secondaryLabel,
    required this.secondaryValue,
    this.tertiaryLabel,
    this.tertiaryValue,
    this.icon = Icons.insights_rounded,
    this.accentColor,
    this.onTap,
  });

  final String title;
  final String primaryLabel;
  final String primaryValue;
  final String secondaryLabel;
  final String secondaryValue;
  final String? tertiaryLabel;
  final String? tertiaryValue;
  final IconData icon;
  final Color? accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = DarbColors.isDark(context);
    final accent = accentColor ?? DarbColors.primaryOf(context);
    final ink = DarbColors.inkOf(context);
    final muted = DarbColors.mutedOf(context);

    return DarbInteractiveCard(
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      borderColor: accent.withValues(alpha: isDark ? 0.30 : 0.20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded, size: 20, color: muted),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LedgerCell(
                  label: primaryLabel,
                  value: primaryValue,
                  valueColor: accent,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: DarbColors.borderOf(context),
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              Expanded(
                child: _LedgerCell(
                  label: secondaryLabel,
                  value: secondaryValue,
                  valueColor: ink,
                ),
              ),
              if (tertiaryLabel != null && tertiaryValue != null) ...[
                Container(
                  width: 1,
                  height: 32,
                  color: DarbColors.borderOf(context),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                Expanded(
                  child: _LedgerCell(
                    label: tertiaryLabel!,
                    value: tertiaryValue!,
                    valueColor: ink,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LedgerCell extends StatelessWidget {
  const _LedgerCell({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: DarbColors.mutedOf(context),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

enum DarbFeedbackKind { info, success, warning, error }

class DarbFeedbackBanner extends StatelessWidget {
  const DarbFeedbackBanner({
    super.key,
    required this.message,
    this.kind = DarbFeedbackKind.info,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });

  final String message;
  final DarbFeedbackKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final isDark = DarbColors.isDark(context);
    final Color foreground;
    final Color background;
    final IconData icon;

    switch (kind) {
      case DarbFeedbackKind.success:
        foreground = DarbColors.successOf(context);
        background = isDark ? DarbColors.forestSoft : DarbColors.mintTint;
        icon = Icons.check_circle_rounded;
      case DarbFeedbackKind.warning:
        foreground = DarbColors.warningOf(context);
        background = DarbColors.warningSoftOf(context);
        icon = Icons.warning_amber_rounded;
      case DarbFeedbackKind.error:
        foreground = DarbColors.dangerOf(context);
        background = DarbColors.dangerSoftOf(context);
        icon = Icons.error_outline_rounded;
      case DarbFeedbackKind.info:
        foreground = DarbColors.infoOf(context);
        background = DarbColors.infoSoftOf(context);
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(DarbRadius.md),
        border: Border.all(color: foreground.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: DarbColors.inkOf(context),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: foreground,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          if (onDismiss != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onDismiss,
              icon: Icon(Icons.close_rounded, size: 17, color: foreground),
            ),
        ],
      ),
    );
  }
}

class DarbGroupedSection extends StatelessWidget {
  const DarbGroupedSection({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final border = DarbColors.borderOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: 4,
            end: 4,
            bottom: 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: DarbColors.inkOf(context),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: DarbColors.mutedOf(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        DarbGlassSurface(
          borderRadius: DarbRadius.lg,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i + 1 < children.length)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 62,
                    endIndent: 14,
                    color: border.withValues(alpha: 0.65),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class DarbSettingsTile extends StatelessWidget {
  const DarbSettingsTile({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    this.subtitle,
    this.valueLabel,
    this.trailing,
    this.isDanger = false,
    this.enabled = true,
    this.showChevron = true,
    this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String? subtitle;
  final String? valueLabel;
  final Widget? trailing;
  final bool isDanger;
  final bool enabled;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = DarbColors.mutedOf(context);
    final ink = DarbColors.inkOf(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    Widget? resolvedTrailing = trailing;
    if (resolvedTrailing == null && valueLabel != null) {
      resolvedTrailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              valueLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accentColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (showChevron && !isDanger) ...[
            const SizedBox(width: 4),
            Icon(
              isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              size: 20,
              color: muted,
            ),
          ],
        ],
      );
    } else if (resolvedTrailing == null && showChevron && !isDanger) {
      resolvedTrailing = Icon(
        isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
        size: 20,
        color: muted,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(DarbRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: enabled ? 0.13 : 0.06),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: enabled ? accentColor : muted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: !enabled
                            ? muted
                            : (isDanger ? accentColor : ink),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (resolvedTrailing != null) ...[
                const SizedBox(width: 8),
                resolvedTrailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DarbOtpPinPreview extends StatelessWidget {
  const DarbOtpPinPreview({
    super.key,
    required this.digits,
    this.length = 6,
  });

  final String digits;
  final int length;

  @override
  Widget build(BuildContext context) {
    final primary = DarbColors.primaryOf(context);
    final isDark = DarbColors.isDark(context);
    final ink = DarbColors.inkOf(context);
    final muted = DarbColors.mutedOf(context);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: List.generate(length, (i) {
          final hasChar = i < digits.length;
          final isCurrent = i == digits.length.clamp(0, length - 1);
          final char = hasChar ? digits[i] : '•';
          return Expanded(
            child: AnimatedContainer(
              duration: DarbMotion.effectiveDuration(context, DarbMotion.fast),
              curve: DarbMotion.enter,
              height: 46,
              margin: EdgeInsets.only(right: i == length - 1 ? 0 : 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hasChar
                    ? primary.withValues(alpha: isDark ? 0.16 : 0.09)
                    : DarbColors.softSurfaceOf(context),
                borderRadius: BorderRadius.circular(DarbRadius.sm),
                border: Border.all(
                  color: hasChar
                      ? primary
                      : (isCurrent
                          ? primary.withValues(alpha: 0.55)
                          : DarbColors.borderOf(context)),
                  width: hasChar || isCurrent ? 1.5 : 1.0,
                ),
              ),
              child: Text(
                char,
                style: TextStyle(
                  color: hasChar ? ink : muted.withValues(alpha: 0.45),
                  fontSize: hasChar ? 18 : 16,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
