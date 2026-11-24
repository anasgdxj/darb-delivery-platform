import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/services/notifications_service.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_motion_components.dart';
import '../shell/app_shell.dart';
import 'login_hero_map.dart';

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
  String? _normalizedPhone;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pauseForConfirmation() async {
    if (!mounted || DarbMotion.reduceMotion(context)) return;
    await Future<void>.delayed(const Duration(milliseconds: 360));
  }

  Future<void> _sendOtp() async {
    final raw = _phoneController.text.trim();
    if (!isValidSyrianPhone(raw)) {
      setState(() {
        _primaryState = DarbActionState.error;
        _primaryErrorTrigger++;
        _error = AppLocalizations.of(context).t('invalidPhone');
      });
      return;
    }
    final phone = normalizeSyrianPhone(raw);
    setState(() {
      _loading = true;
      _primaryState = DarbActionState.loading;
      _error = null;
    });
    try {
      await Api.instance.post('/auth/otp/request', {'phone': phone});
      if (!mounted) return;
      setState(() => _primaryState = DarbActionState.success);
      await _pauseForConfirmation();
      if (!mounted) return;
      setState(() {
        _normalizedPhone = phone;
        _otpSent = true;
        _primaryState = DarbActionState.idle;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _primaryState = DarbActionState.error;
          _primaryErrorTrigger++;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _primaryState = DarbActionState.error;
          _primaryErrorTrigger++;
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
        _error = AppLocalizations.of(context).t('invalidOtp');
      });
      return;
    }
    setState(() {
      _loading = true;
      _primaryState = DarbActionState.loading;
      _error = null;
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
      await DarbNotifications.register();
      if (!mounted) return;
      setState(() => _primaryState = DarbActionState.success);
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
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _primaryState = DarbActionState.error;
          _primaryErrorTrigger++;
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
        _error = AppLocalizations.of(context).t('googleUnavailable');
      });
      return;
    }
    setState(() {
      _googleLoading = true;
      _googleState = DarbActionState.loading;
      _error = null;
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
      await DarbNotifications.register();
      if (!mounted) return;
      setState(() => _googleState = DarbActionState.success);
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
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _googleState = DarbActionState.error;
          _googleErrorTrigger++;
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

    return Scaffold(
      body: DarbAmbientBackground(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: 326,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DarbLoginVectorMap(),
                    SafeArea(
                      bottom: false,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Positioned(
                            top: 10,
                            left: 16,
                            child: DarbGlassSurface(
                              borderRadius: DarbRadius.pill,
                              blurSigma: 14,
                              tintColor:
                                  const Color(0xFF11221B).withValues(alpha: 0.56),
                              borderColor: Colors.white.withValues(alpha: 0.24),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: darbLocale.value.languageCode,
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
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 46, 22, 30),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const DarbBrandMark(size: 44),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'دَرْب • DARB',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 19,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l.t('welcomeTitle'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 27,
                                      fontWeight: FontWeight.w900,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 310),
                                    child: Text(
                                      l.t('welcomeSubtitle'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFFD0DBD5),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
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
                offset: const Offset(0, -18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DarbFadeSlide(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      .withValues(alpha: isDark ? 0.18 : 0.10),
                                  borderRadius:
                                      BorderRadius.circular(DarbRadius.pill),
                                  border: Border.all(
                                    color: DarbColors.primaryOf(context)
                                        .withValues(alpha: 0.25),
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
                          AnimatedSize(
                            duration: DarbMotion.effectiveDuration(
                              context,
                              DarbMotion.standard,
                            ),
                            curve: DarbMotion.enter,
                            alignment: Alignment.topCenter,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (!_otpSent) ...[
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: TextField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [SyrianPhoneFormatter()],
                                      decoration: InputDecoration(
                                        labelText: l.t('phoneLabel'),
                                        hintText: '09XX XXX XXX',
                                        prefixIcon: const Icon(Icons.phone_android_rounded),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  DarbActionButton(
                                    label: l.t('sendOtp'),
                                    state: _primaryState,
                                    errorTrigger: _primaryErrorTrigger,
                                    onPressed: _loading ? null : _sendOtp,
                                  ),
                                ] else ...[
                                  if (_normalizedPhone != null)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: DarbColors.softSurfaceOf(context),
                                        borderRadius: BorderRadius.circular(DarbRadius.sm),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.sms_outlined, size: 18, color: DarbColors.primaryOf(context)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Directionality(
                                              textDirection: TextDirection.ltr,
                                              child: Text(
                                                _normalizedPhone!,
                                                style: TextStyle(
                                                  color: DarbColors.inkOf(context),
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: _loading
                                                ? null
                                                : () {
                                                    DarbHaptics.light();
                                                    setState(() {
                                                      _otpSent = false;
                                                      _primaryState = DarbActionState.idle;
                                                      _otpController.clear();
                                                      _error = null;
                                                    });
                                                  },
                                            child: Text(l.t('changePhone')),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: TextField(
                                      controller: _otpController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 6,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: InputDecoration(
                                        labelText: l.t('otpLabel'),
                                        hintText: '123456',
                                        counterText: '',
                                        prefixIcon: const Icon(Icons.pin_outlined),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      labelText: l.t('nameLabel'),
                                      prefixIcon: const Icon(Icons.person_outline_rounded),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  DarbActionButton(
                                    label: l.t('verify'),
                                    state: _primaryState,
                                    errorTrigger: _primaryErrorTrigger,
                                    onPressed: _loading ? null : _verifyOtp,
                                  ),
                                ],
                                AnimatedSize(
                                  duration: DarbMotion.effectiveDuration(
                                    context,
                                    DarbMotion.interactive,
                                  ),
                                  curve: DarbMotion.enter,
                                  child: _error == null
                                      ? const SizedBox.shrink()
                                      : Padding(
                                          padding: const EdgeInsets.only(top: 14),
                                          child: DarbShakeBox(
                                            trigger: _primaryErrorTrigger +
                                                _googleErrorTrigger,
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: DarbColors.danger.withValues(alpha: isDark ? 0.2 : 0.1),
                                                borderRadius: BorderRadius.circular(DarbRadius.sm),
                                                border: Border.all(color: DarbColors.danger.withValues(alpha: 0.35)),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.error_outline_rounded,
                                                    size: 18,
                                                    color: DarbColors.dangerOf(context),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      _error!,
                                                      style: TextStyle(
                                                        color: DarbColors.dangerOf(context),
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(child: Divider(color: DarbColors.borderOf(context))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  l.t('or'),
                                  style: TextStyle(
                                    color: DarbColors.mutedOf(context),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: DarbColors.borderOf(context))),
                            ],
                          ),
                          const SizedBox(height: 14),
                          DarbActionButton(
                            label: l.t('google'),
                            variant: DarbActionVariant.outlined,
                            state: _googleState,
                            errorTrigger: _googleErrorTrigger,
                            leading: const Icon(Icons.g_mobiledata_rounded, size: 26),
                            onPressed: (_loading || _googleLoading)
                                ? null
                                : _signInWithGoogle,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified_user_outlined, size: 15, color: DarbColors.primaryOf(context)),
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
        border: Border.all(color: DarbColors.mint.withValues(alpha: 0.28)),
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
