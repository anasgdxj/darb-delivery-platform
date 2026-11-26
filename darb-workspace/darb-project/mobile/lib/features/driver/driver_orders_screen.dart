import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_motion_components.dart';

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
  final Set<String> _updatingOrders = <String>{};

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
    } catch (_) {
      if (mounted) setState(() => _error = dt('حدث خطأ غير متوقع، حاول مجدداً'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _advanceStatus(String orderId, String nextStatus) async {
    if (!_updatingOrders.add(orderId)) return;
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
      _updatingOrders.remove(orderId);
      if (mounted) setState(() {});
    }
  }

  Future<void> _openInMaps(num? lat, num? lng) async {
    if (lat == null || lng == null) return;
    try {
      final uri = Uri.parse('https://maps.google.com/?q=$lat,$lng');
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
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
      child: _orders.isEmpty
          ? LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: DarbStateView.empty(
                    message: dt('لا توجد توصيلات حالياً'),
                    icon: Icons.route_outlined,
                    onRetry: _load,
                  ),
                ),
              ),
            )
          : ListView(
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
                    message: dt('لا توجد طلبات مطابقة للتصفية الحالية'),
                    icon: Icons.filter_list_off_rounded,
                    onRetry: () => setState(() => _filter = 'ALL'),
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

    return DarbInteractiveCard(
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
          const SizedBox(height: 10),
          DarbOrderTimeline(
            status: status,
            isPeer: o['type'] == 'PEER_DELIVERY',
            compact: true,
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
                    onPressed: () => _callPhone(customerPhone),
                    icon: const Icon(Icons.call_rounded, size: 16),
                    label: Text(dt('اتصال بالعميل')),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          DarbRouteConnector(
            pickupLabel: dt('الاستلام'),
            pickupAddress: o['pickupAddress']?.toString() ??
                (o['vendor']?['translations'] is List &&
                        (o['vendor']['translations'] as List).isNotEmpty
                    ? (o['vendor']['translations'] as List)
                            .first['name']
                            ?.toString() ??
                        dt('متجر')
                    : dt('متجر')),
            dropoffLabel: dt('التسليم'),
            dropoffAddress: addr?['details']?.toString() ?? dt('غير محدد'),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: DarbColors.primaryOf(context).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DarbRadius.sm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${dt('أجرة التوصيل')}: ${formatDarbMoney(fee, currency)}',
                  style: TextStyle(
                    color: DarbColors.primaryOf(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                Text(
                  formatDarbMoney(total, currency),
                  style: TextStyle(
                    color: DarbColors.inkOf(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                  ),
                ),
              ],
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
              if (status == 'ASSIGNED' || status == 'PICKED_UP')
                FilledButton(
                  onPressed: _updatingOrders.contains(id)
                      ? null
                      : () => _advanceStatus(
                            id,
                            status == 'ASSIGNED' ? 'PICKED_UP' : 'DELIVERED',
                          ),
                  child: _updatingOrders.contains(id)
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          status == 'ASSIGNED'
                              ? dt('تم الاستلام')
                              : dt('تم التسليم'),
                        ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
