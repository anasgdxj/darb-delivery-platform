import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Shared visual language for DAZREVO — Nocturne Atelier 2026.
/// Preserves legacy token getter names (`DarbColors`, `DarbSpace`, etc.) so all
/// modules and automated checks remain 100% compatible while delivering the
/// refined Obsidian & Champagne Gold luxury aesthetic in Light & Dark modes.
abstract final class DarbColors {
  static bool get _dark => DarbTheme.brightness.value == Brightness.dark;

  // Nocturne Atelier Core Palette
  static Color get obsidian => const Color(0xFF090B0E);
  static Color get charcoal => const Color(0xFF11151B);
  static Color get charcoalSoft => const Color(0xFF181E27);
  static Color get champagne => const Color(0xFFDFBE7D);
  static Color get gold => const Color(0xFFC6A15B);
  static Color get goldMuted => const Color(0xFFEAD9B4);
  static Color get ivory => const Color(0xFFF5F2EB);

  // Backwards-compatible brand anchors mapped to Nocturne Atelier
  static Color get forest => charcoal;
  static Color get forestSoft => charcoalSoft;
  static Color get mint => goldMuted;
  static Color get lime => champagne;
  static Color get onForest => ivory;
  static Color get accent => _dark ? champagne : gold;
  static Color get onAccent => obsidian;

  // Adaptive semantic surfaces & foregrounds
  static Color get canvas =>
      _dark ? const Color(0xFF090B0E) : const Color(0xFFF7F6F2);
  static Color get surface =>
      _dark ? const Color(0xFF11151B) : const Color(0xFFFFFFFF);
  static Color get surfaceAlt =>
      _dark ? const Color(0xFF181E27) : const Color(0xFFEFECE4);
  static Color get brandForeground => _dark ? champagne : charcoal;
  static Color get ink =>
      _dark ? const Color(0xFFF5F2EB) : const Color(0xFF11151B);
  static Color get muted =>
      _dark ? const Color(0xFF969DA8) : const Color(0xFF646B76);
  static Color get line =>
      _dark ? const Color(0xFF222934) : const Color(0xFFE4DFD4);
  static Color get borderStrong =>
      _dark ? const Color(0xFF343F4F) : const Color(0xFFCCC4B4);

  // Semantic status indicators
  static Color get danger =>
      _dark ? const Color(0xFFEB7A82) : const Color(0xFFB93D45);
  static Color get success =>
      _dark ? const Color(0xFF4CD49E) : const Color(0xFF1E8E64);
  static Color get warning =>
      _dark ? const Color(0xFFE6B86A) : const Color(0xFFB87A1E);
  static Color get info =>
      _dark ? const Color(0xFF7DB4EE) : const Color(0xFF2B6CB0);
  static Color get scrim =>
      _dark ? const Color(0xCC040507) : const Color(0x99090B0E);
}

abstract final class DarbSpace {
  static const double xxs = 4, xs = 8, sm = 12, md = 16, lg = 20;
  static const double xl = 24, xxl = 32, section = 40;
}

abstract final class DarbRadius {
  static const double sm = 10, md = 14, lg = 20, xl = 26;
  static const double hero = 32, pill = 999;
}

abstract final class DarbMotion {
  static const Duration press = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 260);
  static const Duration route = Duration(milliseconds: 340);
  static const Duration expressive = Duration(milliseconds: 420);
  static const Duration staggerStep = Duration(milliseconds: 50);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve pressCurve = Curves.easeOutCubic;
  static const Curve expressiveCurve = Curves.easeOutBack;

  /// Honors Android/iOS accessibility settings for reduced motion.
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  static Duration effectiveDuration(
    BuildContext context,
    Duration duration,
  ) =>
      reduceMotion(context) ? Duration.zero : duration;

  static Duration staggerDelay(int index) {
    if (index <= 0) return Duration.zero;
    return Duration(milliseconds: staggerStep.inMilliseconds * index);
  }
}

