import 'package:flutter/material.dart';

import '../theme/darb_design_system.dart';
import 'darb_motion_components.dart';

class DarbAdaptiveLayout {
  DarbAdaptiveLayout._();

  static const double tabletBreakpoint = 720;
  static const double desktopBreakpoint = 1080;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  static int columns(
    BuildContext context, {
    int phone = 1,
    int tablet = 2,
    int desktop = 2,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= desktopBreakpoint) return desktop;
    if (w >= tabletBreakpoint) return tablet;
    return phone;
  }

  static int metricColumns(BuildContext context, {double? availableWidth}) {
    final w = availableWidth ?? MediaQuery.sizeOf(context).width;
    return w >= 680 ? 4 : 2;
  }

  static int contentColumns(BuildContext context, {double? availableWidth}) {
    final w = availableWidth ?? MediaQuery.sizeOf(context).width;
    return w >= 620 ? 2 : 1;
  }
}

class DarbAmbientBackground extends StatelessWidget {
  const DarbAmbientBackground({
    super.key,
    required this.child,
    this.showOrbs = true,
  });

  final Widget child;
  final bool showOrbs;

  @override
  Widget build(BuildContext context) {
    final isDark = DarbColors.isDark(context);
    final isGlass = DarbAppearanceController.instance.isGlass;
    final baseColor = DarbColors.canvasOf(context);

    if (!isGlass || !showOrbs) {
      return ColoredBox(color: baseColor, child: child);
    }

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? const [
                        DarbColors.darkCanvas,
                        Color(0xFF111318),
                        DarbColors.darkCanvas,
                      ]
                    : const [
                        DarbColors.canvas,
                        Color(0xFFF4F0E8),
                        DarbColors.canvas,
                      ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -90,
          right: -60,
          child: IgnorePointer(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DarbColors.lime.withValues(alpha: isDark ? 0.12 : 0.22),
                    DarbColors.lime.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 240,
          left: -100,
          child: IgnorePointer(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DarbColors.violet.withValues(alpha: isDark ? 0.15 : 0.08),
                    DarbColors.violet.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class DarbGlassSurface extends StatelessWidget {
  const DarbGlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = DarbRadius.lg,
    this.blurSigma = 20,
    this.tintColor,
    this.borderColor,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final Color? tintColor;
  final Color? borderColor;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final isDark = DarbColors.isDark(context);
    final isGlass = DarbAppearanceController.instance.isGlass;
    final radius = BorderRadius.circular(borderRadius);

    final effectiveBorder = borderColor ??
        (isGlass
            ? (isDark
                ? DarbColors.mint.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.92))
            : DarbColors.borderOf(context));

    final shadow = elevated
        ? (isGlass
            ? DarbElevation.floating(isDark)
            : DarbElevation.card(isDark))
        : DarbElevation.none;

    if (!isGlass) {
      return Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: tintColor ?? DarbColors.surfaceOf(context),
          borderRadius: radius,
          border: Border.all(color: effectiveBorder),
          boxShadow: shadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: child,
        ),
      );
    }

    final fill = tintColor ??
        (isDark
            ? DarbColors.darkSurface.withValues(alpha: 0.80)
            : Colors.white.withValues(alpha: 0.84));

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: darbBlurFilter(blurSigma),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: fill,
              gradient: tintColor != null
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              DarbColors.darkSurfaceElevated
                                  .withValues(alpha: 0.88),
                              DarbColors.darkSurface.withValues(alpha: 0.72),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.94),
                              Colors.white.withValues(alpha: 0.74),
                            ],
                    ),
              border: Border.all(color: effectiveBorder, width: 1.05),
            ),
            foregroundDecoration: tintColor == null && borderRadius >= DarbRadius.md
                ? BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.white.withValues(alpha: isDark ? 0.06 : 0.34),
                        Colors.transparent,
                      ],
                    ),
                  )
                : null,
            padding: padding,
            child: Material(
              color: Colors.transparent,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class DarbGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DarbGlassAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);

  @override
  Widget build(BuildContext context) {
    final isDark = DarbColors.isDark(context);
    final isGlass = DarbAppearanceController.instance.isGlass;
    final ink = DarbColors.inkOf(context);
    final muted = DarbColors.mutedOf(context);

    final content = SafeArea(
      bottom: false,
      child: Container(
        height: kToolbarHeight + 6,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            if (leading != null)
              leading!
            else if (Navigator.canPop(context))
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: DarbColors.softSurfaceOf(context)
                          .withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: DarbColors.borderOf(context)),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 17,
                      color: ink,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 6),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: DarbMotion.effectiveDuration(
                      context,
                      DarbMotion.fast,
                    ),
                    switchInCurve: DarbMotion.enter,
                    switchOutCurve: DarbMotion.exit,
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      alignment: AlignmentDirectional.centerStart,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    ),
                    child: Text(
                      title,
                      key: ValueKey(title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
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
              ),
            ),
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );

    if (!isGlass) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: DarbColors.surfaceOf(context),
          border: Border(
            bottom: BorderSide(color: DarbColors.borderOf(context)),
          ),
        ),
        child: content,
      );
    }

    return ClipRect(
      child: BackdropFilter(
        filter: darbBlurFilter(22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      DarbColors.darkSurfaceElevated.withValues(alpha: 0.88),
                      DarbColors.darkSurface.withValues(alpha: 0.80),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.90),
                      Colors.white.withValues(alpha: 0.78),
                    ],
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? DarbColors.mint.withValues(alpha: 0.16)
                    : DarbColors.line.withValues(alpha: 0.88),
              ),
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}

