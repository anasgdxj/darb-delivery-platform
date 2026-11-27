import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darb/design_system.dart';

void main() {
  group('DAZREVO Nocturne Atelier design system', () {
    test('defines the approved light Material 3 theme', () {
      DarbTheme.updateBrightness(Brightness.light);
      final theme = DarbTheme.light;
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, DarbColors.charcoal);
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF7F6F2));
    });

    test('defines a dark Material 3 theme with semantic contrast', () {
      final theme = DarbTheme.dark;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, const Color(0xFFDFBE7D));
      expect(theme.scaffoldBackgroundColor, const Color(0xFF090B0E));
    });

    test('uses the same DAZREVO route transition in light and dark themes', () {
      for (final theme in [DarbTheme.light, DarbTheme.dark]) {
        for (final platform in TargetPlatform.values) {
          expect(
            theme.pageTransitionsTheme.builders[platform],
            isA<DarbPageTransitionsBuilder>(),
          );
        }
      }
    });

    test('defaults theme selection to follow the device', () {
      expect(DarbTheme.mode.value, ThemeMode.system);
    });

    test('semantic palette adapts when active brightness changes', () {
      DarbTheme.updateBrightness(Brightness.light);
      final lightCanvas = DarbColors.canvas;
      final lightSurface = DarbColors.surface;
      final lightInk = DarbColors.ink;

      DarbTheme.updateBrightness(Brightness.dark);
      expect(DarbColors.canvas, isNot(lightCanvas));
      expect(DarbColors.surface, isNot(lightSurface));
      expect(DarbColors.ink, isNot(lightInk));
      expect(DarbColors.ink, const Color(0xFFF5F2EB));
      expect(DarbColors.line, const Color(0xFF222934));

      DarbTheme.updateBrightness(Brightness.light);
      expect(DarbColors.canvas, lightCanvas);
      expect(DarbColors.surface, lightSurface);
      expect(DarbColors.ink, lightInk);
    });

    test('provides consistent spacing, radius and motion tokens', () {
      expect(DarbSpace.xs, 8);
      expect(DarbSpace.md, 16);
      expect(DarbRadius.md, 14);
      expect(DarbRadius.hero, 32);
      expect(DarbMotion.fast, const Duration(milliseconds: 160));
      expect(DarbMotion.standard, const Duration(milliseconds: 260));
    });

    test('provides rich motion timings and reduced-motion support', () {
      expect(DarbMotion.press.inMilliseconds, 120);
      expect(DarbMotion.route.inMilliseconds, 340);
      expect(DarbMotion.staggerDelay(3).inMilliseconds, 150);
    });

    testWidgets(
      'DarbFadeSlide skips entrance motion when reduced motion is on',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: DarbFadeSlide(child: Text('DAZREVO motion')),
              ),
            ),
          ),
        );

        final fadeFinder = find.descendant(
          of: find.byType(DarbFadeSlide),
          matching: find.byType(FadeTransition),
        );
        expect(fadeFinder, findsOneWidget);

        final fade = tester.widget<FadeTransition>(fadeFinder);
        expect(fade.opacity.value, 1);
      },
    );

    testWidgets('renders DazrevoLogoMark and DazrevoFloatingDock cleanly', (
      tester,
    ) async {
      var tapped = -1;
      await tester.pumpWidget(
        MaterialApp(
          theme: DarbTheme.dark,
          home: Scaffold(
            body: const Center(child: DazrevoLogoMark(size: 54)),
            bottomNavigationBar: DazrevoFloatingDock(
              labels: const ['Home', 'Orders', 'Account'],
              icons: const [
                Icons.explore_rounded,
                Icons.receipt_long_rounded,
                Icons.person_rounded,
              ],
              selectedIndex: 0,
              onSelected: (index) => tapped = index,
            ),
          ),
        ),
      );

      expect(find.byType(DazrevoLogoMark), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      await tester.tap(find.text('Orders'));
      await tester.pump();
      expect(tapped, 1);
    });

    test('includes semantic status colors', () {
      expect(DarbColors.success, isA<Color>());
      expect(DarbColors.warning, isA<Color>());
      expect(DarbColors.info, isA<Color>());
      expect(DarbColors.borderStrong, isA<Color>());
      expect(DarbColors.scrim, isA<Color>());
    });
  });
}
