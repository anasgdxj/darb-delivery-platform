import 'dart:convert';

import 'package:darb/core/l10n/app_localizations.dart';
import 'package:darb/core/network/api_client.dart';
import 'package:darb/core/services/location_service.dart';
import 'package:darb/core/services/notifications_service.dart';
import 'package:darb/core/theme/darb_design_system.dart';
import 'package:darb/core/widgets/darb_city_scene.dart';
import 'package:darb/core/widgets/darb_components.dart';
import 'package:darb/core/widgets/darb_copy_order_number_button.dart';
import 'package:darb/core/widgets/darb_glass.dart';
import 'package:darb/core/widgets/darb_motion_components.dart';
import 'package:darb/core/widgets/darb_spatial_primitives.dart';
import 'package:darb/features/account/account_screen.dart';
import 'package:darb/features/account/ai_role_assistant_screen.dart';
import 'package:darb/features/account/driver_application_screen.dart';
import 'package:darb/features/account/edit_profile_screen.dart';
import 'package:darb/features/account/settings_screen.dart';
import 'package:darb/features/account/vendor_application_screen.dart';
import 'package:darb/features/admin/admin_dashboard_screen.dart';
import 'package:darb/features/auth/login_hero_map.dart';
import 'package:darb/features/auth/login_screen.dart';
import 'package:darb/features/auth/onboarding_screen.dart';
import 'package:darb/features/customer/addresses_screen.dart';
import 'package:darb/features/customer/ai_order_assistant_screen.dart';
import 'package:darb/features/customer/checkout_screen.dart';
import 'package:darb/features/customer/customer_home_screen.dart';
import 'package:darb/features/driver/driver_dashboard_screen.dart';
import 'package:darb/features/driver/driver_orders_screen.dart';
import 'package:darb/features/notifications/notifications_screen.dart';
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

  group('Order reference copy action', () {
    testWidgets('copies a trimmed order number and confirms the action',
        (tester) async {
      final clipboardCalls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardCalls.add(call);
          }
          return null;
        },
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );

      darbLocale.value = const Locale('ar');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DarbCopyOrderNumberButton(
              value: '  DRB-2026-0042  ',
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('نسخ رقم الطلب'));
      await tester.pump();

      expect(clipboardCalls, hasLength(1));
      expect(
        clipboardCalls.single.arguments,
        {'text': 'DRB-2026-0042'},
      );
      expect(find.text('تم نسخ رقم الطلب'), findsOneWidget);
    });

    testWidgets('does not render a copy action for an empty order number',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DarbCopyOrderNumberButton(value: '   '),
          ),
        ),
      );

      expect(find.byType(IconButton), findsNothing);
    });
  });

  group('DAZREVO Design System 2026 & Brand Integrity', () {
    test('enforces exact DESIGN_SYSTEM.md 2026 light and dark semantic tokens', () {
      expect(DarbColors.forest, const Color(0xFF14171D));
      expect(DarbColors.primaryGreen, const Color(0xFF8A651F));
      expect(DarbColors.forestSoft, const Color(0xFF1E222B));
      expect(DarbColors.mint, const Color(0xFFE7D3A3));
      expect(DarbColors.lime, const Color(0xFFD6B46C));
      expect(DarbColors.limeInk, const Color(0xFF6B4F1A));
      expect(DarbColors.limeTint, const Color(0xFFF6EFE0));
      expect(DarbColors.violet, const Color(0xFF1D7A6E));
      expect(DarbColors.violetSoft, const Color(0xFFE8F5F3));
      expect(DarbColors.danger, const Color(0xFFC83E3B));
      expect(DarbColors.success, const Color(0xFF1C7C54));
      expect(DarbColors.warning, const Color(0xFFB87014));
      expect(DarbColors.info, const Color(0xFF2364AA));

      expect(DarbColors.canvas, const Color(0xFFFAF9F6));
      expect(DarbColors.surface, const Color(0xFFFFFFFF));
      expect(DarbColors.surfaceAlt, const Color(0xFFF2EFE9));
      expect(DarbColors.ink, const Color(0xFF141413));
      expect(DarbColors.muted, const Color(0xFF636059));
      expect(DarbColors.line, const Color(0xFFE5E0D6));
      expect(DarbColors.borderStrong, const Color(0xFFCEC7BA));

      expect(DarbColors.darkCanvas, const Color(0xFF0C0D0F));
      expect(DarbColors.darkSurface, const Color(0xFF14161A));
      expect(DarbColors.darkSurfaceElevated, const Color(0xFF1B1E24));
      expect(DarbColors.darkSurfaceAlt, const Color(0xFF232730));
      expect(DarbColors.darkInk, const Color(0xFFF5F3EE));
      expect(DarbColors.darkMuted, const Color(0xFFA39E93));
      expect(DarbColors.darkLine, const Color(0xFF262A33));
      expect(DarbColors.darkBorderStrong, const Color(0xFF3A404D));
      expect(DarbColors.darkPrimary, const Color(0xFFD6B46C));
      expect(DarbColors.darkOnPrimary, const Color(0xFF0C0D0F));
      expect(DarbColors.darkViolet, const Color(0xFF3FD1BE));
      expect(DarbColors.darkVioletSoft, const Color(0xFF112926));

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
      expect(dt('نسخ رقم الطلب'), 'Copy order number');
      expect(dt('تم نسخ رقم الطلب'), 'Order number copied');
      expect(dt('تعذر نسخ رقم الطلب'), 'Could not copy order number');
      expect(dt('وضع عدم الاتصال — يتم عرض البيانات المحفوظة مؤقتاً'), 'Offline mode — showing cached data');
      expect(dt('حدد الموقع على خريطة دمشق'), 'Pin location on the map for دمشق');
      expect(dt('5 منتج متاح'), '5 products available');
      expect(dt('سريع'), 'Fast');
      expect(dt('طلب متجر'), 'Store order');
      expect(formatDarbMoney(15000), '15,000 SYP');

      darbLocale.value = const Locale('tr');
      expect(dt('إلغاء الطلب'), 'Siparişi iptal et');
      expect(dt('الإشعارات'), 'Bildirimler');
      expect(dt('نسخ رقم الطلب'), 'Sipariş numarasını kopyala');
      expect(dt('تم نسخ رقم الطلب'), 'Sipariş numarası kopyalandı');
      expect(dt('تعذر نسخ رقم الطلب'), 'Sipariş numarası kopyalanamadı');
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
      final carOption = find.text('سيارة');
      await tester.ensureVisible(carOption);
      await tester.tap(carOption);
      await tester.pump();
      await tester.tap(find.text('متابعة'));
      await tester.pump();

      expect(find.text('3 / 5'), findsOneWidget);
      expect(find.text('دمشق'), findsOneWidget);
      await tester.tap(find.text('متابعة'));
      await tester.pump();

      expect(find.text('4 / 5'), findsOneWidget);
      final consentCheckboxes = find.byType(Checkbox);
      for (var index = 0; index < consentCheckboxes.evaluate().length; index++) {
        final checkbox = consentCheckboxes.at(index);
        await tester.ensureVisible(checkbox);
        await tester.pump();
        await tester.tap(checkbox, warnIfMissed: false);
        await tester.pump();
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

        expect(find.text(item.subtitle), findsWidgets);
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

      expect(find.text('يتطلب طلب السائق مراجعة الإدارة'), findsWidgets);
      expect(find.text('REJECTED'), findsOneWidget);
      expect(find.text('إحصائيات غير متوفرة حالياً'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'DriverDashboardScreen filters vendor, shopping, and peer orders by backend type',
        (tester) async {
      darbLocale.value = const Locale('ar');
      _mockSecureStorage(<String, String>{});
      Api.instance.setSessionForTest(accessToken: 'valid-token');
      Api.instance.httpClientOverride = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/drivers/me')) {
          return _utf8Response(
            jsonEncode({
              'id': 'drv-1',
              'status': 'APPROVED',
              'isOnline': true,
              'vehicleType': 'MOTORCYCLE',
            }),
            200,
          );
        }
        if (path.endsWith('/drivers/stats')) {
          return _utf8Response(jsonEncode({}), 200);
        }
        if (path.endsWith('/orders/driver/available')) {
          return _utf8Response(
            jsonEncode([
              {
                'id': 'vendor-1',
                'type': 'VENDOR_ORDER',
                'status': 'READY',
                'vendor': {'translations': [{'name': 'متجر تجريبي'}]},
                'deliveryOffers': [],
                'total': '12000',
                'currency': 'SYP',
                'address': {'details': 'حلب - العزيزية'},
              },
              {
                'id': 'shopping-1',
                'type': 'SHOPPING_DELIVERY',
                'status': 'PENDING',
                'shoppingItemName': 'دواء',
                'shoppingDescription': 'شراء دواء من الصيدلية',
                'shoppingStoreName': 'صيدلية تجريبية',
                'shoppingStoreAddress': 'حلب',
                'deliveryOffers': [],
                'address': {'details': 'حلب - الجميلية'},
              },
              {
                'id': 'peer-1',
                'type': 'PEER_DELIVERY',
                'status': 'PENDING',
                'pickupAddress': 'حلب - الفرقان',
                'deliveryOffers': [],
                'address': {'details': 'حلب - الشهباء'},
              },
            ]),
            200,
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
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('متجر تجريبي'), findsOneWidget);
      expect(find.text('شراء وتوصيل: دواء'), findsOneWidget);
      expect(find.text('طلب توصيل مستقل'), findsOneWidget);

      await tester.tap(find.text('طلب متجر'));
      await tester.pump();
      expect(find.text('متجر تجريبي'), findsOneWidget);
      expect(find.text('شراء وتوصيل: دواء'), findsNothing);
      expect(find.text('طلب توصيل مستقل'), findsNothing);

      await tester.tap(find.text('شراء وتوصيل'));
      await tester.pump();
      expect(find.text('شراء وتوصيل: دواء'), findsOneWidget);
      expect(find.text('متجر تجريبي'), findsNothing);
      expect(find.text('طلب توصيل مستقل'), findsNothing);

      await tester.tap(find.text('توصيل مستقل'));
      await tester.pump();
      expect(find.text('طلب توصيل مستقل'), findsOneWidget);
      expect(find.text('متجر تجريبي'), findsNothing);
      expect(find.text('شراء وتوصيل: دواء'), findsNothing);
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
      final syncTileWidget = tester.widget<DarbSettingsTile>(syncTileSurface);
      expect(syncTileWidget.enabled, isTrue);
      expect(syncTileWidget.onTap, isNotNull);
      syncTileWidget.onTap!.call();
      await tester.pumpAndSettle();
      // Clear temporary cache dialog -> confirm
      expect(find.text('Notification sync updated for this device'), findsOneWidget);

      await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
      await tester.pumpAndSettle();
      final clearTile = find.text('Clear cached data');
      await tester.ensureVisible(clearTile);
      final clearTileSurface = find.ancestor(
        of: clearTile,
        matching: find.byType(DarbSettingsTile),
      );
      final clearTileWidget = tester.widget<DarbSettingsTile>(clearTileSurface);
      expect(clearTileWidget.enabled, isTrue);
      expect(clearTileWidget.onTap, isNotNull);
      clearTileWidget.onTap!.call();
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

  group('DAZREVO iPadOS 18 Liquid Glass & Adaptive Layout', () {
    testWidgets('DarbAdaptiveLayout evaluates phone, tablet, and desktop breakpoints',
        (tester) async {
      late bool phoneTablet;
      late bool tabletTablet;
      late bool desktopFlag;
      late int narrowMetricCols;
      late int wideMetricCols;
      late int contentColsWide;

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            phoneTablet = DarbAdaptiveLayout.isTablet(context);
            narrowMetricCols =
                DarbAdaptiveLayout.metricColumns(context, availableWidth: 358);
            return const SizedBox.shrink();
          },
        ),
      );

      tester.view.physicalSize = const Size(1120, 800);
      await tester.pumpWidget(
        Builder(
          key: const ValueKey('tablet-metrics'),
          builder: (context) {
            tabletTablet = DarbAdaptiveLayout.isTablet(context);
            desktopFlag = DarbAdaptiveLayout.isDesktop(context);
            wideMetricCols =
                DarbAdaptiveLayout.metricColumns(context, availableWidth: 840);
            contentColsWide =
                DarbAdaptiveLayout.contentColumns(context, availableWidth: 840);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(phoneTablet, isFalse);
      expect(narrowMetricCols, 2);
      expect(tabletTablet, isTrue);
      expect(desktopFlag, isTrue);
      expect(wideMetricCols, 4);
      expect(contentColsWide, 2);
    });

    testWidgets('DarbOtpPinPreview displays 6 cells and entered digits',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DarbTheme.light,
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: DarbOtpPinPreview(digits: '482'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('4'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('•'), findsNWidgets(3));
    });

    testWidgets('DarbContextMenuButton opens popup menu and triggers callback',
        (tester) async {
      String? picked;
      await tester.pumpWidget(
        MaterialApp(
          theme: DarbTheme.light,
          home: Scaffold(
            body: Center(
              child: DarbContextMenuButton<String>(
                onSelected: (v) => picked = v,
                items: const [
                  DarbContextMenuAction(
                    value: 'refresh',
                    label: 'تحديث',
                    icon: Icons.refresh_rounded,
                  ),
                  DarbContextMenuAction(
                    value: 'vehicle',
                    label: 'تحديث المركبة',
                    icon: Icons.two_wheeler_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      expect(find.text('تحديث'), findsOneWidget);
      expect(find.text('تحديث المركبة'), findsOneWidget);

      await tester.tap(find.text('تحديث المركبة'));
      await tester.pumpAndSettle();
      expect(picked, 'vehicle');
    });

    testWidgets(
        'AppShell uses the adaptive navigation layout on tablet and phone',
        (tester) async {
      darbLocale.value = const Locale('ar');
      _mockSecureStorage(<String, String>{
        'accessToken': 'valid-token',
        'refreshToken': 'valid-refresh',
      });
      addTearDown(() async {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        DriverLocationReporter.stop();
        _clearSecureStorageMock();
        Api.instance.httpClientOverride = null;
        Api.instance.setSessionForTest();
      });

      Api.instance.setSessionForTest(accessToken: 'valid-token');
      Api.instance.httpClientOverride = _createRoleMockClient(role: 'CUSTOMER');

      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(
            size: const Size(1024, 768),
            devicePixelRatio: 1,
            disableAnimations: true,
          ),
          child: DarbApp(
            key: ValueKey('shell-tablet'),
            initialScreen: AppShell(checkForUpdates: false),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(DarbGlassSideRail), findsOneWidget);
      expect(find.byType(DarbGlassBottomNav), findsNothing);
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 844),
            devicePixelRatio: 1,
            disableAnimations: true,
          ),
          child: DarbApp(
            key: ValueKey('shell-phone'),
            initialScreen: AppShell(checkForUpdates: false),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(DarbGlassBottomNav), findsOneWidget);
      expect(find.byType(DarbGlassSideRail), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('LoginScreen split-pane renders cleanly on tablet viewport',
        (tester) async {
      darbLocale.value = const Locale('ar');
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Customer, Driver, Vendor, and Admin dashboards render without tablet overflow',
        (tester) async {
      darbLocale.value = const Locale('ar');
      _mockSecureStorage(<String, String>{});
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        DriverLocationReporter.stop();
        _clearSecureStorageMock();
        Api.instance.httpClientOverride = null;
        Api.instance.setSessionForTest();
      });

      Api.instance.setSessionForTest(accessToken: 'valid-token');
      Api.instance.httpClientOverride = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/cities')) {
          return http.Response(
            jsonEncode([
              {
                'id': 'city-1',
                'code': 'damascus',
                'names': [
                  {'locale': 'ar', 'name': 'دمشق'},
                ],
              },
            ]),
            200,
          );
        }
        if (path.endsWith('/vendors')) {
          return http.Response(
            jsonEncode([
              {
                'id': 'v-1',
                'type': 'مطعم',
                'isOpen': true,
                'translations': [
                  {'locale': 'ar', 'name': 'مطعم دمشق', 'description': 'مأكولات'},
                ],
              },
              {
                'id': 'v-2',
                'type': 'حلويات',
                'isOpen': true,
                'translations': [
                  {'locale': 'ar', 'name': 'حلويات الشام', 'description': 'شرقية'},
                ],
              },
            ]),
            200,
          );
        }
        if (path.endsWith('/drivers/me')) {
          return http.Response(
            jsonEncode({
              'id': 'drv-1',
              'status': 'APPROVED',
              'isOnline': true,
              'vehicleType': 'CAR',
            }),
            200,
          );
        }
        if (path.endsWith('/vendors/mine')) {
          return http.Response(
            jsonEncode({
              'id': 'v-1',
              'status': 'APPROVED',
              'isOpen': true,
              'translations': [
                {'locale': 'ar', 'name': 'متجر الشام', 'description': ''},
              ],
            }),
            200,
          );
        }
        if (path.endsWith('/drivers/stats') ||
            path.endsWith('/vendors/mine/stats') ||
            path.endsWith('/admin/stats')) {
          return http.Response(
            jsonEncode({
              'ordersTotal': 12,
              'ordersActive': 3,
              'driversOnline': 5,
              'deliveredGrossTotal': 150000,
            }),
            200,
          );
        }
        if (path.endsWith('/orders/available') ||
            path.endsWith('/orders/driver/available')) {
          return http.Response(
            jsonEncode([
              {
                'id': 'ord-1',
                'orderNumber': 'DRB-101',
                'type': 'VENDOR',
                'status': 'READY',
                'total': 25000,
                'currency': 'SYP',
                'distanceKm': 2.4,
                'vendor': {
                  'translations': [
                    {'locale': 'ar', 'name': 'مطعم الشام'},
                  ],
                },
              },
              {
                'id': 'ord-2',
                'orderNumber': 'DRB-102',
                'type': 'PEER_DELIVERY',
                'status': 'PENDING',
                'total': 12000,
                'currency': 'SYP',
                'distanceKm': 3.1,
              },
            ]),
            200,
          );
        }
        if (path.endsWith('/orders/vendor')) {
          return http.Response(
            jsonEncode([
              {
                'id': 'vo-1',
                'orderNumber': 'DRB-201',
                'type': 'VENDOR',
                'status': 'PENDING',
                'subtotal': 18000,
                'currency': 'SYP',
                'customer': {'name': 'سارة'},
                'items': [],
              },
              {
                'id': 'vo-2',
                'orderNumber': 'DRB-202',
                'type': 'VENDOR',
                'status': 'PREPARING',
                'subtotal': 32000,
                'currency': 'SYP',
                'customer': {'name': 'عمر'},
                'items': [],
              },
            ]),
            200,
          );
        }
        if (path.endsWith('/admin/vendors/pending')) {
          return http.Response(
            jsonEncode([
              {
                'id': 'pv-1',
                'type': 'مطعم',
                'status': 'PENDING',
                'translations': [
                  {'locale': 'ar', 'name': 'متجر الندى'},
                ],
                'user': {'name': 'أحمد', 'phone': '+963933000111'},
              },
              {
                'id': 'pv-2',
                'type': 'حلويات',
                'status': 'PENDING',
                'translations': [
                  {'locale': 'ar', 'name': 'حلويات الشرق'},
                ],
                'user': {'name': 'نور', 'phone': '+963944000222'},
              },
            ]),
            200,
          );
        }
        if (path.endsWith('/admin/drivers/pending') ||
            path.endsWith('/admin/vendors') ||
            path.endsWith('/admin/drivers')) {
          return http.Response('[]', 200);
        }
        return http.Response('[]', 200);
      });

      final screens = <Widget>[
        const CustomerHomeScreen(
          user: {'id': 'u1', 'name': 'أنس', 'role': 'CUSTOMER'},
        ),
        const DriverDashboardScreen(),
        const VendorOrdersScreen(),
        const AdminDashboardScreen(),
      ];

      for (var i = 0; i < screens.length; i++) {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(1024, 768),
              devicePixelRatio: 1,
              disableAnimations: true,
            ),
            child: DarbApp(
              key: ValueKey('tablet-dashboard-$i'),
              initialScreen: Scaffold(body: screens[i]),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        // Let bounded API retry delays finish before the test binding checks
        // for pending fake timers after disposing each dashboard.
        await tester.pump(const Duration(seconds: 5));
        expect(tester.takeException(), isNull);
        DriverLocationReporter.stop();
      }
    });
  });

  group('Spatial Primitives & Complete Redesign 2026', () {
    testWidgets(
        'DarbCommandStage, DarbSegmentedDock, and DarbCityOrbStrip render and fire callbacks across AR/EN/TR',
        (tester) async {
      var selectedDock = 'ALL';
      var selectedCity = 'c1';

      for (final lang in ['ar', 'en', 'tr']) {
        darbLocale.value = Locale(lang);
        await tester.pumpWidget(
          MaterialApp(
            theme: lang == 'tr' ? DarbTheme.dark : DarbTheme.light,
            home: Directionality(
              textDirection:
                  lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              child: MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: Scaffold(
                  body: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      DarbCommandStage(
                        livePulse: true,
                        eyebrow: 'DAZREVO',
                        title: 'مركز القيادة',
                        subtitle: 'شبكة التوصيل المباشر',
                        bottom: DarbCityOrbStrip(
                          onDarkStage: true,
                          selectedCityId: selectedCity,
                          cities: const [
                            DarbCityOrbOption(
                              id: 'c1',
                              name: 'دمشق',
                              code: 'damascus',
                            ),
                            DarbCityOrbOption(
                              id: 'c2',
                              name: 'حلب',
                              code: 'aleppo',
                            ),
                          ],
                          onSelect: (id) => selectedCity = id,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DarbSegmentedDock<String>(
                        selectedValue: selectedDock,
                        onSelected: (v) => selectedDock = v,
                        options: const [
                          DarbDockOption(value: 'ALL', label: 'الكل', count: 5),
                          DarbDockOption(
                            value: 'ACTIVE',
                            label: 'نشطة',
                            count: 2,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(DarbCommandStage), findsOneWidget);
        expect(find.byType(DarbCityOrbStrip), findsOneWidget);
        expect(find.byType(DarbSegmentedDock<String>), findsOneWidget);
        expect(find.byType(Image), findsNothing);
        expect(tester.takeException(), isNull);
      }

      await tester.tap(find.text('حلب'));
      await tester.pump();
      expect(selectedCity, 'c2');

      await tester.tap(find.text('نشطة'));
      await tester.pump();
      expect(selectedDock, 'ACTIVE');

      darbLocale.value = const Locale('ar');
    });

    testWidgets(
        'DarbTelemetryDeck, DarbTicketPass, DarbEditorialStoreCard, and DarbTelemetryProductCard render cleanly on 320px and 900px viewports',
        (tester) async {
      darbLocale.value = const Locale('ar');
      var storeTapped = false;
      var productTapped = false;

      for (final size in const [Size(320, 640), Size(900, 760)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: size.width < 500 ? DarbTheme.dark : DarbTheme.light,
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const DarbTelemetryDeck(
                      cells: [
                        DarbTelemetryCell(
                          label: 'طلبات اليوم',
                          value: '14',
                          icon: Icons.today_rounded,
                        ),
                        DarbTelemetryCell(
                          label: 'مبيعات اليوم',
                          value: '85,000 ل.س',
                          icon: Icons.trending_up_rounded,
                        ),
                        DarbTelemetryCell(
                          label: 'المكتملة',
                          value: '11',
                          icon: Icons.task_alt_rounded,
                        ),
                        DarbTelemetryCell(
                          label: 'النشطة',
                          value: '3',
                          icon: Icons.bolt_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DarbTicketPass(
                      leadingIcon: Icons.receipt_long_rounded,
                      title: 'DRB-2026-990',
                      subtitle: 'متجر الشام',
                      status: 'READY',
                      body: const Text('تفاصيل التذكرة'),
                      footer: const Text('جاهز للاستلام'),
                    ),
                    const SizedBox(height: 12),
                    DarbEditorialStoreCard(
                      name: 'مقهى دازريفو',
                      category: 'مشروبات',
                      isOpen: true,
                      productsLabel: '12 منتج متاح',
                      address: 'المالكي',
                      ratingAvg: 4.8,
                      reviewsCount: 24,
                      onTap: () => storeTapped = true,
                    ),
                    const SizedBox(height: 12),
                    DarbTelemetryProductCard(
                      name: 'قهوة مختصة',
                      category: 'مشروبات',
                      description: 'محمصة طازجة',
                      priceLabel: '12,000 ل.س',
                      stockLabel: 'المتبقي: 10',
                      stockRatio: 0.5,
                      highlighted: true,
                      onTap: () => productTapped = true,
                      actionDock: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(DarbTelemetryDeck), findsOneWidget);
        expect(find.byType(DarbTicketPass), findsOneWidget);
        expect(find.byType(DarbEditorialStoreCard), findsOneWidget);
        expect(find.byType(DarbTelemetryProductCard), findsOneWidget);
        expect(find.byType(Image), findsNothing);
        expect(tester.takeException(), isNull);
      }

      await tester.tap(find.text('مقهى دازريفو'));
      await tester.pump();
      expect(storeTapped, isTrue);

      await tester.ensureVisible(find.text('قهوة مختصة'));
      await tester.tap(find.text('قهوة مختصة'));
      await tester.pump();
      expect(productTapped, isTrue);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets(
        'AddressesScreen, CheckoutScreen, AI Assistants, and NotificationsScreen render Spatial flows on 320px Dark Mode without overflow',
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
      darbLocale.value = const Locale('ar');
      Api.instance.setSessionForTest(accessToken: 'valid-token');

      final addressRequestPaths = <String>[];
      var addressResponseServed = false;
      var notificationResponseServed = false;
      Api.instance.httpClientOverride = MockClient((request) async {
        final path = request.url.path;
        addressRequestPaths.add(path);
        if (path.endsWith('/addresses')) {
          addressResponseServed = true;
          return _utf8Response(
            jsonEncode([
              {
                'id': 'addr-1',
                'label': 'المنزل',
                'details': 'المالكي · شارع عبد المنعم رياض',
                'latitude': 33.5138,
                'longitude': 36.2765,
              },
              {
                'id': 'addr-2',
                'label': 'المكتب',
                'details': 'المزة أوتوستراد',
              },
            ]),
            200,
          );
        }
        if (path.endsWith('/orders/estimate')) {
          return _utf8Response(
            jsonEncode({
              'subtotal': 24000,
              'deliveryFee': 6000,
              'total': 30000,
              'distanceKm': 2.8,
              'currency': 'SYP',
            }),
            200,
          );
        }
        if (path.endsWith('/ai/order-assistant/drafts/text')) {
          return _utf8Response(
            jsonEncode({
              'intent': 'PEER_DELIVERY',
              'confidence': 0.94,
              'notes': 'إرسال مفاتيح من المزة إلى المالكي',
              'suggestedActions': ['تجهيز طلب التوصيل'],
            }),
            200,
          );
        }
        if (path.endsWith('/ai/assistant/ask')) {
          return _utf8Response(
            jsonEncode({'answer': 'لديك طلب نشط قيد التحضير حالياً.'}),
            200,
          );
        }
        if (path.endsWith('/notifications')) {
          notificationResponseServed = true;
          return _utf8Response(
            jsonEncode({
              'unreadCount': 1,
              'items': [
                {
                  'id': 'n-1',
                  'title': 'تم قبول طلبك',
                  'body': 'المتجر بدأ بتجهيز الطلب رقم DRB-101',
                  'type': 'ORDER_ACCEPTED',
                  'readAt': null,
                  'createdAt': '2026-11-26T09:00:00Z',
                },
              ],
            }),
            200,
          );
        }
        return _utf8Response('{}', 200);
      });

      // 1. AddressesScreen
      await tester.pumpWidget(
        const SizedBox(
          width: 320,
          height: 640,
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 640),
              disableAnimations: true,
            ),
            child: DarbApp(
              key: ValueKey('sp-addresses'),
              initialScreen: AddressesScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(
        addressRequestPaths,
        contains('/api/v1/addresses'),
        reason: 'AddressesScreen must request the authenticated addresses endpoint; captured: $addressRequestPaths',
      );
      expect(
        addressResponseServed,
        isTrue,
        reason: 'The addresses request must receive the fixture response; captured: $addressRequestPaths',
      );
      final addressScrollable = find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first;
      final addressScrollState = tester.state<ScrollableState>(addressScrollable);
      expect(
        addressScrollState.position.viewportDimension,
        greaterThan(0),
        reason: 'The saved-address list must receive a bounded, visible viewport.',
      );
      await tester.scrollUntilVisible(
        find.text('المنزل'),
        180,
        scrollable: addressScrollable,
      );
      expect(find.text('المنزل'), findsOneWidget);
      expect(
        tester.widget<DarbTicketPass>(find.byType(DarbTicketPass).first).title,
        'المنزل',
        reason: 'The first address label must be preserved in its rendered pass.',
      );
      await tester.scrollUntilVisible(
        find.text('المكتب'),
        180,
        scrollable: addressScrollable,
      );
      expect(find.text('المكتب'), findsOneWidget);
      expect(find.byType(DarbCommandStage), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 2. CheckoutScreen
      await tester.pumpWidget(
        const SizedBox(
          width: 320,
          height: 640,
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 640),
              disableAnimations: true,
            ),
            child: DarbApp(
              key: ValueKey('sp-checkout'),
              initialScreen: CheckoutScreen(
                cityId: 'city-1',
                vendorId: 'v-1',
                vendorName: 'مقهى دازريفو',
                items: [
                  CartCheckoutItem(
                    productId: 'p-1',
                    name: 'قهوة مختصة',
                    unitPrice: 12000,
                    currency: 'SYP',
                    quantity: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(DarbCommandStage), findsOneWidget);
      expect(find.byType(DarbRouteConnector), findsOneWidget);
      final checkoutScrollable = find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('قهوة مختصة'),
        180,
        scrollable: checkoutScrollable,
      );
      expect(find.text('قهوة مختصة'), findsOneWidget);
      expect(find.text('2×'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 3. AiOrderAssistantScreen
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: DarbApp(
            key: ValueKey('sp-ai-order'),
            initialScreen: AiOrderAssistantScreen(cityId: 'city-1', cityName: 'دمشق'),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('إرسال مفاتيح من المزة إلى المالكي'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'إرسال مفاتيح من المزة إلى المالكي',
        reason: 'Selecting an example must populate the request without submitting it.',
      );
      await tester.ensureVisible(find.text('تحليل الطلب'));
      await tester.tap(find.text('تحليل الطلب'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.byType(DarbTicketPass),
        findsOneWidget,
        reason: 'The AI draft ticket must appear only after the analysis request succeeds.',
      );
      expect(
        addressRequestPaths.any((path) => path.endsWith('/ai/order-assistant/drafts/text')),
        isTrue,
        reason: 'The test must exercise the AI order-assistant API endpoint.',
      );
      expect(tester.takeException(), isNull);

      // 4. AiRoleAssistantScreen
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: DarbApp(
            key: ValueKey('sp-ai-role'),
            initialScreen: AiRoleAssistantScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(DarbCommandStage), findsOneWidget);
      await tester.tap(find.text('ما حالة طلباتي اليوم؟'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('لديك طلب نشط قيد التحضير حالياً.'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 5. NotificationsScreen
      await tester.pumpWidget(
        const SizedBox(
          width: 320,
          height: 640,
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 640),
              disableAnimations: true,
            ),
            child: DarbApp(
              key: ValueKey('sp-notifications'),
              initialScreen: NotificationsScreen(),
            ),
          ),
        ),
      );
      // The screen loads its feed asynchronously in initState. Pump the
      // bounded viewport until the mocked endpoint has answered, without
      // pumpAndSettle because the live unread indicator intentionally pulses.
      for (var attempt = 0;
          attempt < 10 && !notificationResponseServed;
          attempt++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        notificationResponseServed,
        isTrue,
        reason: 'NotificationsScreen must request and receive /notifications.',
      );
      expect(find.byType(DarbCommandStage), findsOneWidget);
      final notificationsScrollable = find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('تم قبول طلبك'),
        160,
        scrollable: notificationsScrollable,
      );
      expect(
        find.text('تم قبول طلبك'),
        findsOneWidget,
        reason: 'The notification title must render in the scrollable feed after the API response.',
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('FCM Push Registration, Notification Routing & Role Enhancements', () {
    test('DarbNotifications maps platforms cleanly and deduplicates/resets sync state',
        () async {
      expect(
        DarbNotifications.resolvePlatform(TargetPlatform.android, isWeb: false),
        'android',
      );
      expect(
        DarbNotifications.resolvePlatform(TargetPlatform.iOS, isWeb: false),
        'ios',
      );
      expect(
        DarbNotifications.resolvePlatform(TargetPlatform.linux, isWeb: false),
        'web',
      );
      expect(
        DarbNotifications.resolvePlatform(TargetPlatform.macOS, isWeb: false),
        'web',
      );
      expect(
        DarbNotifications.resolvePlatform(TargetPlatform.android, isWeb: true),
        'web',
      );

      DarbNotifications.debugResetForTest(ready: false);
      Api.instance.setSessionForTest(accessToken: 'sess-1');
      addTearDown(() {
        DarbNotifications.debugResetForTest();
        Api.instance.setSessionForTest();
      });

      var registerCalls = 0;
      String? registeredToken;
      String? unregisteredToken;

      DarbNotifications.tokenProviderOverride = () async => 'fcm-tok-123';
      DarbNotifications.registerDeviceOverride = (token, platform) async {
        registerCalls++;
        registeredToken = token;
      };
      DarbNotifications.unregisterDeviceOverride = (token, platform) async {
        unregisteredToken = token;
      };

      await DarbNotifications.register();
      expect(registerCalls, 1);
      expect(registeredToken, 'fcm-tok-123');
      expect(DarbNotifications.hasSyncedToken, isTrue);

      // Deduplicated when already synced with same session & token
      await DarbNotifications.register();
      expect(registerCalls, 1);

      // Force sync triggers a fresh registration
      await DarbNotifications.register(force: true);
      expect(registerCalls, 2);

      await DarbNotifications.unregister();
      expect(unregisteredToken, 'fcm-tok-123');
      expect(DarbNotifications.hasSyncedToken, isFalse);
    });

    testWidgets(
        'DarbBeaconRing and DarbBrandMark(animatePulse: true) honor Reduce Motion',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DarbTheme.dark,
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Column(
                children: [
                  DarbBrandMark(size: 56, animatePulse: true),
                  DarbOrderTimeline(status: 'PREPARING'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(DarbBeaconRing), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'NotificationsScreen triggers tap-to-open order/update routing and device sync',
        (tester) async {
      darbLocale.value = const Locale('ar');
      _mockSecureStorage(<String, String>{});
      DarbNotifications.debugResetForTest(ready: false);
      var syncCalls = 0;
      DarbNotifications.tokenProviderOverride = () async => 'fcm-inbox-tok';
      DarbNotifications.registerDeviceOverride = (token, platform) async {
        syncCalls++;
      };
      Api.instance.setSessionForTest(accessToken: 'valid-token');
      addTearDown(() {
        DarbNotifications.debugResetForTest();
        _clearSecureStorageMock();
        Api.instance.httpClientOverride = null;
        Api.instance.setSessionForTest();
      });

      Api.instance.httpClientOverride = MockClient((request) async {
        if (request.url.path.endsWith('/notifications')) {
          return _utf8Response(
            jsonEncode({
              'unreadCount': 1,
              'items': [
                {
                  'id': 'n-order',
                  'type': 'ORDER_ACCEPTED',
                  'title': 'طلبك قيد التجهيز',
                  'body': 'تم قبول الطلب DRB-707',
                  'data': {'orderId': 'ord-707', 'type': 'ORDER_ACCEPTED'},
                  'readAt': null,
                  'createdAt': '2026-11-27T10:00:00Z',
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/notifications/n-order/read')) {
          return _utf8Response(jsonEncode({'id': 'n-order', 'readAt': '2026-11-27T10:01:00Z'}), 200);
        }
        return _utf8Response('{}', 200);
      });

      Map<String, dynamic>? openedPayload;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: DarbApp(
            initialScreen: NotificationsScreen(
              onOpenNotificationData: (data) async {
                openedPayload = data;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('مزامنة الآن'), findsOneWidget);
      await tester.tap(find.text('مزامنة الآن'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(syncCalls, 1);

      await tester.tap(find.text('طلبك قيد التجهيز'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(openedPayload?['orderId'], 'ord-707');
      expect(openedPayload?['type'], 'ORDER_ACCEPTED');
    });

    testWidgets(
        'CustomerHomeScreen favorite pinning & Driver/Vendor role filters work cleanly',
        (tester) async {
      darbLocale.value = const Locale('ar');
      _mockSecureStorage(<String, String>{});
      addTearDown(() {
        _clearSecureStorageMock();
        Api.instance.httpClientOverride = null;
        Api.instance.setSessionForTest();
      });

      Api.instance.setSessionForTest(accessToken: 'valid-token');
      Api.instance.httpClientOverride = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/cities')) {
          return _utf8Response(
            jsonEncode([
              {
                'id': 'c-1',
                'code': 'damascus',
                'names': [{'locale': 'ar', 'name': 'دمشق'}],
              },
            ]),
            200,
          );
        }
        if (path.endsWith('/vendors')) {
          return _utf8Response(
            jsonEncode([
              {
                'id': 'v-1',
                'type': 'مطعم',
                'isOpen': true,
                'translations': [{'locale': 'ar', 'name': 'مطعم القلعة'}],
              },
            ]),
            200,
          );
        }
        if (path.endsWith('/orders/driver/mine')) {
          return _utf8Response(
            jsonEncode([
              {
                'id': 'do-1',
                'orderNumber': 'DRB-901',
                'type': 'VENDOR',
                'status': 'ASSIGNED',
                'total': 20000,
                'deliveryFee': 4000,
                'currency': 'SYP',
                'customer': {'name': 'سامي'},
              },
              {
                'id': 'do-2',
                'orderNumber': 'DRB-902',
                'type': 'PEER_DELIVERY',
                'status': 'PICKED_UP',
                'total': 15000,
                'deliveryFee': 5000,
                'currency': 'SYP',
                'customer': {'name': 'ريم'},
              },
            ]),
            200,
          );
        }
        return _utf8Response('[]', 200);
      });

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: DarbApp(
            key: ValueKey('cust-fav'),
            initialScreen: Scaffold(
              body: CustomerHomeScreen(
                user: {'id': 'u1', 'name': 'أنس', 'role': 'CUSTOMER'},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      final vendorTitle = find.text('مطعم القلعة');
      await tester.scrollUntilVisible(
        vendorTitle,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(vendorTitle, findsOneWidget);
      final bookmarkButton = find.byIcon(Icons.bookmark_border_rounded).first;
      await tester.ensureVisible(bookmarkButton);
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(bookmarkButton, findsOneWidget);
      expect(tester.getCenter(bookmarkButton).dy, inInclusiveRange(0.0, tester.view.physicalSize.height / tester.view.devicePixelRatio));
      await tester.tap(bookmarkButton);
      await tester.pump();
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
      expect(find.text('المفضلة (1)'), findsOneWidget);

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: DarbApp(
            key: ValueKey('drv-filter'),
            initialScreen: Scaffold(body: DriverOrdersScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('DRB-901'), findsOneWidget);
      expect(find.text('DRB-902'), findsOneWidget);

      final peerChip = find.text('توصيل مستقل').first;
      await tester.ensureVisible(peerChip);
      await tester.tap(peerChip);
      await tester.pump();
      expect(find.text('DRB-902'), findsOneWidget);
      expect(find.text('DRB-901'), findsNothing);
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
