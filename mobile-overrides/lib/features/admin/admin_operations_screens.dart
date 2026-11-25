import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_motion_components.dart';

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
      final rawList =
          res is Map ? (res['items'] as List? ?? []) : (res as List? ?? []);
      final list = rawList.whereType<Map<String, dynamic>>().toList();
      if (mounted) setState(() => _orders = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = dt('حدث خطأ غير متوقع، حاول مجدداً'));
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
                  ('ACCEPTED', dt('مقبول')),
                  ('PREPARING', dt('قيد التحضير')),
                  ('READY', dt('جاهز للاستلام')),
                  ('ASSIGNED', dt('تم تعيين مندوب')),
                  ('PICKED_UP', dt('في الطريق إليك')),
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
              message: _statusFilter.isEmpty
                  ? dt('لا توجد طلبات حتى الآن')
                  : dt('لا توجد طلبات مطابقة للتصفية الحالية'),
              icon: _statusFilter.isEmpty
                  ? Icons.receipt_long_outlined
                  : Icons.filter_list_off_rounded,
              onRetry: _statusFilter.isEmpty
                  ? _load
                  : () {
                      setState(() => _statusFilter = '');
                      _load();
                    },
            )
          else
            for (final o in _orders)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DarbInteractiveCard(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: DarbColors.primaryOf(context)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              o['type'] == 'PEER_DELIVERY'
                                  ? Icons.local_shipping_rounded
                                  : Icons.storefront_rounded,
                              size: 19,
                              color: DarbColors.primaryOf(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${o['orderNumber']} · ${o['city']?['code'] ?? ''}',
                                  style: TextStyle(
                                    color: DarbColors.inkOf(context),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${o['customer']?['name'] ?? ''} · ${o['customer']?['phone'] ?? o['customer']?['email'] ?? ''}',
                                  style: TextStyle(
                                    color: DarbColors.mutedOf(context),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          DarbStatusBadge(
                            status: o['status']?.toString() ?? 'PENDING',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DarbOrderTimeline(
                        status: o['status']?.toString() ?? 'PENDING',
                        isPeer: o['type'] == 'PEER_DELIVERY',
                        compact: true,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: DarbColors.surfaceAltOf(context),
                          borderRadius: BorderRadius.circular(DarbRadius.sm),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              o['type'] == 'PEER_DELIVERY'
                                  ? dt('توصيل مستقل')
                                  : dt('طلب متجر'),
                              style: TextStyle(
                                color: DarbColors.mutedOf(context),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              formatDarbMoney(
                                num.tryParse(o['total']?.toString() ?? '0') ??
                                    0,
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
  final _userSearchCtrl = TextEditingController();
  final _commissionCtrl = TextEditingController();
  final _supportCtrl = TextEditingController();
  List<Map<String, dynamic>> _zones = const [];
  List<Map<String, dynamic>> _cities = const [];
  List<Map<String, dynamic>> _users = const [];
  List<Map<String, dynamic>> _auditLogs = const [];
  Map<String, dynamic> _settings = const {};
  bool _hasExtendedSettings = false;
  bool _loading = true;
  bool _savingSettings = false;
  String? _error;
  String? _partialError;
  int _section = 0; // 0: zones & cities, 1: users, 2: settings & audit
  final Set<String> _busyIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _userSearchCtrl.dispose();
    _commissionCtrl.dispose();
    _supportCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _partialError = null;
    });
    try {
      final results = await Future.wait([
        Api.instance.get('/admin/delivery-zones'),
        Api.instance.get('/cities'),
      ]);

      List<Map<String, dynamic>> cities =
          (results[1] as List? ?? []).whereType<Map<String, dynamic>>().toList();
      List<Map<String, dynamic>> users = const [];
      List<Map<String, dynamic>> logs = const [];
      Map<String, dynamic> settings = const {};
      var hasSettings = false;
      var hasPartialFailure = false;

      try {
        final adminCities = await Api.instance.get('/admin/cities');
        if (adminCities is List && adminCities.isNotEmpty) {
          cities = adminCities.whereType<Map<String, dynamic>>().toList();
        }
      } catch (_) {
        hasPartialFailure = true;
      }

      try {
        final q = _userSearchCtrl.text.trim();
        final path = q.isEmpty
            ? '/admin/users?limit=35'
            : '/admin/users?limit=35&q=${Uri.encodeQueryComponent(q)}';
        final u = await Api.instance.get(path);
        final raw = u is Map ? (u['items'] as List? ?? []) : (u as List? ?? []);
        users = raw.whereType<Map<String, dynamic>>().toList();
      } catch (_) {
        hasPartialFailure = true;
      }

      try {
        final s = await Api.instance.get('/admin/settings');
        if (s is Map<String, dynamic>) {
          settings = s;
          hasSettings = true;
          _commissionCtrl.text =
              s['commissionPercent']?.toString() ?? '10';
          _supportCtrl.text = s['supportContact']?.toString() ?? '';
        }
      } on ApiException catch (e) {
        if (e.statusCode != 404) hasPartialFailure = true;
      } catch (_) {
        hasPartialFailure = true;
      }

      try {
        final audit = await Api.instance.get('/admin/audit-logs?limit=25');
        if (audit is List) {
          logs = audit.whereType<Map<String, dynamic>>().toList();
        }
      } on ApiException catch (e) {
        if (e.statusCode != 404) hasPartialFailure = true;
      } catch (_) {
        hasPartialFailure = true;
      }

      if (!mounted) return;
      setState(() {
        _zones = (results[0] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        _cities = cities;
        _users = users;
        _auditLogs = logs;
        _settings = settings;
        _hasExtendedSettings = hasSettings;
        _partialError = hasPartialFailure
            ? dt('تعذر تحميل بعض البيانات الثانوية. أعد المحاولة لتحديثها.')
            : null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = dt('حدث خطأ غير متوقع، حاول مجدداً'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _cityLabel(Map<String, dynamic> city) {
    final code = darbLocale.value.languageCode;
    final names =
        (city['names'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    for (final n in names) {
      if (n['locale'] == code) return n['name']?.toString() ?? '';
    }
    return names.isNotEmpty
        ? names.first['name']?.toString() ?? city['code']?.toString() ?? ''
        : city['code']?.toString() ?? '';
  }

  Future<void> _openCreateCityDialog() async {
    final codeCtrl = TextEditingController();
    final arCtrl = TextEditingController();
    final enCtrl = TextEditingController();
    final curCtrl = TextEditingController(text: 'SYP');
    String? dlgError;
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(dt('إضافة مدينة')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeCtrl,
                  decoration: InputDecoration(
                    labelText: dt('رمز المدينة: '),
                    hintText: 'aleppo',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: arCtrl,
                  decoration: InputDecoration(labelText: dt('اسم المدينة بالعربية')),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: enCtrl,
                  decoration:
                      InputDecoration(labelText: dt('اسم المدينة بالإنجليزية')),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: curCtrl,
                  maxLength: 3,
                  decoration:
                      InputDecoration(labelText: dt('العملة الافتراضية')),
                ),
                if (dlgError != null)
                  Text(
                    dlgError!,
                    style: TextStyle(color: DarbColors.dangerOf(ctx), fontSize: 12),
                  ),
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
                      if (codeCtrl.text.trim().length < 2 ||
                          arCtrl.text.trim().isEmpty) {
                        setDlg(() => dlgError = dt('أدخل رمز المدينة واسمها العربي'));
                        return;
                      }
                      setDlg(() {
                        saving = true;
                        dlgError = null;
                      });
                      try {
                        await Api.instance.post('/admin/cities', {
                          'code': codeCtrl.text.trim().toLowerCase(),
                          'nameAr': arCtrl.text.trim(),
                          if (enCtrl.text.trim().isNotEmpty)
                            'nameEn': enCtrl.text.trim(),
                          if (curCtrl.text.trim().isNotEmpty)
                            'defaultCurrency':
                                curCtrl.text.trim().toUpperCase(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _load();
                      } on ApiException catch (e) {
                        setDlg(() {
                          saving = false;
                          dlgError = e.message;
                        });
                      } catch (_) {
                        setDlg(() {
                          saving = false;
                          dlgError = dt('حدث خطأ غير متوقع، حاول مجدداً');
                        });
                      }
                    },
              child: Text(dt('حفظ')),
            ),
          ],
        ),
      ),
    );
    codeCtrl.dispose();
    arCtrl.dispose();
    enCtrl.dispose();
    curCtrl.dispose();
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(labelText: dt('الرسم الأساسي (ل.س)')),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: kmCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: dt('الرسم لكل كيلومتر (ل.س)'),
                  ),
                ),
                if (dlgError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    dlgError!,
                    style:
                        TextStyle(color: DarbColors.dangerOf(ctx), fontSize: 12),
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
                      } catch (_) {
                        setDlg(() {
                          saving = false;
                          dlgError = dt('حدث خطأ غير متوقع، حاول مجدداً');
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

  Future<void> _deleteZone(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dt('حذف المنطقة')),
        content: Text(dt('تأكيد حذف منطقة التوصيل؟')),
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
            child: Text(dt('حذف المنطقة')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!_busyIds.add('zone_$id')) return;
    if (mounted) setState(() {});
    try {
      await Api.instance.delete('/admin/delivery-zones/$id');
      if (mounted) DarbHaptics.success();
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dt('حدث خطأ غير متوقع، حاول مجدداً'))),
        );
      }
    } finally {
      _busyIds.remove('zone_$id');
      if (mounted) setState(() {});
    }
  }

  Future<void> _changeUserRole(Map<String, dynamic> user) async {
    final currentRole = user['role']?.toString() ?? 'CUSTOMER';
    final selected = await showDarbGlassModalSheet<String>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${dt('تغيير الصلاحية')} · ${user['name'] ?? ''}',
            style: TextStyle(
              color: DarbColors.inkOf(ctx),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          for (final r in ['CUSTOMER', 'DRIVER', 'VENDOR', 'ADMIN'])
            ListTile(
              title: Text(r, style: const TextStyle(fontWeight: FontWeight.w800)),
              trailing: currentRole == r
                  ? Icon(
                      Icons.check_circle_rounded,
                      color: DarbColors.primaryOf(ctx),
                    )
                  : null,
              onTap: () => Navigator.pop(ctx, r),
            ),
        ],
      ),
    );
    if (selected == null || selected == currentRole) return;
    final uid = user['id'].toString();
    if (!_busyIds.add('user_$uid')) return;
    if (mounted) setState(() {});
    try {
      await Api.instance
          .patch('/admin/users/$uid/role', {'role': selected});
      if (mounted) DarbHaptics.success();
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dt('حدث خطأ غير متوقع، حاول مجدداً'))),
        );
      }
    } finally {
      _busyIds.remove('user_$uid');
      if (mounted) setState(() {});
    }
  }

  Future<void> _toggleCityActive(String id, bool isActive) async {
    if (!_busyIds.add('city_$id')) return;
    if (mounted) setState(() {});
    try {
      await Api.instance.patch('/admin/cities/$id', {'isActive': isActive});
      if (mounted) DarbHaptics.selection();
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dt('حدث خطأ غير متوقع، حاول مجدداً'))),
        );
      }
    } finally {
      _busyIds.remove('city_$id');
      if (mounted) setState(() {});
    }
  }

  Future<void> _updatePlatformSetting(Map<String, dynamic> patch) async {
    if (_savingSettings) return;
    setState(() => _savingSettings = true);
    try {
      final updated = await Api.instance.patch('/admin/settings', patch)
          as Map<String, dynamic>;
      if (mounted) {
        DarbHaptics.success();
        setState(() => _settings = updated);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dt('حدث خطأ غير متوقع، حاول مجدداً'))),
        );
      }
    } finally {
      if (mounted) setState(() => _savingSettings = false);
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
          if (_partialError != null) ...[
            DarbGlassSurface(
              tintColor: DarbColors.warningSoftOf(context),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: DarbColors.warningOf(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _partialError!,
                      style: TextStyle(
                        color: DarbColors.warningOf(context),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _load,
                    child: Text(dt('إعادة المحاولة')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
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
                onRetry: _load,
              )
            else
              for (final z in _zones)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DarbGlassSurface(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: DarbColors.primaryOf(context)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            Icons.route_rounded,
                            size: 19,
                            color: DarbColors.primaryOf(context),
                          ),
                        ),
                        const SizedBox(width: 11),
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
                        IconButton.filledTonal(
                          onPressed: () => _openZoneDialog(existing: z),
                          icon: const Icon(Icons.edit_outlined, size: 19),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: () => _deleteZone(z['id'].toString()),
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: DarbColors.dangerOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            DarbSectionHeader(
              title: dt('المدن المدعومة'),
              trailing: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36)),
                onPressed: _openCreateCityDialog,
                icon: const Icon(Icons.add_location_alt_outlined, size: 17),
                label: Text(dt('إضافة مدينة')),
              ),
            ),
            const SizedBox(height: 10),
            for (final c in _cities)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DarbGlassSurface(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: DarbColors.infoOf(context).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.location_city_rounded,
                        size: 18,
                        color: DarbColors.infoOf(context),
                      ),
                    ),
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
            Row(
              children: [
                Expanded(
                  child: DarbSearchBar(
                    controller: _userSearchCtrl,
                    hintText: dt('ابحث بالاسم أو الهاتف...'),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _load,
                  icon: const Icon(Icons.search_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_users.isEmpty)
              DarbStateView.empty(
                message: dt('لا توجد بيانات متاحة حالياً'),
                icon: Icons.people_outline_rounded,
                onRetry: _load,
              )
            else
              for (final u in _users)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DarbInteractiveCard(
                    onTap: _busyIds.contains('user_${u['id']}')
                        ? null
                        : () => _changeUserRole(u),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: DarbColors.primaryOf(context)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                            color: DarbColors.primaryOf(context),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u['name']?.toString() ?? dt('مستخدم'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
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
                        const SizedBox(width: 6),
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: DarbColors.mutedOf(context),
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
                    TextField(
                      controller: _commissionCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          InputDecoration(labelText: dt('نسبة العمولة (%)')),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _supportCtrl,
                      decoration:
                          InputDecoration(labelText: dt('تواصل الدعم')),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () {
                        final pct =
                            double.tryParse(_commissionCtrl.text.trim()) ?? 10;
                        _updatePlatformSetting({
                          'commissionPercent': pct.clamp(0, 50),
                          'supportContact': _supportCtrl.text.trim(),
                        });
                      },
                      child: Text(dt('حفظ التغييرات')),
                    ),
                    const Divider(height: 22),
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
            const SizedBox(height: 16),
            DarbSectionHeader(title: dt('سجل التدقيق')),
            const SizedBox(height: 10),
            if (_auditLogs.isEmpty)
              DarbGlassSurface(
                padding: const EdgeInsets.all(14),
                child: Text(
                  dt('لا توجد بيانات متاحة حالياً'),
                  style: TextStyle(color: DarbColors.mutedOf(context)),
                ),
              )
            else
              for (final l in _auditLogs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DarbGlassSurface(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: DarbColors.surfaceAltOf(context),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            size: 17,
                            color: DarbColors.primaryOf(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${l['action'] ?? ''} · ${l['targetType'] ?? ''}',
                                style: TextStyle(
                                  color: DarbColors.inkOf(context),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${l['actorRole'] ?? ''} · ${(l['createdAt']?.toString() ?? '').replaceFirst('T', ' ').substring(0, (l['createdAt']?.toString().length ?? 0).clamp(0, 16))}',
                                style: TextStyle(
                                  color: DarbColors.mutedOf(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
  }
}
