import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum DarbVisualStyle { glass, standard }

class DarbColors {
  DarbColors._();

  // Core Brand Identity (Strictly enforced)
  static const forest = Color(0xFF12302A);
  static const primary = Color(0xFF167A5A);
  static const mint = Color(0xFFB9E4D2);
  static const canvas = Color(0xFFF6F6F3);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1A2E29);
  static const muted = Color(0xFF687A75);
  static const danger = Color(0xFFD64545);

  // Derived Light Surfaces & Borders
  static const surfaceSoft = Color(0xFFEDF2EE);
  static const border = Color(0xFFDCE4DF);
  static const mintTint = Color(0xFFE7F5EE);
  static const dangerSoft = Color(0xFFFBEBEB);
  static const warning = Color(0xFFB86B14);
  static const warningSoft = Color(0xFFFCF3E6);
  static const info = Color(0xFF1F6F8B);
  static const infoSoft = Color(0xFFE9F4F8);

  // Derived Dark Theme Tokens (from Forest #12302A & Primary #167A5A)
  static const darkCanvas = Color(0xFF0A1916);
  static const darkSurface = Color(0xFF112621);
  static const darkSurfaceHigh = Color(0xFF17332C);
  static const darkBorder = Color(0xFF23473E);
  static const darkInk = Color(0xFFF1F5F3);
  static const darkMuted = Color(0xFF9DB2AC);
  static const darkPrimary = Color(0xFF28A47C);
  static const darkDanger = Color(0xFFE56868);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color canvasOf(BuildContext context) =>
      isDark(context) ? darkCanvas : canvas;

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? darkSurface : surface;

  static Color softSurfaceOf(BuildContext context) =>
      isDark(context) ? darkSurfaceHigh : surfaceSoft;

  static Color borderOf(BuildContext context) =>
      isDark(context) ? darkBorder : border;

  static Color inkOf(BuildContext context) =>
      isDark(context) ? darkInk : ink;

  static Color mutedOf(BuildContext context) =>
      isDark(context) ? darkMuted : muted;

  static Color primaryOf(BuildContext context) =>
      isDark(context) ? darkPrimary : primary;

  static Color dangerOf(BuildContext context) =>
      isDark(context) ? darkDanger : danger;
}

class DarbSpacing {
  DarbSpacing._();
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
}

class DarbRadius {
  DarbRadius._();
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 30;
  static const double pill = 999;
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

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 480);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;

  static bool reduceMotion(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    return (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
  }

  static Duration effectiveDuration(BuildContext context, Duration target) =>
      reduceMotion(context) ? Duration.zero : target;
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
    final curved = CurvedAnimation(parent: animation, curve: DarbMotion.enter);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(curved),
        child: child,
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
    _controller = AnimationController(vsync: this, duration: DarbMotion.medium);
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
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  State<DarbPressScale> createState() => _DarbPressScaleState();
}

class _DarbPressScaleState extends State<DarbPressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduced = DarbMotion.reduceMotion(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _pressed = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: (!reduced && _pressed) ? 0.978 : 1.0,
        duration: DarbMotion.fast,
        curve: DarbMotion.enter,
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
    final softSurf = isDark ? DarbColors.darkSurfaceHigh : DarbColors.surfaceSoft;
    final ink = isDark ? DarbColors.darkInk : DarbColors.ink;
    final muted = isDark ? DarbColors.darkMuted : DarbColors.muted;
    final primary = isDark ? DarbColors.darkPrimary : DarbColors.primary;
    final border = isDark ? DarbColors.darkBorder : DarbColors.border;
    final danger = isDark ? DarbColors.darkDanger : DarbColors.danger;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: isDark ? DarbColors.forest : DarbColors.mint,
      onPrimaryContainer: isDark ? DarbColors.mint : DarbColors.forest,
      secondary: isDark ? DarbColors.mint : DarbColors.forest,
      onSecondary: isDark ? DarbColors.forest : Colors.white,
      secondaryContainer: softSurf,
      onSecondaryContainer: ink,
      error: danger,
      onError: Colors.white,
      surface: surf,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: border,
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
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surf,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DarbRadius.lg),
          side: BorderSide(color: border.withValues(alpha: 0.7)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.42),
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
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
          side: BorderSide(color: border),
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? DarbColors.darkSurfaceHigh.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.88),
        hintStyle: TextStyle(color: muted, fontSize: 14),
        labelStyle: TextStyle(color: muted, fontWeight: FontWeight.w600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DarbRadius.md),
          borderSide: BorderSide(color: danger),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? DarbColors.forest : DarbColors.ink,
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
          if (states.contains(WidgetState.selected)) return Colors.white;
          return muted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return softSurf;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: softSurf,
        selectedColor: isDark ? DarbColors.forest : DarbColors.mintTint,
        labelStyle: TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 13),
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
