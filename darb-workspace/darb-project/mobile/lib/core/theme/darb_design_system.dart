import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum DarbVisualStyle { glass, standard }

class DarbColors {
  DarbColors._();

  // DAZREVO 2026 Unified Brand Anchors (Obsidian & Champagne Brass + Mineral Teal)
  static const forest = Color(0xFF14171D); // Smoked Obsidian Architectural Anchor
  static const primaryGreen = Color(0xFF8A651F); // Burnished Bronze Light Primary (>=5.3:1 AA with white)
  static const forestSoft = Color(0xFF1E222B); // Elevated Obsidian Slate
  static const mint = Color(0xFFE7D3A3); // Warm Champagne Mist highlight
  static const lime = Color(0xFFD6B46C); // Luminous Champagne Gold CTA & Dark Primary
  static const limeInk = Color(0xFF6B4F1A); // High-contrast Bronze ink on light surfaces
  static const limeTint = Color(0xFFF6EFE0); // Soft Champagne wash in Light mode
  static const violet = Color(0xFF1D7A6E); // Imperial Mineral Teal AI & Smart Highlight
  static const violetSoft = Color(0xFFE8F5F3); // Soft Mineral Teal wash in Light mode
  static const danger = Color(0xFFC83E3B); // Error
  static const success = Color(0xFF1C7C54); // Success
  static const warning = Color(0xFFB87014);
  static const info = Color(0xFF2364AA);

