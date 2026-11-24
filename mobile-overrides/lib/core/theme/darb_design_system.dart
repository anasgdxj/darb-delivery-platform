import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum DarbVisualStyle { glass, standard }

class DarbColors {
  DarbColors._();

  // Shared Brand Anchors (DARB DESIGN SYSTEM 2026 — Premium + Dynamic + Neo)
  static const forest = Color(0xFF12302A); // Dark Green
  static const primaryGreen = Color(0xFF167A5A); // Primary Green
  static const forestSoft = Color(0xFF1C4B3F);
  static const mint = Color(0xFFB9E4D2);
  static const lime = Color(0xFFC8F169);
  static const danger = Color(0xFFD64545); // Error
  static const success = Color(0xFF2E7D32); // Success
  static const warning = Color(0xFFC47B19);
  static const info = Color(0xFF2B6EA3);

  // Light Semantic Surfaces
  static const canvas = Color(0xFFF6F6F3); // Background Light
  static const surface = Color(0xFFFFFFFF); // Surface Light
  static const surfaceAlt = Color(0xFFECEEE9);
  static const ink = Color(0xFF1A2E29); // Primary Text
  static const muted = Color(0xFF687A75); // Secondary Text
  static const line = Color(0xFFD0D7D4); // Border
  static const borderStrong = Color(0xFFB8C3BF);
  static const scrim = Color(0x990D1C18);

  // Compatibility aliases & soft semantic tints
  static const primary = primaryGreen;
  static const surfaceSoft = surfaceAlt;
  static const border = line;
  static const mintTint = Color(0xFFE5F4ED);
  static const dangerSoft = Color(0xFFFDECEC);
  static const warningSoft = Color(0xFFFCF3E3);
  static const infoSoft = Color(0xFFEAF4FB);

  // Dark Semantic Surfaces (Deep Emerald Neo Dark Palette; not mechanically inverted)
  static const darkCanvas = Color(0xFF0B1512);
  static const darkSurface = Color(0xFF12201B);
  static const darkSurfaceElevated = Color(0xFF182A24);
  static const darkSurfaceHigh = darkSurfaceElevated;
  static const darkSurfaceAlt = Color(0xFF1D322B);
  static const darkInk = Color(0xFFEEF5F1);
  static const darkMuted = Color(0xFF9CB0A7);
  static const darkLine = Color(0xFF263B33);
  static const darkBorder = darkLine;
  static const darkBorderStrong = Color(0xFF3A544A);
  static const darkPrimary = Color(0xFF6FE0B7);
  static const darkOnPrimary = Color(0xFF0B1F1A);
  static const darkAccent = lime;
  static const darkScrim = Color(0xB8000000);
  static const darkDanger = Color(0xFFEB6B6B);
  static const darkDangerSoft = Color(0xFF3B1E21);
  static const darkSuccess = Color(0xFF54C977);
  static const darkWarning = Color(0xFFE8B04A);
  static const darkWarningSoft = Color(0xFF382914);
  static const darkInfo = Color(0xFF64ADE8);
  static const darkInfoSoft = Color(0xFF162C3D);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color canvasOf(BuildContext context) =>
      isDark(context) ? darkCanvas : canvas;

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? darkSurface : surface;

  static Color surfaceElevatedOf(BuildContext context) =>
      isDark(context) ? darkSurfaceElevated : surface;

  static Color surfaceAltOf(BuildContext context) =>
      isDark(context) ? darkSurfaceAlt : surfaceAlt;

  static Color softSurfaceOf(BuildContext context) => surfaceAltOf(context);

  static Color borderOf(BuildContext context) =>
      isDark(context) ? darkLine : line;

  static Color borderStrongOf(BuildContext context) =>
      isDark(context) ? darkBorderStrong : borderStrong;

  static Color inkOf(BuildContext context) =>
      isDark(context) ? darkInk : ink;

  static Color mutedOf(BuildContext context) =>
      isDark(context) ? darkMuted : muted;

