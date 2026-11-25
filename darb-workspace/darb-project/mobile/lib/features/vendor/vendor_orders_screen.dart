import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_map_picker.dart';
import '../../core/widgets/darb_motion_components.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> {
  Map<String, dynamic>? _vendor;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _orders = const [];
  String _statusFilter = '';
  bool _loading = true;
  bool _togglingOpen = false;
  String? _error;
  String? _statsError;
  final Set<String> _busyOrderIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _statsError = null;
    });
    try {
      final rawMine = await Api.instance.get('/vendors/mine');
      final mine = rawMine is Map<String, dynamic> ? rawMine : null;
      if (mine == null || mine['status'] != 'APPROVED') {
        if (!mounted) return;
        setState(() {
          _vendor = mine;
          _orders = const [];
          _stats = null;
        });
        return;
      }

      final ordersRaw = await Api.instance.get('/orders/vendor');
      Map<String, dynamic>? stats;
      String? statsError;
      try {
        final s = await Api.instance.get('/vendors/mine/stats');
        if (s is Map<String, dynamic>) stats = s;
      } on ApiException catch (e) {
        statsError = e.message;
      } catch (_) {
        statsError = dt('تعذر تحميل بعض البيانات الثانوية. أعد المحاولة لتحديثها.');
      }

      if (!mounted) return;
      setState(() {
        _vendor = mine;
        _orders =
            (ordersRaw as List? ?? []).whereType<Map<String, dynamic>>().toList();
        _stats = stats;
        _statsError = statsError;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = dt('حدث خطأ غير متوقع، حاول مجدداً'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _callPhone(String phone) async {
    try {
      final launched = await launchUrl(Uri.parse('tel:$phone'));
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dt('حدث خطأ غير متوقع، حاول مجدداً'))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dt('حدث خطأ غير متوقع، حاول مجدداً'))),
        );
      }
    }
  }

  Future<void> _toggleOpen(bool val) async {
    setState(() => _togglingOpen = true);
    try {
      await Api.instance.patch('/vendors/mine', {'isOpen': val});
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
      if (mounted) setState(() => _togglingOpen = false);
    }
  }

  Future<void> _editVendorProfile() async {
    final tr = (_vendor?['translations'] as List? ?? []);
    final nameCtrl = TextEditingController(
      text: tr.isNotEmpty ? tr.first['name']?.toString() ?? '' : '',
    );
    final descCtrl = TextEditingController(
      text: tr.isNotEmpty ? tr.first['description']?.toString() ?? '' : '',
    );
    final typeCtrl =
        TextEditingController(text: _vendor?['type']?.toString() ?? '');
    final addrCtrl = TextEditingController(
      text: _vendor?['location']?['address']?.toString() ?? '',
    );
    final loc = _vendor?['location'] is Map ? _vendor!['location'] as Map : null;
    double? lat = (loc?['latitude'] as num?)?.toDouble();
    double? lng = (loc?['longitude'] as num?)?.toDouble();
    String? err;
    var saving = false;

    await showDarbGlassModalSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              dt('تعديل بيانات المتجر'),
              style: TextStyle(
                color: DarbColors.inkOf(ctx),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: dt('اسم المتجر')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: typeCtrl,
              decoration: InputDecoration(labelText: dt('نوع النشاط')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: InputDecoration(labelText: dt('الوصف')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addrCtrl,
              decoration: InputDecoration(labelText: dt('عنوان المتجر (اختياري)')),
            ),
            const SizedBox(height: 12),
            DarbMapPicker(
              selectedLatitude: lat,
              selectedLongitude: lng,
              onPointSelected: (pickedLat, pickedLng) => setSheet(() {
                lat = pickedLat;
                lng = pickedLng;
                err = null;
              }),
            ),
            if (err != null) ...[
              const SizedBox(height: 8),
              Text(
                err!,
                style: TextStyle(
                  color: DarbColors.dangerOf(ctx),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final trimmedName = nameCtrl.text.trim();
                      if (trimmedName.isNotEmpty && trimmedName.length < 2) {
                        setSheet(() => err = dt('أدخل اسم المتجر (حرفان على الأقل)'));
                        return;
                      }
                      setSheet(() {
                        saving = true;
                        err = null;
                      });
                      try {
                        await Api.instance.patch('/vendors/mine', {
                          if (trimmedName.isNotEmpty) 'name': trimmedName,
                          if (typeCtrl.text.trim().isNotEmpty)
                            'type': typeCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'address': addrCtrl.text.trim(),
                          if (lat != null && lng != null)
                            ...{'latitude': lat, 'longitude': lng},
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _load();
                      } on ApiException catch (e) {
                        setSheet(() {
                          saving = false;
                          err = e.message;
                        });
                      } catch (_) {
                        setSheet(() {
                          saving = false;
                          err = dt('حدث خطأ غير متوقع، حاول مجدداً');
                        });
                      }
                    },
              child: Text(saving ? dt('جارٍ الحفظ') : dt('حفظ التغييرات')),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    descCtrl.dispose();
    typeCtrl.dispose();
    addrCtrl.dispose();
  }

  Future<void> _updateStatus(String orderId, String nextStatus) async {
    if (!_busyOrderIds.add(orderId)) return;
    if (mounted) setState(() {});
    try {
      await Api.instance.patch('/orders/$orderId/status', {'status': nextStatus});
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
      _busyOrderIds.remove(orderId);
      if (mounted) setState(() {});
    }
  }

  Future<void> _openOrderDetail(Map<String, dynamic> o) async {
    final items =
        (o['items'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    final currency = o['currency']?.toString() ?? 'SYP';
    final subtotal = num.tryParse(o['subtotal']?.toString() ?? '0') ?? 0;
    final customerName = o['customer']?['name']?.toString() ?? '';
    final customerPhone = o['customer']?['phone']?.toString();
    final driver = o['driver'] is Map ? o['driver'] as Map : null;
    final driverPhone = driver?['user']?['phone']?.toString();
    final addr = o['address']?['details']?.toString();

    await showDarbGlassModalSheet<void>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${dt('تفاصيل الطلب')} · ${o['orderNumber'] ?? ''}',
                  style: TextStyle(
                    color: DarbColors.inkOf(ctx),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              DarbStatusBadge(status: o['status']?.toString() ?? 'PENDING'),
            ],
          ),
          const SizedBox(height: 10),
          if (customerName.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: Text(
                    customerName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (customerPhone != null && customerPhone.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _callPhone(customerPhone),
                    icon: const Icon(Icons.call_rounded, size: 17),
                    label: Text(dt('اتصال بالعميل')),
                  ),
              ],
            ),
          if (addr != null && addr.isNotEmpty)
            Text(
              '${dt('عنوان التوصيل')}: $addr',
              style: TextStyle(color: DarbColors.mutedOf(ctx), fontSize: 13),
            ),
          if (driver != null) ...[
            const SizedBox(height: 8),
            DarbGlassSurface(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(
                    Icons.delivery_dining_rounded,
                    color: DarbColors.primaryOf(ctx),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      driver['user']?['name']?.toString() ?? dt('سائق معتمد'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (driverPhone != null && driverPhone.isNotEmpty)
                    IconButton(
                      onPressed: () => _callPhone(driverPhone),
                      icon: Icon(
                        Icons.call_rounded,
                        color: DarbColors.primaryOf(ctx),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const Divider(height: 20),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${item['nameSnapshot']} × ${item['quantity']}'),
                  ),
                  Text(
                    formatDarbMoney(
                      (num.tryParse(item['unitPrice']?.toString() ?? '0') ?? 0) *
                          ((item['quantity'] as num?) ?? 1),
                      currency,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          if (o['notes'] != null && o['notes'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              o['notes'].toString(),
              style: TextStyle(color: DarbColors.warningOf(ctx), fontSize: 13),
            ),
          ],
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dt('المجموع الفرعي التقريبي'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                formatDarbMoney(subtotal, currency),
                style: TextStyle(
                  color: DarbColors.primaryOf(ctx),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const DarbStateView.loading();
    if (_error != null) return DarbStateView.error(message: _error, onRetry: _load);
    final vendorStatus = _vendor?['status']?.toString();
    if (_vendor == null || vendorStatus != 'APPROVED') {
      final statusMsg = _vendor == null
          ? dt('ملف المتجر غير مكتمل بعد. تواصل مع الإدارة أو أعد المحاولة.')
          : (vendorStatus == 'PENDING'
              ? dt('طلب متجرك قيد المراجعة')
              : dt('حالة المتجر: $vendorStatus'));
      return RefreshIndicator(
        onRefresh: _load,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: DarbStateView.empty(
                message: statusMsg,
                icon: Icons.store_mall_directory_outlined,
                onRetry: _load,
              ),
            ),
          ),
        ),
      );
    }

    final vendorName = _vendor?['translations'] is List &&
            (_vendor!['translations'] as List).isNotEmpty
        ? (_vendor!['translations'] as List).first['name']?.toString() ??
            dt('متجر')
        : dt('متجر');
    final isOpen = _vendor?['isOpen'] != false;
    final stats = _stats;
    final statsCurrency = stats?['currency']?.toString() ?? 'SYP';
    final filtered = _statusFilter.isEmpty
        ? _orders
        : _orders.where((o) => o['status'] == _statusFilter).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 104),
        children: [
          DarbGlassSurface(
            padding: const EdgeInsets.all(16),
            borderColor: isOpen
                ? DarbColors.primaryOf(context).withValues(alpha: 0.24)
                : null,
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: DarbColors.primaryOf(context).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: DarbColors.primaryOf(context),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: DarbColors.inkOf(context),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          DarbPulseDot(
                            active: isOpen,
                            color: isOpen
                                ? DarbColors.successOf(context)
                                : DarbColors.dangerOf(context),
                            size: 7.5,
                          ),
                          const SizedBox(width: 6),
                          DarbStatusBadge(status: isOpen ? 'OPEN' : 'CLOSED'),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isOpen,
                  onChanged: _togglingOpen ? null : _toggleOpen,
                ),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  tooltip: dt('تعديل'),
                  onPressed: _editVendorProfile,
                  icon: const Icon(Icons.edit_outlined, size: 19),
                ),
              ],
            ),
          ),
          if (stats != null) ...[
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                DarbMetricCard(
                  label: dt('طلبات اليوم'),
                  value: '${stats['todayOrders'] ?? 0}',
                  icon: Icons.today_rounded,
                ),
                DarbMetricCard(
                  label: dt('مبيعات اليوم'),
                  value: formatDarbMoney(
                    (stats['todayRevenue'] as num?) ?? 0,
                    statsCurrency,
                  ),
                  icon: Icons.payments_outlined,
                ),
                DarbMetricCard(
                  label: dt('قيد التنفيذ'),
                  value: '${stats['activeOrders'] ?? 0}',
                  icon: Icons.pending_actions_rounded,
                ),
                DarbMetricCard(
                  label: dt('التقييم'),
                  value: ((stats['ratingAvg'] as num?) ?? 0) > 0
                      ? '${(stats['ratingAvg'] as num).toStringAsFixed(1)} ★'
                      : '—',
                  icon: Icons.star_outline_rounded,
                  accentColor: DarbColors.warningOf(context),
                ),
              ],
            ),
          ],
          if (_statsError != null) ...[
            const SizedBox(height: 12),
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
                      _statsError!,
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
          ],
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final pair in [
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
                    label: Text(pair.$2),
                    selected: _statusFilter == pair.$1,
                    onSelected: (_) => setState(() => _statusFilter = pair.$1),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            DarbStateView.empty(
              message: _orders.isEmpty
                  ? dt('لا توجد طلبات واردة')
                  : dt('لا توجد طلبات مطابقة للتصفية الحالية'),
              icon: _orders.isEmpty
                  ? Icons.receipt_long_outlined
                  : Icons.filter_list_off_rounded,
              onRetry: _orders.isEmpty
                  ? _load
                  : () => setState(() => _statusFilter = ''),
            )
          else
            for (final o in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildOrderCard(o),
              ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> o) {
    final id = o['id'].toString();
    final status = o['status']?.toString() ?? 'PENDING';
    final items =
        (o['items'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    final subtotal = num.tryParse(o['subtotal']?.toString() ?? '0') ?? 0;
    final currency = o['currency']?.toString() ?? 'SYP';

    final isBusy = _busyOrderIds.contains(id);

    return DarbInteractiveCard(
      onTap: () => _openOrderDetail(o),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${o['orderNumber']} · ${o['customer']?['name'] ?? ''}',
                  style: TextStyle(
                    color: DarbColors.inkOf(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              DarbStatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 10),
          DarbOrderTimeline(status: status, compact: true),
          const SizedBox(height: 8),
          for (final item in items.take(3))
            Text(
              '• ${item['nameSnapshot']} × ${item['quantity']}',
              style: TextStyle(
                color: DarbColors.mutedOf(context),
                fontSize: 13,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            formatDarbMoney(subtotal, currency),
            style: TextStyle(
              color: DarbColors.primaryOf(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          if (status == 'PENDING' ||
              status == 'ACCEPTED' ||
              status == 'PREPARING') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (status == 'PENDING') ...[
                  Expanded(
                    child: FilledButton(
                      onPressed: isBusy
                          ? null
                          : () => _updateStatus(id, 'ACCEPTED'),
                      child: isBusy
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(dt('قبول')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DarbColors.dangerOf(context),
                    ),
                    onPressed: isBusy
                        ? null
                        : () => _updateStatus(id, 'CANCELLED'),
                    child: Text(dt('رفض')),
                  ),
                ] else if (status == 'ACCEPTED')
                  Expanded(
                    child: FilledButton(
                      onPressed: isBusy
                          ? null
                          : () => _updateStatus(id, 'PREPARING'),
                      child: isBusy
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(dt('بدء التحضير')),
                    ),
                  )
                else if (status == 'PREPARING')
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          isBusy ? null : () => _updateStatus(id, 'READY'),
                      child: isBusy
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(dt('جاهز للاستلام')),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
