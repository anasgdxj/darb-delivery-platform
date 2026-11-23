import 'package:darb/core/l10n/app_localizations.dart';
import 'package:darb/core/theme/darb_design_system.dart';
import 'package:darb/core/widgets/darb_components.dart';
import 'package:darb/core/widgets/darb_glass.dart';
import 'package:darb/core/widgets/darb_motion_components.dart';
import 'package:darb/features/auth/login_hero_map.dart';
import 'package:darb/features/auth/login_screen.dart';
import 'package:darb/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DARB Design System 2.0 & Brand Integrity', () {
    test('enforces exact DESIGN_SYSTEM.md 2.0 light and dark semantic tokens', () {
      expect(DarbColors.forest, const Color(0xFF102B26));
      expect(DarbColors.forestSoft, const Color(0xFF1C443B));
      expect(DarbColors.mint, const Color(0xFFB9E4D2));
      expect(DarbColors.lime, const Color(0xFFC8F169));
      expect(DarbColors.danger, const Color(0xFFB94747));
      expect(DarbColors.success, const Color(0xFF287A50));
      expect(DarbColors.warning, const Color(0xFFB7791F));
      expect(DarbColors.info, const Color(0xFF356D9A));

      expect(DarbColors.canvas, const Color(0xFFF5F6F2));
      expect(DarbColors.surface, const Color(0xFFFFFFFF));
      expect(DarbColors.ink, const Color(0xFF17231F));
      expect(DarbColors.muted, const Color(0xFF77837D));
      expect(DarbColors.line, const Color(0xFFE4E9E3));
      expect(DarbColors.borderStrong, const Color(0xFFCBD5CE));

      expect(DarbColors.darkCanvas, const Color(0xFF0B1512));
      expect(DarbColors.darkSurface, const Color(0xFF13221D));
      expect(DarbColors.darkSurfaceElevated, const Color(0xFF1A2D26));
      expect(DarbColors.darkInk, const Color(0xFFF1F5F1));
      expect(DarbColors.darkMuted, const Color(0xFFA4B2AA));
      expect(DarbColors.darkLine, const Color(0xFF2A3B33));
      expect(DarbColors.darkPrimary, const Color(0xFFB9E4D2));
      expect(DarbColors.darkOnPrimary, const Color(0xFF102B26));

      final themeLight = DarbTheme.light;
      final themeDark = DarbTheme.dark;

      expect(themeLight.colorScheme.primary, DarbColors.forest);
      expect(themeLight.colorScheme.onPrimary, Colors.white);
      expect(themeLight.scaffoldBackgroundColor, DarbColors.canvas);

      expect(themeDark.colorScheme.primary, DarbColors.darkPrimary);
      expect(themeDark.colorScheme.onPrimary, DarbColors.darkOnPrimary);
      expect(themeDark.scaffoldBackgroundColor, DarbColors.darkCanvas);
      expect(themeDark.colorScheme.brightness, Brightness.dark);
    });

    test('provides standardized DarbSpace, DarbRadius, and DarbMotion scales', () {
      expect(DarbSpace.xxs, 4);
      expect(DarbSpace.md, 16);
      expect(DarbSpace.section, 40);
      expect(DarbRadius.hero, 36);
      expect(DarbRadius.pill, 999);

      expect(DarbMotion.press.inMilliseconds, 120);
      expect(DarbMotion.fast.inMilliseconds, 160);
      expect(DarbMotion.interactive.inMilliseconds, 220);
      expect(DarbMotion.tab.inMilliseconds, 240);
      expect(DarbMotion.standard.inMilliseconds, 260);
      expect(DarbMotion.route.inMilliseconds, 340);
      expect(DarbMotion.expressive.inMilliseconds, 420);
      expect(DarbMotion.staggerDelay(2).inMilliseconds, 110);
    });

    test('switches cleanly between Glass and Standard visual styles and ThemeModes',
        () async {
      final controller = DarbAppearanceController.instance;
      await controller.setVisualStyle(DarbVisualStyle.standard);
      expect(controller.isGlass, isFalse);

      await controller.setVisualStyle(DarbVisualStyle.glass);
      expect(controller.isGlass, isTrue);

      await controller.setThemeMode(ThemeMode.dark);
      expect(controller.themeMode, ThemeMode.dark);

      await controller.setThemeMode(ThemeMode.light);
      expect(controller.themeMode, ThemeMode.light);

      await controller.setThemeMode(ThemeMode.system);
    });
  });

  group('Syrian Phone Validation, Formatting & Localization', () {
    test('validates and normalizes Syrian phone numbers', () {
      expect(isValidSyrianPhone('0933123456'), isTrue);
      expect(isValidSyrianPhone('+963933123456'), isTrue);
      expect(isValidSyrianPhone('00963944556677'), isTrue);
      expect(isValidSyrianPhone('091234'), isFalse);
      expect(isValidSyrianPhone('0812345678'), isFalse);

      expect(normalizeSyrianPhone('0933123456'), '+963933123456');
      expect(normalizeSyrianPhone('944556677'), '+963944556677');
      expect(normalizeSyrianPhone('00963955112233'), '+963955112233');
    });

    test('formats Syrian phone input incrementally', () {
      final formatter = SyrianPhoneFormatter();
      final res = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '0933123456'),
      );
      expect(res.text, '0933 123 456');
    });

    test('supports Arabic, English, and Turkish localization including new flows',
        () {
      darbLocale.value = const Locale('ar');
      expect(dt('إلغاء الطلب'), 'إلغاء الطلب');
      expect(dt('الإشعارات'), 'الإشعارات');
      expect(formatDarbMoney(15000), '15,000 ل.س');

      darbLocale.value = const Locale('en');
      expect(dt('إلغاء الطلب'), 'Cancel order');
      expect(dt('الإشعارات'), 'Notifications');
      expect(dt('وضع عدم الاتصال — يتم عرض البيانات المحفوظة مؤقتاً'), 'Offline mode — showing cached data');
      expect(dt('حدد الموقع على خريطة دمشق'), 'Pin location on the map for دمشق');
      expect(dt('5 منتج متاح'), '5 products available');
      expect(formatDarbMoney(15000), '15,000 SYP');

      darbLocale.value = const Locale('tr');
      expect(dt('إلغاء الطلب'), 'Siparişi iptal et');
      expect(dt('الإشعارات'), 'Bildirimler');
      expect(dt('تحديث التطبيق'), 'Uygulamayı güncelle');
      expect(dt('3 منتج متاح'), '3 ürün mevcut');

      darbLocale.value = const Locale('ar');
    });

    testWidgets('DarbColors soft tokens adapt between light and dark themes',
        (tester) async {
      late Color lightDangerSoft;
      late Color darkDangerSoft;
      late Color lightWarningSoft;
      late Color darkWarningSoft;

      await tester.pumpWidget(
        Column(
          children: [
            Theme(
              data: DarbTheme.light,
              child: Builder(
                builder: (ctx) {
                  lightDangerSoft = DarbColors.dangerSoftOf(ctx);
                  lightWarningSoft = DarbColors.warningSoftOf(ctx);
                  return const SizedBox.shrink();
                },
              ),
            ),
            Theme(
              data: DarbTheme.dark,
              child: Builder(
                builder: (ctx) {
                  darkDangerSoft = DarbColors.dangerSoftOf(ctx);
                  darkWarningSoft = DarbColors.warningSoftOf(ctx);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      );

      expect(lightDangerSoft, DarbColors.dangerSoft);
      expect(darkDangerSoft, DarbColors.darkDangerSoft);
      expect(lightWarningSoft, DarbColors.warningSoft);
      expect(darkWarningSoft, DarbColors.darkWarningSoft);
    });
  });

  group('Widget & Motion Accessibility Smoke Tests', () {
    testWidgets('renders DarbGlassSurface in Glass mode without errors',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DarbTheme.light,
          home: Scaffold(
            appBar: const DarbGlassAppBar(title: 'دَرْب', subtitle: 'تجربة'),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                DarbMetricCard(
                  label: 'الرحلات المكتملة',
                  value: '42',
                  icon: Icons.route_rounded,
                ),
                SizedBox(height: 12),
                DarbStatusBadge(status: 'DELIVERED'),
                SizedBox(height: 8),
                DarbStatusBadge(status: 'WITHDRAWN'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('دَرْب'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('respects MediaQuery disableAnimations for DarbMotion.reduceMotion',
        (tester) async {
      late bool reduced;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              reduced = DarbMotion.reduceMotion(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(reduced, isTrue);
    });

    testWidgets('renders LoginScreen with dark vector map hero and untouched bottom card',
        (tester) async {
      darbLocale.value = const Locale('ar');
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: DarbApp(initialScreen: LoginScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(DarbLoginVectorMap), findsOneWidget);
      expect(find.text('دَرْب • DARB'), findsOneWidget);
      expect(find.text('أهلاً بك في دَرْب'), findsOneWidget);
      expect(find.text('طريقك الأسهل لاكتشاف المتاجر وطلب ما تحتاجه'), findsOneWidget);
      expect(find.text('سجّل الدخول برقم هاتفك'), findsOneWidget);
      expect(find.text('AR'), findsOneWidget);
    });
  });

  group('Phase 1 Motion & Global Navigation Components', () {
    testWidgets('DarbActionButton transitions idle -> loading -> success -> error',
        (tester) async {
      var tapCount = 0;
      var state = DarbActionState.idle;
      var errorTrigger = 0;

      late StateSetter outerSetState;
      await tester.pumpWidget(
        MaterialApp(
          theme: DarbTheme.light,
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) {
                  outerSetState = setState;
                  return DarbActionButton(
                    label: 'متابعة',
                    successLabel: 'تم بنجاح',
                    state: state,
                    errorTrigger: errorTrigger,
                    enableHaptics: false,
                    onPressed: () => tapCount++,
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('متابعة'), findsOneWidget);
      await tester.tap(find.text('متابعة'));
      await tester.pump();
      expect(tapCount, 1);

      outerSetState(() => state = DarbActionState.loading);
      await tester.pump(const Duration(milliseconds: 220));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(DarbActionButton));
      await tester.pump();
      expect(tapCount, 1);

      outerSetState(() => state = DarbActionState.success);
      await tester.pump(const Duration(milliseconds: 240));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('تم بنجاح'), findsOneWidget);

      outerSetState(() {
        state = DarbActionState.error;
        errorTrigger++;
      });
      await tester.pump(const Duration(milliseconds: 160));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('متابعة'), findsOneWidget);

      await tester.tap(find.text('متابعة'));
      await tester.pump();
      expect(tapCount, 2);
    });

    testWidgets('DarbGlassBottomNav selects destinations and renders badges',
        (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        DarbApp(
          initialScreen: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: const SizedBox.shrink(),
              bottomNavigationBar: DarbGlassBottomNav(
                selectedIndex: selected,
                onSelect: (index) => setState(() => selected = index),
                destinations: const [
                  DarbNavDestination(
                    label: 'الرئيسية',
                    icon: Icons.explore_outlined,
                    selectedIcon: Icons.explore_rounded,
                  ),
                  DarbNavDestination(
                    label: 'طلباتي',
                    icon: Icons.receipt_long_outlined,
                    selectedIcon: Icons.receipt_long_rounded,
                    badgeCount: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('الرئيسية'), findsOneWidget);
      expect(find.text('طلباتي'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      await tester.tap(find.text('طلباتي'));
      await tester.pump(const Duration(milliseconds: 260));
      expect(selected, 1);
    });

    testWidgets('DarbTabViewStack preserves tab child state across bidirectional jumps',
        (tester) async {
      var tabIndex = 0;
      late StateSetter outerSetState;

      await tester.pumpWidget(
        DarbApp(
          initialScreen: StatefulBuilder(
            builder: (context, setState) {
              outerSetState = setState;
              return Scaffold(
                body: DarbTabViewStack(
                  index: tabIndex,
                  children: const [
                    _CounterTestTab(label: 'تبويب 1'),
                    _CounterTestTab(label: 'تبويب 2'),
                    _CounterTestTab(label: 'تبويب 3'),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('تبويب 1: 0'));
      await tester.pump();
      expect(find.text('تبويب 1: 1'), findsOneWidget);

      outerSetState(() => tabIndex = 2);
      await tester.pump(const Duration(milliseconds: 260));
      await tester.tap(find.text('تبويب 3: 0'));
      await tester.pump();
      expect(find.text('تبويب 3: 1'), findsOneWidget);

      outerSetState(() => tabIndex = 1);
      await tester.pump(const Duration(milliseconds: 260));
      await tester.tap(find.text('تبويب 2: 0'));
      await tester.pump();
      expect(find.text('تبويب 2: 1'), findsOneWidget);

      outerSetState(() => tabIndex = 0);
      await tester.pump(const Duration(milliseconds: 260));
      expect(find.text('تبويب 1: 1'), findsOneWidget);
    });
  });
}

class _CounterTestTab extends StatefulWidget {
  const _CounterTestTab({required this.label});
  final String label;

  @override
  State<_CounterTestTab> createState() => _CounterTestTabState();
}

class _CounterTestTabState extends State<_CounterTestTab> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => setState(() => _count++),
        child: Text('${widget.label}: $_count'),
      ),
    );
  }
}
