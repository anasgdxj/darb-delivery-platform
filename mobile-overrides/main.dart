import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/api.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'localizations.dart';
import 'notifications.dart';
import 'app_update.dart';
import 'design_system.dart';

Color get ink => DarbColors.ink;
Color get green => DarbColors.forestSoft;
Color get paper => DarbColors.canvas;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DarbTheme.restoreMode();
  runApp(const DarbApp());
}

class DarbApp extends StatelessWidget {
  const DarbApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Locale>(
    valueListenable: darbLocale,
    builder: (context, locale, _) => ValueListenableBuilder<ThemeMode>(
      valueListenable: DarbTheme.mode,
      builder: (context, themeMode, _) => MaterialApp(
      title: 'دَرْب',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: DarbTheme.light,
      darkTheme: DarbTheme.dark,
      themeMode: themeMode,
      themeAnimationDuration: DarbMotion.expressive,
      themeAnimationCurve: DarbMotion.enter,
      builder: (context, child) {
        DarbTheme.updateBrightness(Theme.of(context).brightness);
        return child ?? const SizedBox.shrink();
      },
      home: DarbLaunchGate(locale: locale),
    ),
    ),
  );
}

/// Shows the branded launch experience while local services and the saved
/// authentication session are restored. Temporary bootstrap failures do not
/// clear credentials; AppShell/LoginScreen handle the next recoverable state.
class DarbLaunchGate extends StatefulWidget {
  final Locale locale;
  const DarbLaunchGate({super.key, required this.locale});

  @override
  State<DarbLaunchGate> createState() => _DarbLaunchGateState();
}

class _DarbLaunchGateState extends State<DarbLaunchGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final minimumDisplay = Future<void>.delayed(const Duration(milliseconds: 2100));
    try {
      await DarbNotifications.initialize();
    } catch (_) {
      // Notifications are not allowed to block application startup.
    }
    try {
      await Api.instance.restore();
    } catch (_) {
      // Never clear stored credentials because local restoration temporarily failed.
    }
    DarbUpdater.instance.checkForUpdate();
    await minimumDisplay;
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 520),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    child: _ready
        ? (Api.instance.accessToken == null
            ? LoginScreen(key: ValueKey('login-${widget.locale.languageCode}'))
            : AppShell(key: ValueKey('app-${widget.locale.languageCode}')))
        : const DarbSplashScreen(key: ValueKey('splash')),
  );
}

class DarbSplashScreen extends StatefulWidget {
  const DarbSplashScreen({super.key});

  @override
  State<DarbSplashScreen> createState() => _DarbSplashScreenState();
}

class _DarbSplashScreenState extends State<DarbSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _orbit.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DarbColors.forest,
    body: Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: -150,
          right: -115,
          child: _GlowOrb(size: 330, color: DarbColors.forestSoft.withValues(alpha: .9)),
        ),
        Positioned(
          bottom: -180,
          left: -120,
          child: _GlowOrb(size: 360, color: const Color(0xFF1B5B48).withValues(alpha: .45)),
        ),
        SafeArea(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _entrance, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .07),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic)),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  SizedBox(
                    width: 190,
                    height: 190,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _orbit,
                          builder: (context, _) => Transform.rotate(
                            angle: _orbit.value * 6.28318,
                            child: CustomPaint(
                              size: const Size(180, 180),
                              painter: _OrbitPainter(),
                            ),
                          ),
                        ),
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .09),
                            borderRadius: BorderRadius.circular(36),
                            border: Border.all(color: Colors.white.withValues(alpha: .2)),
                            boxShadow: [
                              BoxShadow(
                                color: DarbColors.mint.withValues(alpha: .13),
                                blurRadius: 42,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'د',
                              style: TextStyle(
                                color: DarbColors.mint,
                                fontSize: 76,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'دَرْب',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    dt('كل طريق يبدأ بخطوة'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .72),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: .3,
                    ),
                  ),
                  const Spacer(flex: 2),
                  SizedBox(
                    width: 116,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        backgroundColor: Color(0x334FFFFF),
                        valueColor: AlwaysStoppedAnimation(DarbColors.mint),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    'CRAFTED BY',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .48),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'anasgdxj',
                    style: TextStyle(
                      color: DarbColors.mint,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    ),
  );
}

class _OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: size.width * .43);
    final track = Paint()
      ..color = Colors.white.withValues(alpha: .13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawArc(rect, 0, 6.28318, false, track);

    final accent = Paint()
      ..color = DarbColors.mint
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2;
    canvas.drawArc(rect, -.8, 1.45, false, accent);

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: .9);
    canvas.drawCircle(
      Offset(center.dx + size.width * .43, center.dy),
      3.2,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
