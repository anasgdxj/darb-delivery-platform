import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/storage/local_cache.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_motion_components.dart';
import 'city_carousel.dart';
import 'login_screen.dart';

const String kDazrevoOnboardingSeenKey = 'onboarding_seen_v1';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.onFinished,
  });

  final VoidCallback? onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    DarbHaptics.medium();
    await DarbLocalCache.instance.writeJson(kDazrevoOnboardingSeenKey, true);
    if (!mounted) return;
    if (widget.onFinished != null) {
      widget.onFinished!.call();
      return;
    }
    Navigator.of(context).pushReplacement(
      DarbPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _next(int total) {
    if (_index >= total - 1) {
      _complete();
      return;
    }
    DarbHaptics.selection();
    _pageController.nextPage(
      duration: DarbMotion.effectiveDuration(context, DarbMotion.standard),
      curve: DarbMotion.enter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = [
      _OnboardingSlideData(
        badge: dt('متاجر مدينتك'),
        title: dt('اطلب من متاجر مدينتك في ثوانٍ'),
        subtitle: dt(
          'تصفح المطاعم والأسواق القريبة في منطقتك مع تقدير واضح لرسوم التوصيل والدفع عند الاستلام.',
        ),
        icon: Icons.storefront_rounded,
        accent: DarbColors.lime,
        secondaryAccent: DarbColors.mint,
        highlights: [
          (Icons.flash_on_rounded, dt('طلب سريع ومباشر')),
          (Icons.payments_outlined, dt('الدفع عند الاستلام')),
          (Icons.verified_rounded, dt('متاجر موثوقة ومعتمدة')),
        ],
      ),
      _OnboardingSlideData(
        badge: dt('التوصيل المستقل'),
        title: dt('أرسل أغراضك بحرية مع عروض السائقين'),
        subtitle: dt(
          'أنشئ طلب توصيل بين أي نقطتين في مدينتك، وقارن عروض الأسعار من المناديب القريبين واختر الأنسب.',
        ),
        icon: Icons.local_shipping_rounded,
        accent: DarbColors.mint,
        secondaryAccent: DarbColors.lime,
        highlights: [
          (Icons.swap_horiz_rounded, dt('من نقطة إلى نقطة')),
          (Icons.local_offer_outlined, dt('عروض متعددة من المناديب')),
          (Icons.schedule_rounded, dt('جاهزية فورية على الطريق')),
        ],
      ),
      _OnboardingSlideData(
        badge: dt('الذكاء والمسار الحي'),
        title: dt('مساعد ذكي وتتبّع لحظي على الخريطة'),
        subtitle: dt(
          'حوّل رسالتك النصية إلى طلب جاهز عبر المساعد الذكي وتابع موقع المندوب لحظة بلحظة عبر GPS.',
        ),
        icon: Icons.auto_awesome_rounded,
        accent: DarbColors.darkViolet,
        secondaryAccent: DarbColors.lime,
        isAiSlide: true,
        highlights: [
          (Icons.auto_awesome_rounded, dt('صياغة ذكية للطلبات')),
          (Icons.my_location_rounded, dt('تتبع حي لمسار المندوب')),
          (Icons.notifications_active_outlined, dt('تنبيهات فورية لكل مرحلة')),
        ],
      ),
    ];

    final current = slides[_index];

    return Scaffold(
      backgroundColor: DarbColors.darkCanvas,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DarbAmbientBackground(child: SizedBox.expand()),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Row(
                    children: [
                      const DarbBrandMark(size: 38),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          dt('دازريفو · DAZREVO'),
                          style: TextStyle(
                            color: DarbColors.inkOf(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      DarbGlassSurface(
                        borderRadius: DarbRadius.pill,
                        blurSigma: 12,
                        elevated: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: darbLocale.value.languageCode,
                            isDense: true,
                            dropdownColor: DarbColors.surfaceElevatedOf(context),
                            style: TextStyle(
                              color: DarbColors.inkOf(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'ar', child: Text('AR')),
                              DropdownMenuItem(value: 'en', child: Text('EN')),
                              DropdownMenuItem(value: 'tr', child: Text('TR')),
                            ],
                            onChanged: (code) {
                              if (code != null) {
                                DarbHaptics.selection();
                                darbLocale.value = Locale(code);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: _complete,
                        child: Text(dt('تخطي')),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: slides.length,
                    onPageChanged: (value) {
                      DarbHaptics.selection();
                      setState(() => _index = value);
                    },
                    itemBuilder: (context, i) => _OnboardingSlideView(
                      slide: slides[i],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(slides.length, (i) {
                          final active = i == _index;
                          return AnimatedContainer(
                            duration: DarbMotion.effectiveDuration(
                              context,
                              DarbMotion.interactive,
                            ),
                            curve: DarbMotion.enter,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(DarbRadius.pill),
                              color: active
                                  ? (current.isAiSlide
                                      ? DarbColors.violetOf(context)
                                      : DarbColors.primaryOf(context))
                                  : DarbColors.borderStrongOf(context),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      DarbActionButton(
                        label: _index == slides.length - 1
                            ? dt('ابدأ الآن')
                            : dt('التالي'),
                        icon: _index == slides.length - 1
                            ? Icons.arrow_forward_rounded
                            : Icons.chevron_right_rounded,
                        onPressed: () => _next(slides.length),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlideData {
  const _OnboardingSlideData({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.secondaryAccent,
    required this.highlights,
    this.isAiSlide = false,
  });

  final String badge;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color secondaryAccent;
  final List<(IconData, String)> highlights;
  final bool isAiSlide;
}

class _OnboardingSlideView extends StatelessWidget {
  const _OnboardingSlideView({required this.slide});

  final _OnboardingSlideData slide;

  @override
  Widget build(BuildContext context) {
    final isDark = DarbColors.isDark(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(DarbRadius.xl),
                child: SizedBox(
                  height: 224,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const CityShowcaseBanner(height: 224),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              DarbColors.darkCanvas.withValues(alpha: 0.16),
                              DarbColors.forest.withValues(alpha: 0.74),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: slide.isAiSlide
                                    ? DarbColors.violet.withValues(alpha: 0.24)
                                    : DarbColors.forest.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: slide.accent.withValues(alpha: 0.78),
                                  width: 1.5,
                                ),
                                boxShadow: DarbElevation.glow(
                                  slide.accent,
                                  isDark: true,
                                ),
                              ),
                              child: Icon(
                                slide.icon,
                                size: 38,
                                color: slide.accent,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    DarbColors.darkCanvas.withValues(alpha: 0.72),
                                borderRadius:
                                    BorderRadius.circular(DarbRadius.pill),
                                border: Border.all(
                                  color: slide.accent.withValues(alpha: 0.45),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  DarbPulseDot(color: slide.accent, size: 7),
                                  const SizedBox(width: 6),
                                  Text(
                                    slide.badge,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              DarbGlassSurface(
                borderRadius: DarbRadius.xl,
                padding: const EdgeInsets.all(20),
                borderColor: slide.isAiSlide
                    ? DarbColors.violetOf(context).withValues(alpha: 0.36)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      slide.title,
                      style: TextStyle(
                        color: DarbColors.inkOf(context),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      slide.subtitle,
                      style: TextStyle(
                        color: DarbColors.mutedOf(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (var i = 0; i < slide.highlights.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: slide.isAiSlide
                              ? DarbColors.violetSoftOf(context)
                                  .withValues(alpha: isDark ? 0.55 : 0.70)
                              : DarbColors.surfaceAltOf(context),
                          borderRadius: BorderRadius.circular(DarbRadius.md),
                          border: Border.all(
                            color: slide.isAiSlide
                                ? DarbColors.violetOf(context)
                                    .withValues(alpha: 0.25)
                                : DarbColors.borderOf(context),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              slide.highlights[i].$1,
                              size: 18,
                              color: slide.isAiSlide
                                  ? DarbColors.violetOf(context)
                                  : DarbColors.primaryOf(context),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                slide.highlights[i].$2,
                                style: TextStyle(
                                  color: DarbColors.inkOf(context),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
