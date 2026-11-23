import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/darb_design_system.dart';

/// Unified tactile haptics helper mapped to interaction severity.
/// Fails silently on platforms/tests where haptics are unsupported.
class DarbHaptics {
  DarbHaptics._();

  static Future<void> selection() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  static Future<void> light() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static Future<void> success() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> error() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static Future<void> warning() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }
}

enum DarbActionState { idle, loading, success, error }

enum DarbActionVariant { primary, outlined, danger }

/// Lightweight horizontal damped shake wrapper triggered only when [trigger]
/// increments. Runs zero idle animations and honors Reduce Motion.
class DarbShakeBox extends StatefulWidget {
  const DarbShakeBox({
    super.key,
    required this.child,
    this.trigger = 0,
    this.amplitude = 7.5,
  });

  final Widget child;
  final int trigger;
  final double amplitude;

  @override
  State<DarbShakeBox> createState() => _DarbShakeBoxState();
}

class _DarbShakeBoxState extends State<DarbShakeBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(covariant DarbShakeBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger > oldWidget.trigger &&
        !DarbMotion.reduceMotion(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (DarbMotion.reduceMotion(context)) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final dx = (t == 0 || t == 1)
            ? 0.0
            : math.sin(t * math.pi * 3.5) * (1.0 - t) * widget.amplitude;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Shared interactive action button for Phase 1+ DARB Motion Experience 2026:
/// - Smooth press shrink & spring release
/// - Animated transition between idle -> loading -> green success check
/// - Damped horizontal shake + haptic feedback on error without locking retries
/// - Full Reduce Motion & semantics support
class DarbActionButton extends StatefulWidget {
  const DarbActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.state = DarbActionState.idle,
    this.variant = DarbActionVariant.primary,
    this.errorTrigger = 0,
    this.icon,
    this.leading,
    this.loadingLabel,
    this.successLabel,
    this.minHeight = 50,
    this.borderRadius = DarbRadius.md,
    this.enableHaptics = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final DarbActionState state;
  final DarbActionVariant variant;
  final int errorTrigger;
  final IconData? icon;
  final Widget? leading;
  final String? loadingLabel;
  final String? successLabel;
  final double minHeight;
  final double borderRadius;
  final bool enableHaptics;

  @override
  State<DarbActionButton> createState() => _DarbActionButtonState();
}

class _DarbActionButtonState extends State<DarbActionButton> {
  bool _pressed = false;

  @override
  void didUpdateWidget(covariant DarbActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enableHaptics) return;
    if (widget.state == DarbActionState.success &&
        oldWidget.state != DarbActionState.success) {
      DarbHaptics.success();
    } else if (widget.errorTrigger > oldWidget.errorTrigger ||
        (widget.state == DarbActionState.error &&
            oldWidget.state != DarbActionState.error)) {
      DarbHaptics.error();
    }
  }

  void _handleTap() {
    if (widget.onPressed == null ||
        widget.state == DarbActionState.loading ||
        widget.state == DarbActionState.success) {
      return;
    }
    if (widget.enableHaptics) {
      DarbHaptics.light();
    }
    widget.onPressed!.call();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = DarbMotion.reduceMotion(context);
    final isDark = DarbColors.isDark(context);
    final primary = DarbColors.primaryOf(context);
    final onPrimary = DarbColors.onPrimaryOf(context);
    final ink = DarbColors.inkOf(context);
    final success = DarbColors.successOf(context);
    final danger = DarbColors.dangerOf(context);

    final isLoading = widget.state == DarbActionState.loading;
    final isSuccess = widget.state == DarbActionState.success;
    final isError = widget.state == DarbActionState.error;
    final isInteractive =
        widget.onPressed != null && !isLoading && !isSuccess;

    final Color backgroundColor;
    final Color foregroundColor;
    final BorderSide? borderSide;

    if (isSuccess) {
      backgroundColor = success;
      foregroundColor = isDark ? DarbColors.forest : Colors.white;
      borderSide = BorderSide(color: success);
    } else {
      switch (widget.variant) {
        case DarbActionVariant.primary:
          backgroundColor = isInteractive || isLoading
              ? primary
              : primary.withValues(alpha: 0.42);
          foregroundColor = isInteractive || isLoading
              ? onPrimary
              : onPrimary.withValues(alpha: 0.72);
          borderSide = isError
              ? BorderSide(color: danger.withValues(alpha: 0.85), width: 1.4)
              : null;
        case DarbActionVariant.danger:
          backgroundColor = isInteractive || isLoading
              ? danger
              : danger.withValues(alpha: 0.42);
          foregroundColor = Colors.white;
          borderSide = null;
        case DarbActionVariant.outlined:
          backgroundColor = isDark
              ? DarbColors.darkSurfaceElevated.withValues(alpha: 0.72)
              : Colors.white.withValues(alpha: 0.90);
          foregroundColor = isInteractive || isLoading
              ? ink
              : ink.withValues(alpha: 0.45);
          borderSide = BorderSide(
            color: isError
                ? danger.withValues(alpha: 0.85)
                : DarbColors.borderStrongOf(context),
            width: isError ? 1.4 : 1.0,
          );
      }
    }

    final Widget contentChild;
    if (isLoading) {
      contentChild = Row(
        key: const ValueKey('loading'),
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 19,
            height: 19,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          if (widget.loadingLabel != null &&
              widget.loadingLabel!.isNotEmpty) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.loadingLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      );
    } else if (isSuccess) {
      contentChild = Row(
        key: const ValueKey('success'),
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: foregroundColor,
          ),
          if (widget.successLabel != null &&
              widget.successLabel!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.successLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      );
    } else {
      final Widget? prefix = widget.leading ??
          (widget.icon != null
              ? Icon(widget.icon, size: 20, color: foregroundColor)
              : null);
      contentChild = Row(
        key: ValueKey('idle_${widget.label}'),
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (prefix != null) ...[
            IconTheme(
              data: IconThemeData(color: foregroundColor, size: 20),
              child: prefix,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontSize: widget.variant == DarbActionVariant.outlined
                    ? 14
                    : 15,
                fontWeight: widget.variant == DarbActionVariant.outlined
                    ? FontWeight.w700
                    : FontWeight.w800,
              ),
            ),
          ),
        ],
      );
    }

    final radius = BorderRadius.circular(widget.borderRadius);
    final duration = DarbMotion.effectiveDuration(
      context,
      DarbMotion.interactive,
    );

    final buttonSurface = AnimatedScale(
      scale: (!reduced && _pressed && isInteractive) ? 0.972 : 1.0,
      duration: DarbMotion.effectiveDuration(
        context,
        _pressed ? DarbMotion.press : DarbMotion.interactive,
      ),
      curve: (!reduced && !_pressed)
          ? DarbMotion.emphasis
          : DarbMotion.enter,
      child: AnimatedContainer(
        duration: duration,
        curve: DarbMotion.enter,
        constraints: BoxConstraints(minHeight: widget.minHeight),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: radius,
          border: borderSide != null ? Border.fromBorderSide(borderSide) : null,
          boxShadow: isSuccess
              ? [
                  BoxShadow(
                    color: success.withValues(alpha: isDark ? 0.28 : 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            splashColor: foregroundColor.withValues(alpha: 0.14),
            highlightColor: foregroundColor.withValues(alpha: 0.06),
            onTapDown: isInteractive
                ? (_) => setState(() => _pressed = true)
                : null,
            onTapUp: isInteractive
                ? (_) => setState(() => _pressed = false)
                : null,
            onTapCancel: isInteractive
                ? () => setState(() => _pressed = false)
                : null,
            onTap: isInteractive ? _handleTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DarbSpace.lg,
                vertical: DarbSpace.sm,
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: DarbMotion.effectiveDuration(
                    context,
                    DarbMotion.fast,
                  ),
                  switchInCurve: DarbMotion.enter,
                  switchOutCurve: DarbMotion.exit,
                  transitionBuilder: (child, anim) {
                    if (reduced) return child;
                    return FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.92, end: 1.0).animate(anim),
                        child: child,
                      ),
                    );
                  },
                  child: contentChild,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: isInteractive,
      label: widget.label,
      child: DarbShakeBox(
        trigger: widget.errorTrigger,
        child: buttonSurface,
      ),
    );
  }
}

