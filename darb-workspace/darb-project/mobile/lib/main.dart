import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/app_localizations.dart';
import 'core/network/api_client.dart';
import 'core/services/notifications_service.dart';
import 'core/storage/local_cache.dart';
import 'core/theme/darb_design_system.dart';
import 'core/widgets/darb_components.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/shell/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Future.wait([
      DarbNotifications.initialize(),
      DarbAppearanceController.instance.restore(),
    ]);
  } catch (_) {}
  runApp(const DarbApp());
}

class DarbApp extends StatelessWidget {
  const DarbApp({super.key, this.initialScreen});

  final Widget? initialScreen;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        DarbAppearanceController.instance,
        darbLocale,
      ]),
      builder: (context, _) {
        final appearance = DarbAppearanceController.instance;
        return MaterialApp(
          title: 'دازريفو · DAZREVO',
          debugShowCheckedModeBanner: false,
          locale: darbLocale.value,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: appearance.themeMode,
          theme: DarbTheme.light,
          darkTheme: DarbTheme.dark,
          themeAnimationDuration: DarbMotion.effectiveDuration(
            context,
            const Duration(milliseconds: 280),
          ),
          themeAnimationCurve: DarbMotion.enter,
          builder: (context, child) {
            if (child == null) return const SizedBox.shrink();
            if (appearance.textScale == 1.0) return child;
            final media = MediaQuery.of(context);
            final effectiveFactor =
                (media.textScaler.scale(1.0) * appearance.textScale)
                    .clamp(0.85, 1.38)
                    .toDouble();
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(effectiveFactor),
              ),
              child: child,
            );
          },
          home: initialScreen ?? const _DarbSplashGate(),
        );
      },
    );
  }
}

class _DarbSplashGate extends StatefulWidget {
  const _DarbSplashGate();

  @override
  State<_DarbSplashGate> createState() => _DarbSplashGateState();
}

class _DarbSplashGateState extends State<_DarbSplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _introController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _emblemScale;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: DarbMotion.expressive,
    )..forward();
    _fadeIn = CurvedAnimation(
      parent: _introController,
      curve: DarbMotion.enter,
    );
    _emblemScale = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: DarbMotion.emphasis,
      ),
    );
    _restoreSession();
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  Future<void> _restoreSession() async {
    var onboardingSeen = false;
    try {
      await Api.instance.restore();
      if (Api.instance.accessToken != null) {
        onboardingSeen = true;
      } else {
        onboardingSeen =
            (await DarbLocalCache.instance.readJson(kDazrevoOnboardingSeenKey)) ==
                true;
      }
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted || _navigated) return;
    _navigated = true;
    final Widget destination;
    if (Api.instance.accessToken != null) {
      destination = const AppShell();
    } else if (onboardingSeen) {
      destination = const LoginScreen();
    } else {
      destination = const OnboardingScreen();
    }
    Navigator.of(context).pushReplacement(
      DarbPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduce = DarbMotion.reduceMotion(context);
    final emblem = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DarbRadius.xl),
        color: DarbColors.forestSoft.withValues(alpha: 0.52),
        border: Border.all(
          color: DarbColors.lime.withValues(alpha: 0.42),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: DarbColors.lime.withValues(alpha: 0.16),
            blurRadius: 34,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: DarbColors.violet.withValues(alpha: 0.18),
            blurRadius: 42,
            offset: const Offset(-10, 12),
          ),
        ],
      ),
      child: const DarbBrandMark(size: 78),
    );

    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          reduce ? emblem : ScaleTransition(scale: _emblemScale, child: emblem),
          const SizedBox(height: 22),
          Text(
            dt('دازريفو · DAZREVO'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dt('كل طريق يبدأ بخطوة'),
            style: TextStyle(
              color: DarbColors.lime.withValues(alpha: 0.94),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 28),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(DarbColors.lime),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DarbColors.darkCanvas,
              DarbColors.forest,
              DarbColors.forestSoft,
            ],
          ),
        ),
        child: reduce
            ? content
            : FadeTransition(
                opacity: _fadeIn,
                child: content,
              ),
      ),
    );
  }
}