  // Light Semantic Surfaces (Alabaster Stone Canvas)
  static const canvas = Color(0xFFFAF9F6);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF2EFE9);
  static const ink = Color(0xFF141413);
  static const muted = Color(0xFF636059);
  static const line = Color(0xFFE5E0D6);
  static const borderStrong = Color(0xFFCEC7BA);
  static const scrim = Color(0x990C0D0F);

  // Compatibility aliases & soft semantic tints
  static const primary = primaryGreen;
  static const surfaceSoft = surfaceAlt;
  static const border = line;
  static const mintTint = Color(0xFFF3ECE0);
  static const dangerSoft = Color(0xFFFDECEC);
  static const warningSoft = Color(0xFFFCF3E3);
  static const infoSoft = Color(0xFFE9F2FC);

  // Dark Semantic Surfaces (Smoked Obsidian — layered, never inverted)
  static const darkCanvas = Color(0xFF0C0D0F);
  static const darkSurface = Color(0xFF14161A);
  static const darkSurfaceElevated = Color(0xFF1B1E24);
  static const darkSurfaceHigh = darkSurfaceElevated;
  static const darkSurfaceAlt = Color(0xFF232730);
  static const darkInk = Color(0xFFF5F3EE);
  static const darkMuted = Color(0xFFA39E93);
  static const darkLine = Color(0xFF262A33);
  static const darkBorder = darkLine;
  static const darkBorderStrong = Color(0xFF3A404D);
  static const darkPrimary = lime;
  static const darkOnPrimary = Color(0xFF0C0D0F);
  static const darkAccent = lime;
  static const darkViolet = Color(0xFF3FD1BE);
  static const darkVioletSoft = Color(0xFF112926);
  static const darkScrim = Color(0xC2000000);
  static const darkDanger = Color(0xFFF0716E);
  static const darkDangerSoft = Color(0xFF381C1E);
  static const darkSuccess = Color(0xFF4CD49A);
  static const darkWarning = Color(0xFFF0B857);
  static const darkWarningSoft = Color(0xFF362814);
  static const darkInfo = Color(0xFF69AEF2);
  static const darkInfoSoft = Color(0xFF142B40);

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
      isDark(context) ? lime : forest;

  static Color limeOf(BuildContext context) =>
      isDark(context) ? lime : limeInk;

  static Color limeTintOf(BuildContext context) =>
      isDark(context) ? forestSoft : limeTint;

  static Color violetOf(BuildContext context) =>
      isDark(context) ? darkViolet : violet;

  static Color violetSoftOf(BuildContext context) =>
      isDark(context) ? darkVioletSoft : violetSoft;

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
              .withValues(alpha: isDark ? 0.34 : 0.06),
          blurRadius: isDark ? 18 : 14,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> floating(bool isDark) => [
        BoxShadow(
          color: (isDark ? Colors.black : DarbColors.forest)
              .withValues(alpha: isDark ? 0.48 : 0.12),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> glow(Color color, {bool isDark = false}) => [
        BoxShadow(
          color: color.withValues(alpha: isDark ? 0.30 : 0.20),
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
  static const _textScaleKey = 'darb_text_scale';
  static const _reduceMotionKey = 'darb_reduce_motion';
  static const _hapticsKey = 'darb_haptics_enabled';
  static const _inAppBannersKey = 'darb_in_app_banners';
  static const _orderAlertsKey = 'darb_order_alerts';
  static const _promoAlertsKey = 'darb_promo_alerts';

  ThemeMode _themeMode = ThemeMode.system;
  DarbVisualStyle _visualStyle = DarbVisualStyle.glass;
  double _textScale = 1.0;
  bool _reduceMotionOverride = false;
  bool _hapticsEnabled = true;
  bool _inAppBannersEnabled = true;
  bool _orderAlertsEnabled = true;
  bool _promoAlertsEnabled = true;

  ThemeMode get themeMode => _themeMode;
  DarbVisualStyle get visualStyle => _visualStyle;
  bool get isGlass => _visualStyle == DarbVisualStyle.glass;
  double get textScale => _textScale;
  bool get reduceMotionOverride => _reduceMotionOverride;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get inAppBannersEnabled => _inAppBannersEnabled;
  bool get orderAlertsEnabled => _orderAlertsEnabled;
  bool get promoAlertsEnabled => _promoAlertsEnabled;

  Future<void> restore() async {
    try {
      final savedTheme = await _storage.read(key: _themeKey);
      final savedStyle = await _storage.read(key: _styleKey);
      final savedScale = await _storage.read(key: _textScaleKey);
      final savedReduceMotion = await _storage.read(key: _reduceMotionKey);
      final savedHaptics = await _storage.read(key: _hapticsKey);
      final savedBanners = await _storage.read(key: _inAppBannersKey);
      final savedOrderAlerts = await _storage.read(key: _orderAlertsKey);
      final savedPromoAlerts = await _storage.read(key: _promoAlertsKey);

      _themeMode = switch (savedTheme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      _visualStyle = switch (savedStyle) {
        'standard' => DarbVisualStyle.standard,
        _ => DarbVisualStyle.glass,
      };
      final parsedScale = double.tryParse(savedScale ?? '');
      _textScale =
          parsedScale != null ? parsedScale.clamp(0.90, 1.25).toDouble() : 1.0;
      _reduceMotionOverride = savedReduceMotion == 'true';
      _hapticsEnabled = savedHaptics != 'false';
      _inAppBannersEnabled = savedBanners != 'false';
      _orderAlertsEnabled = savedOrderAlerts != 'false';
      _promoAlertsEnabled = savedPromoAlerts != 'false';
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

  Future<void> setTextScale(double scale) async {
    final clamped = scale.clamp(0.90, 1.25).toDouble();
    if (_textScale == clamped) return;
    _textScale = clamped;
    notifyListeners();
    try {
      await _storage.write(key: _textScaleKey, value: clamped.toString());
    } catch (_) {}
  }

  Future<void> setReduceMotionOverride(bool enabled) async {
    if (_reduceMotionOverride == enabled) return;
    _reduceMotionOverride = enabled;
    notifyListeners();
    try {
      await _storage.write(key: _reduceMotionKey, value: enabled.toString());
    } catch (_) {}
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    if (_hapticsEnabled == enabled) return;
    _hapticsEnabled = enabled;
    notifyListeners();
    try {
      await _storage.write(key: _hapticsKey, value: enabled.toString());
    } catch (_) {}
  }

  Future<void> setInAppBannersEnabled(bool enabled) async {
    if (_inAppBannersEnabled == enabled) return;
    _inAppBannersEnabled = enabled;
    notifyListeners();
    try {
      await _storage.write(key: _inAppBannersKey, value: enabled.toString());
    } catch (_) {}
  }

  Future<void> setOrderAlertsEnabled(bool enabled) async {
    if (_orderAlertsEnabled == enabled) return;
    _orderAlertsEnabled = enabled;
    notifyListeners();
    try {
      await _storage.write(key: _orderAlertsKey, value: enabled.toString());
    } catch (_) {}
  }

  Future<void> setPromoAlertsEnabled(bool enabled) async {
    if (_promoAlertsEnabled == enabled) return;
    _promoAlertsEnabled = enabled;
    notifyListeners();
    try {
      await _storage.write(key: _promoAlertsKey, value: enabled.toString());
    } catch (_) {}
  }

  Future<void> resetAccessibilityAndNotifications() async {
    _textScale = 1.0;
    _reduceMotionOverride = false;
    _hapticsEnabled = true;
    _inAppBannersEnabled = true;
    _orderAlertsEnabled = true;
    _promoAlertsEnabled = true;
    notifyListeners();
    try {
      await _storage.delete(key: _textScaleKey);
      await _storage.delete(key: _reduceMotionKey);
      await _storage.delete(key: _hapticsKey);
      await _storage.delete(key: _inAppBannersKey);
      await _storage.delete(key: _orderAlertsKey);
      await _storage.delete(key: _promoAlertsKey);
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
        (media?.accessibleNavigation ?? false) ||
        DarbAppearanceController.instance.reduceMotionOverride;
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
    if (widget.enableHaptics &&
        DarbAppearanceController.instance.hapticsEnabled) {
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
      onPrimaryContainer: isDark ? DarbColors.lime : DarbColors.forest,
      secondary: isDark ? DarbColors.darkViolet : DarbColors.forest,
      onSecondary: isDark ? DarbColors.darkCanvas : Colors.white,
      secondaryContainer: softSurf,
      onSecondaryContainer: ink,
      tertiary: isDark ? DarbColors.darkViolet : DarbColors.violet,
      onTertiary: Colors.white,
      tertiaryContainer:
          isDark ? DarbColors.darkVioletSoft : DarbColors.violetSoft,
      onTertiaryContainer: isDark ? DarbColors.darkViolet : DarbColors.violet,
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
          letterSpacing: -0.4,
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
            ? DarbColors.darkSurfaceElevated.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.96),
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
        backgroundColor: isDark ? DarbColors.darkSurfaceElevated : DarbColors.forest,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DarbRadius.md),
          side: BorderSide(
            color: DarbColors.lime.withValues(alpha: isDark ? 0.35 : 0.25),
          ),
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
        checkmarkColor: isDark ? DarbColors.lime : DarbColors.forest,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: TextStyle(
          color: ink,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
        secondaryLabelStyle: TextStyle(
          color: isDark ? DarbColors.lime : DarbColors.forest,
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
