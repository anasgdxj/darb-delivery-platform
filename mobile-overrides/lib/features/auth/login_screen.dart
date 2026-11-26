import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/services/notifications_service.dart';
import '../../core/storage/local_cache.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_motion_components.dart';
import '../shell/app_shell.dart';
import 'login_hero_map.dart';
import 'onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();

  bool _otpSent = false;
  bool _loading = false;
  bool _googleLoading = false;
  DarbActionState _primaryState = DarbActionState.idle;
  DarbActionState _googleState = DarbActionState.idle;
  int _primaryErrorTrigger = 0;
  int _googleErrorTrigger = 0;
  String? _error;
  String? _statusMessage;
  String? _normalizedPhone;

  Timer? _resendTimer;
  int _resendCooldown = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendCooldown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _pauseForConfirmation() async {
    if (!mounted || DarbMotion.reduceMotion(context)) return;
    await Future<void>.delayed(const Duration(milliseconds: 360));
  }

  Future<void> _sendOtp({bool isResend = false}) async {
    final raw = isResend && _normalizedPhone != null
        ? _normalizedPhone!
        : _phoneController.text.trim();
    if (!isValidSyrianPhone(raw)) {
      setState(() {
        _primaryState = DarbActionState.error;
        _primaryErrorTrigger++;
        _statusMessage = null;
        _error = AppLocalizations.of(context).t('invalidPhone');
      });
      return;
    }
    final phone = normalizeSyrianPhone(raw)!;
    setState(() {
      _loading = true;
      _primaryState = DarbActionState.loading;
      _error = null;
      _statusMessage = null;
    });
    try {
      await Api.instance.post('/auth/otp/request', {'phone': phone});
      if (!mounted) return;
      _startResendCooldown();
      if (isResend) {
        DarbHaptics.success();
        setState(() {
          _primaryState = DarbActionState.idle;
          _statusMessage = dt('تم إرسال رمز تحقق جديد إلى هاتفك');
        });
      } else {
        setState(() => _primaryState = DarbActionState.success);
        await _pauseForConfirmation();
        if (!mounted) return;
        setState(() {
          _normalizedPhone = phone;
          _otpSent = true;
          _primaryState = DarbActionState.idle;
          _statusMessage = dt('أرسلنا رمزاً من 6 أرقام عبر رسالة نصية');
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _primaryState = DarbActionState.error;
          _primaryErrorTrigger++;
          _statusMessage = null;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _primaryState = DarbActionState.error;
          _primaryErrorTrigger++;
          _statusMessage = null;
          _error = AppLocalizations.of(context).t('networkError');
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.replaceAll(RegExp(r'\D'), '');
    if (code.length != 6 || _normalizedPhone == null) {
      setState(() {
        _primaryState = DarbActionState.error;
        _primaryErrorTrigger++;
        _statusMessage = null;
        _error = AppLocalizations.of(context).t('invalidOtp');
      });
      return;
    }
    setState(() {
      _loading = true;
      _primaryState = DarbActionState.loading;
      _error = null;
      _statusMessage = null;
    });
    try {
      final body = <String, dynamic>{
        'phone': _normalizedPhone,
        'code': code,
        'locale': darbLocale.value.languageCode,
        if (_nameController.text.trim().isNotEmpty)
          'name': _nameController.text.trim(),
      };
      final data =
          await Api.instance.post('/auth/otp/verify', body) as Map<String, dynamic>;
      final tokens = data['tokens'] is Map
          ? Map<String, dynamic>.from(data['tokens'] as Map)
          : data;
      await Api.instance.saveTokens(tokens);
      if (data['user'] is Map) {
        try {
          await DarbLocalCache.instance.writeJson(
            'auth_me_profile',
            Map<String, dynamic>.from(data['user'] as Map),
          );
        } catch (_) {}
      }
      await DarbNotifications.register();
      if (!mounted) return;
      setState(() {
        _primaryState = DarbActionState.success;
        _statusMessage = dt('تم التحقق بنجاح، جارٍ الدخول...');
      });
      await _pauseForConfirmation();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        DarbPageRoute(builder: (_) => const AppShell()),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _primaryState = DarbActionState.error;
          _primaryErrorTrigger++;
          _statusMessage = null;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _primaryState = DarbActionState.error;
          _primaryErrorTrigger++;
          _statusMessage = null;
          _error = AppLocalizations.of(context).t('networkError');
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_googleServerClientId.isEmpty) {
      setState(() {
        _googleState = DarbActionState.error;
        _googleErrorTrigger++;
        _statusMessage = null;
        _error = AppLocalizations.of(context).t('googleUnavailable');
      });
      return;
    }
    setState(() {
      _googleLoading = true;
      _googleState = DarbActionState.loading;
      _error = null;
      _statusMessage = null;
    });
    try {
      final signIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: _googleServerClientId,
      );
      await signIn.signOut();
      final account = await signIn.signIn();
      if (account == null) {
        if (mounted) {
          setState(() {
            _googleLoading = false;
            _googleState = DarbActionState.idle;
          });
        }
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const ApiException('تعذر استلام رمز المصادقة من Google');
      }
      final data = await Api.instance.post('/auth/google', {
        'idToken': idToken,
        'locale': darbLocale.value.languageCode,
      }) as Map<String, dynamic>;
      final tokens = data['tokens'] is Map
          ? Map<String, dynamic>.from(data['tokens'] as Map)
          : data;
      await Api.instance.saveTokens(tokens);
      if (data['user'] is Map) {
        try {
          await DarbLocalCache.instance.writeJson(
            'auth_me_profile',
            Map<String, dynamic>.from(data['user'] as Map),
          );
        } catch (_) {}
      }
      await DarbNotifications.register();
      if (!mounted) return;
      setState(() {
        _googleState = DarbActionState.success;
        _statusMessage = dt('تم التحقق عبر Google بنجاح، جارٍ الدخول...');
      });
      await _pauseForConfirmation();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        DarbPageRoute(builder: (_) => const AppShell()),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _googleState = DarbActionState.error;
          _googleErrorTrigger++;
          _statusMessage = null;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _googleState = DarbActionState.error;
          _googleErrorTrigger++;
          _statusMessage = null;
          _error = AppLocalizations.of(context).t('googleFailed');
        });
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = DarbColors.isDark(context);
    final screenH = MediaQuery.sizeOf(context).height;
    final heroHeight = screenH < 680 ? 290.0 : 334.0;
    final phoneValid = isValidSyrianPhone(_phoneController.text.trim());
    final otpDigits = _otpController.text.replaceAll(RegExp(r'\D'), '').length;

    return Scaffold(
      body: DarbAmbientBackground(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: heroHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DarbLoginVectorMap(),
                    SafeArea(
                      bottom: false,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          PositionedDirectional(
                            top: 10,
                            start: 16,
                            end: 16,
                            child: Row(
                              children: [
                                DarbGlassSurface(
                                  borderRadius: DarbRadius.pill,
                                  blurSigma: 14,
                                  elevated: false,
                                  tintColor: DarbColors.darkCanvas
                                      .withValues(alpha: 0.72),
                                  borderColor:
                                      DarbColors.lime.withValues(alpha: 0.34),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const DarbPulseDot(
                                        color: DarbColors.lime,
                                        size: 6.5,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        dt('شبكة التوصيل المباشر'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Tooltip(
                                  message: dt('جولة تعريفية'),
                                  child: DarbPressScale(
                                    borderRadius: DarbRadius.pill,
                                    onTap: () {
                                      Navigator.of(context).pushReplacement(
                                        DarbPageRoute(
                                          builder: (_) => const OnboardingScreen(),
                                        ),
                                      );
                                    },
                                    child: DarbGlassSurface(
                                      borderRadius: DarbRadius.pill,
                                      blurSigma: 14,
                                      elevated: false,
                                      tintColor: DarbColors.darkCanvas
                                          .withValues(alpha: 0.72),
                                      borderColor:
                                          Colors.white.withValues(alpha: 0.24),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.auto_stories_outlined,
                                            size: 14.5,
                                            color: DarbColors.lime,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            dt('جولة تعريفية'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                DarbGlassSurface(
                                  borderRadius: DarbRadius.pill,
                                  blurSigma: 14,
                                  elevated: false,
                                  tintColor: DarbColors.darkCanvas
                                      .withValues(alpha: 0.72),
                                  borderColor:
                                      Colors.white.withValues(alpha: 0.24),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.language_rounded,
                                        size: 14,
                                        color: DarbColors.lime,
                                      ),
                                      const SizedBox(width: 4),
                                      DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: const ['ar', 'en', 'tr'].contains(
                                            darbLocale.value.languageCode,
                                          )
                                              ? darbLocale.value.languageCode
                                              : 'ar',
                                          isDense: true,
                                          dropdownColor: DarbColors.forest,
                                          iconEnabledColor: Colors.white,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'ar',
                                              child: Text('AR'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'en',
                                              child: Text('EN'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'tr',
                                              child: Text('TR'),
                                            ),
                                          ],
                                          onChanged: (code) {
                                            if (code != null) {
                                              DarbHaptics.selection();
                                              darbLocale.value = Locale(code);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 48, 22, 26),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  DarbFadeSlide(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            boxShadow: DarbElevation.glow(
                                              DarbColors.lime,
                                              isDark: true,
                                            ),
                                          ),
                                          child: const DarbBrandMark(size: 46),
                                        ),
                                        const SizedBox(width: 11),
                                        Text(
                                          dt('دازريفو · DAZREVO'),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.25,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  DarbFadeSlide(
                                    delay: DarbMotion.staggerDelay(1),
                                    child: Text(
                                      l.t('welcomeTitle'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        height: 1.18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  DarbFadeSlide(
                                    delay: DarbMotion.staggerDelay(2),
                                    child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 320),
                                      child: Text(
                                        l.t('welcomeSubtitle'),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Color(0xFFD2E0D9),
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          height: 1.42,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  DarbFadeSlide(
                                    delay: DarbMotion.staggerDelay(3),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        _HeroFeatureChip(
                                          icon: Icons.storefront_rounded,
                                          label: l.t('featureStores'),
                                        ),
                                        _HeroFeatureChip(
                                          icon: Icons.delivery_dining_rounded,
                                          label: l.t('featureDelivery'),
                                        ),
                                        _HeroFeatureChip(
                                          icon: Icons.near_me_rounded,
                                          label: l.t('featureNearby'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DarbFadeSlide(
                        delay: DarbMotion.staggerDelay(2),
                        child: DarbGlassSurface(
                          borderRadius: DarbRadius.xl,
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _otpSent
                                              ? l.t('otpTitle')
                                              : l.t('phoneTitle'),
                                          style: TextStyle(
                                            color: DarbColors.inkOf(context),
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _otpSent
                                              ? l.t('otpSubtitle')
                                              : l.t('phoneSubtitle'),
                                          style: TextStyle(
                                            color: DarbColors.mutedOf(context),
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: DarbColors.primaryOf(context)
                                          .withValues(
                                              alpha: isDark ? 0.18 : 0.10),
                                      borderRadius: BorderRadius.circular(
                                          DarbRadius.pill),
                                      border: Border.all(
                                        color: DarbColors.primaryOf(context)
                                            .withValues(alpha: 0.28),
                                      ),
                                    ),
                                    child: Text(
                                      _otpSent ? '2 / 2' : '1 / 2',
                                      style: TextStyle(
                                        color: DarbColors.primaryOf(context),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w900,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              AnimatedSwitcher(
                                duration: DarbMotion.effectiveDuration(
                                  context,
                                  DarbMotion.standard,
                                ),
                                switchInCurve: DarbMotion.enter,
                                switchOutCurve: DarbMotion.exit,
                                transitionBuilder: (child, anim) {
                                  if (DarbMotion.reduceMotion(context)) {
                                    return child;
                                  }
                                  return FadeTransition(
                                    opacity: anim,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.04),
                                        end: Offset.zero,
                                      ).animate(anim),
                                      child: child,
                                    ),
                                  );
                                },
                                child: !_otpSent
                                    ? Column(
                                        key: const ValueKey('step_phone'),
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Directionality(
                                            textDirection: TextDirection.ltr,
                                            child: TextField(
                                              controller: _phoneController,
                                              keyboardType: TextInputType.phone,
                                              textInputAction:
                                                  TextInputAction.done,
                                              onChanged: (_) => setState(() {
                                                if (_error != null) {
                                                  _error = null;
                                                }
                                              }),
                                              onSubmitted: (_) {
                                                if (!_loading) _sendOtp();
                                              },
                                              inputFormatters: [
                                                SyrianPhoneFormatter(),
                                              ],
                                              decoration: InputDecoration(
                                                labelText: l.t('phoneLabel'),
                                                hintText: '09XX XXX XXX',
                                                prefixIcon: const Icon(
                                                  Icons.phone_android_rounded,
                                                ),
                                                suffixIcon: phoneValid
                                                    ? Icon(
                                                        Icons
                                                            .check_circle_rounded,
                                                        color: DarbColors
                                                            .successOf(context),
                                                      )
                                                    : (_phoneController
                                                            .text.isNotEmpty
                                                        ? IconButton(
                                                            onPressed: () {
                                                              _phoneController
                                                                  .clear();
                                                              setState(() =>
                                                                  _error =
                                                                      null);
                                                            },
                                                            icon: const Icon(
                                                              Icons
                                                                  .close_rounded,
                                                              size: 18,
                                                            ),
                                                          )
                                                        : null),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          DarbActionButton(
                                            label: l.t('sendOtp'),
                                            loadingLabel:
                                                dt('جارٍ إرسال الرمز...'),
                                            successLabel: dt('تم الإرسال'),
                                            icon: Icons.sms_outlined,
                                            state: _primaryState,
                                            errorTrigger: _primaryErrorTrigger,
                                            onPressed: (_loading ||
                                                    _googleLoading)
                                                ? null
                                                : () => _sendOtp(),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        key: const ValueKey('step_otp'),
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          if (_normalizedPhone != null)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                  bottom: 12),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: DarbColors.softSurfaceOf(
                                                    context),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  DarbRadius.sm,
                                                ),
                                                border: Border.all(
                                                  color: DarbColors.borderOf(
                                                      context),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.sms_outlined,
                                                    size: 18,
                                                    color: DarbColors.primaryOf(
                                                        context),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Directionality(
                                                      textDirection:
                                                          TextDirection.ltr,
                                                      child: Text(
                                                        _normalizedPhone!,
                                                        style: TextStyle(
                                                          color: DarbColors
                                                              .inkOf(context),
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: _loading
                                                        ? null
                                                        : () {
                                                            DarbHaptics.light();
                                                            _resendTimer
                                                                ?.cancel();
                                                            setState(() {
                                                              _otpSent = false;
                                                              _resendCooldown =
                                                                  0;
                                                              _primaryState =
                                                                  DarbActionState
                                                                      .idle;
                                                              _otpController
                                                                  .clear();
                                                              _error = null;
                                                              _statusMessage =
                                                                  null;
                                                            });
                                                          },
                                                    child: Text(
                                                      l.t('changePhone'),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          Directionality(
                                            textDirection: TextDirection.ltr,
                                            child: TextField(
                                              controller: _otpController,
                                              keyboardType:
                                                  TextInputType.number,
                                              textAlign: TextAlign.center,
                                              maxLength: 6,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 6,
                                                fontFeatures: [
                                                  FontFeature.tabularFigures(),
                                                ],
                                              ),
                                              onChanged: (_) => setState(() {
                                                if (_error != null) {
                                                  _error = null;
                                                }
                                              }),
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                              decoration: InputDecoration(
                                                labelText: l.t('otpLabel'),
                                                hintText: '• • • • • •',
                                                counterText: '',
                                                prefixIcon: const Icon(
                                                  Icons.pin_outlined,
                                                ),
                                                suffixIcon: otpDigits == 6
                                                    ? Icon(
                                                        Icons
                                                            .check_circle_rounded,
                                                        color: DarbColors
                                                            .successOf(context),
                                                      )
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          TextField(
                                            controller: _nameController,
                                            decoration: InputDecoration(
                                              labelText: l.t('nameLabel'),
                                              prefixIcon: const Icon(
                                                Icons.person_outline_rounded,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Align(
                                            alignment:
                                                AlignmentDirectional.centerEnd,
                                            child: TextButton.icon(
                                              onPressed: (_loading ||
                                                      _resendCooldown > 0)
                                                  ? null
                                                  : () => _sendOtp(
                                                      isResend: true),
                                              icon: const Icon(
                                                Icons.refresh_rounded,
                                                size: 16,
                                              ),
                                              label: Text(
                                                _resendCooldown > 0
                                                    ? '${dt('إعادة الإرسال بعد')} ${_resendCooldown}s'
                                                    : dt('إعادة إرسال الرمز'),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          DarbActionButton(
                                            label: l.t('verify'),
                                            loadingLabel:
                                                dt('جارٍ التحقق...'),
                                            successLabel: dt('تم الدخول'),
                                            icon: Icons.verified_rounded,
                                            state: _primaryState,
                                            errorTrigger: _primaryErrorTrigger,
                                            onPressed: (_loading ||
                                                    _googleLoading)
                                                ? null
                                                : _verifyOtp,
                                          ),
                                        ],
                                      ),
                              ),
                              AnimatedSize(
                                duration: DarbMotion.effectiveDuration(
                                  context,
                                  DarbMotion.interactive,
                                ),
                                curve: DarbMotion.enter,
                                child: _statusMessage == null || _error != null
                                    ? const SizedBox.shrink()
                                    : Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Container(
                                          padding: const EdgeInsets.all(11),
                                          decoration: BoxDecoration(
                                            color: DarbColors.successOf(context)
                                                .withValues(
                                                    alpha: isDark ? 0.18 : 0.10),
                                            borderRadius: BorderRadius.circular(
                                              DarbRadius.sm,
                                            ),
                                            border: Border.all(
                                              color:
                                                  DarbColors.successOf(context)
                                                      .withValues(alpha: 0.35),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle_outline_rounded,
                                                size: 18,
                                                color: DarbColors.successOf(
                                                    context),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _statusMessage!,
                                                  style: TextStyle(
                                                    color: DarbColors.successOf(
                                                        context),
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
                              AnimatedSize(
                                duration: DarbMotion.effectiveDuration(
                                  context,
                                  DarbMotion.interactive,
                                ),
                                curve: DarbMotion.enter,
                                child: _error == null
                                    ? const SizedBox.shrink()
                                    : Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: DarbShakeBox(
                                          trigger: _primaryErrorTrigger +
                                              _googleErrorTrigger,
                                          child: Container(
                                            padding: const EdgeInsets.all(11),
                                            decoration: BoxDecoration(
                                              color: DarbColors.dangerSoftOf(
                                                  context),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                DarbRadius.sm,
                                              ),
                                              border: Border.all(
                                                color:
                                                    DarbColors.dangerOf(context)
                                                        .withValues(alpha: 0.35),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.error_outline_rounded,
                                                  size: 18,
                                                  color: DarbColors.dangerOf(
                                                      context),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _error!,
                                                    style: TextStyle(
                                                      color:
                                                          DarbColors.dangerOf(
                                                              context),
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: DarbColors.borderOf(context),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      l.t('or'),
                                      style: TextStyle(
                                        color: DarbColors.mutedOf(context),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: DarbColors.borderOf(context),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              DarbActionButton(
                                label: l.t('google'),
                                loadingLabel:
                                    dt('جارٍ المصادقة عبر Google...'),
                                successLabel: dt('تم الدخول بنجاح'),
                                variant: DarbActionVariant.outlined,
                                state: _googleState,
                                errorTrigger: _googleErrorTrigger,
                                leading: const _GoogleEmblem(size: 20),
                                onPressed: (_loading || _googleLoading)
                                    ? null
                                    : _signInWithGoogle,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.verified_user_outlined,
                                    size: 15,
                                    color: DarbColors.primaryOf(context),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      l.t('secure'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: DarbColors.mutedOf(context),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _HeroFeatureChip extends StatelessWidget {
  const _HeroFeatureChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DarbRadius.pill),
        border: Border.all(color: DarbColors.lime.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.5, color: DarbColors.lime),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleEmblem extends StatelessWidget {
  const _GoogleEmblem({this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: const _GoogleEmblemPainter(),
        size: Size.square(size),
      ),
    );
  }
}

class _GoogleEmblemPainter extends CustomPainter {
  const _GoogleEmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;
    final stroke = size.width * 0.18;

    final rect = Rect.fromCircle(center: c, radius: r);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Blue right arc
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.25, 1.35, false, paint);
    // Green bottom arc
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 1.1, 1.35, false, paint);
    // Yellow left arc
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.45, 1.15, false, paint);
    // Red top arc
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.6, 1.9, false, paint);

    // Blue horizontal crossbar
    canvas.drawLine(
      Offset(c.dx, c.dy),
      Offset(c.dx + r + stroke * 0.35, c.dy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleEmblemPainter oldDelegate) => false;
}
