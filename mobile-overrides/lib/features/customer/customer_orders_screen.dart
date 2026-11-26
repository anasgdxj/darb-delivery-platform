import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_copy_order_number_button.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_motion_components.dart';
import '../../core/widgets/darb_spatial_primitives.dart';
import 'driver_tracking_screen.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  List<Map<String, dynamic>> _orders = const [];
  String _filter = 'ALL';
  bool _loading = true;
  bool _offline = false;
  String? _error;
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
    });
    try {
      final res = await Api.instance.getWithCache('/orders/mine', 'customer_orders');
      final list = (res.data as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      if (!mounted) return;
      setState(() {
        _orders = list;
        _offline = res.fromCache;
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

  Future<void> _cancelPendingOrder(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dt('تأكيد إلغاء الطلب؟')),
        content: Text(
          dt('سيتم إلغاء الطلب فوراً وإعادة الكمية إلى المتجر إذا لم يبدأ تحضيره.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(dt('رجوع')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: DarbColors.dangerOf(ctx),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(dt('إلغاء الطلب')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!_busyOrderIds.add(orderId)) return;
    if (mounted) setState(() {});
    try {
      await Api.instance.post('/orders/$orderId/cancel', {});
      DarbHaptics.success();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dt('تم إلغاء الطلب بنجاح'))),
        );
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
      _busyOrderIds.remove(orderId);
      if (mounted) setState(() {});
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

  Future<void> _openShoppingQuoteSheet(String orderId, {num? maxBudget}) async {
    await showDarbGlassModalSheet<void>(
      context: context,
      builder: (ctx) => _ShoppingQuoteSheet(orderId: orderId, maxBudget: maxBudget, onChanged: _load),
    );
  }

  Future<void> _openReviewSheet(String orderId) async {
    int rating = 5;
    final commentCtrl = TextEditingController();
    bool submitting = false;
    String? err;

    await showDarbGlassModalSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              dt('تقييم الطلب'),
              style: TextStyle(
                color: DarbColors.inkOf(ctx),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var star = 1; star <= 5; star++)
                  IconButton(
                    onPressed: submitting
                        ? null
                        : () => setSheet(() => rating = star),
                    icon: Icon(
                      star <= rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 34,
                      color: DarbColors.warningOf(ctx),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: commentCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: dt('أضف تعليقك (اختياري)'),
              ),
            ),
            if (err != null) ...[
              const SizedBox(height: 8),
              Text(
                err!,
                style: TextStyle(color: DarbColors.dangerOf(ctx)),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      setSheet(() {
                        submitting = true;
                        err = null;
                      });
                      try {
                        await Api.instance.post('/orders/$orderId/review', {
                          'rating': rating,
                          if (commentCtrl.text.trim().isNotEmpty)
                            'comment': commentCtrl.text.trim(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _load();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(dt('تم إرسال تقييمك بنجاح'))),
                          );
                        }
                      } on ApiException catch (e) {
                        setSheet(() {
                          submitting = false;
                          err = e.message;
                        });
                      } catch (_) {
                        setSheet(() {
                          submitting = false;
                          err = dt('حدث خطأ غير متوقع، حاول مجدداً');
                        });
                      }
                    },
              child: Text(
                submitting ? dt('جارٍ الحفظ') : dt('إرسال التقييم'),
              ),
            ),
          ],
        ),
      ),
    );
    commentCtrl.dispose();
  }

  Future<void> _openOrderDetails(Map<String, dynamic> order) async {
    final status = order['status']?.toString() ?? 'PENDING';
    final isPeer = order['type'] == 'PEER_DELIVERY';
    final isShopping = order['type'] == 'SHOPPING_DELIVERY';
    final currency = order['currency']?.toString() ?? 'SYP';
    final subtotal = num.tryParse(order['subtotal']?.toString() ?? '0') ?? 0;
    final deliveryFee =
        num.tryParse(order['deliveryFee']?.toString() ?? '0') ?? 0;
    final total = num.tryParse(order['total']?.toString() ?? '0') ?? 0;
    final items =
        (order['items'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    final history = (order['statusHistory'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final driver = order['driver'] is Map ? order['driver'] as Map : null;
    final driverPhone = driver?['user']?['phone']?.toString();
    final vendorTr = order['vendor']?['translations'] as List? ?? [];
    final vendorName = vendorTr.isNotEmpty
        ? vendorTr.first['name']?.toString() ?? ''
        : '';

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
                  '${dt('تفاصيل الطلب')} · ${order['orderNumber'] ?? ''}',
                  style: TextStyle(
                    color: DarbColors.inkOf(ctx),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              DarbStatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 12),
          DarbOrderTimeline(status: status, isPeer: isPeer || isShopping),
          const SizedBox(height: 12),
          if (isShopping) ...[
            Text('${dt('الغرض')}: ${order['shoppingItemName'] ?? ''}', style: TextStyle(color: DarbColors.inkOf(ctx), fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(order['shoppingDescription']?.toString() ?? '', style: TextStyle(color: DarbColors.mutedOf(ctx))),
            if ((order['shoppingStoreName'] ?? '').toString().isNotEmpty) Text('${dt('المتجر المطلوب')}: ${order['shoppingStoreName']}', style: TextStyle(color: DarbColors.inkOf(ctx))),
            const SizedBox(height: 8),
          ],
          if (!isPeer && !isShopping && vendorName.isNotEmpty) ...[
            Text(
              '${dt('متجر')}: $vendorName',
              style: TextStyle(
                color: DarbColors.inkOf(ctx),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (driver != null) ...[
            DarbGlassSurface(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.delivery_dining_rounded,
                    color: DarbColors.primaryOf(ctx),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver['user']?['name']?.toString() ?? dt('سائق معتمد'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (driver['vehicleType'] != null)
                          Text(
                            driver['vehicleType'].toString(),
                            style: TextStyle(
                              color: DarbColors.mutedOf(ctx),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (driverPhone != null && driverPhone.isNotEmpty)
                    IconButton(
                      tooltip: dt('اتصال بالسائق'),
                      onPressed: () => _callPhone(driverPhone),
                      icon: Icon(
                        Icons.call_rounded,
                        color: DarbColors.primaryOf(ctx),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (items.isNotEmpty) ...[
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
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            const Divider(height: 18),
          ],
          if (subtotal > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dt('المجموع الفرعي التقريبي')),
                Text(formatDarbMoney(subtotal, currency)),
              ],
            ),
          if (deliveryFee > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dt('أجرة التوصيل المتوقعة')),
                  Text(formatDarbMoney(deliveryFee, currency)),
                ],
              ),
            ),
          if (total > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dt('الإجمالي عند الاستلام'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    formatDarbMoney(total, currency),
                    style: TextStyle(
                      color: DarbColors.primaryOf(ctx),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          if (order['cancelReason'] != null &&
              order['cancelReason'].toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '${dt('ملغى')}: ${order['cancelReason']}',
              style: TextStyle(color: DarbColors.dangerOf(ctx)),
            ),
          ],
          if (history.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              dt('مسار حالات الطلب'),
              style: TextStyle(
                color: DarbColors.inkOf(ctx),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            for (final step in history)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: DarbColors.primaryOf(ctx),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DarbStatusBadge(
                        status: step['status']?.toString() ?? 'PENDING',
                      ),
                    ),
                    Text(
                      (step['createdAt']?.toString() ?? '').length >= 16
                          ? step['createdAt']
                              .toString()
                              .substring(0, 16)
                              .replaceFirst('T', ' ')
                          : '',
                      style: TextStyle(
                        color: DarbColors.mutedOf(ctx),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (status == 'ASSIGNED' || status == 'PICKED_UP') ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _openDriverLocation(order);
              },
              icon: const Icon(Icons.map_outlined),
              label: Text(dt('موقع السائق')),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openDriverLocation(Map<String, dynamic> order) async {
    final addr = order['address'] is Map ? order['address'] as Map : null;
    await Navigator.of(context).push(
      DarbPageRoute(
        builder: (_) => DriverTrackingScreen(
          orderId: order['id'].toString(),
          pickupLatitude: (order['pickupLatitude'] as num?)?.toDouble(),
          pickupLongitude: (order['pickupLongitude'] as num?)?.toDouble(),
          dropoffLatitude: (addr?['latitude'] as num?)?.toDouble(),
          dropoffLongitude: (addr?['longitude'] as num?)?.toDouble(),
        ),
      ),
    );
  }

  int get _activeCount => _orders
      .where((o) => o['status'] != 'DELIVERED' && o['status'] != 'CANCELLED')
      .length;

  int get _completedCount => _orders
      .where((o) => o['status'] == 'DELIVERED' || o['status'] == 'CANCELLED')
      .length;

  List<Map<String, dynamic>> get _filteredOrders {
    if (_filter == 'ACTIVE') {
      return _orders
          .where((o) =>
              o['status'] != 'DELIVERED' && o['status'] != 'CANCELLED')
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
                    message: dt('لا توجد طلبات حتى الآن'),
                    icon: Icons.receipt_long_outlined,
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
                  padding: EdgeInsets.fromLTRB(hInset, 12, hInset, 98),
                  children: [
                    if (_offline)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DarbFeedbackBanner(
                          kind: DarbFeedbackKind.warning,
                          message: dt('بيانات مخزنة محلياً لضعف الاتصال'),
                        ),
                      ),
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
                          icon: Icons.bolt_rounded,
                        ),
                        DarbDockOption(
                          value: 'COMPLETED',
                          label: dt('مكتملة'),
                          count: _completedCount,
                          icon: Icons.task_alt_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (filtered.isEmpty)
                      DarbStateView.empty(
                        message: dt('لا توجد طلبات مطابقة للتصفية الحالية'),
                        icon: Icons.filter_list_off_rounded,
                        onRetry: () => setState(() => _filter = 'ALL'),
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

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final id = order['id'].toString();
    final number = order['orderNumber']?.toString() ?? '';
    final status = order['status']?.toString() ?? 'PENDING';
    final isPeer = order['type'] == 'PEER_DELIVERY';
    final isShopping = order['type'] == 'SHOPPING_DELIVERY';
    final total = num.tryParse(order['total']?.toString() ?? '0') ?? 0;
    final currency = order['currency']?.toString() ?? 'SYP';
    final items =
        (order['items'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    final reviews = (order['reviews'] as List? ?? []);
    final myReview = reviews.isNotEmpty && reviews.first is Map
        ? reviews.first as Map
        : null;
    final canTrack = status == 'ASSIGNED' || status == 'PICKED_UP';
    final canReview = status == 'DELIVERED' && myReview == null;
    final isActive = status != 'DELIVERED' && status != 'CANCELLED';
    final isBusy = _busyOrderIds.contains(id);

    return DarbTicketPass(
      onTap: () => _openOrderDetails(order),
      leadingIcon: (isPeer || isShopping) ? Icons.local_shipping_outlined : Icons.shopping_bag_outlined,
      title: '${isShopping ? dt('شراء وتوصيل') : (isPeer ? dt('توصيل مستقل') : dt('طلب'))} · $number',
      subtitle: order['address'] is Map
          ? (order['address'] as Map)['details']?.toString()
          : null,
      status: status,
      headerActions: [
        DarbCopyOrderNumberButton(value: number),
        const SizedBox(width: 4),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isActive) ...[
            DarbOrderTimeline(status: status, isPeer: isPeer),
            const SizedBox(height: 10),
          ],
          if (items.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final item in items.take(3))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: DarbColors.surfaceAltOf(context),
                      borderRadius: BorderRadius.circular(DarbRadius.pill),
                      border: Border.all(color: DarbColors.borderOf(context)),
                    ),
                    child: Text(
                      '${item['nameSnapshot']} × ${item['quantity']}',
                      style: TextStyle(
                        color: DarbColors.inkOf(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (isPeer && order['pickupAddress'] != null) ...[
            DarbRouteConnector(
              pickupLabel: dt('الاستلام'),
              pickupAddress: order['pickupAddress'].toString(),
              dropoffLabel: dt('عنوان التسليم'),
              dropoffAddress: (order['address'] is Map)
                  ? ((order['address'] as Map)['details']?.toString() ??
                      dt('غير محدد'))
                  : dt('غير محدد'),
            ),
            const SizedBox(height: 6),
          ],
          if (myReview != null)
            Row(
              children: [
                Text(
                  '${dt('تقييمك')}: ',
                  style: TextStyle(
                    color: DarbColors.mutedOf(context),
                    fontSize: 12.5,
                  ),
                ),
                Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: DarbColors.warningOf(context),
                ),
                Text(
                  '${myReview['rating']}',
                  style: TextStyle(
                    color: DarbColors.inkOf(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
        ],
      ),
      footer: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Text(
            total > 0
                ? formatDarbMoney(total, currency)
                : dt('بانتظار العروض'),
            style: TextStyle(
              color: DarbColors.primaryOf(context),
              fontWeight: FontWeight.w900,
              fontSize: 15,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((isPeer || isShopping) && status == 'PENDING')
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: DarbColors.isDark(context)
                        ? DarbColors.forestSoft
                        : DarbColors.mintTint,
                    foregroundColor: DarbColors.isDark(context)
                        ? DarbColors.mint
                        : DarbColors.forest,
                    minimumSize: const Size(0, 38),
                  ),
                  onPressed: isBusy ? null : () => _openOffersSheet(id),
                  child: Text(dt('عروض السائقين')),
                ),
              if (isShopping && status == 'ASSIGNED')
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: FilledButton.tonalIcon(
                    onPressed: () => _openShoppingQuoteSheet(id, maxBudget: num.tryParse(order['shoppingMaxBudget']?.toString() ?? '')),
                    icon: const Icon(Icons.receipt_long_rounded, size: 17),
                    label: Text(dt('تكلفة المشتريات')),
                  ),
                ),
              if (canTrack)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                    ),
                    onPressed: () => _openDriverLocation(order),
                    icon: const Icon(Icons.map_outlined, size: 17),
                    label: Text(dt('موقع السائق')),
                  ),
                ),
              if (canReview)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 38),
                    ),
                    onPressed: () => _openReviewSheet(id),
                    icon: const Icon(Icons.star_outline_rounded, size: 17),
                    label: Text(dt('تقييم الطلب')),
                  ),
                ),
              if (status == 'PENDING')
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: DarbColors.dangerOf(context),
                    ),
                    onPressed: isBusy ? null : () => _cancelPendingOrder(id),
                    child: Text(dt('إلغاء الطلب')),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}


class _ShoppingQuoteSheet extends StatefulWidget {
  const _ShoppingQuoteSheet({required this.orderId, required this.onChanged, this.maxBudget});
  final String orderId;
  final num? maxBudget;
  final VoidCallback onChanged;
  @override
  State<_ShoppingQuoteSheet> createState() => _ShoppingQuoteSheetState();
}

class _ShoppingQuoteSheetState extends State<_ShoppingQuoteSheet> {
  List<Map<String, dynamic>> _quotes = const [];
  bool _loading = true;
  bool _busy = false;
  bool _allowBudgetOverride = false;
  String? _error;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = (await Api.instance.get('/orders/${widget.orderId}/shopping-quotes') as List? ?? []).whereType<Map<String, dynamic>>().toList();
      if (mounted) setState(() => _quotes = rows);
    } on ApiException catch (e) { if (mounted) setState(() => _error = e.message); }
    catch (_) { if (mounted) setState(() => _error = dt('حدث خطأ غير متوقع، حاول مجدداً')); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  Future<void> _act(Map<String, dynamic> quote, bool approve) async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    final id = quote['id'].toString();
    try {
      if (approve) {
        await Api.instance.post('/orders/${widget.orderId}/shopping-quotes/$id/approve', {'allowBudgetOverride': _allowBudgetOverride});
      } else {
        await Api.instance.post('/orders/${widget.orderId}/shopping-quotes/$id/reject', {});
      }
      DarbHaptics.success();
      widget.onChanged();
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) { if (mounted) setState(() => _error = e.message); }
    catch (_) { if (mounted) setState(() => _error = dt('حدث خطأ غير متوقع، حاول مجدداً')); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(dt('عروض تكلفة المشتريات'), style: TextStyle(color: DarbColors.inkOf(context), fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      if (_loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
      else if (_error != null) Text(_error!, style: TextStyle(color: DarbColors.dangerOf(context)))
      else if (_quotes.isEmpty) Text(dt('لم يرسل السائق تكلفة الشراء بعد'), style: TextStyle(color: DarbColors.mutedOf(context)))
      else for (final quote in _quotes) ...[
        DarbGlassSurface(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [Expanded(child: Text(quote['driver']?['user']?['name']?.toString() ?? dt('السائق'), style: const TextStyle(fontWeight: FontWeight.w900))), Text(formatDarbMoney(num.tryParse(quote['amount']?.toString() ?? '0') ?? 0, quote['currency']?.toString() ?? 'SYP'), style: TextStyle(color: DarbColors.primaryOf(context), fontWeight: FontWeight.w900))]),
          const SizedBox(height: 6), Text(quote['details']?.toString() ?? '', style: TextStyle(color: DarbColors.mutedOf(context))),
          const SizedBox(height: 8), DarbStatusBadge(status: quote['status']?.toString() ?? 'PENDING'),
          if (quote['status'] == 'PENDING') ...[
            if (widget.maxBudget != null && (num.tryParse(quote['amount']?.toString() ?? '0') ?? 0) > widget.maxBudget!)
              CheckboxListTile(contentPadding: EdgeInsets.zero, value: _allowBudgetOverride, onChanged: _busy ? null : (value) => setState(() => _allowBudgetOverride = value == true), title: Text(dt('أوافق على تجاوز الميزانية المحددة')), subtitle: Text('${dt('الميزانية')}: ${formatDarbMoney(widget.maxBudget!, quote['currency']?.toString() ?? 'SYP')}'), controlAffinity: ListTileControlAffinity.leading),
            Row(children: [Expanded(child: OutlinedButton(onPressed: _busy ? null : () => _act(quote, false), child: Text(dt('رفض التكلفة')))), const SizedBox(width: 8), Expanded(child: FilledButton(onPressed: _busy || (widget.maxBudget != null && (num.tryParse(quote['amount']?.toString() ?? '0') ?? 0) > widget.maxBudget! && !_allowBudgetOverride) ? null : () => _act(quote, true), child: Text(_busy ? dt('جارٍ التنفيذ') : dt('موافقة والشراء'))))]),
          ],
          if (quote['receiptReference'] != null) Text('${dt('مرجع الفاتورة')}: ${quote['receiptReference']}'),
        ])),
        const SizedBox(height: 8),
      ],
    ]);
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
  String? _selectingOfferId;
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
      final list = (await Api.instance
                  .get('/orders/${widget.orderId}/offers') as List? ??
              [])
          .whereType<Map<String, dynamic>>()
          .toList();
      if (mounted) setState(() => _offers = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = dt('حدث خطأ غير متوقع، حاول مجدداً'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(String offerId) async {
    if (_selectingOfferId != null) return;
    setState(() {
      _selectingOfferId = offerId;
      _error = null;
    });
    try {
      await Api.instance
          .post('/orders/${widget.orderId}/offers/$offerId/select', {});
      DarbHaptics.success();
      if (!mounted) return;
      widget.onSelected();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dt('تم اختيار السائق وتأكيد الأجرة'))),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = dt('حدث خطأ غير متوقع، حاول مجدداً'));
    } finally {
      if (mounted) setState(() => _selectingOfferId = null);
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
                style: TextStyle(
                  color: DarbColors.inkOf(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              onPressed: _loadOffers,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
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
                            offer['driver']?['user']?['name']?.toString() ??
                                dt('سائق معتمد'),
                            style: TextStyle(
                              color: DarbColors.inkOf(context),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            offer['driver']?['vehicleType']?.toString() ?? '',
                            style: TextStyle(
                              color: DarbColors.mutedOf(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatDarbMoney(
                        num.tryParse(offer['amount']?.toString() ?? '0') ?? 0,
                        offer['currency']?.toString() ?? 'SYP',
                      ),
                      style: TextStyle(
                        color: DarbColors.primaryOf(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 38),
                      ),
                      onPressed: _selectingOfferId != null
                          ? null
                          : () => _select(offer['id'].toString()),
                      child: _selectingOfferId == offer['id']?.toString()
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(dt('اختيار')),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
