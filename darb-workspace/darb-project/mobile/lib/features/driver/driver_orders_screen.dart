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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openInMaps(num? lat, num? lng) async {
    if (lat == null || lng == null) return;
    final uri = Uri.parse('https://maps.google.com/?q=$lat,$lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const DarbStateView.loading();
    if (_error != null) return DarbStateView.error(message: _error, onRetry: _load);

    return RefreshIndicator(
      onRefresh: _load,
      child: _orders.isEmpty
          ? ListView(
              children: [
                DarbStateView.empty(message: dt('لا توجد توصيلات حالياً'), icon: Icons.route_outlined),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: _orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final o = _orders[index];
                final id = o['id'].toString();
                final status = o['status']?.toString() ?? 'ASSIGNED';
                final total = num.tryParse(o['total']?.toString() ?? '0') ?? 0;
                final fee = num.tryParse(o['deliveryFee']?.toString() ?? '0') ?? 0;
                final currency = o['currency']?.toString() ?? 'SYP';
                final pickupLat = o['pickupLatitude'] as num?;
                final pickupLng = o['pickupLongitude'] as num?;

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
                              style: TextStyle(color: DarbColors.inkOf(context), fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                          ),
                          DarbStatusBadge(status: status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (o['pickupAddress'] != null)
                        Text('${dt('الاستلام')}: ${o['pickupAddress']}', style: TextStyle(color: DarbColors.mutedOf(context), fontSize: 13)),
                      if (o['address']?['details'] != null)
                        Text('${dt('التسليم')}: ${o['address']['details']}', style: TextStyle(color: DarbColors.mutedOf(context), fontSize: 13)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            '${dt('أجرة التوصيل')}: ${formatDarbMoney(fee, currency)} · ${formatDarbMoney(total, currency)}',
                            style: TextStyle(color: DarbColors.primaryOf(context), fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (pickupLat != null && pickupLng != null)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 8),
                              child: OutlinedButton.icon(
                                onPressed: () => _openInMaps(pickupLat, pickupLng),
                                icon: const Icon(Icons.navigation_outlined, size: 17),
                                label: Text(dt('موقع الاستلام')),
                              ),
                            ),
                          if (status == 'ASSIGNED')
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _advanceStatus(id, 'PICKED_UP'),
                                child: Text(dt('تم الاستلام')),
                              ),
                            ),
                          if (status == 'PICKED_UP')
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _advanceStatus(id, 'DELIVERED'),
                                child: Text(dt('تم التسليم')),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
