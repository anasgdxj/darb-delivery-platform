import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/darb_design_system.dart';
import 'darb_glass.dart';
import 'darb_motion_components.dart';

class DarbBrandMark extends StatelessWidget {
  const DarbBrandMark({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DarbColors.forestSoft, DarbColors.forest],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: DarbColors.mint.withValues(alpha: 0.38),
          width: size >= 56 ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: DarbColors.forest.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: CustomPaint(
          painter: const _DarbBrandMarkPainter(),
          size: Size.square(size),
        ),
      ),
    );
  }
}

class _DarbBrandMarkPainter extends CustomPainter {
  const _DarbBrandMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // Subtle geometric sage map lines inside the emblem
    final gridPaint = Paint()
      ..color = const Color(0xFF28584B).withValues(alpha: 0.55)
      ..strokeWidth = (s * 0.025).clamp(0.7, 1.8)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final grid = Path()
      ..moveTo(0, s * 0.27)
      ..lineTo(s, s * 0.27)
      ..moveTo(0, s * 0.73)
      ..lineTo(s, s * 0.73)
      ..moveTo(s * 0.27, 0)
      ..lineTo(s * 0.27, s)
      ..moveTo(s * 0.73, 0)
      ..lineTo(s * 0.73, s);
    canvas.drawPath(grid, gridPaint);

    // Symmetrical S-route matching Android ic_launcher.xml
    final start = Offset(s * 0.28, s * 0.72);
    final end = Offset(s * 0.72, s * 0.28);
    final route = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        s * 0.19,
        s * 0.34,
        s * 0.43,
        s * 0.41,
        s * 0.50,
        s * 0.50,
      )
      ..cubicTo(
        s * 0.57,
        s * 0.59,
        s * 0.81,
        s * 0.66,
        end.dx,
        end.dy,
      );

    // Soft mint glow
    canvas.drawPath(
      route,
      Paint()
        ..color = DarbColors.mint.withValues(alpha: 0.28)
        ..strokeWidth = s * 0.15
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Core mint route ribbon
    canvas.drawPath(
      route,
      Paint()
        ..color = DarbColors.mint
        ..strokeWidth = (s * 0.082).clamp(2.2, 7.0)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Start origin node (Mint ring)
    final nodeRadius = (s * 0.088).clamp(2.8, 7.5);
    canvas.drawCircle(start, nodeRadius, Paint()..color = DarbColors.forest);
    canvas.drawCircle(
      start,
      nodeRadius,
      Paint()
        ..color = DarbColors.mint
        ..strokeWidth = (s * 0.036).clamp(1.2, 3.0)
        ..style = PaintingStyle.stroke,
    );

    // Destination beacon (Lime accent)
    canvas.drawCircle(
      end,
      nodeRadius * 1.45,
      Paint()..color = DarbColors.lime.withValues(alpha: 0.24),
    );
    canvas.drawCircle(end, nodeRadius, Paint()..color = DarbColors.lime);
    canvas.drawCircle(
      end,
      nodeRadius * 0.38,
      Paint()..color = DarbColors.forest,
    );
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
      borderColor: color.withValues(alpha: isDark ? 0.28 : 0.16),
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
                        color.withValues(alpha: isDark ? 0.28 : 0.18),
                        color.withValues(alpha: isDark ? 0.12 : 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: color.withValues(alpha: 0.26),
                    ),
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.72),
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
          isDark ? DarbColors.mint : DarbColors.success,
          isDark
              ? DarbColors.forestSoft.withValues(alpha: 0.92)
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
        border: Border.all(color: fg.withValues(alpha: isDark ? 0.34 : 0.26)),
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
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
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
                  ? DarbColors.forestSoft.withValues(alpha: 0.72)
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

/// Visual order progression timeline used across Customer, Driver, and Vendor
/// order views. Automatically adapts steps for store vs peer-delivery orders.
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
            return AnimatedContainer(
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
              ),
              child: Icon(
                steps[stepIdx].$3,
                size: compact ? 13 : 15,
                color: current
                    ? DarbColors.onPrimaryOf(context)
                    : (reached ? activeTone : muted),
              ),
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
                    fontWeight: i == activeIndex ? FontWeight.w900 : FontWeight.w600,
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

/// Visual logistics route connector displaying Pickup -> Dropoff nodes with a
/// vertical connecting track, used across driver dispatch, peer delivery, and
/// customer order summaries.
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

/// Featured Bento tile with Obsidian Emerald or Frosted Glass styling, icon
/// badge, optional pill tag, and tactile press response.
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
              color: DarbColors.mint.withValues(alpha: 0.28),
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
      borderColor: accent.withValues(alpha: isDark ? 0.28 : 0.20),
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
