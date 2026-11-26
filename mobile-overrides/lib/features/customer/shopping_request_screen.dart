import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_motion_components.dart';

class ShoppingRequestScreen extends StatefulWidget {
  const ShoppingRequestScreen({super.key, required this.cityId, required this.cityName, this.onCreated});
  final String cityId;
  final String cityName;
  final VoidCallback? onCreated;
  @override
  State<ShoppingRequestScreen> createState() => _ShoppingRequestScreenState();
}

class _ShoppingRequestScreenState extends State<ShoppingRequestScreen> {
  final _itemName = TextEditingController();
  final _description = TextEditingController();
  final _storeName = TextEditingController();
  final _storeAddress = TextEditingController();
  final _budget = TextEditingController();
  List<Map<String, dynamic>> _addresses = const [];
  String? _addressId;
  bool _loadingAddresses = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() { super.initState(); _loadAddresses(); }
  @override
  void dispose() {
    _itemName.dispose(); _description.dispose(); _storeName.dispose();
    _storeAddress.dispose(); _budget.dispose(); super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() { _loadingAddresses = true; _error = null; });
    try {
      final list = (await Api.instance.get('/addresses') as List? ?? []).whereType<Map<String, dynamic>>().toList();
      if (!mounted) return;
      setState(() {
        _addresses = list;
        if (_addressId == null && list.isNotEmpty) {
          final located = list.where((a) => a['hasLocation'] == true).toList();
          _addressId = (located.isNotEmpty ? located.first : list.first)['id']?.toString();
        }
      });
    } on ApiException catch (e) { if (mounted) setState(() => _error = e.message); }
    catch (_) { if (mounted) setState(() => _error = dt('تعذر قراءة عناوين التوصيل')); }
    finally { if (mounted) setState(() => _loadingAddresses = false); }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final item = _itemName.text.trim();
    final description = _description.text.trim();
    final budgetText = _budget.text.trim();
    final budget = budgetText.isEmpty ? null : double.tryParse(budgetText);
    if (item.length < 2 || description.length < 5 || _addressId == null || (budgetText.isNotEmpty && (budget == null || budget <= 0))) {
      setState(() => _error = dt('تحقق من اسم الغرض والوصف وعنوان التسليم والميزانية'));
      DarbHaptics.warning();
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      await Api.instance.post('/orders/shopping', {
        'cityId': widget.cityId, 'addressId': _addressId,
        'itemName': item, 'description': description,
        if (_storeName.text.trim().isNotEmpty) 'storeName': _storeName.text.trim(),
        if (_storeAddress.text.trim().isNotEmpty) 'storeAddress': _storeAddress.text.trim(),
        if (budget != null) 'maxPurchaseBudget': budget,
      });
      if (!mounted) return;
      DarbHaptics.success();
      widget.onCreated?.call();
      await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
        title: Text(dt('تم إرسال طلب الشراء')),
        content: Text(dt('سيقدم السائقون أجرة التوصيل. بعد اختيار السائق سيرسل تكلفة المشتريات لتوافق عليها قبل أن يبدأ الشراء.')),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(dt('حسناً')))],
      ));
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) { if (mounted) setState(() => _error = e.message); }
    catch (_) { if (mounted) setState(() => _error = dt('حدث خطأ غير متوقع، حاول مجدداً')); }
    finally { if (mounted) setState(() => _submitting = false); }
  }

  InputDecoration _decoration(String label, String hint, IconData icon) => InputDecoration(
    labelText: dt(label), hintText: dt(hint), prefixIcon: Icon(icon),
    filled: true, fillColor: DarbColors.surfaceAltOf(context),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(DarbRadius.md), borderSide: BorderSide.none),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DarbGlassAppBar(title: dt('اطلب أي شيء'), subtitle: widget.cityName),
      body: DarbAmbientBackground(child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          DarbGlassSurface(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: DarbColors.violetSoftOf(context), borderRadius: BorderRadius.circular(DarbRadius.md)), child: Icon(Icons.shopping_bag_rounded, color: DarbColors.violetOf(context), size: 25)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(dt('شراء من أي متجر'), style: TextStyle(color: DarbColors.inkOf(context), fontSize: 17, fontWeight: FontWeight.w900)),
                Text(dt('اكتب ما تحتاجه وسيتولى السائق شراءه وتوصيله'), style: TextStyle(color: DarbColors.mutedOf(context), fontSize: 12.5)),
              ])),
            ]),
            const SizedBox(height: 18),
            TextField(controller: _itemName, textInputAction: TextInputAction.next, decoration: _decoration('ما الغرض الذي تريده؟', 'مثلاً: مستلزمات منزلية أو هدية', Icons.shopping_bag_outlined)),
            const SizedBox(height: 12),
            TextField(controller: _description, minLines: 3, maxLines: 5, decoration: _decoration('وصف الغرض بالتفصيل', 'النوع والكمية والمقاس أو أي مواصفات مهمة', Icons.notes_rounded)),
            const SizedBox(height: 12),
            TextField(controller: _storeName, textInputAction: TextInputAction.next, decoration: _decoration('اسم المتجر (اختياري)', 'اتركه فارغاً ليقترح السائق متجراً', Icons.storefront_outlined)),
            const SizedBox(height: 12),
            TextField(controller: _storeAddress, maxLines: 2, decoration: _decoration('عنوان المتجر (اختياري)', 'المنطقة أو الشارع أو أقرب معلم', Icons.place_outlined)),
            const SizedBox(height: 12),
            TextField(controller: _budget, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _decoration('الحد الأقصى لميزانية الشراء (اختياري)', 'المبلغ بعملة المدينة', Icons.account_balance_wallet_outlined)),
          ])),
          const SizedBox(height: 12),
          DarbGlassSurface(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(dt('عنوان استلام مشترياتك'), style: TextStyle(color: DarbColors.inkOf(context), fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 8),
            if (_loadingAddresses) const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
            else if (_addresses.isEmpty) Text(dt('أضف عنوان تسليم من صفحة عناويني أولاً'), style: TextStyle(color: DarbColors.mutedOf(context)))
            else DropdownButtonFormField<String>(
              value: _addressId, isExpanded: true, decoration: _decoration('اختر عنوان التسليم', 'عنوانك المحفوظ', Icons.location_on_outlined),
              items: [for (final address in _addresses) DropdownMenuItem(value: address['id']?.toString(), child: Text([address['label'], address['details']].where((v) => v != null && v.toString().trim().isNotEmpty).join(' · '), overflow: TextOverflow.ellipsis))],
              onChanged: _submitting ? null : (value) => setState(() => _addressId = value),
            ),
          ])),
          const SizedBox(height: 12),
          DarbFeedbackBanner(kind: DarbFeedbackKind.info, message: dt('لن يبدأ السائق الشراء قبل أن ترى التكلفة الفعلية وتوافق عليها. أجرة التوصيل وقيمة المشتريات تظهران كبندين منفصلين.')),
          if (_error != null) ...[const SizedBox(height: 10), Text(_error!, style: TextStyle(color: DarbColors.dangerOf(context), fontWeight: FontWeight.w700))],
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _submitting || _loadingAddresses || _addresses.isEmpty ? null : _submit, icon: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded), label: Text(_submitting ? dt('جارٍ إرسال الطلب') : dt('إرسال طلب الشراء')), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DarbRadius.pill)))),
        ],
      )),
    );
  }
}
