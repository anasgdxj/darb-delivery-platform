import 'dart:async';

import 'package:flutter/material.dart';

import '../design_system.dart';

class DarbCityCarousel extends StatefulWidget {
  const DarbCityCarousel({super.key});

  @override
  State<DarbCityCarousel> createState() => _DarbCityCarouselState();
}

class _DarbCityCarouselState extends State<DarbCityCarousel> {
  static const _cities = <_CitySlide>[
    _CitySlide('aleppo', 'حلب', 'Aleppo', 'Halep'),
    _CitySlide('homs', 'حمص', 'Homs', 'Humus'),
    _CitySlide('hama', 'حماة', 'Hama', 'Hama'),
    _CitySlide('damascus', 'دمشق', 'Damascus', 'Şam'),
    _CitySlide('latakia', 'اللاذقية', 'Latakia', 'Lazkiye'),
  ];

  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted || DarbMotion.reduceMotion(context)) return;
      setState(() => _index = (_index + 1) % _cities.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final city = _cities[_index];
    final language = Localizations.localeOf(context).languageCode;
    final cityName = switch (language) {
      'en' => city.english,
      'tr' => city.turkish,
      _ => city.arabic,
    };
    final duration = DarbMotion.effectiveDuration(
      context,
      const Duration(milliseconds: 1100),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: duration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (current, previous) => Stack(
            fit: StackFit.expand,
            children: [...previous, if (current != null) current],
          ),
          transitionBuilder: (child, animation) {
            final reduced = DarbMotion.reduceMotion(context);
            return FadeTransition(
              opacity: animation,
              child: reduced
                  ? child
                  : ScaleTransition(
                      scale: Tween<double>(begin: 1.035, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
            );
          },
          child: Image.asset(
            'assets/cities/${city.assetName}.jpg',
            key: ValueKey(city.assetName),
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => const SizedBox.expand(),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                DarbColors.obsidian.withValues(alpha: .32),
                DarbColors.obsidian.withValues(alpha: .88),
              ],
            ),
          ),
        ),
        PositionedDirectional(
          top: 22,
          end: 20,
          child: AnimatedSwitcher(
            duration: duration,
            child: Container(
              key: ValueKey(city.assetName),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: DarbColors.obsidian.withValues(alpha: .72),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: DarbColors.champagne.withValues(alpha: .36),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: DarbColors.champagne,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    cityName,
                    style: TextStyle(
                      color: DarbColors.ivory,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        PositionedDirectional(
          bottom: 16,
          end: 20,
          child: Row(
            children: List.generate(
              _cities.length,
              (index) => AnimatedContainer(
                duration: DarbMotion.fast,
                curve: DarbMotion.enter,
                margin: const EdgeInsetsDirectional.only(start: 4),
                width: index == _index ? 18 : 5,
                height: 4,
                decoration: BoxDecoration(
                  color: index == _index
                      ? DarbColors.champagne
                      : DarbColors.ivory.withValues(alpha: .42),
                  borderRadius: BorderRadius.circular(DarbRadius.pill),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CitySlide {
  const _CitySlide(this.assetName, this.arabic, this.english, this.turkish);
  final String assetName;
  final String arabic;
  final String english;
  final String turkish;
}
