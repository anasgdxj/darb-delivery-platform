import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Shared visual language for DARB. Keep product screens on these tokens.
abstract final class DarbColors {
  static bool get _dark => DarbTheme.brightness.value == Brightness.dark;

  // Brand anchors remain stable; semantic surfaces and foregrounds adapt.
  static Color get forest => const Color(0xFF102B26);
  static Color get forestSoft => const Color(0xFF1C443B);
  static Color get mint => const Color(0xFFB9E4D2);
  static Color get canvas => _dark ? const Color(0xFF0B1512) : const Color(0xFFF5F6F2);
  static Color get surface => _dark ? const Color(0xFF13221D) : const Color(0xFFFFFFFF);
  static Color get surfaceAlt => _dark ? const Color(0xFF1A2D26) : const Color(0xFFEAF2EC);
  static Color get onForest => const Color(0xFFFFFFFF);
  static Color get primary => _dark ? mint : forest;
  static Color get onPrimary => _dark ? forest : const Color(0xFFFFFFFF);
  static Color get surfaceElevated => _dark ? const Color(0xFF1A2D26) : surface;
  static Color get onBrand => const Color(0xFFFFFFFF);
  static Color get brandForeground => _dark ? mint : forest;
  static Color get ink => _dark ? const Color(0xFFF1F5F1) : const Color(0xFF17231F);
  static Color get muted => _dark ? const Color(0xFFA4B2AA) : const Color(0xFF77837D);
  static Color get line => _dark ? const Color(0xFF2A3B33) : const Color(0xFFE4E9E3);
  static Color get danger => _dark ? const Color(0xFFE47777) : const Color(0xFFB94747);
  static Color get success => _dark ? const Color(0xFF75C99A) : const Color(0xFF287A50);
  static Color get warning => _dark ? const Color(0xFFE5B968) : const Color(0xFFB7791F);
  static Color get info => _dark ? const Color(0xFF83B8E0) : const Color(0xFF356D9A);
  static Color get borderStrong => _dark ? const Color(0xFF40564A) : const Color(0xFFCBD5CE);
  static Color get scrim => _dark ? const Color(0xB8000000) : const Color(0x990B1713);
}

abstract final class DarbSpace {
  static const double xxs = 4, xs = 8, sm = 12, md = 16, lg = 20;
  static const double xl = 24, xxl = 32, section = 40;
}

abstract final class DarbRadius {
  static const double sm = 12, md = 16, lg = 22, xl = 28;
  static const double hero = 36, pill = 999;
}

abstract final class DarbMotion {
  static const Duration press = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 260);
  static const Duration route = Duration(milliseconds: 340);
  static const Duration expressive = Duration(milliseconds: 420);
  static const Duration staggerStep = Duration(milliseconds: 55);

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
  ) => reduceMotion(context) ? Duration.zero : duration;

  static Duration staggerDelay(int index) {
    if (index <= 0) return Duration.zero;
    return Duration(milliseconds: staggerStep.inMilliseconds * index);
  }
}

/// One route transition shared by light and dark themes.
/// It remains short and never blocks navigation when reduced motion is enabled.
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
          begin: const Offset(0, .035),
          end: Offset.zero,
        ).animate(progress),
        child: ScaleTransition(
          scale: Tween<double>(begin: .985, end: 1).animate(progress),
          child: child,
        ),
      ),
    );
  }
}

