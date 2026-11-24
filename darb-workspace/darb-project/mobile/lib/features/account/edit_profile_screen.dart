import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_motion_components.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.user,
    required this.onRefreshUser,
    this.skipInitialFetch = false,
    this.loadMeOverride,
    this.saveProfileOverride,
  });

  final Map<String, dynamic> user;
  final Future<void> Function() onRefreshUser;
  final bool skipInitialFetch;
  final Future<Map<String, dynamic>> Function()? loadMeOverride;
  final Future<Map<String, dynamic>?> Function(Map<String, dynamic> payload)?
      saveProfileOverride;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late Map<String, dynamic> _profile;
  late final TextEditingController _nameCtrl;
  late String _selectedLocale;
  late String _initialName;
  late String _initialLocale;

  bool _loadingProfile = false;
  String? _loadError;
  String? _nameError;
  String? _submitError;
  bool _savedSuccess = false;
  DarbActionState _saveState = DarbActionState.idle;
  int _shakeTrigger = 0;

  @override
  void initState() {
    super.initState();
    _profile = Map<String, dynamic>.from(widget.user);
    _initialName = _profile['name']?.toString().trim() ?? '';
    final rawLocale =
        _profile['locale']?.toString() ?? darbLocale.value.languageCode;
    _initialLocale = const ['ar', 'en', 'tr'].contains(rawLocale)
        ? rawLocale
        : darbLocale.value.languageCode;
    _selectedLocale = _initialLocale;
    _nameCtrl = TextEditingController(text: _initialName);
    _nameCtrl.addListener(_onFormEdited);
    if (!widget.skipInitialFetch) {
      _refreshProfile();
    }
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onFormEdited);
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onFormEdited() {
    if (!mounted) return;
    setState(() {
      _nameError = null;
      _submitError = null;
      _savedSuccess = false;
      if (_saveState == DarbActionState.error ||
          _saveState == DarbActionState.success) {
        _saveState = DarbActionState.idle;
      }
    });
  }

  bool get _hasChanges =>
      _nameCtrl.text.trim() != _initialName ||
      _selectedLocale != _initialLocale;

  Future<void> _refreshProfile() async {
    setState(() {
      _loadingProfile = true;
      _loadError = null;
    });
    try {
      final data = widget.loadMeOverride != null
          ? await widget.loadMeOverride!()
          : await Api.instance.get('/auth/me');
      if (!mounted) return;
      if (data is Map<String, dynamic>) {
        final hadEdits = _hasChanges;
        setState(() {
          _profile = Map<String, dynamic>.from(data);
          final remoteName = _profile['name']?.toString().trim() ?? '';
          final remoteLocale = _profile['locale']?.toString() ?? 'ar';
          if (!hadEdits) {
            _initialName = remoteName;
            _nameCtrl.text = remoteName;
            if (const ['ar', 'en', 'tr'].contains(remoteLocale)) {
              _initialLocale = remoteLocale;
              _selectedLocale = remoteLocale;
            }
          }
          _loadingProfile = false;
        });
      } else {
        setState(() => _loadingProfile = false);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
        _loadError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
        _loadError = dt('تعذر تحميل أحدث بيانات الحساب');
      });
    }
  }

  String? _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return dt('أدخل الاسم الكامل للمتابعة');
    }
    if (trimmed.length < 2) {
      return dt('الاسم يجب أن يكون من حرفين على الأقل');
    }
    if (trimmed.length > 120) {
      return dt('الاسم طويل جداً (الحد الأقصى 120 حرفاً)');
    }
    return null;
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    final nameErr = _validateName(_nameCtrl.text);
    if (nameErr != null) {
      setState(() {
        _nameError = nameErr;
        _submitError = nameErr;
        _saveState = DarbActionState.error;
        _shakeTrigger++;
      });
      return;
    }

    final trimmedName = _nameCtrl.text.trim();
    final payload = <String, dynamic>{
      'name': trimmedName,
      'locale': _selectedLocale,
    };

    setState(() {
      _nameError = null;
      _submitError = null;
      _savedSuccess = false;
      _saveState = DarbActionState.loading;
    });

    try {
      final res = widget.saveProfileOverride != null
          ? await widget.saveProfileOverride!(payload)
          : await Api.instance.patch('/auth/me', payload);

      if (!mounted) return;
      if (darbLocale.value.languageCode != _selectedLocale) {
        darbLocale.value = Locale(_selectedLocale);
      }

      if (res is Map<String, dynamic>) {
        _profile = {
          ..._profile,
          ...res,
        };
      } else {
        _profile = {
          ..._profile,
          'name': trimmedName,
          'locale': _selectedLocale,
        };
      }

      await widget.onRefreshUser();
      if (!mounted) return;

      setState(() {
        _initialName = trimmedName;
        _initialLocale = _selectedLocale;
        _saveState = DarbActionState.success;
        _savedSuccess = true;
      });
      DarbHaptics.success();

      Future<void>.delayed(const Duration(milliseconds: 1400), () {
        if (mounted && _saveState == DarbActionState.success) {
          setState(() => _saveState = DarbActionState.idle);
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saveState = DarbActionState.error;
        _submitError = e.message;
        _shakeTrigger++;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saveState = DarbActionState.error;
        _submitError = dt('حدث خطأ غير متوقع، حاول مجدداً');
        _shakeTrigger++;
      });
    }
  }

  String _roleLabel(String role) => switch (role.toUpperCase()) {
        'ADMIN' => dt('إدارة دَرْب'),
        'DRIVER' => dt('حساب سائق'),
        'VENDOR' => dt('حساب تاجر'),
        _ => dt('حساب عميل'),
      };

  String _monogram(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return dt('د');
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = DarbColors.isDark(context);
    final ink = DarbColors.inkOf(context);
    final muted = DarbColors.mutedOf(context);
    final primary = DarbColors.primaryOf(context);
    final role = _profile['role']?.toString() ?? 'CUSTOMER';
    final phone = _profile['phone']?.toString();
    final email = _profile['email']?.toString();
    final driverApp = _profile['driverApplication']?.toString();
    final vendorApp = _profile['vendorApplication']?.toString();
    final displayName = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim()
        : (_profile['name']?.toString().trim().isNotEmpty == true
            ? _profile['name'].toString().trim()
            : dt('مرحباً بك في دَرْب'));

    return Scaffold(
      appBar: DarbGlassAppBar(
        title: dt('تعديل الملف الشخصي'),
        subtitle: dt('إدارة بيانات حسابك وتفضيلات اللغة'),
        actions: [
          IconButton(
            tooltip: dt('تحديث'),
            onPressed: _loadingProfile ? null : _refreshProfile,
            icon: _loadingProfile
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primary,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: DarbAmbientBackground(
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                children: [
                  DarbFadeSlide(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: AlignmentDirectional.topStart,
                          end: AlignmentDirectional.bottomEnd,
                          colors: [
                            DarbColors.forest,
                            DarbColors.forestSoft,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(DarbRadius.xl),
                        border: Border.all(
                          color: DarbColors.mint.withValues(alpha: 0.24),
                        ),
                        boxShadow: DarbElevation.glow(
                          DarbColors.forest,
                          isDark: isDark,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  DarbColors.mint.withValues(alpha: 0.28),
                                  DarbColors.lime.withValues(alpha: 0.22),
                                ],
                              ),
                              border: Border.all(
                                color: DarbColors.mint.withValues(alpha: 0.50),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _monogram(displayName),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _roleLabel(role),
                                  style: TextStyle(
                                    color: DarbColors.mint.withValues(alpha: 0.90),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    DarbStatusBadge(status: role),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(DarbRadius.pill),
                                        border: Border.all(
                                          color: DarbColors.mint
                                              .withValues(alpha: 0.30),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.verified_user_outlined,
                                            size: 13,
                                            color: DarbColors.lime,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            dt('هوية موثّقة'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_loadError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: DarbColors.warningSoftOf(context),
                        borderRadius: BorderRadius.circular(DarbRadius.md),
                        border: Border.all(
                          color: DarbColors.warningOf(context)
                              .withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            size: 18,
                            color: DarbColors.warningOf(context),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _loadError!,
                              style: TextStyle(
                                color: ink,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadingProfile ? null : _refreshProfile,
                            child: Text(dt('إعادة المحاولة')),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DarbFadeSlide(
                    delay: DarbMotion.staggerDelay(1),
                    child: DarbGlassSurface(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DarbSectionHeader(
                            title: dt('المعلومات الأساسية'),
                            subtitle: dt('تظهر هذه البيانات في الطلبات والتواصل'),
                          ),
                          const SizedBox(height: 14),
                          DarbShakeBox(
                            trigger: _shakeTrigger,
                            child: TextField(
                              controller: _nameCtrl,
                              maxLength: 120,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: dt('الاسم الكامل'),
                                hintText: dt('أدخل اسمك كما تحب أن يظهر في دَرْب'),
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                  color: primary,
                                ),
                                errorText: _nameError,
                                counterStyle: TextStyle(
                                  color: muted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            dt('لغة الواجهة المفضلة'),
                            style: TextStyle(
                              color: ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final item in [
                            ('ar', 'العربية', 'واجهة عربية كاملة واتجاه RTL'),
                            ('en', 'English', 'Full English interface (LTR)'),
                            ('tr', 'Türkçe', 'Tam Türkçe arayüz (LTR)'),
                          ]) ...[
                            DarbRadioOptionTile(
                              selected: _selectedLocale == item.$1,
                              title: item.$2,
                              subtitle: dt(item.$3),
                              trailing: Text(
                                item.$1.toUpperCase(),
                                style: TextStyle(
                                  color: _selectedLocale == item.$1
                                      ? primary
                                      : muted,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              onTap: () {
                                DarbHaptics.selection();
                                setState(() {
                                  _selectedLocale = item.$1;
                                  _submitError = null;
                                  _savedSuccess = false;
                                  if (_saveState != DarbActionState.idle) {
                                    _saveState = DarbActionState.idle;
                                  }
                                });
                              },
                            ),
                            if (item.$1 != 'tr') const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DarbFadeSlide(
                    delay: DarbMotion.staggerDelay(2),
                    child: DarbGlassSurface(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DarbSectionHeader(
                            title: dt('بيانات التوثيق والحساب'),
                            subtitle: dt('بيانات محمية مرتبطة بطريقة تسجيل دخولك'),
                          ),
                          const SizedBox(height: 14),
                          _VerifiedInfoRow(
                            icon: Icons.phone_android_rounded,
                            label: dt('رقم الهاتف'),
                            value: (phone != null && phone.isNotEmpty)
                                ? phone
                                : dt('غير مرتبط'),
                            isLtrValue: phone != null && phone.isNotEmpty,
                            badgeLabel: dt('موثّق'),
                            accentColor: primary,
                          ),
                          const SizedBox(height: 10),
                          _VerifiedInfoRow(
                            icon: Icons.alternate_email_rounded,
                            label: dt('البريد الإلكتروني'),
                            value: (email != null && email.isNotEmpty)
                                ? email
                                : dt('غير مرتبط'),
                            isLtrValue: email != null && email.isNotEmpty,
                            badgeLabel: (email != null && email.isNotEmpty)
                                ? 'Google'
                                : null,
                            accentColor: DarbColors.infoOf(context),
                          ),
                          const SizedBox(height: 10),
                          _VerifiedInfoRow(
                            icon: Icons.badge_outlined,
                            label: dt('نوع الحساب'),
                            value: _roleLabel(role),
                            trailing: DarbStatusBadge(status: role),
                            accentColor: DarbColors.warningOf(context),
                          ),
                          if (driverApp != null || vendorApp != null) ...[
                            const SizedBox(height: 10),
                            if (driverApp != null)
                              _VerifiedInfoRow(
                                icon: Icons.delivery_dining_outlined,
                                label: dt('طلب انضمام سائق'),
                                value: dt('حالة الطلب المسجّلة'),
                                trailing: DarbStatusBadge(status: driverApp),
                                accentColor: DarbColors.successOf(context),
                              ),
                            if (driverApp != null && vendorApp != null)
                              const SizedBox(height: 10),
                            if (vendorApp != null)
                              _VerifiedInfoRow(
                                icon: Icons.storefront_outlined,
                                label: dt('طلب انضمام متجر'),
                                value: dt('حالة الطلب المسجّلة'),
                                trailing: DarbStatusBadge(status: vendorApp),
                                accentColor: DarbColors.warningOf(context),
                              ),
                          ],
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: DarbColors.softSurfaceOf(context),
                              borderRadius: BorderRadius.circular(DarbRadius.sm),
                              border:
                                  Border.all(color: DarbColors.borderOf(context)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 16,
                                  color: muted,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    dt('لتغيير رقم الهاتف أو البريد المرتبط بحسابك تواصل مع دعم دَرْب لحماية أمان حسابك.'),
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
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
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: DarbMotion.effectiveDuration(
                      context,
                      DarbMotion.fast,
                    ),
                    child: _submitError != null
                        ? Container(
                            key: ValueKey('err_$_submitError'),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: DarbColors.dangerSoftOf(context),
                              borderRadius:
                                  BorderRadius.circular(DarbRadius.md),
                              border: Border.all(
                                color: DarbColors.dangerOf(context)
                                    .withValues(alpha: 0.35),
                              ),
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
                                    _submitError!,
                                    style: TextStyle(
                                      color: DarbColors.dangerOf(context),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : (_savedSuccess
                            ? Container(
                                key: const ValueKey('saved_banner'),
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? DarbColors.forestSoft
                                      : DarbColors.mintTint,
                                  borderRadius:
                                      BorderRadius.circular(DarbRadius.md),
                                  border: Border.all(
                                    color: DarbColors.successOf(context)
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 18,
                                      color: DarbColors.successOf(context),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        dt('تم تحديث بيانات حسابك'),
                                        style: TextStyle(
                                          color: DarbColors.successOf(context),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(key: ValueKey('no_banner'))),
                  ),
                  DarbActionButton(
                    label: dt('حفظ التغييرات'),
                    loadingLabel: dt('جارٍ الحفظ'),
                    successLabel: dt('تم الحفظ'),
                    icon: Icons.check_rounded,
                    state: _saveState,
                    errorTrigger: _shakeTrigger,
                    onPressed: _saveState == DarbActionState.loading
                        ? null
                        : _saveProfile,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerifiedInfoRow extends StatelessWidget {
  const _VerifiedInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    this.isLtrValue = false,
    this.badgeLabel,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final bool isLtrValue;
  final String? badgeLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ink = DarbColors.inkOf(context);
    final muted = DarbColors.mutedOf(context);

    final valueText = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: ink,
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: DarbColors.softSurfaceOf(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(DarbRadius.md),
        border: Border.all(color: DarbColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                isLtrValue
                    ? Directionality(
                        textDirection: TextDirection.ltr,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: valueText,
                        ),
                      )
                    : valueText,
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (badgeLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(DarbRadius.pill),
              ),
              child: Text(
                badgeLabel!,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