  static Color primaryOf(BuildContext context) =>
      isDark(context) ? darkPrimary : primaryGreen;

  static Color onPrimaryOf(BuildContext context) =>
      isDark(context) ? darkOnPrimary : Colors.white;

  static Color accentOf(BuildContext context) =>
      isDark(context) ? darkAccent : forest;

  static Color dangerOf(BuildContext context) =>
      isDark(context) ? darkDanger : danger;

  static Color dangerSoftOf(BuildContext context) =>
      isDark(context) ? darkDangerSoft : dangerSoft;

  static Color successOf(BuildContext context) =>
      isDark(context) ? darkSuccess : success;

  static Color warningOf(BuildContext context) =>
      isDark(context) ? darkWarning : warning;

  static Color warningSoftOf(BuildContext context) =>
      isDark(context) ? darkWarningSoft : warningSoft;

  static Color infoOf(BuildContext context) =>
      isDark(context) ? darkInfo : info;

  static Color infoSoftOf(BuildContext context) =>
      isDark(context) ? darkInfoSoft : infoSoft;

  static Color scrimOf(BuildContext context) =>
      isDark(context) ? darkScrim : scrim;
}

class DarbSpace {
  DarbSpace._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double section = 40;
}

class DarbSpacing {
  DarbSpacing._();

  static const double xs = DarbSpace.xs;
  static const double sm = DarbSpace.sm;
  static const double md = DarbSpace.md;
  static const double lg = DarbSpace.lg;
  static const double xl = DarbSpace.xl;
}

class DarbRadius {
  DarbRadius._();

  static const double sm = 12;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double hero = 36;
  static const double pill = 999;
}

class DarbElevation {
  DarbElevation._();

  static const List<BoxShadow> none = [];

  static List<BoxShadow> card(bool isDark) => [
        BoxShadow(
          color: (isDark ? Colors.black : DarbColors.forest)
              .withValues(alpha: isDark ? 0.30 : 0.055),
          blurRadius: isDark ? 18 : 14,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> floating(bool isDark) => [
        BoxShadow(
          color: (isDark ? Colors.black : DarbColors.forest)
              .withValues(alpha: isDark ? 0.44 : 0.11),
          blurRadius: 26,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> glow(Color color, {bool isDark = false}) => [
        BoxShadow(
          color: color.withValues(alpha: isDark ? 0.28 : 0.18),
          blurRadius: isDark ? 24 : 20,
          offset: const Offset(0, 6),
        ),
      ];
}

class DarbAppearanceController extends ChangeNotifier {
  DarbAppearanceController._();
  static final instance = DarbAppearanceController._();

  static const _storage = FlutterSecureStorage();
  static const _themeKey = 'darb_theme_mode';
  static const _styleKey = 'darb_visual_style';

  ThemeMode _themeMode = ThemeMode.system;
  DarbVisualStyle _visualStyle = DarbVisualStyle.glass;

  ThemeMode get themeMode => _themeMode;
  DarbVisualStyle get visualStyle => _visualStyle;
  bool get isGlass => _visualStyle == DarbVisualStyle.glass;

  Future<void> restore() async {
    try {
      final savedTheme = await _storage.read(key: _themeKey);
      final savedStyle = await _storage.read(key: _styleKey);
      _themeMode = switch (savedTheme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      _visualStyle = switch (savedStyle) {
        'standard' => DarbVisualStyle.standard,
        _ => DarbVisualStyle.glass,
      };
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      await _storage.write(key: _themeKey, value: mode.name);
    } catch (_) {}
  }

  Future<void> setVisualStyle(DarbVisualStyle style) async {
    if (_visualStyle == style) return;
    _visualStyle = style;
    notifyListeners();
    try {
      await _storage.write(key: _styleKey, value: style.name);
    } catch (_) {}
  }
}

class DarbMotion {
  DarbMotion._();

  static const Duration press = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration interactive = Duration(milliseconds: 220);
  static const Duration tab = Duration(milliseconds: 240);
  static const Duration standard = Duration(milliseconds: 260);
  static const Duration medium = standard;
  static const Duration route = Duration(milliseconds: 340);
  static const Duration expressive = Duration(milliseconds: 420);
  static const Duration slow = expressive;
  static const Duration staggerStep = Duration(milliseconds: 55);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasis = Curves.easeOutBack;

  static Duration staggerDelay(int index, {int maxItems = 6}) {
    final clamped = index.clamp(0, maxItems);
    return Duration(milliseconds: clamped * staggerStep.inMilliseconds);
  }

  static bool reduceMotion(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    return (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
  }

  static Duration effectiveDuration(BuildContext context, Duration target) =>
      reduceMotion(context) ? Duration.zero : target;
}

class DarbPageRoute<T> extends PageRouteBuilder<T> {
  DarbPageRoute({required WidgetBuilder builder, super.settings})
      : super(
          transitionDuration: DarbMotion.route,
          reverseTransitionDuration: DarbMotion.interactive,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (DarbMotion.reduceMotion(context)) return child;
            final curved = CurvedAnimation(
              parent: animation,
              curve: DarbMotion.enter,
              reverseCurve: DarbMotion.exit,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(curved),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.984, end: 1.0).animate(curved),
                  child: child,
                ),
              ),
            );
          },
        );
}

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
    final curved = CurvedAnimation(
      parent: animation,
      curve: DarbMotion.enter,
      reverseCurve: DarbMotion.exit,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.025),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1.0).animate(curved),
          child: child,
        ),
      ),
    );
  }
}