class DarbNavDestination {
  const DarbNavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int badgeCount;
}

class DarbGlassBottomNav extends StatelessWidget {
  const DarbGlassBottomNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<DarbNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final isGlass = DarbAppearanceController.instance.isGlass;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    final itemsRow = Row(
      children: List.generate(destinations.length, (i) {
        final item = destinations[i];
        final active = i == selectedIndex;
        return Expanded(
          child: _DarbNavTile(
            destination: item,
            active: active,
            onTap: () {
              if (!active) {
                DarbHaptics.selection();
              } else {
                DarbHaptics.light();
              }
              onSelect(i);
            },
          ),
        );
      }),
    );

    if (!isGlass) {
      return AnimatedContainer(
        duration: DarbMotion.effectiveDuration(context, DarbMotion.interactive),
        curve: DarbMotion.enter,
        padding: EdgeInsets.fromLTRB(8, 6, 8, bottomPadding + 6),
        decoration: BoxDecoration(
          color: DarbColors.surfaceOf(context),
          border: Border(top: BorderSide(color: DarbColors.borderOf(context))),
        ),
        child: itemsRow,
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        bottomPadding > 0 ? bottomPadding + 4 : 12,
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: DarbGlassSurface(
            borderRadius: DarbRadius.hero,
            blurSigma: 28,
            borderColor: DarbColors.isDark(context)
                ? DarbColors.lime.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.95),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: itemsRow,
          ),
        ),
      ),
    );
  }
}

