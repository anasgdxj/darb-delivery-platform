import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/darb_design_system.dart';
import 'darb_components.dart';
import 'darb_glass.dart';
import 'darb_motion_components.dart';

/// Dark emerald/obsidian architectural header stage used as the signature focal
/// anchor across Customer, Driver, Vendor, Admin, and Account screens.
class DarbCommandStage extends StatelessWidget {
  const DarbCommandStage({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.leading,
    this.trailing,
    this.bottom,
    this.accentColor,
    this.livePulse = false,
    this.padding = const EdgeInsets.all(20),
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? bottom;
  final Color? accentColor;
  final bool livePulse;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = DarbColors.isDark(context);
    final accent = accentColor ?? DarbColors.lime;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            DarbColors.darkCanvas,
            DarbColors.forest,
            DarbColors.forestSoft,
          ],
        ),
        borderRadius: BorderRadius.circular(DarbRadius.xl),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.34 : 0.24),
        ),
        boxShadow: DarbElevation.glow(
          DarbColors.forest,
          isDark: isDark,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DarbRadius.xl),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _OrbitalStagePainter(accent: accent),
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (eyebrow != null && eyebrow!.isNotEmpty) ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (livePulse) ...[
                                    DarbPulseDot(
                                      active: true,
                                      color: accent,
                                      size: 7.5,
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Flexible(
                                    child: Text(
                                      eyebrow!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: accent,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                            ],
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (subtitle != null && subtitle!.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                subtitle!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFD2E4DB),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 10),
                        trailing!,
                      ],
                    ],
                  ),
                  if (bottom != null) ...[
                    const SizedBox(height: 14),
                    bottom!,
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

class _OrbitalStagePainter extends CustomPainter {
  const _OrbitalStagePainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.88, size.height * 0.14);
    final glowRect = Rect.fromCircle(center: center, radius: 130);
    canvas.drawCircle(
      center,
      130,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: 0.16),
            DarbColors.violet.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(glowRect),
    );

    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    canvas.drawCircle(center, 68, ringPaint);
    canvas.drawCircle(center, 108, ringPaint);

    // Subtle diagonal precision grid arc
    final arcRect = Rect.fromCircle(
      center: Offset(size.width * 0.12, size.height * 1.1),
      radius: size.width * 0.55,
    );
    canvas.drawArc(
      arcRect,
      -math.pi * 0.55,
      math.pi * 0.45,
      false,
      Paint()
        ..color = DarbColors.mint.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitalStagePainter oldDelegate) =>
      oldDelegate.accent != accent;
}

class DarbDockOption<T> {
  const DarbDockOption({
    required this.value,
    required this.label,
    this.count,
    this.icon,
  });

  final T value;
  final String label;
  final int? count;
  final IconData? icon;
}

/// Sleek horizontally scrollable segmented pill dock replacing generic Material
/// ChoiceChip bars across discovery, order queues, and admin consoles.
class DarbSegmentedDock<T> extends StatelessWidget {
  const DarbSegmentedDock({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    this.accentColor,
    this.compact = false,
  });

