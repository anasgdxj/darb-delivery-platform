import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/services/app_update_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/notifications_service.dart';
import '../../core/storage/local_cache.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_motion_components.dart';
import '../auth/login_screen.dart';
import '../auth/onboarding_screen.dart';
import '../customer/addresses_screen.dart';
import 'ai_role_assistant_screen.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.user,
    required this.onRefreshUser,
    this.saveLocaleOverride,
    this.syncNotificationsOverride,
    this.clearCacheOverride,
  });

  final Map<String, dynamic> user;
  final Future<void> Function() onRefreshUser;
  final Future<void> Function(String locale)? saveLocaleOverride;
  final Future<String?> Function()? syncNotificationsOverride;
  final Future<void> Function()? clearCacheOverride;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DarbFeedbackKind _feedbackKind = DarbFeedbackKind.success;
  String? _feedbackMessage;
  Timer? _feedbackTimer;
  bool _syncingPush = false;
  bool _clearingCache = false;
  bool _checkingUpdates = false;
  bool _loggingOut = false;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  void _showFeedback(DarbFeedbackKind kind, String message) {
    debugPrint('DAZREVO_SETTINGS_FEEDBACK kind=$kind message=$message');
    _feedbackTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _feedbackKind = kind;
      _feedbackMessage = message;
    });
    _feedbackTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _feedbackMessage = null);
    });
  }

  String _localeDisplayName(String code) => switch (code) {
        'en' => 'English',
        'tr' => 'Türkçe',
        _ => 'العربية',
      };

  String _textScaleLabel(double scale) {
    if (scale <= 0.94) return dt('صغير');
    if (scale >= 1.18) return dt('كبير جداً');
    if (scale >= 1.08) return dt('كبير');
    return dt('افتراضي');
  }

  Future<void> _openLanguageSheet() async {
    final initial = darbLocale.value.languageCode;
    var selected = initial;
    var saveState = DarbActionState.idle;
    var shakeTrigger = 0;
    String? errorMsg;

    await showDarbGlassModalSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final ink = DarbColors.inkOf(ctx);
          final muted = DarbColors.mutedOf(ctx);
          final primary = DarbColors.primaryOf(ctx);
          final busy = saveState == DarbActionState.loading;

          Future<void> save() async {
            if (busy) return;
            if (selected == initial) {
              Navigator.pop(ctx);
              return;
            }
            setSheet(() {
              saveState = DarbActionState.loading;
              errorMsg = null;
            });
            try {
              if (widget.saveLocaleOverride != null) {
                await widget.saveLocaleOverride!(selected);
              } else {
                await Api.instance.patch('/auth/me', {'locale': selected});
              }
              darbLocale.value = Locale(selected);
              try {
                await widget.onRefreshUser();
              } catch (_) {}
              if (!ctx.mounted) return;
              setSheet(() => saveState = DarbActionState.success);
              DarbHaptics.success();
              Navigator.pop(ctx);
              _showFeedback(
                DarbFeedbackKind.success,
                AppLocalizations(Locale(selected)).t('languageSaved'),
              );
            } on ApiException catch (e) {
              if (!ctx.mounted) return;
              DarbHaptics.error();
              setSheet(() {
                saveState = DarbActionState.error;
                errorMsg = e.message;
                shakeTrigger++;
              });
            } catch (_) {
              if (!ctx.mounted) return;
              DarbHaptics.error();
              setSheet(() {
                saveState = DarbActionState.error;
                errorMsg = dt('حدث خطأ غير متوقع، حاول مجدداً');
                shakeTrigger++;
              });
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(ctx).t('languageTitle'),
                style: TextStyle(
                  color: ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(ctx).t('languageSubtitle'),
                style: TextStyle(
                  color: muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              for (final item in const [
                ('ar', 'العربية', 'واجهة عربية كاملة واتجاه RTL'),
                ('en', 'English', 'Full English interface (LTR)'),
                ('tr', 'Türkçe', 'Tam Türkçe arayüz (LTR)'),
              ]) ...[
                DarbRadioOptionTile(
                  selected: selected == item.$1,
                  title: item.$2,
                  subtitle: dt(item.$3),
                  trailing: Text(
                    item.$1.toUpperCase(),
                    style: TextStyle(
                      color: selected == item.$1 ? primary : muted,
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                    ),
                  ),
                  onTap: busy
                      ? () {}
                      : () {
                          DarbHaptics.selection();
                          setSheet(() {
                            selected = item.$1;
                            errorMsg = null;
                            if (saveState != DarbActionState.idle) {
                              saveState = DarbActionState.idle;
                            }
                          });
                        },
                ),
                if (item.$1 != 'tr') const SizedBox(height: 8),
              ],
              if (errorMsg != null) ...[
                const SizedBox(height: 12),
                DarbFeedbackBanner(
                  kind: DarbFeedbackKind.error,
                  message: errorMsg!,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : () => Navigator.pop(ctx),
                      child: Text(dt('إلغاء')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DarbActionButton(
                      label: AppLocalizations.of(ctx).t('languageSave'),
                      loadingLabel:
                          AppLocalizations.of(ctx).t('languageSaving'),
                      successLabel: dt('تم الحفظ'),
                      icon: Icons.check_rounded,
                      state: saveState,
                      errorTrigger: shakeTrigger,
                      onPressed: busy ? null : save,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _syncPushNotifications() async {
    debugPrint('DAZREVO_SETTINGS_SYNC tapped override=${widget.syncNotificationsOverride != null}');
    if (_syncingPush) return;
    setState(() => _syncingPush = true);
    try {
      String? err;
      if (widget.syncNotificationsOverride != null) {
        err = await widget.syncNotificationsOverride!();
      } else {
        await DarbNotifications.register();
        err = DarbNotifications.lastError;
      }
      if (!mounted) return;
      if (err != null && err.isNotEmpty) {
        DarbHaptics.warning();
        _showFeedback(DarbFeedbackKind.warning, err);
      } else {
        DarbHaptics.success();
        _showFeedback(
          DarbFeedbackKind.success,
          dt('تم تحديث حالة مزامنة الإشعارات لهذا الجهاز'),
        );
      }
    } catch (_) {
      if (!mounted) return;
      DarbHaptics.error();
      _showFeedback(
        DarbFeedbackKind.error,
        dt('حدث خطأ غير متوقع، حاول مجدداً'),
      );
    } finally {
      if (mounted) setState(() => _syncingPush = false);
    }
  }

  Future<void> _confirmClearCache() async {
    if (_clearingCache) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dt('مسح البيانات المؤقتة؟')),
        content: Text(
          dt('سيتم حذف النسخ المحفوظة مؤقتاً فقط دون تسجيل خروجك أو المساس بحسابك.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(dt('إلغاء')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(dt('مسح المؤقت')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _clearingCache = true);
    try {
      if (widget.clearCacheOverride != null) {
        await widget.clearCacheOverride!();
      } else {
        await DarbLocalCache.instance.clearAll();
      }
      if (!mounted) return;
      DarbHaptics.success();
      _showFeedback(
        DarbFeedbackKind.success,
        dt('تم مسح البيانات المؤقتة بنجاح'),
      );
    } catch (_) {
      if (!mounted) return;
      DarbHaptics.error();
      _showFeedback(
        DarbFeedbackKind.error,
        dt('تعذر مسح البيانات المؤقتة، حاول مجدداً'),
      );
    } finally {
      if (mounted) setState(() => _clearingCache = false);
    }
  }

  Future<void> _openSecuritySheet() async {
    final phone = widget.user['phone']?.toString();
    final email = widget.user['email']?.toString();
    final role = widget.user['role']?.toString() ?? 'CUSTOMER';

    await showDarbGlassModalSheet<void>(
      context: context,
      builder: (ctx) {
        final ink = DarbColors.inkOf(ctx);
        final muted = DarbColors.mutedOf(ctx);
        final primary = DarbColors.primaryOf(ctx);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.verified_user_rounded, color: primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dt('حماية الحساب والجلسة'),
                    style: TextStyle(
                      color: ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                DarbStatusBadge(status: role),
              ],
            ),
            const SizedBox(height: 12),
            DarbFeedbackBanner(
              kind: DarbFeedbackKind.info,
              message: dt('يتم حفظ رموز الجلسة داخل التخزين المشفّر الآمن على جهازك مع تجديد تلقائي عند الانتهاء.'),
            ),
            const SizedBox(height: 12),
            if (phone != null && phone.isNotEmpty) ...[
              Text(
                dt('رقم الهاتف الموثّق'),
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    phone,
                    style: TextStyle(
                      color: ink,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (email != null && email.isNotEmpty) ...[
              Text(
                dt('البريد الإلكتروني الموثّق'),
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    email,
                    style: TextStyle(
                      color: ink,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(dt('إغلاق')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openPrivacySummarySheet() async {
    await showDarbGlassModalSheet<void>(
      context: context,
      builder: (ctx) {
        final ink = DarbColors.inkOf(ctx);
        final muted = DarbColors.mutedOf(ctx);
        final primary = DarbColors.primaryOf(ctx);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.privacy_tip_outlined, color: primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dt('الخصوصية وحماية البيانات'),
                    style: TextStyle(
                      color: ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              dt('تستخدم منصة دازريفو بياناتك الأساسية (الاسم، الهاتف أو البريد، وعناوين التوصيل التي تختارها) فقط لتنفيذ الطلبات والتواصل أثناء التوصيل.'),
              style: TextStyle(
                color: muted,
                fontSize: 13.5,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              dt('لا يتم تتبع موقع السائق إلا عند تفعيل حالة التوفر أثناء تنفيذ الطلبات النشطة، ويمكنك إيقاف التوفر في أي وقت من لوحة السائق.'),
              style: TextStyle(
                color: muted,
                fontSize: 13.5,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(dt('حسناً')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkUpdates() async {
    if (_checkingUpdates) return;
    setState(() => _checkingUpdates = true);
    try {
      await DarbUpdater.instance.checkForUpdate(force: true);
      if (!mounted) return;
      final update = DarbUpdater.instance.availableUpdate.value;
      if (update != null) {
        await showDialog<void>(
          context: context,
          builder: (_) => DarbUpdateDialog(info: update),
        );
      } else {
        _showFeedback(
          DarbUpdater.instance.checkFailed
              ? DarbFeedbackKind.warning
              : DarbFeedbackKind.info,
          DarbUpdater.instance.checkFailed
              ? dt('تعذر التحقق من التحديث')
              : dt('تطبيقك محدّث إلى آخر إصدار'),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingUpdates = false);
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dt('تسجيل الخروج؟')),
        content: Text(dt('ستحتاج إلى تسجيل الدخول مجدداً للوصول إلى حسابك.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(dt('إلغاء')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: DarbColors.dangerOf(ctx),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(dt('تسجيل الخروج')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _loggingOut = true);
    DarbHaptics.warning();
    DriverLocationReporter.stop();
    await DarbNotifications.unregister();
    await Api.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      DarbPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appearance = DarbAppearanceController.instance;
    final role = widget.user['role']?.toString().toUpperCase() ?? 'CUSTOMER';
    final primary = DarbColors.primaryOf(context);
    final muted = DarbColors.mutedOf(context);
    final ink = DarbColors.inkOf(context);
    final langCode = darbLocale.value.languageCode;

    return Scaffold(
      appBar: DarbGlassAppBar(
        title: dt('الإعدادات والتخصيص'),
        subtitle: dt('المظهر، إمكانية الوصول، الإشعارات، والخصوصية'),
      ),
      body: DarbAmbientBackground(
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: AnimatedBuilder(
                animation: appearance,
                builder: (context, _) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
                  children: [
                    AnimatedSwitcher(
                      duration: DarbMotion.effectiveDuration(
                        context,
                        DarbMotion.fast,
                      ),
                      child: _feedbackMessage == null
                          ? const SizedBox.shrink(key: ValueKey('no_feedback'))
                          : Padding(
                              key: ValueKey(_feedbackMessage),
                              padding: const EdgeInsets.only(bottom: 14),
                              child: DarbFeedbackBanner(
                                kind: _feedbackKind,
                                message: _feedbackMessage!,
                                onDismiss: () =>
                                    setState(() => _feedbackMessage = null),
                              ),
                            ),
                    ),
                    DarbGroupedSection(
                      title: dt('المظهر والعرض'),
                      subtitle: dt('خصص الألوان ونمط البطاقات ولغة التطبيق'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                dt('مظهر التطبيق'),
                                style: TextStyle(
                                  color: ink,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SegmentedButton<ThemeMode>(
                                segments: [
                                  ButtonSegment(
                                    value: ThemeMode.system,
                                    label: Text(dt('حسب الجهاز')),
                                  ),
                                  ButtonSegment(
                                    value: ThemeMode.light,
                                    label: Text(dt('نهاري')),
                                  ),
                                  ButtonSegment(
                                    value: ThemeMode.dark,
                                    label: Text(dt('ليلي')),
                                  ),
                                ],
                                selected: {appearance.themeMode},
                                onSelectionChanged: (s) {
                                  appearance.setThemeMode(s.first);
                                  DarbHaptics.selection();
                                  _showFeedback(
                                    DarbFeedbackKind.success,
                                    dt('تم حفظ تفضيلات العرض'),
                                  );
                                },
                              ),
                              const SizedBox(height: 14),
                              Text(
                                dt('نمط الواجهة'),
                                style: TextStyle(
                                  color: ink,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SegmentedButton<DarbVisualStyle>(
                                segments: [
                                  ButtonSegment(
                                    value: DarbVisualStyle.glass,
                                    label: Text(dt('زجاجي حديث (Glass)')),
                                  ),
                                  ButtonSegment(
                                    value: DarbVisualStyle.standard,
                                    label: Text(dt('كلاسيكي (Standard)')),
                                  ),
                                ],
                                selected: {appearance.visualStyle},
                                onSelectionChanged: (s) {
                                  appearance.setVisualStyle(s.first);
                                  DarbHaptics.selection();
                                  _showFeedback(
                                    DarbFeedbackKind.success,
                                    dt('تم حفظ تفضيلات العرض'),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        DarbSettingsTile(
                          icon: Icons.language_rounded,
                          accentColor: primary,
                          title: dt('لغة التطبيق'),
                          subtitle: dt('العربية RTL، الإنجليزية والتركية LTR'),
                          valueLabel: _localeDisplayName(langCode),
                          onTap: _openLanguageSheet,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    DarbGroupedSection(
                      title: dt('إمكانية الوصول والحركة'),
                      subtitle: dt('تحكم بحجم الخط وتقليل الحركة والتفاعل اللمسي'),
                      trailing: TextButton(
                        onPressed: () async {
                          await appearance.resetAccessibilityAndNotifications();
                          DarbHaptics.selection();
                          _showFeedback(
                            DarbFeedbackKind.info,
                            dt('تمت استعادة الإعدادات الافتراضية'),
                          );
                        },
                        child: Text(dt('استعادة الافتراضي')),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      dt('حجم النصوص'),
                                      style: TextStyle(
                                        color: ink,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _textScaleLabel(appearance.textScale),
                                    style: TextStyle(
                                      color: primary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final item in [
                                    (0.92, dt('صغير')),
                                    (1.0, dt('افتراضي')),
                                    (1.12, dt('كبير')),
                                    (1.22, dt('كبير جداً')),
                                  ])
                                    ChoiceChip(
                                      label: Text(item.$2),
                                      selected: (appearance.textScale - item.$1)
                                              .abs() <
                                          0.04,
                                      onSelected: (_) {
                                        appearance.setTextScale(item.$1);
                                        DarbHaptics.selection();
                                        _showFeedback(
                                          DarbFeedbackKind.success,
                                          dt('تم حفظ حجم النصوص'),
                                        );
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                dt('معاينة النص: هكذا ستظهر عناوين الطلبات وتفاصيلها.'),
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DarbSettingsTile(
                          icon: Icons.motion_photos_off_outlined,
                          accentColor: DarbColors.violetOf(context),
                          title: dt('تقليل الحركة والانتقالات'),
                          subtitle: dt('إيقاف التأثيرات المتكررة وتبسيط الانتقالات'),
                          showChevron: false,
                          trailing: Switch(
                            value: appearance.reduceMotionOverride,
                            onChanged: (v) {
                              appearance.setReduceMotionOverride(v);
                              _showFeedback(
                                DarbFeedbackKind.success,
                                dt('تم حفظ تفضيلات الوصول'),
                              );
                            },
                          ),
                          onTap: () {
                            appearance.setReduceMotionOverride(
                              !appearance.reduceMotionOverride,
                            );
                          },
                        ),
                        DarbSettingsTile(
                          icon: Icons.vibration_rounded,
                          accentColor: DarbColors.infoOf(context),
                          title: dt('الاهتزاز التفاعلي'),
                          subtitle: dt('استجابة لمسية لطيفة عند الضغط وتنفيذ الإجراءات'),
                          showChevron: false,
                          trailing: Switch(
                            value: appearance.hapticsEnabled,
                            onChanged: (v) {
                              appearance.setHapticsEnabled(v);
                              if (v) DarbHaptics.selection();
                              _showFeedback(
                                DarbFeedbackKind.success,
                                dt('تم حفظ تفضيلات الوصول'),
                              );
                            },
                          ),
                          onTap: () {
                            appearance
                                .setHapticsEnabled(!appearance.hapticsEnabled);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    DarbGroupedSection(
                      title: dt('تفضيلات الإشعارات'),
                      subtitle: dt('تحكم بالإشعارات الفورية ومزامنة الجهاز'),
                      children: [
                        DarbSettingsTile(
                          icon: Icons.notifications_active_outlined,
                          accentColor: primary,
                          title: dt('التنبيهات المباشرة داخل التطبيق'),
                          subtitle: dt('إظهار شريط علوي سريع عند وصول إشعار أثناء التصفح'),
                          showChevron: false,
                          trailing: Switch(
                            value: appearance.inAppBannersEnabled,
                            onChanged: (v) {
                              appearance.setInAppBannersEnabled(v);
                              DarbHaptics.selection();
                            },
                          ),
                          onTap: () => appearance.setInAppBannersEnabled(
                            !appearance.inAppBannersEnabled,
                          ),
                        ),
                        DarbSettingsTile(
                          icon: Icons.local_shipping_outlined,
                          accentColor: DarbColors.successOf(context),
                          title: dt('تنبيهات حالة الطلبات'),
                          subtitle: dt('تحديثات القبول والتحضير والتعيين والوصول'),
                          showChevron: false,
                          trailing: Switch(
                            value: appearance.orderAlertsEnabled,
                            onChanged: (v) {
                              appearance.setOrderAlertsEnabled(v);
                              DarbHaptics.selection();
                            },
                          ),
                          onTap: () => appearance.setOrderAlertsEnabled(
                            !appearance.orderAlertsEnabled,
                          ),
                        ),
                        DarbSettingsTile(
                          icon: Icons.campaign_outlined,
                          accentColor: DarbColors.warningOf(context),
                          title: dt('تنبيهات التحديثات والإعلانات'),
                          subtitle: dt('إصدارات التطبيق والتنبيهات العامة'),
                          showChevron: false,
                          trailing: Switch(
                            value: appearance.promoAlertsEnabled,
                            onChanged: (v) {
                              appearance.setPromoAlertsEnabled(v);
                              DarbHaptics.selection();
                            },
                          ),
                          onTap: () => appearance.setPromoAlertsEnabled(
                            !appearance.promoAlertsEnabled,
                          ),
                        ),
                        DarbSettingsTile(
                          icon: Icons.sync_rounded,
                          accentColor: DarbColors.infoOf(context),
                          title: dt('مزامنة إشعارات الجهاز'),
                          subtitle: dt('إعادة تسجيل رمز الجهاز لاستقبال الإشعارات الفورية'),
                          enabled: !_syncingPush,
                          trailing: _syncingPush
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : null,
                          onTap: _syncPushNotifications,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    DarbGroupedSection(
                      title: dt('الخصوصية والأمان'),
                      subtitle: dt('حماية الجلسة والبيانات المخزنة محلياً'),
                      children: [
                        DarbSettingsTile(
                          icon: Icons.verified_user_outlined,
                          accentColor: DarbColors.successOf(context),
                          title: dt('حماية الحساب والجلسة'),
                          subtitle: dt('مراجعة بيانات التوثيق وتشفير الجلسة النشطة'),
                          onTap: _openSecuritySheet,
                        ),
                        DarbSettingsTile(
                          icon: Icons.cleaning_services_outlined,
                          accentColor: DarbColors.warningOf(context),
                          title: dt('مسح البيانات المؤقتة'),
                          subtitle: dt('تحديث القوائم المحلية وحذف الملفات المخزنة مؤقتاً'),
                          enabled: !_clearingCache,
                          trailing: _clearingCache
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : null,
                          onTap: _confirmClearCache,
                        ),
                        DarbSettingsTile(
                          icon: Icons.privacy_tip_outlined,
                          accentColor: DarbColors.infoOf(context),
                          title: dt('الخصوصية وحماية البيانات'),
                          subtitle: dt('كيفية استخدام معلوماتك ومسار التوصيل بأمان'),
                          onTap: _openPrivacySummarySheet,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    DarbGroupedSection(
                      title: dt('إدارة الحساب والدعم'),
                      children: [
                        DarbSettingsTile(
                          icon: Icons.manage_accounts_outlined,
                          accentColor: primary,
                          title: dt('تعديل الملف الشخصي'),
                          subtitle: dt('تحديث الاسم ولغة الواجهة ومراجعة بيانات التوثيق'),
                          onTap: () => Navigator.push<void>(
                            context,
                            DarbPageRoute(
                              builder: (_) => EditProfileScreen(
                                user: widget.user,
                                onRefreshUser: widget.onRefreshUser,
                              ),
                            ),
                          ),
                        ),
                        if (role == 'CUSTOMER')
                          DarbSettingsTile(
                            icon: Icons.location_on_outlined,
                            accentColor: DarbColors.infoOf(context),
                            title: dt('عناوين التوصيل'),
                            subtitle: dt('إدارة عناوينك المحفوظة وتحديدها على الخريطة'),
                            onTap: () => Navigator.push<void>(
                              context,
                              DarbPageRoute(
                                builder: (_) => const AddressesScreen(),
                              ),
                            ),
                          ),
                        DarbSettingsTile(
                          icon: Icons.auto_awesome_rounded,
                          accentColor: DarbColors.violetOf(context),
                          title: dt('مساعد دازريفو الشخصي'),
                          subtitle: dt('احصل على إرشادات وإجابات فورية حسب دورك'),
                          onTap: () => Navigator.push<void>(
                            context,
                            DarbPageRoute(
                              builder: (_) => const AiRoleAssistantScreen(),
                            ),
                          ),
                        ),
                        DarbSettingsTile(
                          icon: Icons.auto_stories_outlined,
                          accentColor: primary,
                          title: dt('جولة تعريفية'),
                          onTap: () => Navigator.push<void>(
                            context,
                            DarbPageRoute(
                              builder: (_) => OnboardingScreen(
                                onFinished: () => Navigator.pop(context),
                              ),
                            ),
                          ),
                        ),
                        if (!kDarbPlayStoreBuild)
                          DarbSettingsTile(
                            icon: Icons.system_update_rounded,
                            accentColor: DarbColors.infoOf(context),
                            title: dt('تحديث التطبيق'),
                            enabled: !_checkingUpdates,
                            trailing: _checkingUpdates
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : null,
                            onTap: _checkUpdates,
                          ),
                        DarbSettingsTile(
                          icon: Icons.logout_rounded,
                          accentColor: DarbColors.dangerOf(context),
                          title: dt('تسجيل الخروج'),
                          isDanger: true,
                          enabled: !_loggingOut,
                          onTap: _logout,
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
    );
  }
}