/// Reusable entrance motion for content blocks and list items.
/// The optional delay enables a controlled stagger without extra packages.
class DarbFadeSlide extends StatefulWidget {
  const DarbFadeSlide({
    super.key,
    required this.child,
    this.duration = DarbMotion.standard,
    this.delay = Duration.zero,
    this.offset = const Offset(0, .10),
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

/// Adds tactile press feedback while respecting reduced-motion settings.
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
    BoxShadow(color: Color(0x080F2B24), blurRadius: 18, offset: Offset(0, 6)),
  ];
  static const floating = <BoxShadow>[
    BoxShadow(color: Color(0x160F2B24), blurRadius: 28, offset: Offset(0, 12)),
  ];
}


abstract final class DarbTheme {
  static const _storage = FlutterSecureStorage();
  static const _modeKey = 'darb_theme_mode';
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);
  static final ValueNotifier<Brightness> brightness = ValueNotifier(Brightness.light);

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
      primary: Color(0xFFB9E4D2),
      onPrimary: Color(0xFF102B26),
      secondary: Color(0xFFB9E4D2),
      onSecondary: Color(0xFF102B26),
      error: Color(0xFFE47777),
      onError: Color(0xFF2A1010),
      surface: Color(0xFF13221D),
      onSurface: Color(0xFFF1F5F1),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0B1512),
      canvasColor: const Color(0xFF13221D),
      cardColor: const Color(0xFF13221D),
      fontFamily: 'Arial',
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
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF102B26),
        foregroundColor: Color(0xFFF1F5F1),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFF13221D),
        indicatorColor: Color(0xFF29483B),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A2D26),
        hintStyle: const TextStyle(color: Color(0xFFA4B2AA)),
        labelStyle: const TextStyle(color: Color(0xFFA4B2AA)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2A3B33)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFB9E4D2), width: 1.5),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF13221D),
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF13221D),
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF2A3B33)),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFFB9E4D2),
        linearTrackColor: Color(0xFF2A3B33),
        circularTrackColor: Color(0xFF2A3B33),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFB9E4D2),
          foregroundColor: const Color(0xFF102B26),
          disabledBackgroundColor: const Color(0xFF40564A),
          disabledForegroundColor: const Color(0xFFA4B2AA),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFF1F5F1),
          side: const BorderSide(color: Color(0xFF40564A)),
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF13221D),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFF2A3B33)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A2D26),
        contentTextStyle: const TextStyle(color: Color(0xFFF1F5F1), fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static ThemeData get light {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF102B26),
      onPrimary: Colors.white,
      secondary: Color(0xFFB9E4D2),
      onSecondary: Color(0xFF102B26),
      error: Color(0xFFB94747),
      onError: Colors.white,
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF17231F),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Color(0xFFF5F6F2),
      fontFamily: 'Arial',
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: Color(0xFF17231F), fontSize: 28, fontWeight: FontWeight.w900, height: 1.2),
        headlineMedium: TextStyle(color: Color(0xFF17231F), fontSize: 23, fontWeight: FontWeight.w900, height: 1.25),
        titleLarge: TextStyle(color: Color(0xFF17231F), fontSize: 19, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(color: Color(0xFF17231F), fontSize: 15, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: Color(0xFF17231F), fontSize: 15, height: 1.5),
        bodyMedium: TextStyle(color: Color(0xFF77837D), fontSize: 13, height: 1.45),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
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
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: Color(0xFF102B26),
        linearTrackColor: Color(0xFFE4E9E3),
        circularTrackColor: Color(0xFFE4E9E3),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DarbRadius.xl)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: Color(0xFFCBD5CE),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(DarbRadius.xl)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFFF5F6F2),
        foregroundColor: Color(0xFF17231F),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF17231F),
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: Color(0xFFFFFFFF),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Color(0xFFE4E9E3)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        indicatorColor: Color(0xFFB9E4D2).withValues(alpha: .55),
        labelTextStyle: WidgetStateProperty.resolveWith((states) =>
          TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800 : FontWeight.w500,
          )),
        elevation: 0,
        height: 70,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFFFFFFF),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        hintStyle: TextStyle(color: Color(0xFF77837D), fontSize: 14),
        labelStyle: TextStyle(color: Color(0xFF77837D)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFE4E9E3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFE4E9E3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFF102B26), width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Color(0xFF102B26),
          foregroundColor: Colors.white,
          minimumSize: Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Color(0xFF102B26),
          minimumSize: Size(0, 50),
          side: BorderSide(color: Color(0xFFE4E9E3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: DividerThemeData(color: Color(0xFFE4E9E3), thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF102B26),
        contentTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
