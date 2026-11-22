import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  List<Map<String, dynamic>> _orders = const [];
  bool _loading = true;
  bool _offline = false;
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
      final res = await Api.instance.getWithCache('/orders/mine', 'customer_orders');
      final list = (res.data as List? ?? []).whereType<Map<String, dynamic>>().toList();
      if (!mounted) return;
      setState(() {
        _orders = list;
        _offline = res.fromCache;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancelPendingOrder(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dt('تأكيد إلغاء الطلب؟')),
        content: Text(dt('سيتم إلغاء الطلب فوراً وإعادة الكمية إلى المتجر إذا لم يبدأ تحضيره.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(dt('رجوع'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: DarbColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(dt('إلغاء الطلب')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Api.instance.post('/orders/$orderId/cancel', {});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dt('تم إلغاء الطلب بنجاح'))),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _openOffersSheet(String orderId) async {
    await showDarbGlassModalSheet<void>(
      context: context,
      builder: (ctx) => _DriverOffersSheet(
        orderId: orderId,
        onSelected: _load,
      ),
    );
  }

  Future<void> _openDriverLocation(String orderId) async {
    try {
      final loc = await Api.instance.get('/orders/$orderId/driver-location');
      if (loc is! Map ||
          loc['available'] != true ||
          loc['latitude'] == null ||
          loc['longitude'] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(dt('لم يشارك السائق موقعه بعد'))),
          );
        }
        return;
      }
      final lat = loc['latitude'];
      final lng = loc['longitude'];
      final uri = Uri.parse('https://maps.google.com/?q=$lat,$lng');
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(dt('تعذر فتح الخرائط'))),
          );
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
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
                DarbStateView.empty(
                  message: dt('لا توجد طلبات حتى الآن'),
                  icon: Icons.receipt_long_outlined,
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 98),
              itemCount: _orders.length + (_offline ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (_offline && index == 0) {
                  return DarbGlassSurface(
                    tintColor: DarbColors.warningSoft,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Text(
                      dt('بيانات مخزنة محلياً لضعف الاتصال'),
                      style: const TextStyle(color: DarbColors.warning, fontWeight: FontWeight.w700),
                    ),
                  );
                }
                final order = _orders[_offline ? index - 1 : index];
                return _buildOrderCard(order);
              },
            ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final id = order['id'].toString();
    final number = order['orderNumber']?.toString() ?? '';
    final status = order['status']?.toString() ?? 'PENDING';
    final isPeer = order['type'] == 'PEER_DELIVERY';
    final total = num.tryParse(order['total']?.toString() ?? '0') ?? 0;
    final currency = order['currency']?.toString() ?? 'SYP';
    final items = (order['items'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    final canTrack = status == 'ASSIGNED' || status == 'PICKED_UP';

    return DarbFadeSlide(
      child: DarbGlassSurface(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${isPeer ? dt('توصيل مستقل') : dt('طلب')} · $number',
                        style: TextStyle(
                          color: DarbColors.inkOf(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (order['address'] is Map)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            (order['address'] as Map)['details']?.toString() ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: DarbColors.mutedOf(context), fontSize: 12.5),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                DarbStatusBadge(status: status),
              ],
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final item in items.take(3))
                Text(
                  '• ${item['nameSnapshot']} × ${item['quantity']}',
                  style: TextStyle(color: DarbColors.mutedOf(context), fontSize: 13),
                ),
            ],
            if (isPeer && order['pickupAddress'] != null) ...[
              const SizedBox(height: 8),
              Text(
                '${dt('الاستلام')}: ${order['pickupAddress']}',
                style: TextStyle(color: DarbColors.mutedOf(context), fontSize: 13),
              ),
            ],
            const Divider(height: 20),
            Row(
              children: [
                Text(
                  total > 0 ? formatDarbMoney(total, currency) : dt('بانتظار العروض'),
                  style: TextStyle(
                    color: DarbColors.primaryOf(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                if (isPeer && status == 'PENDING')
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: DarbColors.mintTint,
                      foregroundColor: DarbColors.forest,
                      minimumSize: const Size(0, 38),
                    ),
                    onPressed: () => _openOffersSheet(id),
                    child: Text(dt('عروض السائقين')),
                  ),
                if (canTrack)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
                      onPressed: () => _openDriverLocation(id),
                      icon: const Icon(Icons.map_outlined, size: 17),
                      label: Text(dt('موقع السائق')),
                    ),
                  ),
                if (status == 'PENDING')
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8),
                    child: TextButton(
                      style: TextButton.styleFrom(foregroundColor: DarbColors.dangerOf(context)),
                      onPressed: () => _cancelPendingOrder(id),
                      child: Text(dt('إلغاء الطلب')),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverOffersSheet extends StatefulWidget {
  const _DriverOffersSheet({required this.orderId, required this.onSelected});
  final String orderId;
  final VoidCallback onSelected;

  @override
  State<_DriverOffersSheet> createState() => _DriverOffersSheetState();
}

class _DriverOffersSheetState extends State<_DriverOffersSheet> {
  List<Map<String, dynamic>> _offers = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = (await Api.instance.get('/orders/${widget.orderId}/offers') as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      if (mounted) setState(() => _offers = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(String offerId) async {
    try {
      await Api.instance.post('/orders/${widget.orderId}/offers/$offerId/select', {});
      if (!mounted) return;
      widget.onSelected();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dt('تم اختيار السائق وتأكيد الأجرة'))),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                dt('عروض السائقين'),
                style: TextStyle(color: DarbColors.inkOf(context), fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            IconButton(onPressed: _loadOffers, icon: const Icon(Icons.refresh_rounded)),
          ],
        ),
        const SizedBox(height: 10),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_error != null)
          Text(_error!, style: TextStyle(color: DarbColors.dangerOf(context)))
        else if (_offers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              dt('بانتظار عروض السائقين.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: DarbColors.mutedOf(context)),
            ),
          )
        else
          for (final offer in _offers)
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
                            offer['driver']?['user']?['name']?.toString() ?? dt('سائق معتمد'),
                            style: TextStyle(color: DarbColors.inkOf(context), fontWeight: FontWeight.w800),
                          ),
                          Text(
                            offer['driver']?['vehicleType']?.toString() ?? '',
                            style: TextStyle(color: DarbColors.mutedOf(context), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatDarbMoney(
                        num.tryParse(offer['amount']?.toString() ?? '0') ?? 0,
                        offer['currency']?.toString() ?? 'SYP',
                      ),
                      style: TextStyle(color: DarbColors.primaryOf(context), fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
                      onPressed: () => _select(offer['id'].toString()),
                      child: Text(dt('اختيار')),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
