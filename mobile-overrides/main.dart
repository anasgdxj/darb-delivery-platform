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
Color get green => DarbColors.brandForeground;
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
            title: 'DAZREVO',
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

/// Shows the branded Nocturne Atelier launch experience while local services
/// and the saved authentication session are restored.
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
    final minimumDisplay =
        Future<void>.delayed(const Duration(milliseconds: 1850));
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
        duration: const Duration(milliseconds: 480),
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
    duration: const Duration(milliseconds: 2800),
  );
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..forward();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DarbMotion.reduceMotion(context)) {
      _orbit.stop();
      _entrance.value = 1;
    } else if (!_orbit.isAnimating) {
      _orbit.repeat();
    }
  }

  @override
  void dispose() {
    _orbit.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: DarbColors.obsidian,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -150,
              right: -115,
              child: _GlowOrb(
                size: 340,
                color: DarbColors.champagne.withValues(alpha: .16),
              ),
            ),
            Positioned(
              bottom: -180,
              left: -120,
              child: _GlowOrb(
                size: 360,
                color: DarbColors.gold.withValues(alpha: .10),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _entrance,
                  curve: Curves.easeOut,
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, .06),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _entrance,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Spacer(flex: 3),
                      SizedBox(
                        width: 196,
                        height: 196,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _orbit,
                              builder: (context, _) => Transform.rotate(
                                angle: _orbit.value * 6.28318,
                                child: CustomPaint(
                                  size: const Size(184, 184),
                                  painter: _OrbitPainter(),
                                ),
                              ),
                            ),
                            const DazrevoLogoMark(size: 108),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      const DazrevoWordmark(
                        fontSize: 34,
                        letterSpacing: 4.5,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        dt('كل طريق يبدأ بخطوة'),
                        style: TextStyle(
                          color: DarbColors.ivory.withValues(alpha: .72),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: .3,
                        ),
                      ),
                      const Spacer(flex: 2),
                      SizedBox(
                        width: 120,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            minHeight: 2.5,
                            backgroundColor:
                                DarbColors.ivory.withValues(alpha: .12),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              DarbColors.champagne,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'NOCTURNE ATELIER',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: DarbColors.champagne.withValues(alpha: .58),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.6,
                        ),
                      ),
                      const SizedBox(height: 30),
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
    final radius = size.width * .44;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = DarbColors.ivory.withValues(alpha: .10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawArc(rect, 0, 6.28318, false, track);

    final accent = Paint()
      ..color = DarbColors.champagne
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.6;
    canvas.drawArc(rect, -.8, 1.45, false, accent);

    final dotPaint = Paint()..color = DarbColors.ivory.withValues(alpha: .92);
    canvas.drawCircle(
      Offset(center.dx + radius, center.dy),
      3.0,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