/// Animated numeric badge for notification counts and nav badges.
class DarbAnimatedBadge extends StatelessWidget {
  const DarbAnimatedBadge({
    super.key,
    required this.count,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
  });

  final int count;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final reduced = DarbMotion.reduceMotion(context);
    return AnimatedSwitcher(
      duration: DarbMotion.effectiveDuration(context, DarbMotion.fast),
      switchInCurve: reduced ? Curves.linear : DarbMotion.emphasis,
      switchOutCurve: DarbMotion.exit,
      transitionBuilder: (child, anim) {
        if (reduced) return child;
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: anim, child: child),
        );
      },
      child: count <= 0
          ? const SizedBox.shrink(key: ValueKey('empty'))
          : Container(
              key: ValueKey('badge_$count'),
              padding: padding,
              decoration: BoxDecoration(
                color: DarbColors.dangerOf(context),
                borderRadius: BorderRadius.circular(DarbRadius.pill),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
    );
  }
}

/// Stateful tab container replacing hard-cut IndexedStack:
/// preserves scroll & form state of every tab while cross-fading and gently
/// sliding incoming views. Pauses offscreen tickers and blocks offscreen hits.
class DarbTabViewStack extends StatefulWidget {
  const DarbTabViewStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<DarbTabViewStack> createState() => _DarbTabViewStackState();
}

class _DarbTabViewStackState extends State<DarbTabViewStack> {
  int _previousIndex = 0;

  @override
  void didUpdateWidget(covariant DarbTabViewStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _previousIndex = oldWidget.index;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduced = DarbMotion.reduceMotion(context);
    final duration = DarbMotion.effectiveDuration(context, DarbMotion.tab);
    final movingForward = widget.index >= _previousIndex;

    // Stack paints later children above earlier ones. Always paint the
    // selected tab last so it remains the foreground page regardless of
    // whether the user moves to a lower or higher tab index. The previous
    // page stays underneath during its exit fade, while inactive tabs remain inert.
    final paintOrder = List<int>.generate(widget.children.length, (i) => i)
      ..remove(widget.index)
      ..add(widget.index);

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: paintOrder.map((i) {
          final active = i == widget.index;
          final inactiveOffset =
              movingForward ? const Offset(-0.025, 0) : const Offset(0.025, 0);

          return Positioned.fill(
            child: IgnorePointer(
              ignoring: !active,
              child: ExcludeSemantics(
                excluding: !active,
                child: TickerMode(
                  enabled: active,
                  child: reduced
                      ? Visibility(
                          visible: active,
                          maintainState: true,
                          child: widget.children[i],
                        )
                      : AnimatedOpacity(
                          opacity: active ? 1.0 : 0.0,
                          duration: duration,
                          curve: active ? DarbMotion.enter : DarbMotion.exit,
                          child: AnimatedSlide(
                            offset: active ? Offset.zero : inactiveOffset,
                            duration: duration,
                            curve: DarbMotion.enter,
                            child: widget.children[i],
                          ),
                        ),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}
