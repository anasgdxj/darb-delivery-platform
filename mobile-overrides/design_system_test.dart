import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darb/design_system.dart';

void main() {
  group('DARB design system', () {
    test('defines the approved Material 3 theme', () {
      final theme = DarbTheme.light;
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, DarbColors.forest);
    expect(DarbColors.primary, DarbColors.forest);
    expect(DarbColors.onPrimary, const Color(0xFFFFFFFF));
      expect(theme.scaffoldBackgroundColor, DarbColors.canvas);
    });

    test('defines a dark Material 3 theme with semantic contrast', () {
      final theme = DarbTheme.dark;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, const Color(0xFFB9E4D2));
    expect(DarbColors.primary, DarbColors.mint);
    expect(DarbColors.onPrimary, DarbColors.forest);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF0B1512));
    });

    test('uses the same DARB route transition in light and dark themes', () {
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
      expect(DarbColors.ink, const Color(0xFFF1F5F1));
      expect(DarbColors.line, const Color(0xFF2A3B33));

      DarbTheme.updateBrightness(Brightness.light);
      expect(DarbColors.canvas, lightCanvas);
      expect(DarbColors.surface, lightSurface);
      expect(DarbColors.ink, lightInk);
    });

    test('provides consistent spacing, radius and motion tokens', () {
      expect(DarbSpace.xs, 8);
      expect(DarbSpace.md, 16);
      expect(DarbRadius.md, 16);
      expect(DarbRadius.hero, 36);
      expect(DarbMotion.fast, const Duration(milliseconds: 160));
      expect(DarbMotion.standard, const Duration(milliseconds: 260));
    });

    test('provides rich motion timings and reduced-motion support', () {
      expect(DarbMotion.press.inMilliseconds, 120);
      expect(DarbMotion.route.inMilliseconds, 340);
      expect(DarbMotion.staggerDelay(3).inMilliseconds, 165);
    });

    testWidgets('DarbFadeSlide skips entrance motion when reduced motion is on', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: DarbFadeSlide(child: Text('DARB motion')),
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
