import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import 'addresses_screen.dart';

class CartCheckoutItem {
  const CartCheckoutItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.currency,
    required this.quantity,
  });

  final String productId;
  final String name;
  final double unitPrice;
  final String currency;
  final int quantity;
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.cityId,
    required this.vendorId,
    required this.vendorName,
    required this.items,
  });

  final String cityId;
  final String vendorId;
  final String vendorName;
  final List<CartCheckoutItem> items;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _notesController = TextEditingController();
  List<Map<String, dynamic>> _addresses = const [];
  String? _selectedAddressId;
  Map<String, dynamic>? _estimate;
  bool _loadingAddresses = true;
  bool _estimating = false;
  bool _submitting = false;
  int _estimateGeneration = 0;
  String? _estimateError;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _subtotal =>
      widget.items.fold(0, (sum, item) => sum + item.unitPrice * item.quantity);

  Future<void> _loadAddresses() async {
    setState(() => _loadingAddresses = true);
    try {
      final list = (await Api.instance.get('/addresses') as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      if (!mounted) return;
      setState(() {
        _addresses = list;
        if (_selectedAddressId == null && list.isNotEmpty) {
          final withLoc = list.where((a) => a['hasLocation'] == true).toList();
          _selectedAddressId = (withLoc.isNotEmpty ? withLoc.first : list.first)['id']?.toString();
        }
      });
      if (_selectedAddressId != null) {
        await _refreshEstimate();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loadingAddresses = false);
    }
  }

  Future<void> _refreshEstimate() async {
    final addrId = _selectedAddressId;
    if (addrId == null || widget.items.isEmpty) {
      _estimateGeneration++;
      setState(() {
        _estimating = false;
        _estimate = null;
        _estimateError = null;
      });
      return;
    }
    final generation = ++_estimateGeneration;
    setState(() {
      _estimating = true;
      _estimate = null;
      _estimateError = null;
    });
    try {
      final res = await Api.instance.post('/orders/estimate', {
        'cityId': widget.cityId,
        'addressId': addrId,
        'vendorId': widget.vendorId,
        'items': widget.items
            .map((e) => {'productId': e.productId, 'quantity': e.quantity})
            .toList(),
      }) as Map<String, dynamic>;
      if (mounted && generation == _estimateGeneration) {
        setState(() {
          _estimate = res;
          if (res['vendorOpen'] == false) {
            _estimateError = dt('المتجر مغلق حالياً ولا يستقبل طلبات جديدة');
          }
        });
      }
    } on ApiException catch (e) {
      if (mounted && generation == _estimateGeneration) {
        setState(() => _estimateError = e.message);
      }
    } catch (_) {
      if (mounted && generation == _estimateGeneration) {
        setState(() => _estimateError = dt('تعذر حساب تكلفة التوصيل. تحقق من الاتصال وحاول مجدداً.'));
      }
    } finally {
      if (mounted && generation == _estimateGeneration) {
        setState(() => _estimating = false);
      }
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedAddressId == null) {
      setState(() => _error = dt('اختر عنوان توصيل صالحاً أو أضف عنواناً جديداً'));
      return;
    }
    if (_estimating || _estimate == null || _estimateError != null) {
      setState(() => _error = _estimateError ?? dt('يجب حساب تكلفة الطلب بنجاح قبل الإرسال'));
      return;
    }
    if (_estimate?['vendorOpen'] == false) {
      setState(() => _error = dt('المتجر مغلق حالياً ولا يستقبل طلبات جديدة'));
      return;
    }
    if (widget.items.isEmpty) {
      setState(() => _error = dt('السلة فارغة'));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final order = await Api.instance.post('/orders', {
        'cityId': widget.cityId,
        'addressId': _selectedAddressId,
        'vendorId': widget.vendorId,
        'items': widget.items
            .map((e) => {'productId': e.productId, 'quantity': e.quantity})
            .toList(),
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
      }) as Map<String, dynamic>;

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(dt('تم استلام طلبك')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dt('وصل طلبك إلى النظام، ويمكنك متابعة حالته من قسم طلباتي.')),
              const SizedBox(height: 12),
              Text(
                '${dt('رقم الطلب: ')}${order['orderNumber'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                '${dt('الإجمالي عند الاستلام')}: ${formatDarbMoney(num.tryParse(order['total']?.toString() ?? '0') ?? 0, order['currency']?.toString() ?? 'SYP')}',
                style: TextStyle(color: DarbColors.primaryOf(ctx), fontWeight: FontWeight.w900),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(dt('حسناً')),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = _estimate?['currency']?.toString() ??
        (widget.items.isNotEmpty ? widget.items.first.currency : 'SYP');
    final estSubtotal = num.tryParse(_estimate?['subtotal']?.toString() ?? '') ?? _subtotal;
    final estDelivery = num.tryParse(_estimate?['deliveryFee']?.toString() ?? '');
    final estTotal = num.tryParse(_estimate?['total']?.toString() ?? '');
    final estDistance = _estimate?['distanceKm'];

    return Scaffold(
      appBar: DarbGlassAppBar(
        title: dt('مراجعة طلبك'),
        subtitle: widget.vendorName,
      ),
      body: DarbAmbientBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
          children: [
            DarbGlassSurface(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dt('عنوان التوصيل'),
                          style: TextStyle(color: DarbColors.inkOf(context), fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final created = await showAddressFormSheet(context, requireLocation: true);
                          if (created != null) {
                            setState(() => _selectedAddressId = created['id']?.toString());
                            await _loadAddresses();
                          }
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(dt('إضافة عنوان')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_loadingAddresses)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                  else if (_addresses.isEmpty)
                    Text(
                      dt('لا يوجد عنوان محفوظ'),
                      style: TextStyle(color: DarbColors.mutedOf(context)),
                    )
                  else
                    Column(
                      children: [
                        for (var i = 0; i < _addresses.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          DarbRadioOptionTile(
                            selected: _addresses[i]['id']?.toString() == _selectedAddressId,
                            title: _addresses[i]['label']?.toString().isNotEmpty == true
                                ? _addresses[i]['label'].toString()
                                : dt('عنوان'),
                            subtitle: _addresses[i]['details']?.toString() ?? '',
                            trailing: DarbStatusBadge(
                              status: _addresses[i]['hasLocation'] == true ? 'OPEN' : 'PENDING',
                            ),
                            onTap: _submitting
                                ? null
                                : () async {
                                    setState(() {
                                      _selectedAddressId = _addresses[i]['id']?.toString();
                                      _error = null;
                                    });
                                    await _refreshEstimate();
                                  },
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            DarbGlassSurface(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    dt('ملخص السلة'),
                    style: TextStyle(color: DarbColors.inkOf(context), fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  for (final item in widget.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.name} × ${item.quantity}',
                              style: TextStyle(color: DarbColors.inkOf(context), fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            formatDarbMoney(item.unitPrice * item.quantity, item.currency),
                            style: TextStyle(color: DarbColors.inkOf(context), fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 22),
                  _feeRow(dt('المجموع الفرعي التقريبي'), formatDarbMoney(estSubtotal, currency)),
                  if (_estimating)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: LinearProgressIndicator(borderRadius: BorderRadius.circular(DarbRadius.pill)),
                    )
                  else if (_estimateError != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _estimateError!,
                          style: TextStyle(
                            color: DarbColors.dangerOf(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: _selectedAddressId == null ? null : _refreshEstimate,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(dt('إعادة حساب التكلفة')),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    if (estDistance != null)
                      _feeRow(dt('مسافة التوصيل: $estDistance كم'), ''),
                    if (estDelivery != null)
                      _feeRow(dt('أجرة التوصيل المتوقعة'), formatDarbMoney(estDelivery, currency)),
                    if (estTotal != null)
                      _feeRow(
                        dt('الإجمالي التقديري'),
                        formatDarbMoney(estTotal, currency),
                        highlight: true,
                      ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.payments_outlined, size: 17, color: DarbColors.primaryOf(context)),
                      const SizedBox(width: 6),
                      Text(
                        dt('الدفع نقداً عند الاستلام'),
                        style: TextStyle(color: DarbColors.mutedOf(context), fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            DarbGlassSurface(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: dt('ملاحظات للمتجر (اختياري)'),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              DarbGlassSurface(
                tintColor: DarbColors.dangerSoft,
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: DarbColors.danger, fontWeight: FontWeight.w700),
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: (_submitting || _loadingAddresses || _estimating || _estimate == null || _estimateError != null || _estimate?['vendorOpen'] == false) ? null : _placeOrder,
              child: Text(
                _submitting ? dt('جارٍ الحفظ') : dt('إرسال الطلب — الدفع عند الاستلام'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feeRow(String label, String value, {bool highlight = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: highlight ? DarbColors.inkOf(context) : DarbColors.mutedOf(context),
                  fontWeight: highlight ? FontWeight.w900 : FontWeight.w600,
                  fontSize: highlight ? 15 : 13.5,
                ),
              ),
            ),
            if (value.isNotEmpty)
              Text(
                value,
                style: TextStyle(
                  color: highlight ? DarbColors.primaryOf(context) : DarbColors.inkOf(context),
                  fontWeight: FontWeight.w900,
                  fontSize: highlight ? 16 : 14,
                ),
              ),
          ],
        ),
      );
}
