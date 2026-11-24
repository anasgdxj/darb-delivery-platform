import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_glass.dart';
import 'login_hero_map.dart';

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
                        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                      ),
                      child: child,
                    ),
            );
          },
          child: DarbLoginVectorMap(key: ValueKey(city.code)),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x28000000), Color(0xD612302A)],
            ),
          ),
        ),
        PositionedDirectional(
          top: 66,
          end: 16,
          child: AnimatedSwitcher(
            duration: duration,
            child: DarbGlassSurface(
              key: ValueKey(city.code),
              borderRadius: DarbRadius.pill,
              blurSigma: 14,
              tintColor: DarbColors.forest.withValues(alpha: 0.72),
              borderColor: DarbColors.mint.withValues(alpha: 0.38),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded, color: DarbColors.mint, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    cityName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        PositionedDirectional(
          bottom: 14,
          end: 18,
          child: Row(
            children: List.generate(
              _cities.length,
              (index) => AnimatedContainer(
                duration: DarbMotion.fast,
                curve: DarbMotion.enter,
                margin: const EdgeInsetsDirectional.only(start: 4),
                width: index == _index ? 18 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: (index == _index ? DarbColors.mint : Colors.white)
                      .withValues(alpha: index == _index ? 0.96 : 0.45),
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
  const _CitySlide(this.code, this.arabic, this.english, this.turkish);
  final String code;
  final String arabic;
  final String english;
  final String turkish;
}
