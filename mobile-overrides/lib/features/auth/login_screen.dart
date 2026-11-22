import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/services/notifications_service.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../shell/app_shell.dart';
import 'darb_animated_map_hero.dart';

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
  String? _error;
  String? _normalizedPhone;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final raw = _phoneController.text.trim();
    if (!isValidSyrianPhone(raw)) {
      setState(() => _error = AppLocalizations.of(context).t('invalidPhone'));
      return;
    }
    final phone = normalizeSyrianPhone(raw);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Api.instance.post('/auth/otp/request', {'phone': phone});
      if (!mounted) return;
      setState(() {
        _normalizedPhone = phone;
        _otpSent = true;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).t('networkError'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.replaceAll(RegExp(r'\D'), '');
    if (code.length != 6 || _normalizedPhone == null) {
      setState(() => _error = AppLocalizations.of(context).t('invalidOtp'));
      return;
    }
    setState(() {
      _loading = true;
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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).t('networkError'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_googleServerClientId.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).t('googleUnavailable'));
      return;
    }
    setState(() {
      _googleLoading = true;
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
        if (mounted) setState(() => _googleLoading = false);
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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).t('googleFailed'));
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
              child: DarbAnimatedMapHero(
                title: l.t('welcomeTitle'),
                subtitle: l.t('welcomeSubtitle'),
                localeCode: darbLocale.value.languageCode,
                onLocaleChanged: (code) => darbLocale.value = Locale(code),
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
                          Text(
                            _otpSent ? l.t('otpTitle') : l.t('phoneTitle'),
                            style: TextStyle(
                              color: DarbColors.inkOf(context),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _otpSent ? l.t('otpSubtitle') : l.t('phoneSubtitle'),
                            style: TextStyle(
                              color: DarbColors.mutedOf(context),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 18),
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
                            FilledButton(
                              onPressed: _loading ? null : _sendOtp,
                              child: _loading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: DarbColors.onPrimaryOf(context),
                                      ),
                                    )
                                  : Text(l.t('sendOtp')),
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
                                          : () => setState(() {
                                                _otpSent = false;
                                                _otpController.clear();
                                                _error = null;
                                              }),
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
                            FilledButton(
                              onPressed: _loading ? null : _verifyOtp,
                              child: _loading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: DarbColors.onPrimaryOf(context),
                                      ),
                                    )
                                  : Text(l.t('verify')),
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: DarbColors.danger.withValues(alpha: isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(DarbRadius.sm),
                                border: Border.all(color: DarbColors.danger.withValues(alpha: 0.35)),
                              ),
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
                          OutlinedButton.icon(
                            onPressed: (_loading || _googleLoading) ? null : _signInWithGoogle,
                            icon: _googleLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.g_mobiledata_rounded, size: 26),
                            label: Text(l.t('google')),
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
