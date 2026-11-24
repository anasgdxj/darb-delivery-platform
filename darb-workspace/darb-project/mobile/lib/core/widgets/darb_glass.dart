import 'package:flutter/material.dart';

import '../theme/darb_design_system.dart';
import 'darb_motion_components.dart';

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
                        Color(0xFF0E1D18),
                        DarbColors.darkCanvas,
                      ]
                    : const [
                        DarbColors.canvas,
                        Color(0xFFEDF2EC),
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
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DarbColors.mint.withValues(alpha: isDark ? 0.14 : 0.40),
                    DarbColors.mint.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 230,
          left: -100,
          child: IgnorePointer(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DarbColors.forestSoft
                        .withValues(alpha: isDark ? 0.22 : 0.10),
                    DarbColors.forestSoft.withValues(alpha: 0),
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
    this.blurSigma = 18,
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
                ? DarbColors.mint.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.85))
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
        child: child,
      );
    }

    final fill = tintColor ??
        (isDark
            ? DarbColors.darkSurface.withValues(alpha: 0.76)
            : Colors.white.withValues(alpha: 0.76));

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
            padding: padding,
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
                                  .withValues(alpha: 0.82),
                              DarbColors.darkSurface.withValues(alpha: 0.68),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.86),
                              Colors.white.withValues(alpha: 0.66),
                            ],
                    ),
              border: Border.all(color: effectiveBorder, width: 1.05),
            ),
            child: child,
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    final isDark = DarbColors.isDark(context);
    final isGlass = DarbAppearanceController.instance.isGlass;
    final ink = DarbColors.inkOf(context);
    final muted = DarbColors.mutedOf(context);

    final content = SafeArea(
      bottom: false,
      child: Container(
        height: kToolbarHeight + 4,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            if (leading != null)
              leading!
            else if (Navigator.canPop(context))
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: DarbColors.softSurfaceOf(context)
                          .withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(12),
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
        filter: darbBlurFilter(20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: (isDark ? DarbColors.darkSurface : Colors.white)
                .withValues(alpha: 0.80),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? DarbColors.mint.withValues(alpha: 0.14)
                    : DarbColors.line.withValues(alpha: 0.85),
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
        14,
        0,
        14,
        bottomPadding > 0 ? bottomPadding + 2 : 12,
      ),
      child: DarbGlassSurface(
        borderRadius: DarbRadius.xl,
        blurSigma: 26,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: itemsRow,
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
    final indicatorColor = isDark ? DarbColors.mint : primary;

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
                      ? DarbColors.forestSoft.withValues(alpha: 0.90)
                      : DarbColors.mintTint)
                  : Colors.transparent,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedScale(
                      scale: (!reduced && active) ? 1.12 : 1.0,
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
                          color: active ? primary : muted,
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
                    color: active ? primary : muted,
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
                                alpha: isDark ? 0.55 : 0.35,
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
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: DarbGlassSurface(
        borderRadius: DarbRadius.xl,
        blurSigma: 24,
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
  );
}