/// Shared route transition across light and dark themes.
class DarbPageTransitionsBuilder extends PageTransitionsBuilder {
  const DarbPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (DarbMotion.reduceMotion(context)) return child;

    final progress = CurvedAnimation(
      parent: animation,
      curve: DarbMotion.enter,
      reverseCurve: DarbMotion.exit,
    );
    return FadeTransition(
      opacity: progress,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .03),
          end: Offset.zero,
        ).animate(progress),
        child: ScaleTransition(
          scale: Tween<double>(begin: .988, end: 1).animate(progress),
          child: child,
        ),
      ),
    );
  }
}

/// Reusable staggered entrance motion for sections and cards.
class DarbFadeSlide extends StatefulWidget {
  const DarbFadeSlide({
    super.key,
    required this.child,
    this.duration = DarbMotion.standard,
    this.delay = Duration.zero,
    this.offset = const Offset(0, .07),
    this.curve = DarbMotion.enter,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset offset;
  final Curve curve;

  @override
  State<DarbFadeSlide> createState() => _DarbFadeSlideState();
}

class _DarbFadeSlideState extends State<DarbFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delayTimer;
  bool _hasScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 0,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DarbMotion.reduceMotion(context)) {
      _delayTimer?.cancel();
      _controller.value = 1;
      return;
    }
    if (_hasScheduled) return;
    _hasScheduled = true;
    _controller.value = 0;
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void didUpdateWidget(covariant DarbFadeSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: widget.offset,
          end: Offset.zero,
        ).animate(animation),
        child: widget.child,
      ),
    );
  }
}

/// Tactile press scale feedback honoring reduced motion.
class DarbPressScale extends StatefulWidget {
  const DarbPressScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = .97,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final HitTestBehavior behavior;

  @override
  State<DarbPressScale> createState() => _DarbPressScaleState();
}

class _DarbPressScaleState extends State<DarbPressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = DarbMotion.reduceMotion(context);
    return AnimatedScale(
      scale: _pressed && !reduceMotion ? widget.pressedScale : 1,
      duration: DarbMotion.effectiveDuration(context, DarbMotion.press),
      curve: DarbMotion.pressCurve,
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
        onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
        onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
        onTap: widget.onTap,
        child: widget.child,
      ),
    );
  }
}

abstract final class DarbElevation {
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x0A090B0E), blurRadius: 16, offset: Offset(0, 6)),
  ];
  static const floating = <BoxShadow>[
    BoxShadow(color: Color(0x28090B0E), blurRadius: 28, offset: Offset(0, 12)),
  ];
}

