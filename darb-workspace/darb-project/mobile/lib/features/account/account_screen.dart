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

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: widget.user['name']?.toString() ?? '');
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dt('تعديل الملف الشخصي')),
        content: TextField(controller: ctrl, decoration: InputDecoration(labelText: dt('الاسم'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(dt('إلغاء'))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(dt('حفظ التغييرات')),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (saved == null || saved.isEmpty) return;
    try {
      await Api.instance.patch('/auth/me', {'name': saved});
      await widget.onRefreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dt('تم تحديث بيانات حسابك'))));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
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

  Future<void> _applyDriver() async {
    final cities = (await Api.instance.get('/cities') as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    if (!mounted || cities.isEmpty) return;
    String cityId = cities.first['id'].toString();
    String vehicleType = 'MOTORCYCLE';
    String? err;

    await showDarbGlassModalSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(dt('طلب انضمام سائق'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: cityId,
              decoration: InputDecoration(labelText: dt('المدينة')),
              items: [
                for (final c in cities)
                  DropdownMenuItem(
                    value: c['id'].toString(),
                    child: Text(_cityName(c)),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setSheet(() => cityId = v);
              },
            ),
            const SizedBox(height: 14),
            Text(dt('نوع المركبة'), style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final v in [
                  ('BICYCLE', dt('دراجة هوائية')),
                  ('MOTORCYCLE', dt('دراجة نارية')),
                  ('CAR', dt('سيارة')),
                ])
                  ChoiceChip(
                    label: Text(v.$2),
                    selected: vehicleType == v.$1,
                    onSelected: (_) => setSheet(() => vehicleType = v.$1),
                  ),
              ],
            ),
            if (err != null) ...[
              const SizedBox(height: 10),
              Text(err!, style: TextStyle(color: DarbColors.dangerOf(ctx))),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                try {
                  await Api.instance.post('/drivers/apply', {
                    'cityId': cityId,
                    'vehicleType': vehicleType,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  await widget.onRefreshUser();
                } on ApiException catch (e) {
                  setSheet(() => err = e.message);
                }
              },
              child: Text(dt('إرسال الطلب')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyVendor() async {
    final cities = (await Api.instance.get('/cities') as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    if (!mounted || cities.isEmpty) return;
    String cityId = cities.first['id'].toString();
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    double? lat;
    double? lng;
    String? err;

    await showDarbGlassModalSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(dt('طلب انضمام متجر'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: dt('اسم المتجر'))),
            const SizedBox(height: 10),
            TextField(controller: typeCtrl, decoration: InputDecoration(labelText: dt('نوع النشاط'))),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: cityId,
              decoration: InputDecoration(labelText: dt('المدينة')),
              items: [
                for (final c in cities)
                  DropdownMenuItem(
                    value: c['id'].toString(),
                    child: Text(_cityName(c)),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setSheet(() => cityId = v);
              },
            ),
            const SizedBox(height: 10),
            TextField(controller: addrCtrl, decoration: InputDecoration(labelText: dt('عنوان المتجر (اختياري)'))),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final pos = await DarbLocationService.getCurrentPosition();
                  setSheet(() {
                    lat = pos.latitude;
                    lng = pos.longitude;
                  });
                } catch (_) {}
              },
              icon: Icon(lat != null ? Icons.check_circle_rounded : Icons.my_location_rounded),
              label: Text(lat != null ? dt('تم تحديد موقع المتجر') : dt('تحديد موقع المتجر')),
            ),
            if (err != null) ...[
              const SizedBox(height: 8),
              Text(err!, style: TextStyle(color: DarbColors.dangerOf(ctx))),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () async {
                try {
                  await Api.instance.post('/vendors/apply', {
                    'name': nameCtrl.text.trim(),
                    'type': typeCtrl.text.trim(),
                    'cityId': cityId,
                    if (addrCtrl.text.trim().isNotEmpty) 'address': addrCtrl.text.trim(),
                    if (lat != null && lng != null) ...{'latitude': lat, 'longitude': lng},
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  await widget.onRefreshUser();
                } on ApiException catch (e) {
                  setSheet(() => err = e.message);
                }
              },
              child: Text(dt('إرسال الطلب')),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    typeCtrl.dispose();
    addrCtrl.dispose();
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
            style: FilledButton.styleFrom(backgroundColor: DarbColors.danger),
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
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  String _cityName(Map<String, dynamic> city) {
    final code = darbLocale.value.languageCode;
    final names = (city['names'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    for (final n in names) {
      if (n['locale'] == code) return n['name']?.toString() ?? '';
    }
    return names.isNotEmpty
        ? names.first['name']?.toString() ?? city['code']?.toString() ?? ''
        : city['code']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final appearance = DarbAppearanceController.instance;
    final role = widget.user['role']?.toString() ?? 'CUSTOMER';
    final roleLabel = switch (role) {
      'ADMIN' => dt('إدارة دَرْب'),
      'DRIVER' => dt('حساب سائق'),
      'VENDOR' => dt('حساب تاجر'),
      _ => dt('حساب عميل'),
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 108),
      children: [
        DarbGlassSurface(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const DarbBrandMark(size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user['name']?.toString().isNotEmpty == true
                          ? widget.user['name'].toString()
                          : dt('مرحباً بك في دَرْب'),
                      style: TextStyle(color: DarbColors.inkOf(context), fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.user['phone']?.toString() ?? widget.user['email']?.toString() ?? roleLabel,
                      style: TextStyle(color: DarbColors.mutedOf(context), fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    DarbStatusBadge(status: role),
                  ],
                ),
              ),
              IconButton(onPressed: _editName, icon: const Icon(Icons.edit_outlined)),
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
                    ButtonSegment(value: DarbVisualStyle.glass, label: Text(dt('زجاجي حديث (Glass)'))),
                    ButtonSegment(value: DarbVisualStyle.standard, label: Text(dt('كلاسيكي (Standard)'))),
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
                  style: TextStyle(color: DarbColors.inkOf(context), fontWeight: FontWeight.w900, fontSize: 15),
                ),
                const SizedBox(height: 10),
                SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(value: ThemeMode.system, label: Text(dt('حسب الجهاز'))),
                    ButtonSegment(value: ThemeMode.light, label: Text(dt('نهاري'))),
                    ButtonSegment(value: ThemeMode.dark, label: Text(dt('ليلي'))),
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
              ListTile(
                leading: Icon(Icons.auto_awesome_rounded, color: DarbColors.primaryOf(context)),
                title: Text(dt('مساعد دَرْب الشخصي'), style: const TextStyle(fontWeight: FontWeight.w800)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AiRoleAssistantScreen()),
                ),
              ),
              if (role == 'CUSTOMER') ...[
                ListTile(
                  leading: Icon(Icons.location_on_outlined, color: DarbColors.primaryOf(context)),
                  title: Text(dt('عناوين التوصيل'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddressesScreen()),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.delivery_dining_outlined, color: DarbColors.primaryOf(context)),
                  title: Text(dt('كن سائقاً في دَرْب'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(dt('استقبل طلبات التوصيل وقدّم عروض الأجرة للعملاء')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _applyDriver,
                ),
                ListTile(
                  leading: Icon(Icons.storefront_outlined, color: DarbColors.primaryOf(context)),
                  title: Text(dt('انضم بمتجرك'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(dt('اعرض منتجات متجرك واستقبل طلبات العملاء')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _applyVendor,
                ),
              ],
              ListTile(
                leading: Icon(Icons.language_rounded, color: DarbColors.primaryOf(context)),
                title: Text(dt('لغة التطبيق'), style: const TextStyle(fontWeight: FontWeight.w800)),
                trailing: Text(darbLocale.value.languageCode.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
                onTap: _pickLanguage,
              ),
              ListTile(
                leading: Icon(Icons.system_update_rounded, color: DarbColors.primaryOf(context)),
                title: Text(dt('تحديث التطبيق'), style: const TextStyle(fontWeight: FontWeight.w800)),
                onTap: () async {
                  await DarbUpdater.instance.checkForUpdate(force: true);
                  if (!context.mounted) return;
                  final update = DarbUpdater.instance.availableUpdate.value;
                  if (update != null) {
                    showDialog<void>(context: context, builder: (_) => DarbUpdateDialog(info: update));
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
              ListTile(
                leading: Icon(Icons.logout_rounded, color: DarbColors.dangerOf(context)),
                title: Text(
                  dt('تسجيل الخروج'),
                  style: TextStyle(color: DarbColors.dangerOf(context), fontWeight: FontWeight.w800),
                ),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
