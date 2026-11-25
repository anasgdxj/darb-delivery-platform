import 'dart:convert';

import 'package:darb/core/l10n/app_localizations.dart';
import 'package:darb/core/network/api_client.dart';
import 'package:darb/core/services/location_service.dart';
import 'package:darb/core/theme/darb_design_system.dart';
import 'package:darb/core/widgets/darb_city_scene.dart';
import 'package:darb/core/widgets/darb_components.dart';
import 'package:darb/core/widgets/darb_glass.dart';
import 'package:darb/core/widgets/darb_motion_components.dart';
import 'package:darb/features/account/account_screen.dart';
import 'package:darb/features/account/driver_application_screen.dart';
import 'package:darb/features/account/edit_profile_screen.dart';
import 'package:darb/features/account/settings_screen.dart';
import 'package:darb/features/account/vendor_application_screen.dart';
import 'package:darb/features/auth/login_hero_map.dart';
import 'package:darb/features/auth/login_screen.dart';
import 'package:darb/features/auth/onboarding_screen.dart';
import 'package:darb/features/customer/customer_home_screen.dart';
import 'package:darb/features/driver/driver_dashboard_screen.dart';
import 'package:darb/features/shell/app_shell.dart';
import 'package:darb/features/vendor/vendor_orders_screen.dart';
import 'package:darb/features/vendor/vendor_products_screen.dart';
import 'package:darb/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DAZREVO Design System 2026 & Brand Integrity', () {
    test('enforces exact DESIGN_SYSTEM.md 2026 light and dark semantic tokens', () {
      expect(DarbColors.forest, const Color(0xFF0B2F24));
      expect(DarbColors.primaryGreen, const Color(0xFF0D6E4E));
      expect(DarbColors.forestSoft, const Color(0xFF144435));
      expect(DarbColors.mint, const Color(0xFFA8EBC8));
      expect(DarbColors.lime, const Color(0xFFA7FF00));
      expect(DarbColors.limeInk, const Color(0xFF3E6800));
      expect(DarbColors.limeTint, const Color(0xFFE7FFAD));
      expect(DarbColors.violet, const Color(0xFF8A5CF6));
      expect(DarbColors.violetSoft, const Color(0xFFF1EBFF));
      expect(DarbColors.danger, const Color(0xFFCF3B3B));
      expect(DarbColors.success, const Color(0xFF17804B));
      expect(DarbColors.warning, const Color(0xFFC67A12));
      expect(DarbColors.info, const Color(0xFF1E6FA8));

      expect(DarbColors.canvas, const Color(0xFFF8FAF7));
      expect(DarbColors.surface, const Color(0xFFFFFFFF));
      expect(DarbColors.surfaceAlt, const Color(0xFFEDF2EC));
      expect(DarbColors.ink, const Color(0xFF0E221B));
      expect(DarbColors.muted, const Color(0xFF586E65));
      expect(DarbColors.line, const Color(0xFFD5DFD9));
      expect(DarbColors.borderStrong, const Color(0xFFB9C7BF));

      expect(DarbColors.darkCanvas, const Color(0xFF071A14));
      expect(DarbColors.darkSurface, const Color(0xFF0E281F));
      expect(DarbColors.darkSurfaceElevated, const Color(0xFF14352A));
      expect(DarbColors.darkSurfaceAlt, const Color(0xFF194033));
      expect(DarbColors.darkInk, const Color(0xFFF1F7F4));
      expect(DarbColors.darkMuted, const Color(0xFF9CB3A8));
      expect(DarbColors.darkLine, const Color(0xFF214438));
      expect(DarbColors.darkBorderStrong, const Color(0xFF325E4E));
      expect(DarbColors.darkPrimary, const Color(0xFFA7FF00));
      expect(DarbColors.darkOnPrimary, const Color(0xFF071A14));
      expect(DarbColors.darkViolet, const Color(0xFFA78BFA));
      expect(DarbColors.darkVioletSoft, const Color(0xFF251A45));

      final themeLight = DarbTheme.light;
      final themeDark = DarbTheme.dark;

      expect(themeLight.colorScheme.primary, DarbColors.primaryGreen);
      expect(themeLight.colorScheme.onPrimary, Colors.white);
      expect(themeLight.colorScheme.tertiary, DarbColors.violet);
      expect(themeLight.scaffoldBackgroundColor, DarbColors.canvas);

      expect(themeDark.colorScheme.primary, DarbColors.darkPrimary);
      expect(themeDark.colorScheme.onPrimary, DarbColors.darkOnPrimary);
      expect(themeDark.colorScheme.tertiary, DarbColors.darkViolet);
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
      expect(dt('سريع'), 'Fast');
      expect(dt('طلب متجر'), 'Store order');
      expect(formatDarbMoney(15000), '15,000 SYP');

      darbLocale.value = const Locale('tr');
      expect(dt('إلغاء الطلب'), 'Siparişi iptal et');
      expect(dt('الإشعارات'), 'Bildirimler');
      expect(dt('تحديث التطبيق'), 'Uygulamayı güncelle');
      expect(dt('3 منتج متاح'), '3 ürün mevcut');
      expect(dt('سريع'), 'Hızlı');

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
            appBar: const DarbGlassAppBar(title: 'دازريفو', subtitle: 'تجربة'),
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
      expect(find.text('دازريفو'), findsOneWidget);
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

    testWidgets('renders redesigned LoginScreen with geometric hero, step pill, and Google CTA',
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
      expect(find.byType(DarbBrandMark), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(find.text('دازريفو · DAZREVO'), findsOneWidget);
      expect(find.text('جولة تعريفية'), findsOneWidget);
      expect(find.text('أهلاً بك في دازريفو'), findsOneWidget);
      expect(find.text('طريقك الأسهل لاكتشاف المتاجر وطلب ما تحتاجه'), findsOneWidget);
      expect(find.text('سجّل الدخول برقم هاتفك'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.text('AR'), findsOneWidget);
      expect(find.text('المتابعة باستخدام Google'), findsOneWidget);
    });

    testWidgets('OnboardingScreen advances 3 DAZREVO slides and triggers completion callback',
        (tester) async {
      darbLocale.value = const Locale('ar');
      var finished = false;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: DarbApp(
            initialScreen: OnboardingScreen(
              onFinished: () => finished = true,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('دازريفو · DAZREVO'), findsOneWidget);
      expect(find.text('اطلب من متاجر مدينتك في ثوانٍ'), findsOneWidget);
      expect(find.text('التالي'), findsOneWidget);

      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
      expect(find.text('أرسل أغراضك بحرية مع عروض السائقين'), findsOneWidget);

      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
      expect(find.text('مساعد ذكي وتتبّع لحظي على الخريطة'), findsOneWidget);
      expect(find.text('ابدأ الآن'), findsOneWidget);

      await tester.tap(find.text('ابدأ الآن'));
      await tester.pump();
      expect(finished, isTrue);
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

  group('DAZREVO Design Evolution 2026 Widgets', () {
    testWidgets('DarbCitySceneCard renders abstract Neo artwork with zero city photos',
        (tester) async {
      darbLocale.value = const Locale('ar');
      var addressTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: DarbTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: DarbCitySceneCard(
                cityCode: 'damascus',
                cityName: 'دمشق',
                vendorCount: 7,
                activeAddressLabel: 'الكورنيش البحري',
                onTapAddresses: () => addressTapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Image), findsNothing);
      expect(find.text('دمشق'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('الكورنيش البحري'), findsOneWidget);

      await tester.tap(find.text('الكورنيش البحري'));
      await tester.pump();
      expect(addressTapped, isTrue);
    });

    testWidgets('DarbOrderTimeline renders store, peer, and cancelled timelines',
        (tester) async {
      darbLocale.value = const Locale('ar');

      await tester.pumpWidget(
        MaterialApp(
          theme: DarbTheme.dark,
          home: Scaffold(
            body: Column(
              children: const [
                DarbOrderTimeline(status: 'PREPARING'),
                SizedBox(height: 12),
                DarbOrderTimeline(status: 'PICKED_UP', isPeer: true),
                SizedBox(height: 12),
                DarbOrderTimeline(status: 'CANCELLED'),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('التحضير'), findsOneWidget);
      expect(find.text('في الطريق'), findsOneWidget);
      expect(find.text('تم إلغاء هذا الطلب'), findsOneWidget);
    });

    testWidgets('DarbInteractiveCard and DarbPulseDot honor Reduce Motion and taps',
        (tester) async {
      var cardTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: DarbTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: DarbInteractiveCard(
                onTap: () => cardTapped = true,
                child: const Row(
                  children: [
                    DarbPulseDot(active: true),
                    SizedBox(width: 8),
                    Text('بطاقة تفاعلية'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(DarbPulseDot), findsOneWidget);
      await tester.tap(find.text('بطاقة تفاعلية'));
      await tester.pump();
      expect(cardTapped, isTrue);
    });

    test('DarbElevation.glow creates soft colored shadow for light and dark themes', () {
      final lightGlow = DarbElevation.glow(DarbColors.forest, isDark: false);
      final darkGlow = DarbElevation.glow(DarbColors.forest, isDark: true);
      expect(lightGlow, hasLength(1));
      expect(darkGlow, hasLength(1));
      expect(lightGlow.first.blurRadius, greaterThan(0));
      expect(darkGlow.first.blurRadius, greaterThan(lightGlow.first.blurRadius));
    });

    testWidgets('DarbRouteConnector, DarbBentoActionCard, DarbShimmer, and DarbTypingDots render cleanly under Reduce Motion',
        (tester) async {
      var heroTapped = false;
      var glassTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: DarbTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const DarbRouteConnector(
                    pickupLabel: 'الاستلام',
                    pickupAddress: 'شارع الثورة · دمشق',
                    dropoffLabel: 'التسليم',
                    dropoffAddress: 'حي المالكي · شارع عبد المنعم رياض',
                    badgeText: '8,500 ل.س',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DarbBentoActionCard(
                          icon: Icons.local_shipping_rounded,
                          title: 'توصيل خاص',
                          subtitle: 'أرسل غرضاً سريعاً',
                          badge: 'سريع',
                          isHeroDark: true,
                          onTap: () => heroTapped = true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DarbBentoActionCard(
                          icon: Icons.auto_awesome_rounded,
                          title: 'اطلب بالكتابة',
                          subtitle: 'جهّز مسودتك فوراً',
                          isHeroDark: false,
                          onTap: () => glassTapped = true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const DarbShimmer(
                    child: SizedBox(height: 24, width: 140),
                  ),
                  const SizedBox(height: 12),
                  const DarbTypingDots(),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(DarbRouteConnector), findsOneWidget);
      expect(find.text('شارع الثورة · دمشق'), findsOneWidget);
      expect(find.text('حي المالكي · شارع عبد المنعم رياض'), findsOneWidget);
      expect(find.text('8,500 ل.س'), findsOneWidget);

      expect(find.byType(DarbBentoActionCard), findsNWidgets(2));
      expect(find.text('سريع'), findsOneWidget);

      expect(find.byType(DarbShimmer), findsOneWidget);
      expect(find.byType(DarbTypingDots), findsOneWidget);

      await tester.tap(find.text('توصيل خاص'));
      await tester.pump();
      expect(heroTapped, isTrue);

      await tester.tap(find.text('اطلب بالكتابة'));
      await tester.pump();
      expect(glassTapped, isTrue);
    });

    testWidgets('DarbActivityLedgerStrip displays 3 tabular metrics and fires onTap',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: DarbTheme.dark,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: DarbActivityLedgerStrip(
                title: 'ملخص النشاط والأرباح',
                primaryLabel: 'الأرباح المحققة',
                primaryValue: '125,000 ل.س',
                secondaryLabel: 'الرحلات المكتملة',
                secondaryValue: '18',
                tertiaryLabel: 'التقييم',
                tertiaryValue: '4.9',
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('ملخص النشاط والأرباح'), findsOneWidget);
      expect(find.text('125,000 ل.س'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(find.text('4.9'), findsOneWidget);

      await tester.tap(find.byType(DarbActivityLedgerStrip));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('Account Profile & Multi-Step Onboarding Wizards', () {
    testWidgets('EditProfileScreen validates name and submits UpdateProfileDto payload',
        (tester) async {
      darbLocale.value = const Locale('ar');
      Map<String, dynamic>? savedPayload;
      var refreshed = false;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: DarbApp(
            initialScreen: EditProfileScreen(
              skipInitialFetch: true,
              user: const {
                'id': 'u1',
                'name': 'أنس محمد',
                'phone': '+963933123456',
                'email': 'anas@darb.sy',
                'role': 'CUSTOMER',
                'locale': 'ar',
              },
              onRefreshUser: () async => refreshed = true,
              saveProfileOverride: (payload) async {
                savedPayload = payload;
                return {'id': 'u1', ...payload};
              },
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('تعديل الملف الشخصي'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'أنس الحمصي');
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('+963933123456'),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      expect(find.text('+963933123456'), findsOneWidget);
      expect(find.text('anas@darb.sy'), findsOneWidget);

      final saveBtn = find.text('حفظ التغييرات');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump(const Duration(milliseconds: 200));

      expect(savedPayload, {'name': 'أنس الحمصي', 'locale': 'ar'});
      expect(refreshed, isTrue);
    });

    testWidgets('DriverApplicationScreen walks through 5-step wizard and shows PENDING status',
        (tester) async {
      darbLocale.value = const Locale('ar');
      Map<String, dynamic>? submitted;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: DarbApp(
            initialScreen: DriverApplicationScreen(
              enableDraftCache: false,
              user: const {
                'id': 'u1',
                'name': 'خالد العلي',
                'phone': '+963944112233',
                'role': 'CUSTOMER',
              },
              onRefreshUser: () async {},
              loadCitiesOverride: () async => [
                {
                  'id': 'city-1',
                  'code': 'damascus',
                  'names': [
                    {'locale': 'ar', 'name': 'دمشق'},
                  ],
                },
              ],
              submitApplicationOverride: (payload) async {
                submitted = payload;
                return {'id': 'drv-1', 'status': 'PENDING'};
              },
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('1 / 5'), findsOneWidget);
      await tester.tap(find.text('متابعة'));
      await tester.pump();

      expect(find.text('2 / 5'), findsOneWidget);
      await tester.tap(find.text('سيارة'));
      await tester.pump();
      await tester.tap(find.text('متابعة'));
      await tester.pump();

      expect(find.text('3 / 5'), findsOneWidget);
      expect(find.text('دمشق'), findsOneWidget);
      await tester.tap(find.text('متابعة'));
      await tester.pump();

      expect(find.text('4 / 5'), findsOneWidget);
      for (final box in find.byType(Checkbox).evaluate()) {
        await tester.tap(find.byWidget(box.widget));
      }
      await tester.pump();
      await tester.tap(find.text('متابعة'));
      await tester.pump();

      expect(find.text('5 / 5'), findsOneWidget);
      await tester.tap(find.text('إرسال الطلب'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(submitted, {'cityId': 'city-1', 'vehicleType': 'CAR'});
      expect(find.text('تم استلام طلب انضمامك كسائق'), findsOneWidget);
    });

    testWidgets('VendorApplicationScreen shows status view when pending and submits 5-step wizard',
        (tester) async {
      darbLocale.value = const Locale('ar');

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: DarbApp(
            initialScreen: VendorApplicationScreen(
              enableDraftCache: false,
              enableInteractiveMap: false,
              user: const {
                'id': 'u2',
                'name': 'ليلى',
                'vendorApplication': 'PENDING',
              },
              onRefreshUser: () async {},
              loadCitiesOverride: () async => const [],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('طلب متجرك قيد المراجعة'), findsOneWidget);

      Map<String, dynamic>? vendorSubmitted;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: DarbApp(
            key: const ValueKey('vendor-form-app'),
            initialScreen: VendorApplicationScreen(
              enableDraftCache: false,
              enableInteractiveMap: false,
              user: const {
                'id': 'u3',
                'name': 'ليلى الشامي',
                'phone': '+963955001122',
                'role': 'CUSTOMER',
              },
              onRefreshUser: () async {},
              loadCitiesOverride: () async => [
                {
                  'id': 'city-2',
                  'code': 'aleppo',
                  'names': [
                    {'locale': 'ar', 'name': 'حلب'},
                  ],
                },
              ],
              submitApplicationOverride: (payload) async {
                vendorSubmitted = payload;
                return {'id': 'vnd-1', 'status': 'PENDING'};
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('1 / 5'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), 'متجر الشهباء');
      await tester.tap(find.text('حلويات'));
      await tester.pump();
      await tester.tap(find.text('متابعة'));
      await tester.pump();

      expect(find.text('2 / 5'), findsOneWidget);
      await tester.tap(find.text('متابعة'));
      await tester.pump();

      expect(find.text('3 / 5'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      final cityField = find.byWidgetPredicate((widget) => widget is DropdownButtonFormField);
      expect(cityField, findsOneWidget);
      await tester.tap(cityField);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('حلب').last);
      await tester.pump();
      await tester.tap(find.text('متابعة'));
      await tester.pump();

      expect(find.text('4 / 5'), findsOneWidget);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('متابعة'));
      await tester.pump();

      expect(find.text('5 / 5'), findsOneWidget);
      await tester.tap(find.text('إرسال الطلب'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(vendorSubmitted, {
        'name': 'متجر الشهباء',
        'type': 'حلويات',
        'cityId': 'city-2',
      });
      expect(find.text('تم استلام طلب انضمام متجرك'), findsOneWidget);
    });
  });

  group('Phase 0 Stability & Session Recovery', () {
    test('Api.restore handles secure storage exceptions gracefully on cold start',
        () async {
      _mockSecureStorage(<String, String>{}, failAll: true);
      addTearDown(() async {
        _clearSecureStorageMock();
        Api.instance.httpClientOverride = null;
        Api.instance.setSessionForTest();
      });

      final expiredBefore = Api.instance.sessionExpiredNotifier.value;
      await Api.instance.restore();

      expect(Api.instance.accessToken, isNull);
      expect(Api.instance.sessionInvalidated, isTrue);
      expect(Api.instance.sessionExpiredNotifier.value, expiredBefore);
    });

    test('mid-session 401 with revoked refresh clears session and emits expiry event',
        () async {
      final store = <String, String>{'refreshToken': 'revoked-refresh-token'};
      _mockSecureStorage(store);
      Api.instance.setSessionForTest(accessToken: 'expired-access-token');
      Api.instance.httpClientOverride = MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          return _utf8Response(
            jsonEncode({'message': 'Refresh token revoked'}),
            401,
          );
        }
        return _utf8Response(jsonEncode({'message': 'Unauthorized'}), 401);
      });
      addTearDown(() async {
        _clearSecureStorageMock();
        Api.instance.httpClientOverride = null;
        Api.instance.setSessionForTest();
      });

      final expiredBefore = Api.instance.sessionExpiredNotifier.value;
      await expectLater(
        Api.instance.get('/orders/mine'),
        throwsA(isA<ApiException>()),
      );

      expect(Api.instance.accessToken, isNull);
      expect(Api.instance.sessionInvalidated, isTrue);
      expect(store.containsKey('refreshToken'), isFalse);
      expect(Api.instance.sessionExpiredNotifier.value, expiredBefore + 1);
    });

    testWidgets(
        'DarbApp splash gate never freezes when storage fails and navigates to OnboardingScreen',
        (tester) async {
      darbLocale.value = const Locale('ar');
      _mockSecureStorage(<String, String>{}, failAll: true);
      Api.instance.setSessionForTest();
      addTearDown(() async {
        _clearSecureStorageMock();
        Api.instance.httpClientOverride = null;
        Api.instance.setSessionForTest();
      });

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: DarbApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'AppShell loads and routes CUSTOMER, DRIVER, VENDOR, and ADMIN roles from /auth/me',
        (tester) async {
      darbLocale.value = const Locale('ar');
      _mockSecureStorage(<String, String>{
        'accessToken': 'valid-token',
        'refreshToken': 'valid-refresh',
      });
      addTearDown(() async {
        DriverLocationReporter.stop();
        _clearSecureStorageMock();
        Api.instance.httpClientOverride = null;
        Api.instance.setSessionForTest();
      });

      final cases = <({String role, String subtitle, String firstTab})>[
        (role: 'CUSTOMER', subtitle: 'حساب عميل', firstTab: 'الرئيسية'),
        (role: 'DRIVER', subtitle: 'حساب سائق', firstTab: 'الطلبات المتاحة'),
        (role: 'VENDOR', subtitle: 'حساب تاجر', firstTab: 'طلبات المتجر'),
        (role: 'ADMIN', subtitle: 'إدارة دازريفو', firstTab: 'لوحة المؤشرات'),
      ];

      for (final item in cases) {
        Api.instance.setSessionForTest(accessToken: 'valid-token');
        Api.instance.httpClientOverride =
            _createRoleMockClient(role: item.role);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: DarbApp(
              key: ValueKey('role-app-${item.role}'),
              initialScreen: const AppShell(checkForUpdates: false),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.text(item.subtitle), findsOneWidget);
        expect(find.text(item.firstTab), findsWidgets);
        expect(tester.takeException(), isNull);

        DriverLocationReporter.stop();
      }
    });

    testWidgets(
        'AppShell recovers from transient /auth/me error via Retry and renders offline cached profile',
        (tester) async {
      darbLocale.value = const Locale('ar');
      final store = <String, String>{
        'accessToken': 'valid-token',
        'refreshToken': 'valid-refresh',
      };
      _mockSecureStorage(store);
      addTearDown(() async {
        _clearSecureStorageMock();
        Api.instance.httpClientOverride = null;
        Api.instance.setSessionForTest();
      });

      var failAuthMe = true;
      Api.instance.setSessionForTest(accessToken: 'valid-token');
      Api.instance.httpClientOverride = _createRoleMockClient(
        role: 'CUSTOMER',
        onAuthMe: () async {
          if (failAuthMe) {
            return _utf8Response(jsonEncode({'message': 'خطأ مؤقت بالخادم'}), 500);
          }
          return null;
        },
      );

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: DarbApp(initialScreen: AppShell(checkForUpdates: false)),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      expect(find.text('تعذر تحميل حسابك'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);

      failAuthMe = false;
      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('حساب عميل'), findsOneWidget);

      // Now simulate offline startup using the cached profile persisted above.
      Api.instance.setSessionForTest(accessToken: 'valid-token');
      Api.instance.httpClientOverride = _createRoleMockClient(
        role: 'CUSTOMER',
        onAuthMe: () async => throw http.ClientException('offline'),
      );

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: DarbApp(
            key: ValueKey('offline-app'),
            initialScreen: AppShell(checkForUpdates: false),
          ),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      expect(find.text('حساب عميل'), findsOneWidget);
      expect(
        find.text('وضع عدم الاتصال — يتم عرض البيانات المحفوظة مؤقتاً'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'AppShell redirects cleanly to LoginScreen when session expires mid-session',
        (tester) async {
      darbLocale.value = const Locale('ar');
      _mockSecureStorage(<String, String>{
        'accessToken': 'valid-token',
        'refreshToken': 'valid-refresh',
      });
      Api.instance.setSessionForTest(accessToken: 'valid-token');
      Api.instance.httpClientOverride = _createRoleMockClient(role: 'CUSTOMER');
      addTearDown(() async {
        _clearSecureStorageMock();
        Api.instance.httpClientOverride = null;
        Api.instance.setSessionForTest();
      });

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: DarbApp(initialScreen: AppShell(checkForUpdates: false)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('حساب عميل'), findsOneWidget);

      Api.instance.sessionExpiredNotifier.value++;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'CustomerHomeScreen keeps Peer Delivery and AI cards visible when /vendors fails',
        (tester) async {
      darbLocale.value = const Locale('ar');
      _mockSecureStorage(<String, String>{});
      Api.instance.setSessionForTest(accessToken: 'valid-token');
      Api.instance.httpClientOverride = _createRoleMockClient(
        role: 'CUSTOMER',
        failVendors: true,
      );
      addTearDown(() async {
        _clearSecureStorageMock();
        Api.instance.httpClientOverride = null;
        Api.instance.setSessionForTest();
      });

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: DarbApp(
            initialScreen: Scaffold(
              body: CustomerHomeScreen(
                user: {'id': 'u1', 'name': 'أنس', 'role': 'CUSTOMER'},
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      expect(find.text('إرسال غرض مستقل'), findsOneWidget);
      expect(find.text('المساعد الذكي'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('إعادة المحاولة'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('إعادة المحاولة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'VendorOrdersScreen and VendorProductsScreen handle null or PENDING vendor profiles cleanly',
        (tester) async {
      darbLocale.value = const Locale('ar');
      _mockSecureStorage(<String, String>{});
      Api.instance.setSessionForTest(accessToken: 'valid-token');
      var vendorOrdersCalls = 0;
      Api.instance.httpClientOverride = MockClient((request) async {
        if (request.url.path.endsWith('/vendors/mine')) {
          return _utf8Response('null', 200);
        }
        if (request.url.path.endsWith('/orders/vendor')) {
          vendorOrdersCalls++;
          return _utf8Response('[]', 200);
        }
        return _utf8Response('[]', 200);
      });
      addTearDown(() async {
        _clearSecureStorageMock();
        Api.instance.httpClientOverride = null;
        Api.instance.setSessionForTest();
      });

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: DarbApp(initialScreen: Scaffold(body: VendorOrdersScreen())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(vendorOrdersCalls, 0);
      expect(
        find.text('ملف المتجر غير مكتمل بعد. تواصل مع الإدارة أو أعد المحاولة.'),
        findsOneWidget,
      );
      expect(find.text('إعادة المحاولة'), findsOneWidget);

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: DarbApp(
            key: ValueKey('vendor-products-null'),
            initialScreen: Scaffold(body: VendorProductsScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text('ملف المتجر غير مكتمل بعد. تواصل مع الإدارة أو أعد المحاولة.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      Api.instance.httpClientOverride = MockClient((request) async {
        if (request.url.path.endsWith('/vendors/mine')) {
          return _utf8Response(
            jsonEncode({'id': 'v1', 'status': 'PENDING'}),
            200,
          );
        }
        return _utf8Response('[]', 200);
      });

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: DarbApp(
            key: ValueKey('vendor-orders-pending'),
            initialScreen: Scaffold(body: VendorOrdersScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('طلب متجرك قيد المراجعة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'DriverDashboardScreen handles REJECTED status and non-fatal stats failure cleanly',
        (tester) async {
      darbLocale.value = const Locale('ar');
      _mockSecureStorage(<String, String>{});
      Api.instance.setSessionForTest(accessToken: 'valid-token');
      Api.instance.httpClientOverride = MockClient((request) async {
        if (request.url.path.endsWith('/drivers/me')) {
          return _utf8Response(
            jsonEncode({
              'id': 'drv-1',
              'status': 'REJECTED',
              'isOnline': false,
              'vehicleType': 'CAR',
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/drivers/stats')) {
          return _utf8Response(
            jsonEncode({'message': 'إحصائيات غير متوفرة حالياً'}),
            404,
          );
        }
        return _utf8Response('[]', 200);
      });
      addTearDown(() async {
        DriverLocationReporter.stop();
        _clearSecureStorageMock();
        Api.instance.httpClientOverride = null;
        Api.instance.setSessionForTest();
      });

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: DarbApp(
            initialScreen: Scaffold(body: DriverDashboardScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('يتطلب طلب السائق مراجعة الإدارة'), findsOneWidget);
      expect(find.text('REJECTED'), findsOneWidget);
      expect(find.text('إحصائيات غير متوفرة حالياً'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'AppShell renders without overflow on 320px narrow viewport in Dark Mode and EN/TR locales',
        (tester) async {
      _mockSecureStorage(<String, String>{
        'accessToken': 'valid-token',
        'refreshToken': 'valid-refresh',
      });
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await DarbAppearanceController.instance.setThemeMode(ThemeMode.system);
        darbLocale.value = const Locale('ar');
        _clearSecureStorageMock();
        Api.instance.httpClientOverride = null;
        Api.instance.setSessionForTest();
      });

      await DarbAppearanceController.instance.setThemeMode(ThemeMode.dark);

      for (final lang in ['en', 'tr']) {
        darbLocale.value = Locale(lang);
        Api.instance.setSessionForTest(accessToken: 'valid-token');
        Api.instance.httpClientOverride = _createRoleMockClient(
          role: 'CUSTOMER',
          localeOverride: lang,
        );

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: DarbApp(
              key: ValueKey('responsive-$lang'),
              initialScreen: const AppShell(checkForUpdates: false),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.text(lang == 'en' ? 'Customer account' : 'Müşteri hesabı'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('Settings, Personalization & Accessibility Transformation', () {
    test('DarbAppearanceController persists and resets accessibility and notification prefs', () async {
      final store = <String, String>{};
      _mockSecureStorage(store);
      addTearDown(() async {
        await DarbAppearanceController.instance
            .resetAccessibilityAndNotifications();
        await DarbAppearanceController.instance.setThemeMode(ThemeMode.system);
        await DarbAppearanceController.instance
            .setVisualStyle(DarbVisualStyle.glass);
        _clearSecureStorageMock();
      });

      final ctrl = DarbAppearanceController.instance;
      await ctrl.resetAccessibilityAndNotifications();

      await ctrl.setTextScale(1.40);
      expect(ctrl.textScale, closeTo(1.25, 0.001));
      await ctrl.setTextScale(0.70);
      expect(ctrl.textScale, closeTo(0.90, 0.001));
      await ctrl.setTextScale(1.12);

      await ctrl.setReduceMotionOverride(true);
      await ctrl.setHapticsEnabled(false);
      await ctrl.setInAppBannersEnabled(false);
      await ctrl.setOrderAlertsEnabled(false);
      await ctrl.setPromoAlertsEnabled(false);

      expect(store['darb_text_scale'], '1.12');
      expect(store['darb_reduce_motion'], 'true');
      expect(store['darb_haptics_enabled'], 'false');
      expect(store['darb_in_app_banners'], 'false');
      expect(store['darb_order_alerts'], 'false');
      expect(store['darb_promo_alerts'], 'false');

      await ctrl.resetAccessibilityAndNotifications();
      expect(ctrl.textScale, 1.0);
      expect(ctrl.reduceMotionOverride, isFalse);
      expect(ctrl.hapticsEnabled, isTrue);
      expect(ctrl.inAppBannersEnabled, isTrue);
      expect(ctrl.orderAlertsEnabled, isTrue);
      expect(ctrl.promoAlertsEnabled, isTrue);

      store['darb_reduce_motion'] = 'true';
      store['darb_text_scale'] = '1.22';
      await ctrl.restore();
      expect(ctrl.reduceMotionOverride, isTrue);
      expect(ctrl.textScale, closeTo(1.22, 0.001));
    });

    testWidgets('DarbApp propagates textScale and DarbMotion honors reduceMotionOverride', (tester) async {
      _mockSecureStorage(<String, String>{});
      addTearDown(() async {
        await DarbAppearanceController.instance
            .resetAccessibilityAndNotifications();
        _clearSecureStorageMock();
      });

      final ctrl = DarbAppearanceController.instance;
      await ctrl.resetAccessibilityAndNotifications();
      await ctrl.setTextScale(1.22);
      await ctrl.setReduceMotionOverride(true);

      double? capturedScale;
      bool? capturedReduceMotion;

      await tester.pumpWidget(
        DarbApp(
          initialScreen: Builder(
            builder: (context) {
              capturedScale = MediaQuery.textScalerOf(context).scale(10);
              capturedReduceMotion = DarbMotion.reduceMotion(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();

      expect(capturedScale, closeTo(12.2, 0.05));
      expect(capturedReduceMotion, isTrue);
    });

    testWidgets('SettingsScreen renders grouped sections cleanly on 320px Dark Mode across AR/EN/TR', (tester) async {
      _mockSecureStorage(<String, String>{});
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await DarbAppearanceController.instance
            .resetAccessibilityAndNotifications();
        await DarbAppearanceController.instance.setThemeMode(ThemeMode.system);
        darbLocale.value = const Locale('ar');
        _clearSecureStorageMock();
      });

      await DarbAppearanceController.instance.setThemeMode(ThemeMode.dark);

      for (final entry in const [
        ('ar', 'الإعدادات والتخصيص', 'إمكانية الوصول والحركة'),
        ('en', 'Settings & Personalization', 'Accessibility & Motion'),
        ('tr', 'Ayarlar ve Kişiselleştirme', 'Erişilebilirlik ve Hareket'),
      ]) {
        darbLocale.value = Locale(entry.$1);
        await tester.pumpWidget(
          DarbApp(
            key: ValueKey('settings-${entry.$1}'),
            initialScreen: SettingsScreen(
              user: const {
                'id': 'u-1',
                'name': 'Anas',
                'phone': '+963933123456',
                'role': 'CUSTOMER',
              },
              onRefreshUser: () async {},
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text(entry.$2), findsOneWidget);
        expect(find.text(entry.$3), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('SettingsScreen handles text size, reduce motion, language Save/Cancel/Error, notification sync, and cache clear', (tester) async {
      _mockSecureStorage(<String, String>{});
      tester.view.physicalSize = const Size(412, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await DarbAppearanceController.instance
            .resetAccessibilityAndNotifications();
        darbLocale.value = const Locale('ar');
        _clearSecureStorageMock();
      });

      await DarbAppearanceController.instance.resetAccessibilityAndNotifications();
      darbLocale.value = const Locale('ar');

      var failLocaleSave = true;
      String? savedLocale;
      var cacheCleared = false;

      await tester.pumpWidget(
        DarbApp(
          initialScreen: SettingsScreen(
            user: const {
              'id': 'u-1',
              'name': 'أنس',
              'phone': '+963933123456',
              'role': 'CUSTOMER',
            },
            onRefreshUser: () async {},
            saveLocaleOverride: (locale) async {
              if (failLocaleSave) {
                throw ApiException('فشل حفظ اللغة مؤقتاً', statusCode: 500);
              }
              savedLocale = locale;
            },
            syncNotificationsOverride: () async => null,
            clearCacheOverride: () async {
              cacheCleared = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Language modal: open -> pick English -> error state -> retry success
      await tester.tap(find.text('لغة التطبيق'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pump();
      await tester.tap(find.text('حفظ اللغة'));
      await tester.pumpAndSettle();
      expect(find.text('فشل حفظ اللغة مؤقتاً'), findsOneWidget);

      failLocaleSave = false;
      await tester.tap(find.text('حفظ اللغة'));
      await tester.pumpAndSettle();
      expect(savedLocale, 'en');
      expect(darbLocale.value.languageCode, 'en');
      expect(find.text('App language saved'), findsOneWidget);

      // Text scale ChoiceChip
      final largeChip = find.widgetWithText(ChoiceChip, 'Large');
      await tester.ensureVisible(largeChip);
      await tester.tap(largeChip);
      await tester.pumpAndSettle();
      expect(DarbAppearanceController.instance.textScale, closeTo(1.12, 0.01));

      // Reduce Motion toggle
      final reduceTile = find.text('Reduce motion & transitions');
      await tester.ensureVisible(reduceTile);
      await tester.tap(reduceTile);
      await tester.pumpAndSettle();
      expect(DarbAppearanceController.instance.reduceMotionOverride, isTrue);

      // Sync device notifications
      final syncTile = find.text('Sync device push notifications');
      await tester.ensureVisible(syncTile);
      final syncTileSurface = find.ancestor(
        of: syncTile,
        matching: find.byType(DarbSettingsTile),
      );
      await tester.tap(syncTileSurface);
      await tester.pumpAndSettle();
      // Clear temporary cache dialog -> confirm
      await tester.drag(find.byType(ListView).first, const Offset(0, 1200));
      await tester.pumpAndSettle();
      expect(find.text('Notification sync updated for this device'), findsOneWidget);

      final clearTile = find.text('Clear cached data');
      await tester.ensureVisible(clearTile);
      await tester.tap(clearTile);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear cache'));
      await tester.pumpAndSettle();
      expect(cacheCleared, isTrue);
      expect(find.text('Cached data cleared successfully'), findsOneWidget);
    });

    testWidgets('AccountScreen renders grouped sections and navigates to SettingsScreen', (tester) async {
      _mockSecureStorage(<String, String>{});
      addTearDown(() async {
        await DarbAppearanceController.instance
            .resetAccessibilityAndNotifications();
        darbLocale.value = const Locale('ar');
        _clearSecureStorageMock();
        Api.instance.httpClientOverride = null;
        Api.instance.setSessionForTest();
      });

      darbLocale.value = const Locale('ar');
      Api.instance.setSessionForTest(accessToken: 'valid-token');
      Api.instance.httpClientOverride = _createRoleMockClient(role: 'CUSTOMER');

      await tester.pumpWidget(
        DarbApp(
          initialScreen: AccountScreen(
            user: const {
              'id': 'u-1',
              'name': 'أنس',
              'phone': '+963933123456',
              'role': 'CUSTOMER',
            },
            onRefreshUser: () async {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('الحساب والخدمات'), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(find.text('التخصيص واللغة'), findsOneWidget);

      final settingsTile = find.text('الإعدادات والتخصيص');
      await tester.ensureVisible(settingsTile);
      await tester.tap(settingsTile);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('إمكانية الوصول والحركة'), findsOneWidget);
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

void _mockSecureStorage(Map<String, String> store, {bool failAll = false}) {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
    if (failAll) {
      throw PlatformException(
        code: 'STORAGE_UNAVAILABLE',
        message: 'Keystore unavailable',
      );
    }
    final args =
        (call.arguments as Map?)?.cast<Object?, Object?>() ?? const {};
    final key = args['key']?.toString();
    switch (call.method) {
      case 'read':
        return key == null ? null : store[key];
      case 'write':
        if (key != null) store[key] = args['value']?.toString() ?? '';
        return null;
      case 'delete':
        if (key != null) store.remove(key);
        return null;
      case 'readAll':
        return Map<String, String>.from(store);
      case 'deleteAll':
        store.clear();
        return null;
      case 'containsKey':
        return key != null && store.containsKey(key);
      default:
        return null;
    }
  });
}

void _clearSecureStorageMock() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null);
}

http.Response _utf8Response(String body, int statusCode) =>
    http.Response.bytes(
      utf8.encode(body),
      statusCode,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

MockClient _createRoleMockClient({
  required String role,
  String? localeOverride,
  bool failVendors = false,
  Future<http.Response?> Function()? onAuthMe,
}) {
  return MockClient((request) async {
    final path = request.url.path;

    if (path.endsWith('/auth/me')) {
      if (onAuthMe != null) {
        final custom = await onAuthMe();
        if (custom != null) return custom;
      }
      return _utf8Response(
        jsonEncode({
          'id': 'u-$role',
          'name': 'أنس',
          'phone': '+963933123456',
          'role': role,
          'locale': localeOverride ?? 'ar',
        }),
        200,
      );
    }

    if (path.endsWith('/auth/logout')) {
      return _utf8Response('{}', 200);
    }

    if (path.endsWith('/notifications')) {
      return _utf8Response(
        jsonEncode({'items': <Object>[], 'unreadCount': 0}),
        200,
      );
    }

    if (path.endsWith('/cities')) {
      return _utf8Response(
        jsonEncode([
          {
            'id': 'city-1',
            'code': 'damascus',
            'names': [
              {'locale': 'ar', 'name': 'دمشق'},
              {'locale': 'en', 'name': 'Damascus'},
              {'locale': 'tr', 'name': 'Şam'},
            ],
          },
        ]),
        200,
      );
    }

    if (path.endsWith('/vendors')) {
      if (failVendors) {
        return _utf8Response(jsonEncode({'message': 'خطأ مؤقت بالخادم'}), 500);
      }
      return _utf8Response('[]', 200);
    }

    if (path.endsWith('/vendors/mine')) {
      return _utf8Response(
        jsonEncode({
          'id': 'v-1',
          'status': 'APPROVED',
          'isOpen': true,
          'translations': [
            {'locale': 'ar', 'name': 'متجر تجريبي', 'description': ''},
          ],
        }),
        200,
      );
    }

    if (path.endsWith('/drivers/me')) {
      return _utf8Response(
        jsonEncode({
          'id': 'd-1',
          'status': 'PENDING',
          'isOnline': false,
          'vehicleType': 'MOTORCYCLE',
        }),
        200,
      );
    }

    if (path.endsWith('/drivers/stats') ||
        path.endsWith('/vendors/mine/stats') ||
        path.endsWith('/admin/stats') ||
        path.endsWith('/admin/settings')) {
      return _utf8Response('{}', 200);
    }

    if (path.endsWith('/admin/orders')) {
      return _utf8Response(jsonEncode({'items': <Object>[]}), 200);
    }

    return _utf8Response('[]', 200);
  });
}
