import 'package:darb/core/l10n/app_localizations.dart';
import 'package:darb/core/theme/darb_design_system.dart';
import 'package:darb/core/widgets/darb_city_scene.dart';
import 'package:darb/core/widgets/darb_components.dart';
import 'package:darb/core/widgets/darb_glass.dart';
import 'package:darb/core/widgets/darb_motion_components.dart';
import 'package:darb/features/account/driver_application_screen.dart';
import 'package:darb/features/account/edit_profile_screen.dart';
import 'package:darb/features/account/vendor_application_screen.dart';
import 'package:darb/features/auth/login_hero_map.dart';
import 'package:darb/features/auth/login_screen.dart';
import 'package:darb/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DARB Design System 2026 & Brand Integrity', () {
    test('enforces exact DESIGN_SYSTEM.md 2026 light and dark semantic tokens', () {
      expect(DarbColors.forest, const Color(0xFF12302A));
      expect(DarbColors.primaryGreen, const Color(0xFF167A5A));
      expect(DarbColors.forestSoft, const Color(0xFF1C4B3F));
      expect(DarbColors.mint, const Color(0xFFB9E4D2));
      expect(DarbColors.lime, const Color(0xFFC8F169));
      expect(DarbColors.danger, const Color(0xFFD64545));
      expect(DarbColors.success, const Color(0xFF2E7D32));
      expect(DarbColors.warning, const Color(0xFFC47B19));
      expect(DarbColors.info, const Color(0xFF2B6EA3));

      expect(DarbColors.canvas, const Color(0xFFF6F6F3));
      expect(DarbColors.surface, const Color(0xFFFFFFFF));
      expect(DarbColors.surfaceAlt, const Color(0xFFECEEE9));
      expect(DarbColors.ink, const Color(0xFF1A2E29));
      expect(DarbColors.muted, const Color(0xFF687A75));
      expect(DarbColors.line, const Color(0xFFD0D7D4));
      expect(DarbColors.borderStrong, const Color(0xFFB8C3BF));

      expect(DarbColors.darkCanvas, const Color(0xFF0B1512));
      expect(DarbColors.darkSurface, const Color(0xFF12201B));
      expect(DarbColors.darkSurfaceElevated, const Color(0xFF182A24));
      expect(DarbColors.darkSurfaceAlt, const Color(0xFF1D322B));
      expect(DarbColors.darkInk, const Color(0xFFEEF5F1));
      expect(DarbColors.darkMuted, const Color(0xFF9CB0A7));
      expect(DarbColors.darkLine, const Color(0xFF263B33));
      expect(DarbColors.darkBorderStrong, const Color(0xFF3A544A));
      expect(DarbColors.darkPrimary, const Color(0xFF6FE0B7));
      expect(DarbColors.darkOnPrimary, const Color(0xFF0B1F1A));

      final themeLight = DarbTheme.light;
      final themeDark = DarbTheme.dark;

      expect(themeLight.colorScheme.primary, DarbColors.primaryGreen);
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
      expect(find.text('دَرْب • DARB'), findsOneWidget);
      expect(find.text('أهلاً بك في دَرْب'), findsOneWidget);
      expect(find.text('طريقك الأسهل لاكتشاف المتاجر وطلب ما تحتاجه'), findsOneWidget);
      expect(find.text('سجّل الدخول برقم هاتفك'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.text('AR'), findsOneWidget);
      expect(find.text('المتابعة باستخدام Google'), findsOneWidget);
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

  group('DARB Design Evolution 2026 Widgets', () {
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
      await tester.pumpAndSettle();
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
      await tester.pumpAndSettle();
      final cityField = find.byType(DropdownButtonFormField<String>);
      expect(cityField, findsOneWidget);
      await tester.tap(cityField);
      await tester.pumpAndSettle();
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
