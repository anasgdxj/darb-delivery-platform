import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/services/app_update_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/notifications_service.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_motion_components.dart';
import '../auth/login_screen.dart';
import '../customer/addresses_screen.dart';
import 'ai_role_assistant_screen.dart';
import 'driver_application_screen.dart';
import 'edit_profile_screen.dart';
import 'vendor_application_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.user,
    required this.onRefreshUser,
  });

  final Map<String, dynamic> user;
  final Future<void> Function() onRefreshUser;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _preferenceSaved = false;
  Timer? _savedTimer;

  @override
  void dispose() {
    _savedTimer?.cancel();
    super.dispose();
  }

  void _notifyPreferenceSaved() {
    DarbHaptics.selection();
    _savedTimer?.cancel();
    setState(() => _preferenceSaved = true);
    _savedTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _preferenceSaved = false);
    });
  }

  Future<void> _openEditProfile() async {
    DarbHaptics.selection();
    await Navigator.push<void>(
      context,
      DarbPageRoute(
        builder: (_) => EditProfileScreen(
          user: widget.user,
          onRefreshUser: widget.onRefreshUser,
        ),
      ),
    );
  }

  Future<void> _pickLanguage() async {
    final current = darbLocale.value.languageCode;
    final selected = await showDarbGlassModalSheet<String>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(ctx).t('languageTitle'),
            style: TextStyle(color: DarbColors.inkOf(ctx), fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          for (final item in [
            ('ar', 'العربية'),
            ('en', 'English'),
            ('tr', 'Türkçe'),
          ])
            ListTile(
              title: Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w800)),
              trailing: current == item.$1 ? Icon(Icons.check_circle_rounded, color: DarbColors.primaryOf(ctx)) : null,
              onTap: () => Navigator.pop(ctx, item.$1),
            ),
        ],
      ),
    );
    if (selected == null || selected == current) return;
    DarbHaptics.selection();
    darbLocale.value = Locale(selected);
    try {
      await Api.instance.patch('/auth/me', {'locale': selected});
      await widget.onRefreshUser();
    } catch (_) {}
  }

  Future<void> _openDriverApplication() async {
    DarbHaptics.selection();
    await Navigator.push<void>(
      context,
      DarbPageRoute(
        builder: (_) => DriverApplicationScreen(
          user: widget.user,
          onRefreshUser: widget.onRefreshUser,
        ),
      ),
    );
  }

  Future<void> _openVendorApplication() async {
    DarbHaptics.selection();
    await Navigator.push<void>(
      context,
      DarbPageRoute(
        builder: (_) => VendorApplicationScreen(
          user: widget.user,
          onRefreshUser: widget.onRefreshUser,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dt('تسجيل الخروج؟')),
        content: Text(dt('ستحتاج إلى تسجيل الدخول مجدداً للوصول إلى حسابك.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(dt('إلغاء'))),
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
    final role = widget.user['role']?.toString() ?? 'CUSTOMER';
    final driverApplication = widget.user['driverApplication']?.toString();
    final vendorApplication = widget.user['vendorApplication']?.toString();
    final roleLabel = switch (role) {
      'ADMIN' => dt('إدارة دَرْب'),
      'DRIVER' => dt('حساب سائق'),
      'VENDOR' => dt('حساب تاجر'),
      _ => dt('حساب عميل'),
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 108),
      children: [
        Container(
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
            boxShadow: DarbElevation.glow(DarbColors.forest, isDark: DarbColors.isDark(context)),
          ),
          child: Row(
            children: [
              const DarbBrandMark(size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user['name']?.toString().isNotEmpty == true
                          ? widget.user['name'].toString()
                          : dt('مرحباً بك في دَرْب'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user['phone']?.toString() ??
                          widget.user['email']?.toString() ??
                          roleLabel,
                      style: TextStyle(
                        color: DarbColors.mint.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DarbStatusBadge(status: role),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  foregroundColor: Colors.white,
                ),
                onPressed: _openEditProfile,
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        DarbGlassSurface(
          padding: const EdgeInsets.all(16),
          child: AnimatedBuilder(
            animation: appearance,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dt('نمط الواجهة'),
                        style: TextStyle(
                          color: DarbColors.inkOf(context),
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: DarbMotion.effectiveDuration(
                        context,
                        DarbMotion.fast,
                      ),
                      child: !_preferenceSaved
                          ? const SizedBox.shrink(key: ValueKey('no_save'))
                          : Container(
                              key: const ValueKey('saved'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: DarbColors.successOf(context)
                                    .withValues(alpha: 0.14),
                                borderRadius:
                                    BorderRadius.circular(DarbRadius.pill),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 14,
                                    color: DarbColors.successOf(context),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    dt('تم الحفظ'),
                                    style: TextStyle(
                                      color: DarbColors.successOf(context),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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
                    _notifyPreferenceSaved();
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  dt('مظهر التطبيق'),
                  style: TextStyle(
                    color: DarbColors.inkOf(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
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
                    _notifyPreferenceSaved();
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        DarbGlassSurface(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              _AccountActionTile(
                icon: Icons.manage_accounts_outlined,
                accentColor: DarbColors.primaryOf(context),
                title: dt('تعديل الملف الشخصي'),
                subtitle: dt('تحديث الاسم ولغة الواجهة ومراجعة بيانات التوثيق'),
                onTap: _openEditProfile,
              ),
              _AccountActionTile(
                icon: Icons.auto_awesome_rounded,
                accentColor: DarbColors.primaryOf(context),
                title: dt('مساعد دَرْب الشخصي'),
                onTap: () => Navigator.push(
                  context,
                  DarbPageRoute(builder: (_) => const AiRoleAssistantScreen()),
                ),
              ),
              if (role == 'CUSTOMER') ...[
                _AccountActionTile(
                  icon: Icons.location_on_outlined,
                  accentColor: DarbColors.infoOf(context),
                  title: dt('عناوين التوصيل'),
                  onTap: () => Navigator.push(
                    context,
                    DarbPageRoute(builder: (_) => const AddressesScreen()),
                  ),
                ),
                _AccountActionTile(
                  icon: Icons.delivery_dining_outlined,
                  accentColor: DarbColors.successOf(context),
                  title: dt('كن سائقاً في دَرْب'),
                  subtitle: driverApplication != null
                      ? dt('متابعة حالة طلب السائق المسجّل')
                      : dt('استقبل طلبات التوصيل وقدّم عروض الأجرة للعملاء'),
                  trailing: driverApplication != null
                      ? DarbStatusBadge(status: driverApplication)
                      : null,
                  onTap: _openDriverApplication,
                ),
                _AccountActionTile(
                  icon: Icons.storefront_outlined,
                  accentColor: DarbColors.warningOf(context),
                  title: dt('انضم بمتجرك'),
                  subtitle: vendorApplication != null
                      ? dt('متابعة حالة طلب المتجر المسجّل')
                      : dt('اعرض منتجات متجرك واستقبل طلبات العملاء'),
                  trailing: vendorApplication != null
                      ? DarbStatusBadge(status: vendorApplication)
                      : null,
                  onTap: _openVendorApplication,
                ),
              ],
              _AccountActionTile(
                icon: Icons.language_rounded,
                accentColor: DarbColors.primaryOf(context),
                title: dt('لغة التطبيق'),
                trailing: Text(
                  darbLocale.value.languageCode.toUpperCase(),
                  style: TextStyle(
                    color: DarbColors.primaryOf(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                onTap: _pickLanguage,
              ),
              if (!kDarbPlayStoreBuild)
                _AccountActionTile(
                  icon: Icons.system_update_rounded,
                  accentColor: DarbColors.infoOf(context),
                  title: dt('تحديث التطبيق'),
                  onTap: () async {
                    await DarbUpdater.instance.checkForUpdate(force: true);
                    if (!context.mounted) return;
                    final update = DarbUpdater.instance.availableUpdate.value;
                    if (update != null) {
                      showDialog<void>(
                        context: context,
                        builder: (_) => DarbUpdateDialog(info: update),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            DarbUpdater.instance.checkFailed
                                ? dt('تعذر التحقق من التحديث')
                                : dt('تطبيقك محدّث إلى آخر إصدار'),
                          ),
                        ),
                      );
                    }
                  },
                ),
              _AccountActionTile(
                icon: Icons.logout_rounded,
                accentColor: DarbColors.dangerOf(context),
                title: dt('تسجيل الخروج'),
                isDanger: true,
                onTap: _logout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountActionTile extends StatelessWidget {
  const _AccountActionTile({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.isDanger = false,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool isDanger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, size: 20, color: accentColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? accentColor : DarbColors.inkOf(context),
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing ??
          (isDanger ? null : const Icon(Icons.chevron_right_rounded)),
      onTap: onTap,
    );
  }
}
