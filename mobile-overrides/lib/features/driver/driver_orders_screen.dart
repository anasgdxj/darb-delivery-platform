import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';

class DriverOrdersScreen extends StatefulWidget {
  const DriverOrdersScreen({super.key});

  @override
  State<DriverOrdersScreen> createState() => _DriverOrdersScreenState();
}

class _DriverOrdersScreenState extends State<DriverOrdersScreen> {
  List<Map<String, dynamic>> _orders = const [];
  String _filter = 'ALL';
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
      final list = (await Api.instance.get('/orders/driver/mine') as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      if (mounted) setState(() => _orders = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _advanceStatus(String orderId, String nextStatus) async {
    try {
      await Api.instance.patch('/orders/$orderId/status', {'status': nextStatus});
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _openInMaps(num? lat, num? lng) async {
    if (lat == null || lng == null) return;
    final uri = Uri.parse('https://maps.google.com/?q=$lat,$lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_filter == 'ACTIVE') {
      return _orders
          .where((o) =>
              o['status'] == 'ASSIGNED' || o['status'] == 'PICKED_UP')
          .toList();
    }
    if (_filter == 'COMPLETED') {
      return _orders
          .where((o) =>
              o['status'] == 'DELIVERED' || o['status'] == 'CANCELLED')
          .toList();
    }
    return _orders;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const DarbStateView.loading();
    if (_error != null) return DarbStateView.error(message: _error, onRetry: _load);

    final filtered = _filteredOrders;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in [
                  ('ALL', dt('الكل')),
                  ('ACTIVE', dt('نشطة')),
                  ('COMPLETED', dt('مكتملة')),
                ]) ...[
                  ChoiceChip(
                    label: Text(f.$2),
                    selected: _filter == f.$1,
                    onSelected: (_) => setState(() => _filter = f.$1),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            DarbStateView.empty(
              message: dt('لا توجد توصيلات حالياً'),
              icon: Icons.route_outlined,
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
    final status = o['status']?.toString() ?? 'ASSIGNED';
    final total = num.tryParse(o['total']?.toString() ?? '0') ?? 0;
    final fee = num.tryParse(o['deliveryFee']?.toString() ?? '0') ?? 0;
    final currency = o['currency']?.toString() ?? 'SYP';
    final pickupLat = o['pickupLatitude'] as num?;
    final pickupLng = o['pickupLongitude'] as num?;
    final customerName = o['customer']?['name']?.toString();
    final customerPhone = o['customer']?['phone']?.toString();
    final addr = o['address'] is Map ? o['address'] as Map : null;
    final dropLat = addr?['latitude'] as num?;
    final dropLng = addr?['longitude'] as num?;

    return DarbGlassSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  o['orderNumber']?.toString() ?? '',
                  style: TextStyle(
                    color: DarbColors.inkOf(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              DarbStatusBadge(status: status),
            ],
          ),
          if (customerName != null && customerName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: DarbColors.mutedOf(context),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    customerName,
                    style: TextStyle(
                      color: DarbColors.inkOf(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (customerPhone != null && customerPhone.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => launchUrl(Uri.parse('tel:$customerPhone')),
                    icon: const Icon(Icons.call_rounded, size: 16),
                    label: Text(dt('اتصال بالعميل')),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          if (o['pickupAddress'] != null)
            Text(
              '${dt('الاستلام')}: ${o['pickupAddress']}',
              style: TextStyle(
                color: DarbColors.mutedOf(context),
                fontSize: 13,
              ),
            ),
          if (addr?['details'] != null)
            Text(
              '${dt('التسليم')}: ${addr!['details']}',
              style: TextStyle(
                color: DarbColors.mutedOf(context),
                fontSize: 13,
              ),
            ),
          const SizedBox(height: 10),
          Text(
            '${dt('أجرة التوصيل')}: ${formatDarbMoney(fee, currency)} · ${formatDarbMoney(total, currency)}',
            style: TextStyle(
              color: DarbColors.primaryOf(context),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (pickupLat != null && pickupLng != null)
                OutlinedButton.icon(
                  onPressed: () => _openInMaps(pickupLat, pickupLng),
                  icon: const Icon(Icons.navigation_outlined, size: 17),
                  label: Text(dt('موقع الاستلام')),
                ),
              if (dropLat != null && dropLng != null)
                OutlinedButton.icon(
                  onPressed: () => _openInMaps(dropLat, dropLng),
                  icon: const Icon(Icons.place_outlined, size: 17),
                  label: Text(dt('موقع التسليم')),
                ),
              if (status == 'ASSIGNED')
                FilledButton(
                  onPressed: () => _advanceStatus(id, 'PICKED_UP'),
                  child: Text(dt('تم الاستلام')),
                ),
              if (status == 'PICKED_UP')
                FilledButton(
                  onPressed: () => _advanceStatus(id, 'DELIVERED'),
                  child: Text(dt('تم التسليم')),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