  final List<DarbDockOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final Color? accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = DarbColors.isDark(context);
    final activeBg = accentColor ??
        (isDark ? DarbColors.lime : DarbColors.forest);
    final activeFg = accentColor != null
        ? Colors.white
        : (isDark ? DarbColors.darkCanvas : Colors.white);
    final idleBg = DarbColors.surfaceOf(context);
    final ink = DarbColors.inkOf(context);
    final muted = DarbColors.mutedOf(context);
    final border = DarbColors.borderOf(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Builder(
              builder: (ctx) {
                final opt = options[i];
                final active = opt.value == selectedValue;
                return DarbPressScale(
                  borderRadius: BorderRadius.circular(DarbRadius.pill),
                  onTap: () {
                    if (!active) {
                      DarbHaptics.selection();
                      onSelected(opt.value);
                    }
                  },
                  child: AnimatedContainer(
                    duration: DarbMotion.effectiveDuration(
                      ctx,
                      DarbMotion.interactive,
                    ),
                    curve: DarbMotion.enter,
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 14,
                      vertical: compact ? 7 : 9,
                    ),
                    decoration: BoxDecoration(
                      color: active ? activeBg : idleBg,
                      borderRadius: BorderRadius.circular(DarbRadius.pill),
                      border: Border.all(
                        color: active ? activeBg : border,
                        width: active ? 1.2 : 1.0,
                      ),
                      boxShadow: active
                          ? DarbElevation.glow(activeBg, isDark: isDark)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (opt.icon != null) ...[
                          Icon(
                            opt.icon,
                            size: compact ? 14 : 15.5,
                            color: active ? activeFg : muted,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          opt.label,
                          style: TextStyle(
                            color: active ? activeFg : ink,
                            fontSize: compact ? 12 : 12.5,
                            fontWeight: active
                                ? FontWeight.w900
                                : FontWeight.w700,
                          ),
                        ),
                        if (opt.count != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? activeFg.withValues(alpha: 0.18)
                                  : DarbColors.surfaceAltOf(ctx),
                              borderRadius:
                                  BorderRadius.circular(DarbRadius.pill),
                            ),
                            child: Text(
                              '${opt.count}',
                              style: TextStyle(
                                color: active ? activeFg : muted,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class DarbCityOrbOption {
  const DarbCityOrbOption({
    required this.id,
    required this.name,
    this.code = '',
  });

  final String id;
  final String name;
  final String code;
}

/// Interactive horizontal city capsule selector replacing clunky dropdown boxes.
class DarbCityOrbStrip extends StatelessWidget {
  const DarbCityOrbStrip({
    super.key,
    required this.cities,
    required this.selectedCityId,
    required this.onSelect,
    this.onDarkStage = false,
  });

  final List<DarbCityOrbOption> cities;
  final String? selectedCityId;
  final ValueChanged<String> onSelect;
  final bool onDarkStage;

  @override
  Widget build(BuildContext context) {
    final isDark = DarbColors.isDark(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < cities.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Builder(
              builder: (ctx) {
                final c = cities[i];
                final active = c.id == selectedCityId;
                final bg = active
                    ? (onDarkStage || isDark
                        ? DarbColors.lime
                        : DarbColors.forest)
                    : (onDarkStage
                        ? Colors.white.withValues(alpha: 0.10)
                        : DarbColors.surfaceOf(ctx));
                final fg = active
                    ? (onDarkStage || isDark
                        ? DarbColors.darkCanvas
                        : Colors.white)
                    : (onDarkStage ? Colors.white : DarbColors.inkOf(ctx));
                final borderColor = active
                    ? Colors.transparent
                    : (onDarkStage
                        ? Colors.white.withValues(alpha: 0.18)
                        : DarbColors.borderOf(ctx));

                return DarbPressScale(
                  borderRadius: BorderRadius.circular(DarbRadius.pill),
                  onTap: () {
                    if (!active) {
                      DarbHaptics.selection();
                      onSelect(c.id);
                    }
                  },
                  child: AnimatedContainer(
                    duration: DarbMotion.effectiveDuration(
                      ctx,
                      DarbMotion.interactive,
                    ),
                    curve: DarbMotion.enter,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(DarbRadius.pill),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (active) ...[
                          DarbPulseDot(
                            active: true,
                            color: onDarkStage || isDark
                                ? DarbColors.forest
                                : DarbColors.lime,
                            size: 6.5,
                          ),
                          const SizedBox(width: 6),
                        ] else ...[
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: onDarkStage
                                ? DarbColors.mint
                                : DarbColors.mutedOf(ctx),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          c.name,
                          style: TextStyle(
                            color: fg,
                            fontSize: 12.5,
                            fontWeight:
                                active ? FontWeight.w900 : FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class DarbTelemetryCell {
  const DarbTelemetryCell({
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accentColor;
  final String? subtitle;
}

/// High-density unified telemetry instrument cluster replacing disconnected
/// square stat boxes across Driver, Vendor, and Admin dashboards.
class DarbTelemetryDeck extends StatelessWidget {
  const DarbTelemetryDeck({
    super.key,
    required this.cells,
    this.title,
    this.trailing,
  });

  final List<DarbTelemetryCell> cells;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = DarbColors.isDark(context);
    final border = DarbColors.borderOf(context);
    final muted = DarbColors.mutedOf(context);
    final ink = DarbColors.inkOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 680 && cells.length >= 4;
        return DarbGlassSurface(
          borderRadius: DarbRadius.xl,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null || trailing != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
                  child: Row(
                    children: [
                      if (title != null)
                        Expanded(
                          child: Text(
                            title!,
                            style: TextStyle(
                              color: muted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                ),
              ],
              if (isWide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < cells.length; i++) ...[
                        if (i > 0)
                          VerticalDivider(
                            width: 16,
                            thickness: 1,
                            color: border.withValues(alpha: 0.7),
                          ),
                        Expanded(
                          child: _TelemetryItem(
                            cell: cells[i],
                            ink: ink,
                            muted: muted,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < cells.length; i += 2) ...[
                      if (i > 0)
                        Divider(
                          height: 16,
                          thickness: 1,
                          color: border.withValues(alpha: 0.7),
                        ),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _TelemetryItem(
                                cell: cells[i],
                                ink: ink,
                                muted: muted,
                                isDark: isDark,
                              ),
                            ),
                            VerticalDivider(
                              width: 16,
                              thickness: 1,
                              color: border.withValues(alpha: 0.7),
                            ),
                            Expanded(
                              child: i + 1 < cells.length
                                  ? _TelemetryItem(
                                      cell: cells[i + 1],
                                      ink: ink,
                                      muted: muted,
                                      isDark: isDark,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TelemetryItem extends StatelessWidget {
  const _TelemetryItem({
    required this.cell,
    required this.ink,
    required this.muted,
    required this.isDark,
  });

  final DarbTelemetryCell cell;
  final Color ink;
  final Color muted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accent = cell.accentColor ?? DarbColors.primaryOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.11),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(cell.icon, size: 15, color: accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cell.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            cell.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ink,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (cell.subtitle != null && cell.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              cell.subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tactile Courier Dispatch Ticket / Pass replacing generic text boxes for
/// active and historical orders across Customer, Driver, and Vendor views.
class DarbTicketPass extends StatelessWidget {
  const DarbTicketPass({
    super.key,
    required this.title,
    required this.status,
    required this.body,
    this.subtitle,
    this.leadingIcon,
    this.accentColor,
    this.headerActions = const [],
    this.footer,
    this.onTap,
  });

  final String title;
  final String status;
  final String? subtitle;
  final IconData? leadingIcon;
  final Color? accentColor;
  final List<Widget> headerActions;
  final Widget body;
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = DarbColors.isDark(context);
    final accent = accentColor ?? _statusAccent(context, status);
    final ink = DarbColors.inkOf(context);
    final muted = DarbColors.mutedOf(context);
    final dividerColor = DarbColors.borderOf(context);

    return DarbInteractiveCard(
      padding: EdgeInsets.zero,
      borderColor: accent.withValues(alpha: isDark ? 0.30 : 0.20),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(DarbRadius.pill),
                  ),
                ),
                const SizedBox(width: 10),
                if (leadingIcon != null) ...[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(leadingIcon, size: 18, color: accent),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ...headerActions,
                DarbStatusBadge(status: status),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: body,
          ),
          if (footer != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 14,
              child: CustomPaint(
                painter: _TicketPerforationPainter(
                  lineColor: dividerColor,
                  notchColor: DarbColors.canvasOf(context),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: BoxDecoration(
                color: DarbColors.surfaceAltOf(context)
                    .withValues(alpha: isDark ? 0.40 : 0.55),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(DarbRadius.lg),
                ),
              ),
              child: footer!,
            ),
          ] else
            const SizedBox(height: 14),
        ],
      ),
    );
  }

  static Color _statusAccent(BuildContext context, String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
      case 'APPROVED':
      case 'OPEN':
        return DarbColors.successOf(context);
      case 'CANCELLED':
      case 'REJECTED':
      case 'SUSPENDED':
      case 'CLOSED':
        return DarbColors.dangerOf(context);
      case 'PICKED_UP':
      case 'ASSIGNED':
      case 'READY':
        return DarbColors.infoOf(context);
      default:
        return DarbColors.primaryOf(context);
    }
  }
}

class _TicketPerforationPainter extends CustomPainter {
  const _TicketPerforationPainter({
    required this.lineColor,
    required this.notchColor,
  });

  final Color lineColor;
  final Color notchColor;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    const notchRadius = 6.5;

    final dashPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.85)
      ..strokeWidth = 1.1;

    var x = notchRadius + 6;
    const dash = 5.0;
    const gap = 4.0;
    while (x < size.width - notchRadius - 6) {
      final endX = math.min(x + dash, size.width - notchRadius - 6);
      canvas.drawLine(Offset(x, midY), Offset(endX, midY), dashPaint);
      x += dash + gap;
    }

    final notchPaint = Paint()..color = notchColor;
    canvas.drawCircle(Offset(0, midY), notchRadius, notchPaint);
    canvas.drawCircle(Offset(size.width, midY), notchRadius, notchPaint);
  }

  @override
  bool shouldRepaint(covariant _TicketPerforationPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor ||
      oldDelegate.notchColor != notchColor;
}

/// Editorial asymmetric storefront card replacing traditional vertical store rows.
class DarbEditorialStoreCard extends StatelessWidget {
  const DarbEditorialStoreCard({
    super.key,
    required this.name,
    required this.category,
    required this.isOpen,
    required this.productsLabel,
    this.address,
    this.ratingAvg = 0,
    this.reviewsCount = 0,
    this.onTap,
  });

  final String name;
  final String category;
  final bool isOpen;
  final String productsLabel;
  final String? address;
  final double ratingAvg;
  final int reviewsCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = DarbColors.isDark(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final primary = DarbColors.primaryOf(context);
    final ink = DarbColors.inkOf(context);
    final muted = DarbColors.mutedOf(context);

    return DarbInteractiveCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: isOpen
                    ? [
                        DarbColors.forest,
                        isDark ? DarbColors.forestSoft : DarbColors.primaryGreen,
                      ]
                    : [
                        DarbColors.surfaceAltOf(context),
                        DarbColors.borderOf(context),
                      ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DarbRadius.lg),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isOpen
                        ? DarbColors.lime.withValues(alpha: 0.18)
                        : DarbColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: isOpen
                          ? DarbColors.lime.withValues(alpha: 0.42)
                          : DarbColors.borderOf(context),
                    ),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    size: 19,
                    color: isOpen ? DarbColors.lime : muted,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? Colors.white.withValues(alpha: 0.14)
                        : DarbColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(DarbRadius.pill),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isOpen ? Colors.white : ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                DarbStatusBadge(status: isOpen ? 'OPEN' : 'CLOSED'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isOpen) ...[
                      const DarbPulseDot(active: true, size: 7),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                if (address != null && address!.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 14, color: muted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: isDark ? 0.18 : 0.10),
                        borderRadius: BorderRadius.circular(DarbRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 13.5,
                            color: primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            productsLabel,
                            style: TextStyle(
                              color: primary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (ratingAvg > 0 || reviewsCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: DarbColors.warningOf(context)
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(DarbRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: DarbColors.warningOf(context),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${ratingAvg.toStringAsFixed(1)} ($reviewsCount)',
                              style: TextStyle(
                                color: ink,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: DarbColors.surfaceAltOf(context),
                        shape: BoxShape.circle,
                        border: Border.all(color: DarbColors.borderOf(context)),
                      ),
                      child: Icon(
                        isRtl
                            ? Icons.arrow_back_rounded
                            : Icons.arrow_forward_rounded,
                        size: 16,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern split product row/card for Customer Catalog & Merchant Inventory.
class DarbTelemetryProductCard extends StatelessWidget {
  const DarbTelemetryProductCard({
    super.key,
    required this.name,
    required this.priceLabel,
    required this.actionDock,
    this.description,
    this.category,
    this.stockLabel,
    this.stockRatio,
    this.outOfStock = false,
    this.highlighted = false,
    this.leadingIcon = Icons.shopping_bag_outlined,
    this.onTap,
  });

  final String name;
  final String priceLabel;
  final String? description;
  final String? category;
  final String? stockLabel;
  final double? stockRatio;
  final bool outOfStock;
  final bool highlighted;
  final IconData leadingIcon;
  final Widget actionDock;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = DarbColors.isDark(context);
    final primary = DarbColors.primaryOf(context);
    final ink = DarbColors.inkOf(context);
    final muted = DarbColors.mutedOf(context);

    return DarbInteractiveCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      borderColor:
          highlighted ? primary.withValues(alpha: 0.55) : null,
      tintColor: highlighted
          ? (isDark
              ? DarbColors.forestSoft.withValues(alpha: 0.45)
              : DarbColors.mintTint.withValues(alpha: 0.42))
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: highlighted
                    ? [
                        primary.withValues(alpha: 0.24),
                        DarbColors.mint.withValues(alpha: isDark ? 0.14 : 0.34),
                      ]
                    : [
                        DarbColors.surfaceAltOf(context),
                        DarbColors.surfaceOf(context),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: highlighted
                    ? primary.withValues(alpha: 0.36)
                    : DarbColors.borderOf(context),
              ),
            ),
            child: Icon(
              leadingIcon,
              color: outOfStock ? muted : primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (category != null && category!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: DarbColors.surfaceAltOf(context),
                          borderRadius: BorderRadius.circular(DarbRadius.pill),
                        ),
                        child: Text(
                          category!,
                          style: TextStyle(
                            color: muted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (description != null && description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      priceLabel,
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (stockLabel != null)
                      Text(
                        stockLabel!,
                        style: TextStyle(
                          color: outOfStock
                              ? DarbColors.dangerOf(context)
                              : muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                if (stockRatio != null) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(DarbRadius.pill),
                    child: LinearProgressIndicator(
                      value: stockRatio!.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: DarbColors.surfaceAltOf(context),
                      color: outOfStock
                          ? DarbColors.dangerOf(context)
                          : (stockRatio! < 0.25
                              ? DarbColors.warningOf(context)
                              : primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          actionDock,
        ],
      ),
    );
  }
}
