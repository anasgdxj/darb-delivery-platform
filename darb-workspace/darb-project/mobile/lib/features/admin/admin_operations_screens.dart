import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<Map<String, dynamic>> _orders = const [];
  String _statusFilter = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final q = _statusFilter.isEmpty ? '' : '?status=$_statusFilter';
      final res = await Api.instance.get('/admin/orders$q');
      final rawList = res is Map ? (res['items'] as List? ?? []) : (res as List? ?? []);
      final list = rawList.whereType<Map<String, dynamic>>().toList();
      if (mounted) setState(() => _orders = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const DarbStateView.loading();
    if (_error != null) return DarbStateView.error(message: _error, onRetry: _load);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 108),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in [
                  ('', dt('الكل')),
                  ('PENDING', dt('قيد الانتظار')),
                  ('PREPARING', dt('قيد التحضير')),
                  ('ASSIGNED', dt('تم تعيين مندوب')),
                  ('DELIVERED', dt('تم التسليم')),
                  ('CANCELLED', dt('ملغى')),
                ]) ...[
                  ChoiceChip(
                    label: Text(f.$2),
                    selected: _statusFilter == f.$1,
                    onSelected: (_) {
                      setState(() => _statusFilter = f.$1);
                      _load();
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_orders.isEmpty)
            DarbStateView.empty(
              message: dt('لا توجد طلبات حتى الآن'),
              icon: Icons.receipt_long_outlined,
            )
          else
            for (final o in _orders)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DarbGlassSurface(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${o['orderNumber']} · ${o['city']?['code'] ?? ''}',
                              style: TextStyle(
                                color: DarbColors.inkOf(context),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          DarbStatusBadge(
                            status: o['status']?.toString() ?? 'PENDING',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${o['customer']?['name'] ?? ''} · ${o['customer']?['phone'] ?? o['customer']?['email'] ?? ''}',
                        style: TextStyle(
                          color: DarbColors.mutedOf(context),
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatDarbMoney(
                          num.tryParse(o['total']?.toString() ?? '0') ?? 0,
                          o['currency']?.toString() ?? 'SYP',
                        ),
                        style: TextStyle(
                          color: DarbColors.primaryOf(context),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class AdminOperationsScreen extends StatefulWidget {
  const AdminOperationsScreen({super.key});

  @override
  State<AdminOperationsScreen> createState() => _AdminOperationsScreenState();
}

class _AdminOperationsScreenState extends State<AdminOperationsScreen> {
  List<Map<String, dynamic>> _zones = const [];
  List<Map<String, dynamic>> _cities = const [];
  List<Map<String, dynamic>> _users = const [];
  Map<String, dynamic> _settings = const {};
  bool _hasExtendedSettings = false;
  bool _loading = true;
  String? _error;
  int _section = 0; // 0: zones & cities, 1: users, 2: settings

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        Api.instance.get('/admin/delivery-zones'),
        Api.instance.get('/cities'),
      ]);

      List<Map<String, dynamic>> cities =
          (results[1] as List? ?? []).whereType<Map<String, dynamic>>().toList();
      List<Map<String, dynamic>> users = const [];
      Map<String, dynamic> settings = const {};
      var hasSettings = false;

      try {
        final adminCities = await Api.instance.get('/admin/cities');
        if (adminCities is List && adminCities.isNotEmpty) {
          cities = adminCities.whereType<Map<String, dynamic>>().toList();
        }
      } catch (_) {}

      try {
        final u = await Api.instance.get('/admin/users?limit=30');
        final raw = u is Map ? (u['items'] as List? ?? []) : (u as List? ?? []);
        users = raw.whereType<Map<String, dynamic>>().toList();
      } catch (_) {}

      try {
        final s = await Api.instance.get('/admin/settings');
        if (s is Map<String, dynamic>) {
          settings = s;
          hasSettings = true;
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _zones = (results[0] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        _cities = cities;
        _users = users;
        _settings = settings;
        _hasExtendedSettings = hasSettings;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _cityLabel(Map<String, dynamic> city) {
    final code = darbLocale.value.languageCode;
    final names = (city['names'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    for (final n in names) {
      if (n['locale'] == code) return n['name']?.toString() ?? '';
    }
    return names.isNotEmpty
        ? names.first['name']?.toString() ?? city['code']?.toString() ?? ''
        : city['code']?.toString() ?? '';
  }

  Future<void> _openZoneDialog({Map<String, dynamic>? existing}) async {
    final selectableCities = existing == null
        ? _cities
            .where((c) => !_zones.any((z) => z['cityId'] == c['id']))
            .toList()
        : _cities;

    if (existing == null && selectableCities.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dt('لا توجد مدن أخرى تحتاج إلى إعداد رسوم'))),
        );
      }
      return;
    }

    final nameCtrl =
        TextEditingController(text: existing?['name']?.toString() ?? '');
    final baseCtrl =
        TextEditingController(text: existing?['feeBase']?.toString() ?? '5000');
    final kmCtrl =
        TextEditingController(text: existing?['feePerKm']?.toString() ?? '1000');
    String? cityId = existing?['cityId']?.toString() ??
        (selectableCities.isNotEmpty
            ? selectableCities.first['id']?.toString()
            : null);
    String? dlgError;
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(
            existing == null
                ? dt('إضافة منطقة توصيل')
                : dt('تعديل رسوم التوصيل'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (existing == null && selectableCities.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: cityId,
                    decoration: InputDecoration(labelText: dt('المدينة')),
                    items: [
                      for (final c in selectableCities)
                        DropdownMenuItem(
                          value: c['id'].toString(),
                          child: Text(_cityLabel(c)),
                        ),
                    ],
                    onChanged: (v) => setDlg(() => cityId = v),
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: dt('وصف إعداد الرسوم')),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: baseCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(labelText: dt('الرسم الأساسي (ل.س)')),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: kmCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: dt('الرسم لكل كيلومتر (ل.س)'),
                  ),
                ),
                if (dlgError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    dlgError!,
                    style: TextStyle(color: DarbColors.dangerOf(ctx), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: Text(dt('إلغاء')),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final feeBase = double.tryParse(baseCtrl.text.trim());
                      final feePerKm = double.tryParse(kmCtrl.text.trim());
                      if (nameCtrl.text.trim().isEmpty ||
                          feeBase == null ||
                          feePerKm == null ||
                          feeBase < 0 ||
                          feePerKm < 0) {
                        setDlg(() => dlgError =
                            dt('أدخل اسمًا ورسومًا رقمية غير سالبة'));
                        return;
                      }
                      setDlg(() {
                        saving = true;
                        dlgError = null;
                      });
                      try {
                        if (existing == null) {
                          await Api.instance.post('/admin/delivery-zones', {
                            'cityId': cityId,
                            'name': nameCtrl.text.trim(),
                            'feeBase': feeBase,
                            'feePerKm': feePerKm,
                          });
                        } else {
                          await Api.instance.patch(
                              '/admin/delivery-zones/${existing['id']}', {
                            'name': nameCtrl.text.trim(),
                            'feeBase': feeBase,
                            'feePerKm': feePerKm,
                          });
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _load();
                      } on ApiException catch (e) {
                        setDlg(() {
                          saving = false;
                          dlgError = e.message;
                        });
                      }
                    },
              child: Text(dt('حفظ')),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    baseCtrl.dispose();
    kmCtrl.dispose();
  }

  Future<void> _toggleCityActive(String id, bool isActive) async {
    try {
      await Api.instance.patch('/admin/cities/$id', {'isActive': isActive});
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _updatePlatformSetting(Map<String, dynamic> patch) async {
    try {
      final updated =
          await Api.instance.patch('/admin/settings', patch) as Map<String, dynamic>;
      if (mounted) setState(() => _settings = updated);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const DarbStateView.loading();
    if (_error != null) return DarbStateView.error(message: _error, onRetry: _load);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 108),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(dt('رسوم التوصيل')),
                  selected: _section == 0,
                  onSelected: (_) => setState(() => _section = 0),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(dt('المستخدمون والمدن')),
                  selected: _section == 1,
                  onSelected: (_) => setState(() => _section = 1),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(dt('الإعدادات والسجلات')),
                  selected: _section == 2,
                  onSelected: (_) => setState(() => _section = 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_section == 0) ...[
            DarbSectionHeader(
              title: dt('إعداد رسوم التوصيل'),
              trailing: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
                onPressed: () => _openZoneDialog(),
                icon: const Icon(Icons.add_rounded, size: 17),
                label: Text(dt('إضافة')),
              ),
            ),
            const SizedBox(height: 10),
            if (_zones.isEmpty)
              DarbStateView.empty(
                message: dt('لم تُضف رسوم توصيل بعد'),
                icon: Icons.payments_outlined,
              )
            else
              for (final z in _zones)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DarbGlassSurface(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                z['name']?.toString() ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                              Text(
                                '${z['city']?['code'] ?? ''} · ${formatDarbMoney(num.tryParse(z['feeBase']?.toString() ?? '0') ?? 0)} + ${formatDarbMoney(num.tryParse(z['feePerKm']?.toString() ?? '0') ?? 0)}/km',
                                style: TextStyle(
                                  color: DarbColors.mutedOf(context),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _openZoneDialog(existing: z),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            DarbSectionHeader(title: dt('المدن المدعومة')),
            const SizedBox(height: 10),
            for (final c in _cities)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DarbGlassSurface(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _cityLabel(c),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${dt('رمز المدينة: ')}${c['code']} · ${c['defaultCurrency']}',
                    ),
                    value: c['isActive'] == true,
                    onChanged: (v) => _toggleCityActive(c['id'].toString(), v),
                  ),
                ),
              ),
          ],
          if (_section == 1) ...[
            DarbSectionHeader(title: dt('المستخدمون والمدن')),
            const SizedBox(height: 10),
            if (_users.isEmpty)
              DarbStateView.empty(
                message: dt('لا توجد بيانات متاحة حالياً'),
                icon: Icons.people_outline_rounded,
              )
            else
              for (final u in _users)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DarbGlassSurface(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u['name']?.toString() ?? dt('مستخدم'),
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                u['phone']?.toString() ??
                                    u['email']?.toString() ??
                                    '',
                                style: TextStyle(
                                  color: DarbColors.mutedOf(context),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DarbStatusBadge(
                          status: u['role']?.toString() ?? 'CUSTOMER',
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          if (_section == 2) ...[
            DarbGlassSurface(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    dt('الإعدادات والسجلات'),
                    style: TextStyle(
                      color: DarbColors.inkOf(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!_hasExtendedSettings)
                    Text(
                      dt('الإعدادات المتقدمة تُدار من الخادم مباشرة.'),
                      style: TextStyle(color: DarbColors.mutedOf(context)),
                    )
                  else ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(dt('توصيل مستقل')),
                      value: _settings['peerDeliveryEnabled'] != false,
                      onChanged: (v) =>
                          _updatePlatformSetting({'peerDeliveryEnabled': v}),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(dt('المساعد الذكي')),
                      value: _settings['aiAssistantEnabled'] != false,
                      onChanged: (v) =>
                          _updatePlatformSetting({'aiAssistantEnabled': v}),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(dt('وضع الصيانة')),
                      value: _settings['maintenanceMode'] == true,
                      onChanged: (v) =>
                          _updatePlatformSetting({'maintenanceMode': v}),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
