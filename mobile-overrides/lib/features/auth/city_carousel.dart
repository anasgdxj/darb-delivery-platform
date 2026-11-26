import 'package:flutter/material.dart';

import 'login_hero_map.dart';

/// Vector-only city showcase card used in onboarding & login headers.
/// Keeps city visuals strictly vector/procedural (zero city photography).
class CityShowcaseBanner extends StatelessWidget {
  const CityShowcaseBanner({
    super.key,
    this.height = 176,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return DarbLoginVectorMap(height: height);
  }
}
