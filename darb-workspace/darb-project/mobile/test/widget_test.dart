import 'package:darb/core/l10n/app_localizations.dart';
import 'package:darb/core/theme/darb_design_system.dart';
import 'package:darb/core/widgets/darb_components.dart';
import 'package:darb/core/widgets/darb_glass.dart';
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
      expect(dt('5 منتج متاح'), '5 products available');
      expect(formatDarbMoney(15000), '15,000 SYP');

      darbLocale.value = const Locale('tr');
      expect(dt('إلغاء الطلب'), 'Siparişi iptal et');
      expect(dt('الإشعارات'), 'Bildirimler');
      expect(dt('3 منتج متاح'), '3 ürün mevcut');

      darbLocale.value = const Locale('ar');
    });
  });

  group('Widget & Motion Accessibility Smoke Tests', () {
    testWidgets('renders DarbGlassSurface in Glass and Standard modes without errors',
        (tester) async {
      await DarbAppearanceController.instance.setVisualStyle(DarbVisualStyle.glass);
      await tester.pumpWidget(
        DarbApp(
          initialScreen: Scaffold(
            appBar: const DarbGlassAppBar(title: 'دَرْب', subtitle: 'تجربة'),
            body: DarbAmbientBackground(
              child: ListView(
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
        ),
      );
      await tester.pump();
      expect(find.text('دَرْب'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);

      await DarbAppearanceController.instance.setVisualStyle(DarbVisualStyle.standard);
      await tester.pump();
      expect(find.text('42'), findsOneWidget);
      await DarbAppearanceController.instance.setVisualStyle(DarbVisualStyle.glass);
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
  });
}
