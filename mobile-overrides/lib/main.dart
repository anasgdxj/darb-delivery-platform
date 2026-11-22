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
  late final AnimationController _pulseController;
  late final Animation<double> _fadeIn;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: DarbMotion.slow,
    )..forward();
    _fadeIn = CurvedAnimation(parent: _pulseController, curve: DarbMotion.enter);
    _restoreSession();
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduce = DarbMotion.reduceMotion(context);
    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: const Color(0x22FFFFFF),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: const DarbBrandMark(size: 76),
          ),
          const SizedBox(height: 20),
          Text(
            dt('دَرْب'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dt('كل طريق يبدأ بخطوة'),
            style: TextStyle(
              color: DarbColors.mint.withValues(alpha: 0.92),
              fontSize: 14,
              fontWeight: FontWeight.w600,
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
              Color(0xFF15473A),
              DarbColors.primary,
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