class DarbFadeSlide extends StatefulWidget {
  const DarbFadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 14,
  });

  final Widget child;
  final Duration delay;
  final double offsetY;

  @override
  State<DarbFadeSlide> createState() => _DarbFadeSlideState();
}

class _DarbFadeSlideState extends State<DarbFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _offset;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DarbMotion.standard,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: DarbMotion.enter);
    _offset = Tween<double>(begin: widget.offsetY, end: 0).animate(_opacity);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (DarbMotion.reduceMotion(context)) {
      _controller.value = 1;
      return;
    }
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
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
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: Offset(0, _offset.value),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

class DarbPressScale extends StatefulWidget {
  const DarbPressScale({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = DarbRadius.md,
    this.scaleFactor = 0.974,
    this.enableHaptics = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final double scaleFactor;
  final bool enableHaptics;

  @override
  State<DarbPressScale> createState() => _DarbPressScaleState();
}

class _DarbPressScaleState extends State<DarbPressScale> {
  bool _pressed = false;

  void _handleTap() {
    if (widget.onTap == null) return;
    if (widget.enableHaptics) {
      try {
        HapticFeedback.selectionClick();
      } catch (_) {}
    }
    widget.onTap!.call();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = DarbMotion.reduceMotion(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown:
          widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapUp:
          widget.onTap == null ? null : (_) => setState(() => _pressed = false),
      onTapCancel:
          widget.onTap == null ? null : () => setState(() => _pressed = false),
      onTap: widget.onTap == null ? null : _handleTap,
      child: AnimatedScale(
        scale: (!reduced && _pressed) ? widget.scaleFactor : 1.0,
        duration: DarbMotion.effectiveDuration(
          context,
          _pressed ? DarbMotion.press : DarbMotion.interactive,
        ),
        curve: (!reduced && !_pressed)
            ? DarbMotion.emphasis
            : DarbMotion.enter,
        child: widget.child,
      ),
    );
  }
}

class DarbTheme {
  DarbTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? DarbColors.darkCanvas : DarbColors.canvas;
    final surf = isDark ? DarbColors.darkSurface : DarbColors.surface;
    final surfElevated =
        isDark ? DarbColors.darkSurfaceElevated : DarbColors.surface;
    final softSurf =
        isDark ? DarbColors.darkSurfaceAlt : DarbColors.surfaceAlt;
    final ink = isDark ? DarbColors.darkInk : DarbColors.ink;
    final muted = isDark ? DarbColors.darkMuted : DarbColors.muted;
    final primary = isDark ? DarbColors.darkPrimary : DarbColors.primaryGreen;
    final onPrimary = isDark ? DarbColors.darkOnPrimary : Colors.white;
    final border = isDark ? DarbColors.darkLine : DarbColors.line;
    final borderStrong =
        isDark ? DarbColors.darkBorderStrong : DarbColors.borderStrong;
    final danger = isDark ? DarbColors.darkDanger : DarbColors.danger;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: isDark ? DarbColors.forestSoft : DarbColors.mintTint,
      onPrimaryContainer: isDark ? DarbColors.mint : DarbColors.forest,
      secondary: isDark ? DarbColors.lime : DarbColors.forest,
      onSecondary: isDark ? DarbColors.forest : Colors.white,
      secondaryContainer: softSurf,
      onSecondaryContainer: ink,
      error: danger,
      onError: Colors.white,
      surface: surf,
      onSurface: ink,
      surfaceContainerHighest: surfElevated,
      onSurfaceVariant: muted,
      outline: border,
      outlineVariant: borderStrong,
      scrim: isDark ? DarbColors.darkScrim : DarbColors.scrim,
      shadow: Colors.black,
    );

    const transitions = PageTransitionsTheme(
      builders: {
        TargetPlatform.android: DarbPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: DarbPageTransitionsBuilder(),
        TargetPlatform.macOS: DarbPageTransitionsBuilder(),
        TargetPlatform.windows: DarbPageTransitionsBuilder(),
      },
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      pageTransitionsTheme: transitions,
      dividerColor: border,
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          color: ink,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          color: ink,
          fontSize: 19,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          color: ink,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        bodyLarge: TextStyle(
          color: ink,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          color: ink,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          height: 1.42,
        ),
        bodySmall: TextStyle(
          color: muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surf,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DarbRadius.lg),
          side: BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DarbRadius.xl),
          side: BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: primary.withValues(alpha: 0.40),
          disabledForegroundColor: onPrimary.withValues(alpha: 0.7),
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(
            horizontal: DarbSpace.lg,
            vertical: DarbSpace.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DarbRadius.md),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: borderStrong),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DarbRadius.md),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: softSurf,
          foregroundColor: ink,
          selectedBackgroundColor: primary,
          selectedForegroundColor: onPrimary,
          side: BorderSide(color: border),
          textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? DarbColors.darkSurfaceElevated.withValues(alpha: 0.90)
            : Colors.white.withValues(alpha: 0.95),
        hintStyle: TextStyle(color: muted, fontSize: 14),
        labelStyle: TextStyle(color: muted, fontWeight: FontWeight.w600),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DarbRadius.md),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DarbRadius.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DarbRadius.md),
          borderSide: BorderSide(color: primary, width: 1.7),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DarbRadius.md),
          borderSide: BorderSide(color: danger),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? DarbColors.forestSoft : DarbColors.forest,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DarbRadius.md),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return onPrimary;
          return muted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return softSurf;
        }),
        trackOutlineColor: WidgetStatePropertyAll(border),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: softSurf,
        selectedColor: isDark ? DarbColors.forestSoft : DarbColors.mintTint,
        checkmarkColor: isDark ? DarbColors.mint : DarbColors.forest,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: TextStyle(
          color: ink,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
        secondaryLabelStyle: TextStyle(
          color: isDark ? DarbColors.mint : DarbColors.forest,
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DarbRadius.pill),
        ),
      ),
    );
  }
}

bool get darbSupportsHighBlur =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.macOS;

ImageFilter darbBlurFilter(double sigma) => ImageFilter.blur(
      sigmaX: darbSupportsHighBlur ? sigma : sigma * 0.5,
      sigmaY: darbSupportsHighBlur ? sigma : sigma * 0.5,
    );
