import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> {
  Map<String, dynamic>? _vendor;
  List<Map<String, dynamic>> _orders = const [];
  String _statusFilter = '';
  bool _loading = true;
  bool _togglingOpen = false;
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
      final results = await Future.wait([
        Api.instance.get('/vendors/mine'),
        Api.instance.get('/orders/vendor'),
      ]);
      if (!mounted) return;
      setState(() {
        _vendor = results[0] as Map<String, dynamic>?;
        _orders = (results[1] as List? ?? []).whereType<Map<String, dynamic>>().toList();
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleOpen(bool val) async {
    setState(() => _togglingOpen = true);
    try {
      await Api.instance.patch('/vendors/mine', {'isOpen': val});
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _togglingOpen = false);
    }
  }

  Future<void> _editVendorProfile() async {
    final tr = (_vendor?['translations'] as List? ?? []);
    final nameCtrl = TextEditingController(text: tr.isNotEmpty ? tr.first['name']?.toString() ?? '' : '');
    final descCtrl = TextEditingController(text: tr.isNotEmpty ? tr.first['description']?.toString() ?? '' : '');
    final typeCtrl = TextEditingController(text: _vendor?['type']?.toString() ?? '');
    final addrCtrl = TextEditingController(text: _vendor?['location']?['address']?.toString() ?? '');
    double? lat;
    double? lng;

    await showDarbGlassModalSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              dt('تعديل بيانات المتجر'),
              style: TextStyle(color: DarbColors.inkOf(ctx), fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: dt('اسم المتجر'))),
            const SizedBox(height: 10),
            TextField(controller: typeCtrl, decoration: InputDecoration(labelText: dt('نوع النشاط'))),
            const SizedBox(height: 10),
            TextField(controller: descCtrl, maxLines: 2, decoration: InputDecoration(labelText: dt('الوصف'))),
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
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () async {
                try {
                  await Api.instance.patch('/vendors/mine', {
                    if (nameCtrl.text.trim().isNotEmpty) 'name': nameCtrl.text.trim(),
                    if (typeCtrl.text.trim().isNotEmpty) 'type': typeCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'address': addrCtrl.text.trim(),
                    if (lat != null && lng != null) ...{'latitude': lat, 'longitude': lng},
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _load();
                } on ApiException catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.message)));
                  }
                }
              },
              child: Text(dt('حفظ التغييرات')),
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
    try {
      await Api.instance.patch('/orders/$orderId/status', {'status': nextStatus});
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const DarbStateView.loading();
    if (_error != null) return DarbStateView.error(message: _error, onRetry: _load);

    final vendorName = _vendor?['translations'] is List && (_vendor!['translations'] as List).isNotEmpty
        ? (_vendor!['translations'] as List).first['name']?.toString() ?? dt('متجر')
        : dt('متجر');
    final isOpen = _vendor?['isOpen'] != false;
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendorName,
                        style: TextStyle(color: DarbColors.inkOf(context), fontSize: 17, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      DarbStatusBadge(status: isOpen ? 'OPEN' : 'CLOSED'),
                    ],
                  ),
                ),
                Switch(value: isOpen, onChanged: _togglingOpen ? null : _toggleOpen),
                IconButton(
                  tooltip: dt('تعديل'),
                  onPressed: _editVendorProfile,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
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
            DarbStateView.empty(message: dt('لا توجد طلبات واردة'), icon: Icons.receipt_long_outlined)
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
    final items = (o['items'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    final subtotal = num.tryParse(o['subtotal']?.toString() ?? '0') ?? 0;
    final currency = o['currency']?.toString() ?? 'SYP';

    return DarbGlassSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${o['orderNumber']} · ${o['customer']?['name'] ?? ''}',
                  style: TextStyle(color: DarbColors.inkOf(context), fontWeight: FontWeight.w900),
                ),
              ),
              DarbStatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Text(
              '• ${item['nameSnapshot']} × ${item['quantity']}',
              style: TextStyle(color: DarbColors.mutedOf(context), fontSize: 13),
            ),
          const SizedBox(height: 8),
          Text(
            formatDarbMoney(subtotal, currency),
            style: TextStyle(color: DarbColors.primaryOf(context), fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (status == 'PENDING') ...[
                Expanded(
                  child: FilledButton(
                    onPressed: () => _updateStatus(id, 'ACCEPTED'),
                    child: Text(dt('قبول')),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: DarbColors.dangerOf(context)),
                  onPressed: () => _updateStatus(id, 'CANCELLED'),
                  child: Text(dt('رفض')),
                ),
              ] else if (status == 'ACCEPTED')
                Expanded(
                  child: FilledButton(
                    onPressed: () => _updateStatus(id, 'PREPARING'),
                    child: Text(dt('بدء التحضير')),
                  ),
                )
              else if (status == 'PREPARING')
                Expanded(
                  child: FilledButton(
                    onPressed: () => _updateStatus(id, 'READY'),
                    child: Text(dt('جاهز للاستلام')),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