abstract final class DarbTheme {
  static const _storage = FlutterSecureStorage();
  static const _modeKey = 'darb_theme_mode';
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);
  static final ValueNotifier<Brightness> brightness =
      ValueNotifier(Brightness.light);

  static void updateBrightness(Brightness value) {
    if (brightness.value != value) brightness.value = value;
  }

  static Future<void> restoreMode() async {
    try {
      final saved = await _storage.read(key: _modeKey);
      mode.value = switch (saved) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      mode.value = ThemeMode.system;
    }
  }

  static Future<void> setMode(ThemeMode value) async {
    mode.value = value;
    try {
      final saved = switch (value) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      await _storage.write(key: _modeKey, value: saved);
    } catch (_) {
      // Keep the in-memory selection active if secure storage is unavailable.
    }
  }

  static ThemeData get dark {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFDFBE7D),
      onPrimary: Color(0xFF090B0E),
      secondary: Color(0xFFC6A15B),
      onSecondary: Color(0xFF090B0E),
      error: Color(0xFFEB7A82),
      onError: Color(0xFF28090D),
      surface: Color(0xFF11151B),
      onSurface: Color(0xFFF5F2EB),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF090B0E),
      canvasColor: const Color(0xFF11151B),
      cardColor: const Color(0xFF11151B),
      fontFamily: 'Arial',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Color(0xFFF5F2EB),
          fontSize: 28,
          fontWeight: FontWeight.w900,
          height: 1.2,
          letterSpacing: -.3,
        ),
        headlineMedium: TextStyle(
          color: Color(0xFFF5F2EB),
          fontSize: 22,
          fontWeight: FontWeight.w900,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          color: Color(0xFFF5F2EB),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: Color(0xFFF5F2EB),
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFFF5F2EB),
          fontSize: 15,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF969DA8),
          fontSize: 13,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: DarbPageTransitionsBuilder(),
          TargetPlatform.fuchsia: DarbPageTransitionsBuilder(),
          TargetPlatform.iOS: DarbPageTransitionsBuilder(),
          TargetPlatform.linux: DarbPageTransitionsBuilder(),
          TargetPlatform.macOS: DarbPageTransitionsBuilder(),
          TargetPlatform.windows: DarbPageTransitionsBuilder(),
        },
      ),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF090B0E),
        foregroundColor: Color(0xFFF5F2EB),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFFF5F2EB),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF11151B),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DarbRadius.lg),
          side: const BorderSide(color: Color(0xFF222934)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF11151B),
        indicatorColor: const Color(0xFFDFBE7D).withValues(alpha: .16),
        elevation: 0,
        height: 70,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF181E27),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: Color(0xFF969DA8), fontSize: 14),
        labelStyle: const TextStyle(color: Color(0xFF969DA8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DarbRadius.md),
          borderSide: const BorderSide(color: Color(0xFF222934)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DarbRadius.md),
          borderSide: const BorderSide(color: Color(0xFF222934)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DarbRadius.md),
          borderSide: const BorderSide(color: Color(0xFFDFBE7D), width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFDFBE7D),
          foregroundColor: const Color(0xFF090B0E),
          disabledBackgroundColor: const Color(0xFF222934),
          disabledForegroundColor: const Color(0xFF646B76),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DarbRadius.md),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFF5F2EB),
          minimumSize: const Size(0, 50),
          side: const BorderSide(color: Color(0xFF343F4F)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DarbRadius.md),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFDFBE7D),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFDFBE7D),
        foregroundColor: Color(0xFF090B0E),
        elevation: 4,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF11151B),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DarbRadius.xl),
          side: const BorderSide(color: Color(0xFF222934)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF11151B),
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: Color(0xFF343F4F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(DarbRadius.xl)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF222934),
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFFDFBE7D),
        linearTrackColor: Color(0xFF222934),
        circularTrackColor: Color(0xFF222934),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF181E27),
        contentTextStyle: const TextStyle(
          color: Color(0xFFF5F2EB),
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF343F4F)),
        ),
      ),
    );
  }

  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF11151B),
      onPrimary: Color(0xFFF5F2EB),
      secondary: Color(0xFFC6A15B),
      onSecondary: Color(0xFF090B0E),
      error: Color(0xFFB93D45),
      onError: Colors.white,
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF11151B),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF7F6F2),
      canvasColor: const Color(0xFFFFFFFF),
      cardColor: const Color(0xFFFFFFFF),
      fontFamily: 'Arial',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Color(0xFF11151B),
          fontSize: 28,
          fontWeight: FontWeight.w900,
          height: 1.2,
          letterSpacing: -.3,
        ),
        headlineMedium: TextStyle(
          color: Color(0xFF11151B),
          fontSize: 22,
          fontWeight: FontWeight.w900,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          color: Color(0xFF11151B),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: Color(0xFF11151B),
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF11151B),
          fontSize: 15,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF646B76),
          fontSize: 13,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: DarbPageTransitionsBuilder(),
          TargetPlatform.fuchsia: DarbPageTransitionsBuilder(),
          TargetPlatform.iOS: DarbPageTransitionsBuilder(),
          TargetPlatform.linux: DarbPageTransitionsBuilder(),
          TargetPlatform.macOS: DarbPageTransitionsBuilder(),
          TargetPlatform.windows: DarbPageTransitionsBuilder(),
        },
      ),
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF11151B),
        linearTrackColor: Color(0xFFE4DFD4),
        circularTrackColor: Color(0xFFE4DFD4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DarbRadius.xl),
          side: const BorderSide(color: Color(0xFFE4DFD4)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: Color(0xFFCCC4B4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(DarbRadius.xl)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF7F6F2),
        foregroundColor: Color(0xFF11151B),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF11151B),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DarbRadius.lg),
          side: const BorderSide(color: Color(0xFFE4DFD4)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        indicatorColor: const Color(0xFFEAD9B4).withValues(alpha: .55),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w500,
          ),
        ),
        elevation: 0,
        height: 70,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: Color(0xFF646B76), fontSize: 14),
        labelStyle: const TextStyle(color: Color(0xFF646B76)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DarbRadius.md),
          borderSide: const BorderSide(color: Color(0xFFE4DFD4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DarbRadius.md),
          borderSide: const BorderSide(color: Color(0xFFE4DFD4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DarbRadius.md),
          borderSide: const BorderSide(color: Color(0xFF11151B), width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF11151B),
          foregroundColor: const Color(0xFFF5F2EB),
          disabledBackgroundColor: const Color(0xFFCCC4B4),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DarbRadius.md),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF11151B),
          minimumSize: const Size(0, 50),
          side: const BorderSide(color: Color(0xFFCCC4B4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DarbRadius.md),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF11151B),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF11151B),
        foregroundColor: Color(0xFFF5F2EB),
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE4DFD4),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF11151B),
        contentTextStyle: const TextStyle(
          color: Color(0xFFF5F2EB),
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

// =============================================================================
// REUSABLE DAZREVO NOCTURNE ATELIER DESIGN SYSTEM COMPONENTS
// =============================================================================

/// Custom kinetic geometric "D" emblem for DAZREVO, synchronized with `ic_launcher.xml`
/// and web SVG marks.
class DazrevoLogoMark extends StatelessWidget {
  final double size;
  final bool darkSurface;
  final bool showBorder;

  const DazrevoLogoMark({
    super.key,
    this.size = 42,
    this.darkSurface = true,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: darkSurface ? DarbColors.charcoal : DarbColors.obsidian,
        borderRadius: BorderRadius.circular(radius),
        border: showBorder
            ? Border.all(
                color: DarbColors.champagne.withValues(alpha: .36),
                width: 1.2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: DarbColors.champagne.withValues(alpha: .14),
            blurRadius: size * 0.38,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size.square(size),
        painter: _DazrevoMarkPainter(),
      ),
    );
  }
}

class _DazrevoMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final champagnePaint = Paint()
      ..color = DarbColors.champagne
      ..style = PaintingStyle.fill;
    final goldPaint = Paint()
      ..color = DarbColors.gold
      ..style = PaintingStyle.fill;
    final ivoryPaint = Paint()
      ..color = DarbColors.ivory
      ..style = PaintingStyle.fill;

    // Vertical precision spine
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * .25, s * .25, s * .09, s * .50),
        Radius.circular(s * .03),
      ),
      champagnePaint,
    );

    // Outer kinetic D arch
    final dPath = Path()
      ..moveTo(s * .38, s * .25)
      ..lineTo(s * .54, s * .25)
      ..cubicTo(s * .71, s * .25, s * .80, s * .36, s * .80, s * .50)
      ..cubicTo(s * .80, s * .64, s * .71, s * .75, s * .54, s * .75)
      ..lineTo(s * .38, s * .75)
      ..lineTo(s * .38, s * .65)
      ..lineTo(s * .53, s * .65)
      ..cubicTo(s * .63, s * .65, s * .69, s * .59, s * .69, s * .50)
      ..cubicTo(s * .69, s * .41, s * .63, s * .35, s * .53, s * .35)
      ..lineTo(s * .38, s * .35)
      ..close();
    canvas.drawPath(dPath, champagnePaint);

    // Inner precision route chevron
    final innerPath = Path()
      ..moveTo(s * .43, s * .43)
      ..lineTo(s * .52, s * .43)
      ..cubicTo(s * .58, s * .43, s * .61, s * .46, s * .61, s * .50)
      ..cubicTo(s * .61, s * .54, s * .58, s * .57, s * .52, s * .57)
      ..lineTo(s * .43, s * .57)
      ..close();
    canvas.drawPath(innerPath, goldPaint);

    // Waypoint beacon
    canvas.drawCircle(Offset(s * .295, s * .17), s * .042, ivoryPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Branded DAZREVO typographic wordmark.
class DazrevoWordmark extends StatelessWidget {
  final Color? color;
  final double fontSize;
  final double letterSpacing;

  const DazrevoWordmark({
    super.key,
    this.color,
    this.fontSize = 18,
    this.letterSpacing = 1.6,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'DAZREVO',
      textDirection: TextDirection.ltr,
      style: TextStyle(
        color: color ?? DarbColors.ivory,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: letterSpacing,
        height: 1.05,
      ),
    );
  }
}

/// Architectural Obsidian Hero card with subtle Champagne Gold edge & ambient glow.
class DazrevoHeroSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const DazrevoHeroSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = DarbRadius.xl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            DarbColors.charcoalSoft,
            DarbColors.charcoal,
            DarbColors.obsidian,
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: DarbColors.champagne.withValues(alpha: .22),
          width: 1,
        ),
        boxShadow: DarbElevation.floating,
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: -54,
            end: -42,
            child: IgnorePointer(
              child: Container(
                width: 168,
                height: 168,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      DarbColors.champagne.withValues(alpha: .16),
                      DarbColors.champagne.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            bottom: -75,
            start: -40,
            child: IgnorePointer(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .04),
                    width: 20,
                  ),
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Floating capsule bottom navigation bar for DAZREVO mobile shell.
class DazrevoFloatingDock extends StatelessWidget {
  final List<String> labels;
  final List<IconData> icons;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const DazrevoFloatingDock({
    super.key,
    required this.labels,
    required this.icons,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dockBg = isDark
        ? DarbColors.charcoal.withValues(alpha: .96)
        : DarbColors.surface.withValues(alpha: .97);
    final activeBg = isDark
        ? DarbColors.champagne.withValues(alpha: .16)
        : DarbColors.charcoal;
    final activeFg = isDark ? DarbColors.champagne : DarbColors.ivory;
    final inactiveFg = DarbColors.muted;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: dockBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? DarbColors.champagne.withValues(alpha: .20)
                    : DarbColors.line,
              ),
              boxShadow: [
                BoxShadow(
                  color: DarbColors.obsidian.withValues(alpha: isDark ? .55 : .14),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: List.generate(labels.length, (i) {
                final active = i == selectedIndex;
                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: active,
                    label: labels[i],
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        if (!active) {
                          HapticFeedback.selectionClick();
                          onSelected(i);
                        }
                      },
                      child: AnimatedContainer(
                        duration: DarbMotion.effectiveDuration(
                          context,
                          DarbMotion.standard,
                        ),
                        curve: DarbMotion.enter,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: active ? activeBg : Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                          border: active && isDark
                              ? Border.all(
                                  color: DarbColors.champagne.withValues(alpha: .35),
                                )
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icons[i],
                              size: 21,
                              color: active ? activeFg : inactiveFg,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              labels[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight:
                                    active ? FontWeight.w800 : FontWeight.w600,
                                color: active ? activeFg : inactiveFg,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// Crisp architectural status indicator (8px radius, subtle border, zero candy pill bloat).
class DazrevoStatusTag extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const DazrevoStatusTag({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: .1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Consistent section header across all DAZREVO views.
class DazrevoSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const DazrevoSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: DarbColors.ink,
                  letterSpacing: -.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: DarbColors.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Consistent icon frame used on cards and list rows.
class DazrevoIconWell extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final double radius;

  const DazrevoIconWell({
    super.key,
    required this.icon,
    this.size = 44,
    this.backgroundColor,
    this.iconColor,
    this.radius = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? DarbColors.surfaceAlt,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: DarbColors.line),
      ),
      child: Icon(
        icon,
        size: size * 0.48,
        color: iconColor ?? DarbColors.brandForeground,
      ),
    );
  }
}

/// Architectural vertical pickup -> delivery route timeline.
class DazrevoRouteTimeline extends StatelessWidget {
  final String pickupTitle;
  final String pickupAddress;
  final String dropoffTitle;
  final String dropoffAddress;

  const DazrevoRouteTimeline({
    super.key,
    required this.pickupTitle,
    required this.pickupAddress,
    required this.dropoffTitle,
    required this.dropoffAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                const SizedBox(height: 3),
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DarbColors.accent,
                    border: Border.all(
                      color: DarbColors.accent.withValues(alpha: .35),
                      width: 2.5,
                    ),
                  ),
                ),
                Container(
                  width: 1.5,
                  height: 26,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  color: DarbColors.borderStrong,
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pickupTitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: DarbColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pickupAddress,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: DarbColors.ink,
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
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.location_on_rounded,
                size: 14,
                color: DarbColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dropoffTitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: DarbColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dropoffAddress,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: DarbColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Pulsing loading skeleton tile honoring reduced-motion accessibility.
class DazrevoShimmerTile extends StatefulWidget {
  final double height;
  final double radius;

  const DazrevoShimmerTile({
    super.key,
    this.height = 84,
    this.radius = DarbRadius.lg,
  });

  @override
  State<DazrevoShimmerTile> createState() => _DazrevoShimmerTileState();
}

class _DazrevoShimmerTileState extends State<DazrevoShimmerTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DarbMotion.reduceMotion(context)) {
      _controller.stop();
      _controller.value = .5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final alpha = .35 + (_controller.value * .35);
        return Container(
          height: widget.height,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DarbColors.surface,
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(color: DarbColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: DarbColors.surfaceAlt.withValues(alpha: alpha + .25),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 140,
                      decoration: BoxDecoration(
                        color: DarbColors.line.withValues(alpha: alpha + .2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 90,
                      decoration: BoxDecoration(
                        color: DarbColors.line.withValues(alpha: alpha),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shared segmented control for Auth modes, order status filters, and appearance.
class DazrevoChoiceSegment<T> extends StatelessWidget {
  final List<(T value, String label, IconData? icon)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const DazrevoChoiceSegment({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DarbColors.surfaceAlt,
        borderRadius: BorderRadius.circular(DarbRadius.md),
        border: Border.all(color: DarbColors.line),
      ),
      child: Row(
        children: options.map((opt) {
          final active = opt.$1 == selected;
          final bg = active
              ? (isDark ? DarbColors.champagne : DarbColors.charcoal)
              : Colors.transparent;
          final fg = active
              ? (isDark ? DarbColors.obsidian : DarbColors.ivory)
              : DarbColors.muted;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: () {
                if (!active) {
                  HapticFeedback.selectionClick();
                  onChanged(opt.$1);
                }
              },
              child: AnimatedContainer(
                duration: DarbMotion.effectiveDuration(context, DarbMotion.fast),
                curve: DarbMotion.enter,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (opt.$3 != null) ...[
                      Icon(opt.$3, size: 15, color: fg),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        opt.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                          color: fg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Shared empty state card.
class DazrevoEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  const DazrevoEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: DarbColors.surface,
        borderRadius: BorderRadius.circular(DarbRadius.lg),
        border: Border.all(color: DarbColors.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DazrevoIconWell(icon: icon, size: 52, radius: 16),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DarbColors.ink,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DarbColors.muted,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 14),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Shared recoverable error panel.
class DazrevoErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  final String retryLabel;

  const DazrevoErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    required this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DarbColors.danger.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(DarbRadius.md),
        border: Border.all(color: DarbColors.danger.withValues(alpha: .28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded, color: DarbColors.danger, size: 19),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: DarbColors.danger,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, size: 17, color: DarbColors.danger),
              label: Text(
                retryLabel,
                style: TextStyle(color: DarbColors.danger, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
