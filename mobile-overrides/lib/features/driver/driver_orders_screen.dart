import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_copy_order_number_button.dart';
import '../../core/widgets/darb_motion_components.dart';
import '../../core/widgets/darb_spatial_primitives.dart';

class DriverOrdersScreen extends StatefulWidget {
  const DriverOrdersScreen({super.key});

  @override
  State<DriverOrdersScreen> createState() => _DriverOrdersScreenState();
}

class _DriverOrdersScreenState extends State<DriverOrdersScreen> {
  List<Map<String, dynamic>> _orders = const [];
  String _filter = 'ALL';
  String _typeFilter = 'ALL';
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

  Future<void> _submitShoppingQuote(String orderId, String currency) async {
    final amountController = TextEditingController();
    final detailsController = TextEditingController();
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (ctx) => AlertDialog(
      title: Text(dt('إرسال تكلفة المشتريات')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: dt('قيمة المشتريات'), suffixText: currency)),
        const SizedBox(height: 10),
        TextField(controller: detailsController, minLines: 2, maxLines: 4, decoration: InputDecoration(labelText: dt('تفاصيل الأصناف والسعر'))),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(dt('إلغاء'))), FilledButton(onPressed: () {
        final amount = double.tryParse(amountController.text.trim());
        if (amount != null && amount > 0 && detailsController.text.trim().length >= 3) Navigator.pop(ctx, {'amount': amount, 'details': detailsController.text.trim()});
      }, child: Text(dt('إرسال للعميل')))],
    ));
    amountController.dispose(); detailsController.dispose();
    if (result == null || !_updatingOrders.add(orderId)) return;
    if (mounted) setState(() {});
    try {
      await Api.instance.post('/orders/$orderId/shopping-quote', result);
      if (mounted) DarbHaptics.success();
      await _load();
    } on ApiException catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); }
    catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dt('حدث خطأ غير متوقع، حاول مجدداً')))); }
    finally { _updatingOrders.remove(orderId); if (mounted) setState(() {}); }
  }

  Future<void> _recordShoppingProof(String orderId) async {
    final referenceController = TextEditingController();
    final noteController = TextEditingController();
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (ctx) => AlertDialog(
      title: Text(dt('إثبات الشراء')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: referenceController, decoration: InputDecoration(labelText: dt('رقم الفاتورة أو مرجع الشراء'))),
        const SizedBox(height: 10),
        TextField(controller: noteController, minLines: 2, maxLines: 3, decoration: InputDecoration(labelText: dt('ملاحظة (اختياري)'))),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(dt('إلغاء'))), FilledButton(onPressed: () {
        if (referenceController.text.trim().length >= 2) Navigator.pop(ctx, {'receiptReference': referenceController.text.trim(), if (noteController.text.trim().isNotEmpty) 'proofNote': noteController.text.trim()});
      }, child: Text(dt('تأكيد الشراء')))],
    ));
    referenceController.dispose(); noteController.dispose();
    if (result == null || !_updatingOrders.add(orderId)) return;
    if (mounted) setState(() {});
    try {
      await Api.instance.post('/orders/$orderId/purchase-proof', result);
      if (mounted) DarbHaptics.success();
      await _load();
    } on ApiException catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); }
    catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dt('حدث خطأ غير متوقع، حاول مجدداً')))); }
    finally { _updatingOrders.remove(orderId); if (mounted) setState(() {}); }
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

  int get _activeCount => _orders
      .where((o) => o['status'] == 'ASSIGNED' || o['status'] == 'PICKED_UP')
      .length;

  int get _completedCount => _orders
      .where((o) => o['status'] == 'DELIVERED' || o['status'] == 'CANCELLED')
      .length;

  List<Map<String, dynamic>> get _filteredOrders {
    Iterable<Map<String, dynamic>> list = _orders;
    if (_filter == 'ACTIVE') {
      list = list.where(
        (o) => o['status'] == 'ASSIGNED' || o['status'] == 'PICKED_UP',
      );
    } else if (_filter == 'COMPLETED') {
      list = list.where(
        (o) => o['status'] == 'DELIVERED' || o['status'] == 'CANCELLED',
      );
    }
    if (_typeFilter == 'VENDOR') {
      list = list.where((o) => o['type']?.toString() != 'PEER_DELIVERY');
    } else if (_typeFilter == 'PEER_DELIVERY') {
      list = list.where((o) => o['type']?.toString() == 'PEER_DELIVERY');
    }
    return list.toList();
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
          : LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth;
                final hInset = maxW > 1080 ? (maxW - 1080) / 2 + 16 : 16.0;
                return ListView(
                  padding: EdgeInsets.fromLTRB(hInset, 12, hInset, 100),
                  children: [
                    DarbSegmentedDock<String>(
                      selectedValue: _filter,
                      onSelected: (val) => setState(() => _filter = val),
                      options: [
                        DarbDockOption(
                          value: 'ALL',
                          label: dt('الكل'),
                          count: _orders.length,
                        ),
                        DarbDockOption(
                          value: 'ACTIVE',
                          label: dt('نشطة'),
                          count: _activeCount,
                          icon: Icons.route_rounded,
                        ),
                        DarbDockOption(
                          value: 'COMPLETED',
                          label: dt('مكتملة'),
                          count: _completedCount,
                          icon: Icons.task_alt_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DarbSegmentedDock<String>(
                      compact: true,
                      selectedValue: _typeFilter,
                      onSelected: (val) => setState(() => _typeFilter = val),
                      options: [
                        DarbDockOption(
                          value: 'ALL',
                          label: dt('الكل'),
                          count: _orders.length,
                        ),
                        DarbDockOption(
                          value: 'VENDOR',
                          label: dt('طلب متجر'),
                          count: _orders
                              .where(
                                (o) => o['type']?.toString() != 'PEER_DELIVERY',
                              )
                              .length,
                          icon: Icons.storefront_outlined,
                        ),
                        DarbDockOption(
                          value: 'PEER_DELIVERY',
                          label: dt('توصيل مستقل'),
                          count: _orders
                              .where(
                                (o) => o['type']?.toString() == 'PEER_DELIVERY',
                              )
                              .length,
                          icon: Icons.local_shipping_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (filtered.isEmpty)
                      DarbStateView.empty(
                        message: dt('لا توجد طلبات مطابقة للتصفية الحالية'),
                        icon: Icons.filter_list_off_rounded,
                        onRetry: () => setState(() {
                          _filter = 'ALL';
                          _typeFilter = 'ALL';
                        }),
                      )
                    else
                      DarbResponsiveTwoColumn(
                        children: [
                          for (var i = 0; i < filtered.length; i++)
                            i < 6
                                ? DarbFadeSlide(
                                    delay: DarbMotion.staggerDelay(i),
                                    child: _buildOrderCard(filtered[i]),
                                  )
                                : _buildOrderCard(filtered[i]),
                        ],
                      ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> o) {
    final id = o['id'].toString();
    final orderNumber = o['orderNumber']?.toString() ?? '';
    final status = o['status']?.toString() ?? 'ASSIGNED';
    final isPeer = o['type'] == 'PEER_DELIVERY';
    final isShopping = o['type'] == 'SHOPPING_DELIVERY';
    final shoppingQuotes = (o['shoppingPurchaseQuotes'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    final latestQuote = shoppingQuotes.isNotEmpty ? shoppingQuotes.first : null;
    final purchaseRecorded = latestQuote?['purchasedAt'] != null;
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

    return DarbTicketPass(
      leadingIcon: (isPeer || isShopping) ? Icons.local_shipping_outlined : Icons.route_rounded,
      title: isShopping ? '${dt('شراء وتوصيل')} · ${o['shoppingItemName'] ?? orderNumber}' : orderNumber,
      subtitle: customerName,
      status: status,
      headerActions: [
        DarbCopyOrderNumberButton(value: orderNumber),
        const SizedBox(width: 4),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DarbOrderTimeline(status: status, isPeer: isPeer || isShopping, compact: true),
          if (isShopping) ...[
            const SizedBox(height: 8),
            Text('${dt('وصف الغرض')}: ${o['shoppingDescription'] ?? ''}', style: TextStyle(color: DarbColors.inkOf(context), fontWeight: FontWeight.w700)),
            if ((o['shoppingStoreName'] ?? '').toString().isNotEmpty) Text('${dt('المتجر')}: ${o['shoppingStoreName']}', style: TextStyle(color: DarbColors.mutedOf(context))),
            if (latestQuote != null) DarbFeedbackBanner(kind: latestQuote['status'] == 'APPROVED' ? DarbFeedbackKind.success : DarbFeedbackKind.info, message: '${dt('تكلفة المشتريات')}: ${formatDarbMoney(num.tryParse(latestQuote['amount']?.toString() ?? '0') ?? 0, currency)} · ${dt(latestQuote['status'] == 'APPROVED' ? 'موافق عليها' : latestQuote['status'] == 'PENDING' ? 'بانتظار موافقة العميل' : 'تحتاج عرضاً جديداً')}'),
          ],
          if (customerName != null && customerName.isNotEmpty) ...[
            const SizedBox(height: 8),
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
          const SizedBox(height: 8),
          DarbRouteConnector(
            pickupLabel: dt('الاستلام'),
            pickupAddress: isShopping ? ((o['shoppingStoreName'] ?? '').toString().isNotEmpty ? o['shoppingStoreName'].toString() : dt('متجر يحدده السائق')) : (o['pickupAddress']?.toString() ??
                (o['vendor']?['translations'] is List &&
                        (o['vendor']['translations'] as List).isNotEmpty
                    ? (o['vendor']['translations'] as List)
                            .first['name']
                            ?.toString() ??
                        dt('متجر')
                    : dt('متجر'))),
            dropoffLabel: dt('التسليم'),
            dropoffAddress: addr?['details']?.toString() ?? dt('غير محدد'),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: DarbColors.primaryOf(context).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DarbRadius.sm),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final feeText = Text(
                  '${dt('أجرة التوصيل')}: ${formatDarbMoney(fee, currency)}',
                  softWrap: true,
                  style: TextStyle(
                    color: DarbColors.primaryOf(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                );
                final totalText = Text(
                  formatDarbMoney(total, currency),
                  textAlign: TextAlign.end,
                  softWrap: true,
                  style: TextStyle(
                    color: DarbColors.inkOf(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                );
                if (constraints.maxWidth < 380) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      feeText,
                      const SizedBox(height: 4),
                      totalText,
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: feeText),
                    const SizedBox(width: 12),
                    Flexible(child: totalText),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      footer: Wrap(
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
          if (isShopping && status == 'ASSIGNED' && latestQuote?['status'] == 'APPROVED' && !purchaseRecorded)
            OutlinedButton.icon(onPressed: _updatingOrders.contains(id) ? null : () => _recordShoppingProof(id), icon: const Icon(Icons.receipt_long_rounded, size: 17), label: Text(dt('تسجيل إثبات الشراء'))),
          if (isShopping && status == 'ASSIGNED' && (latestQuote == null || latestQuote['status'] == 'REJECTED' || latestQuote['status'] == 'SUPERSEDED'))
            OutlinedButton.icon(onPressed: _updatingOrders.contains(id) ? null : () => _submitShoppingQuote(id, currency), icon: const Icon(Icons.request_quote_outlined, size: 17), label: Text(dt('إرسال تكلفة الشراء'))),
          if (status == 'ASSIGNED' || status == 'PICKED_UP')
            if (!isShopping || status == 'PICKED_UP' || purchaseRecorded)
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
    );
  }
}
