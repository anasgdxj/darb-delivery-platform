import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/app_localizations.dart';
import 'core/network/api_client.dart';
import 'core/services/notifications_service.dart';
import 'core/theme/darb_design_system.dart';
import 'core/widgets/darb_components.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    DarbNotifications.initialize(),
    DarbAppearanceController.instance.restore(),
  ]);
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
          title: 'دَرْب · DARB',
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
    await Api.instance.restore();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted || _navigated) return;
    _navigated = true;
    final destination = Api.instance.accessToken != null
        ? const AppShell()
        : const LoginScreen();
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
        color: Colors.white.withValues(alpha: 0.10),
        border: Border.all(
          color: DarbColors.mint.withValues(alpha: 0.34),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: DarbColors.mint.withValues(alpha: 0.16),
            blurRadius: 32,
            spreadRadius: 2,
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
            dt('دَرْب'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dt('كل طريق يبدأ بخطوة'),
            style: TextStyle(
              color: DarbColors.mint.withValues(alpha: 0.94),
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
              valueColor: AlwaysStoppedAnimation<Color>(DarbColors.mint),
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
              DarbColors.forest,
              DarbColors.forestSoft,
              DarbColors.primaryGreen,
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