/// iPadOS 18-inspired Floating Translucent Sidebar Navigation for tablets (>= 720dp).
class DarbGlassSideRail extends StatelessWidget {
  const DarbGlassSideRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    this.roleLabel,
  });

  final List<DarbNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String? roleLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = DarbColors.isDark(context);
    final primary = DarbColors.primaryOf(context);
    final muted = DarbColors.mutedOf(context);
    final ink = DarbColors.inkOf(context);
    final activeTint = isDark
        ? DarbColors.forestSoft.withValues(alpha: 0.96)
        : DarbColors.limeTint.withValues(alpha: 0.82);
    final activeForeground = isDark ? DarbColors.lime : DarbColors.forest;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 8, 16),
      child: SizedBox(
        width: 222,
        child: DarbGlassSurface(
          borderRadius: DarbRadius.xl,
          blurSigma: 26,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (roleLabel != null && roleLabel!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? DarbColors.lime : primary)
                        .withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(DarbRadius.md),
                    border: Border.all(
                      color: (isDark ? DarbColors.lime : primary)
                          .withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    children: [
                      DarbPulseDot(
                        active: true,
                        color: isDark ? DarbColors.lime : primary,
                        size: 7,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          roleLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? DarbColors.lime : primary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              for (var i = 0; i < destinations.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                Builder(
                  builder: (ctx) {
                    final item = destinations[i];
                    final active = i == selectedIndex;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(DarbRadius.md),
                        onTap: () {
                          if (!active) {
                            DarbHaptics.selection();
                          } else {
                            DarbHaptics.light();
                          }
                          onSelect(i);
                        },
                        child: AnimatedContainer(
                          duration: DarbMotion.effectiveDuration(
                            context,
                            DarbMotion.tab,
                          ),
                          curve: DarbMotion.enter,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(DarbRadius.md),
                            color: active ? activeTint : Colors.transparent,
                            border: active
                                ? Border.all(
                                    color: (isDark ? DarbColors.lime : primary)
                                        .withValues(alpha: 0.30),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: DarbMotion.effectiveDuration(
                                  context,
                                  DarbMotion.fast,
                                ),
                                width: 3.5,
                                height: active ? 20 : 0,
                                margin: const EdgeInsetsDirectional.only(
                                  end: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? activeForeground
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    DarbRadius.pill,
                                  ),
                                ),
                              ),
                              Icon(
                                active ? item.selectedIcon : item.icon,
                                size: 20,
                                color: active ? activeForeground : muted,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: active ? activeForeground : ink,
                                    fontSize: 13.5,
                                    fontWeight: active
                                        ? FontWeight.w900
                                        : FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (item.badgeCount > 0)
                                DarbAnimatedBadge(count: item.badgeCount),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'DAZREVO',
                      style: TextStyle(
                        color: muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DarbContextMenuAction<T> {
  const DarbContextMenuAction({
    required this.value,
    required this.label,
    required this.icon,
    this.isDanger = false,
  });

  final T value;
  final String label;
  final IconData icon;
  final bool isDanger;
}

class DarbContextMenuButton<T> extends StatelessWidget {
  const DarbContextMenuButton({
    super.key,
    required this.items,
    required this.onSelected,
    this.tooltip,
    this.icon = Icons.more_horiz_rounded,
    this.iconColor,
    this.backgroundColor,
  });

  final List<DarbContextMenuAction<T>> items;
  final ValueChanged<T> onSelected;
  final String? tooltip;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final ink = DarbColors.inkOf(context);
    final danger = DarbColors.dangerOf(context);
    final primary = DarbColors.primaryOf(context);

    return PopupMenuButton<T>(
      tooltip: tooltip ?? '',
      color: DarbColors.surfaceElevatedOf(context),
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DarbRadius.lg),
        side: BorderSide(color: DarbColors.borderOf(context)),
      ),
      onOpened: DarbHaptics.light,
      onSelected: (v) {
        DarbHaptics.selection();
        onSelected(v);
      },
      itemBuilder: (ctx) => [
        for (final item in items)
          PopupMenuItem<T>(
            value: item.value,
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: item.isDanger ? danger : primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: item.isDanger ? danger : ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: backgroundColor ??
              DarbColors.softSurfaceOf(context).withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DarbColors.borderOf(context)),
        ),
        child: Icon(icon, size: 19, color: iconColor ?? ink),
      ),
    );
  }
}

class _DarbNavTile extends StatefulWidget {
  const _DarbNavTile({
    required this.destination,
    required this.active,
    required this.onTap,
  });

  final DarbNavDestination destination;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_DarbNavTile> createState() => _DarbNavTileState();
}

class _DarbNavTileState extends State<_DarbNavTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = DarbColors.isDark(context);
    final reduced = DarbMotion.reduceMotion(context);
    final primary = DarbColors.primaryOf(context);
    final muted = DarbColors.mutedOf(context);
    final active = widget.active;
    final item = widget.destination;
    final indicatorColor = isDark ? DarbColors.lime : DarbColors.forest;
    final activeIconAndText = isDark ? DarbColors.lime : DarbColors.forest;

    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: (!reduced && _pressed) ? 0.94 : 1.0,
          duration: DarbMotion.effectiveDuration(
            context,
            _pressed ? DarbMotion.press : DarbMotion.interactive,
          ),
          curve: (!reduced && !_pressed)
              ? DarbMotion.emphasis
              : DarbMotion.enter,
          child: AnimatedContainer(
            duration: DarbMotion.effectiveDuration(context, DarbMotion.tab),
            curve: DarbMotion.enter,
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DarbRadius.md),
              color: active
                  ? (isDark
                      ? DarbColors.forestSoft.withValues(alpha: 0.92)
                      : DarbColors.limeTint.withValues(alpha: 0.72))
                  : Colors.transparent,
              border: active
                  ? Border.all(
                      color: (isDark ? DarbColors.lime : primary)
                          .withValues(alpha: 0.25),
                    )
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedScale(
                      scale: (!reduced && active) ? 1.10 : 1.0,
                      duration: DarbMotion.effectiveDuration(
                        context,
                        DarbMotion.interactive,
                      ),
                      curve: (!reduced && active)
                          ? DarbMotion.emphasis
                          : DarbMotion.enter,
                      child: AnimatedSwitcher(
                        duration: DarbMotion.effectiveDuration(
                          context,
                          DarbMotion.fast,
                        ),
                        child: Icon(
                          active ? item.selectedIcon : item.icon,
                          key: ValueKey('${item.label}_$active'),
                          size: 22,
                          color: active ? activeIconAndText : muted,
                        ),
                      ),
                    ),
                    if (item.badgeCount > 0)
                      PositionedDirectional(
                        top: -4,
                        end: -8,
                        child: DarbAnimatedBadge(count: item.badgeCount),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: DarbMotion.effectiveDuration(
                    context,
                    DarbMotion.fast,
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                    color: active ? activeIconAndText : muted,
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: DarbMotion.effectiveDuration(
                    context,
                    DarbMotion.interactive,
                  ),
                  curve: DarbMotion.enter,
                  width: active ? 22 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: active ? indicatorColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(DarbRadius.pill),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: indicatorColor.withValues(
                                alpha: isDark ? 0.55 : 0.28,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
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

Future<T?> showDarbGlassModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    barrierColor: DarbColors.scrimOf(context),
    backgroundColor: Colors.transparent,
    builder: (ctx) => Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: DarbGlassSurface(
            borderRadius: DarbRadius.xl,
            blurSigma: 26,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: DarbColors.mutedOf(ctx).withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(DarbRadius.pill),
                        ),
                      ),
                    ),
                    builder(ctx),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Renders [children] as a single vertical stack on narrow viewports and
/// equal-height paired rows on wide/tablet viewports without fixed aspect clipping.
class DarbResponsiveTwoColumn extends StatelessWidget {
  const DarbResponsiveTwoColumn({
    super.key,
    required this.children,
    this.spacing = 12,
    this.breakpoint = 620,
  });

  final List<Widget> children;
  final double spacing;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint || children.length <= 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                children[i],
              ],
            ],
          );
        }
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += 2) {
          final hasSecond = i + 1 < children.length;
          rows.add(
            Padding(
              padding: EdgeInsets.only(
                bottom: i + 2 < children.length ? spacing : 0,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: children[i]),
                    SizedBox(width: spacing),
                    Expanded(
                      child: hasSecond
                          ? children[i + 1]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}
