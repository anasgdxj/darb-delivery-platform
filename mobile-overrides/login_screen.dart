import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/api.dart';
import '../main.dart';
import '../localizations.dart';
import '../design_system.dart';
import 'city_carousel.dart';
import 'app_shell.dart';

const _googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final phone = TextEditingController();
  final code = TextEditingController();
  final name = TextEditingController();
  bool sent = false, busy = false, googleLoading = false;
  String? error;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: DarbMotion.expressive,
  )..forward();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _shakeX = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: -9), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -9, end: 9), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 9, end: -6), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
  ]).animate(CurvedAnimation(parent: _shake, curve: Curves.easeOut));

  bool get validPhone =>
      RegExp(r'^09[3-9][0-9]{7}$').hasMatch(digits);
  String get digits => phone.text.replaceAll(RegExp(r'\D'), '');
  bool get authenticating => busy || googleLoading;

  @override
  void dispose() {
    phone.dispose();
    code.dispose();
    name.dispose();
    _entrance.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() => error = message);
    _shake.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  Future<void> requestCode() async {
    final l = AppLocalizations.of(context);
    if (!validPhone) {
      _fail(l.t('invalidPhone'));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() { busy = true; error = null; });
    try {
      await Api.instance.post('/auth/otp/request', {
        'phone': '+963${digits.substring(1)}',
      });
      if (mounted) setState(() => sent = true);
    } on ApiException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail(l.t('networkError'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> verify() async {
    final l = AppLocalizations.of(context);
    if (code.text.trim().length != 6) {
      _fail(l.t('invalidOtp'));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() { busy = true; error = null; });
    try {
      final result = await Api.instance.post('/auth/otp/verify', {
        'phone': '+963${digits.substring(1)}',
        'code': code.text.trim(),
        'name': name.text.trim().isEmpty ? null : name.text.trim(),
        'locale': darbLocale.value.languageCode,
      });
      await Api.instance.saveTokens(
        Map<String, dynamic>.from(result['tokens'] as Map),
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppShell()),
        );
      }
    } on ApiException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail(l.t('networkError'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final l = AppLocalizations.of(context);
    if (authenticating) return;
    setState(() { googleLoading = true; error = null; });
    try {
      if (_googleServerClientId.isEmpty) {
        throw StateError('GOOGLE_SERVER_CLIENT_ID is missing from this release build');
      }
      final google = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: _googleServerClientId,
      );
      final account = await google.signIn();
      if (account == null) return;
      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError(
          'Google returned no ID token. Check Android OAuth package name and release SHA-1.',
        );
      }
      final result = await Api.instance.post('/auth/google', {
        'idToken': idToken,
        'locale': darbLocale.value.languageCode,
      });
      await Api.instance.saveTokens(
        Map<String, dynamic>.from(result['tokens'] as Map),
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppShell()),
        );
      }
    } catch (_) {
      _fail(l.t('googleFailed'));
    } finally {
      if (mounted) setState(() => googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: DarbColors.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _entrance,
                    curve: DarbMotion.enter,
                  ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, .035),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _entrance,
                      curve: DarbMotion.enter,
                    )),
                    child: AnimatedBuilder(
                      animation: _shake,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(_shakeX.value, 0),
                        child: child,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _languageBar(),
                          const SizedBox(height: 18),
                          _brandPanel(l),
                          const SizedBox(height: 18),
                          _formPanel(l, isRtl),
                          const SizedBox(height: 18),
                          _securityNote(l),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _languageBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Tooltip(
          message: isDark ? dt('التبديل إلى الوضع النهاري') : dt('التبديل إلى الوضع الليلي'),
          child: IconButton(
            onPressed: authenticating
                ? null
                : () => DarbTheme.setMode(
                      isDark ? ThemeMode.light : ThemeMode.dark,
                    ),
            style: IconButton.styleFrom(
              backgroundColor: DarbColors.surface,
              foregroundColor: DarbColors.brandForeground,
              side: BorderSide(color: DarbColors.line),
              shape: const CircleBorder(),
              fixedSize: const Size(44, 44),
            ),
            icon: AnimatedSwitcher(
              duration: DarbMotion.standard,
              switchInCurve: DarbMotion.enter,
              switchOutCurve: DarbMotion.exit,
              transitionBuilder: (child, animation) => RotationTransition(
                turns: Tween<double>(begin: -.18, end: 0).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                key: ValueKey(isDark),
              ),
            ),
          ),
        ),
        _languageChip('AR', const Locale('ar')),
        const SizedBox(width: 6),
        _languageChip('EN', const Locale('en')),
        const SizedBox(width: 6),
        _languageChip('TR', const Locale('tr')),
      ],
    );
  }

  Widget _brandPanel(AppLocalizations l) => Container(
    decoration: BoxDecoration(
      color: DarbColors.brandForeground,
      borderRadius: BorderRadius.circular(DarbRadius.hero),
      boxShadow: DarbElevation.floating,
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      children: [
        const Positioned.fill(child: DarbCityCarousel()),
        PositionedDirectional(
          top: -55,
          end: -48,
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .07), width: 22),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: DarbColors.lime,
                    borderRadius: BorderRadius.circular(19),
                    boxShadow: [
                      BoxShadow(
                        color: DarbColors.lime.withValues(alpha: .2),
                        blurRadius: 22,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'د',
                    style: TextStyle(
                      color: DarbColors.brandForeground,
                      fontSize: 37,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(DarbRadius.pill),
                    border: Border.all(color: Colors.white.withValues(alpha: .12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.route_rounded, color: DarbColors.lime, size: 15),
                      SizedBox(width: 6),
                      Text(
                        'DARB',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Text(
              l.t('welcomeTitle'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                height: 1.25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              l.t('welcomeSubtitle'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: .72),
                fontSize: 13,
                height: 1.65,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _featurePill(Icons.storefront_rounded, l.t('featureStores')),
                _featurePill(Icons.local_shipping_rounded, l.t('featureDelivery')),
                _featurePill(Icons.near_me_rounded, l.t('featureNearby')),
              ],
            ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _featurePill(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(DarbRadius.pill),
      border: Border.all(color: Colors.white.withValues(alpha: .10)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: DarbColors.lime, size: 13),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _formPanel(AppLocalizations l, bool isRtl) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: DarbColors.surface,
      borderRadius: BorderRadius.circular(DarbRadius.xl),
      border: Border.all(color: DarbColors.line),
      boxShadow: DarbElevation.card,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          sent ? l.t('otpTitle') : l.t('phoneTitle'),
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            color: DarbColors.ink,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          sent ? l.t('otpSubtitle') : l.t('phoneSubtitle'),
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            color: DarbColors.muted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        if (!sent) ...[
          Text(
            l.t('phoneLabel'),
            style: TextStyle(
              color: DarbColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          _phoneField(),
        ] else ...[
          TextField(
            controller: code,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: TextStyle(
              fontSize: 23,
              letterSpacing: 9,
              fontWeight: FontWeight.w800,
              color: DarbColors.ink,
            ),
            decoration: _inputDecoration(l.t('otpLabel')),
            onChanged: (_) {
              if (error != null) setState(() => error = null);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: name,
            decoration: _inputDecoration(l.t('nameLabel')),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: authenticating
                  ? null
                  : () => setState(() {
                        sent = false;
                        code.clear();
                        error = null;
                      }),
              child: Text(l.t('changePhone')),
            ),
          ),
        ],
        AnimatedSize(
          duration: DarbMotion.standard,
          curve: DarbMotion.enter,
          child: error == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DarbColors.danger.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(DarbRadius.md),
                      border: Border.all(
                        color: DarbColors.danger.withValues(alpha: .18),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: DarbColors.danger,
                          size: 19,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            error!,
                            style: TextStyle(
                              color: DarbColors.danger,
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 17),
        SizedBox(
          height: 55,
          child: FilledButton(
            onPressed: authenticating || (!sent && !validPhone)
                ? null
                : (sent ? verify : requestCode),
            style: FilledButton.styleFrom(
              backgroundColor: DarbColors.primary,
              foregroundColor: DarbColors.onPrimary,
              disabledBackgroundColor: DarbColors.borderStrong,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DarbRadius.md),
              ),
              elevation: 0,
            ),
            child: busy
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        sent ? l.t('verify') : l.t('sendOtp'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Icon(
                        isRtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                    ],
                  ),
          ),
        ),
        if (!sent) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  l.t('or'),
                  style: TextStyle(
                    color: DarbColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 54,
            child: OutlinedButton(
              onPressed: authenticating ? null : _handleGoogleSignIn,
              style: OutlinedButton.styleFrom(
                backgroundColor: DarbColors.surface,
                foregroundColor: DarbColors.ink,
                side: BorderSide(color: DarbColors.line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DarbRadius.md),
                ),
              ),
              child: googleLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DarbColors.brandForeground,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _googleMark(),
                        const SizedBox(width: 10),
                        Text(
                          l.t('google'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _securityNote(AppLocalizations l) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.verified_user_outlined,
        size: 15,
        color: DarbColors.muted,
      ),
      const SizedBox(width: 7),
      Flexible(
        child: Text(
          l.t('secure'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: DarbColors.muted,
            fontSize: 10,
            height: 1.45,
          ),
        ),
      ),
    ],
  );

  Widget _languageChip(String label, Locale locale) {
    final selected = darbLocale.value.languageCode == locale.languageCode;
    return InkWell(
      borderRadius: BorderRadius.circular(DarbRadius.pill),
      onTap: authenticating ? null : () => darbLocale.value = locale,
      child: AnimatedContainer(
        duration: DarbMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? DarbColors.forest : DarbColors.surface,
          borderRadius: BorderRadius.circular(DarbRadius.pill),
          border: Border.all(
            color: selected ? DarbColors.forest : DarbColors.line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : DarbColors.muted,
          ),
        ),
      ),
    );
  }

  Widget _phoneField() => Directionality(
    textDirection: TextDirection.ltr,
    child: AnimatedContainer(
      duration: DarbMotion.fast,
      height: 60,
      decoration: BoxDecoration(
        color: DarbColors.surface,
        borderRadius: BorderRadius.circular(DarbRadius.md),
        border: Border.all(
          color: validPhone ? DarbColors.success : DarbColors.line,
          width: validPhone ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: double.infinity,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: DarbColors.line)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🇸🇾', style: TextStyle(fontSize: 19)),
                SizedBox(width: 7),
                Text(
                  '+963',
                  style: TextStyle(
                    color: DarbColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              enabled: !authenticating,
              inputFormatters: [SyrianPhoneFormatter()],
              style: TextStyle(
                color: DarbColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: .3,
              ),
              decoration: const InputDecoration(
                hintText: '09X XXX XXXX',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 13),
              ),
              onChanged: (_) => setState(() => error = null),
            ),
          ),
          if (validPhone)
            Padding(
              padding: EdgeInsetsDirectional.only(end: 12),
              child: Icon(
                Icons.check_circle_rounded,
                color: DarbColors.success,
                size: 20,
              ),
            ),
        ],
      ),
    ),
  );

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: DarbColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(DarbRadius.md),
      borderSide: BorderSide(color: DarbColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(DarbRadius.md),
      borderSide: BorderSide(color: DarbColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(DarbRadius.md),
      borderSide: BorderSide(color: DarbColors.primary, width: 1.5),
    ),
  );

  Widget _googleMark() => Container(
    width: 25,
    height: 25,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(DarbRadius.pill),
      border: Border.all(color: DarbColors.line),
    ),
    child: const Text(
      'G',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: Color(0xFF4285F4),
      ),
    ),
  );
}

class SyrianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(RegExp(r'\D'), '');
    final digits = raw.length > 10 ? raw.substring(0, 10) : raw;
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) out.write(' ');
      out.write(digits[i]);
    }
    final text = out.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
