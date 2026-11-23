import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';

class VendorProductsScreen extends StatefulWidget {
  const VendorProductsScreen({super.key});

  @override
  State<VendorProductsScreen> createState() => _VendorProductsScreenState();
}

class _VendorProductsScreenState extends State<VendorProductsScreen> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _products = const [];
  String _selectedCategory = '';
  String? _vendorStatus;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    darbLocale.addListener(_onLocaleChanged);
    _load();
  }

  void _onLocaleChanged() {
    if (mounted) _load();
  }

  @override
  void dispose() {
    darbLocale.removeListener(_onLocaleChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final mine =
          await Api.instance.get('/vendors/mine') as Map<String, dynamic>;
      final status = mine['status']?.toString() ?? 'PENDING';
      if (status != 'APPROVED') {
        if (mounted) {
          setState(() {
            _vendorStatus = status;
            _products = const [];
          });
        }
        return;
      }
      final vendorId = mine['id'].toString();
      final locale = darbLocale.value.languageCode;
      final list = (await Api.instance
                  .get('/vendors/$vendorId/products?locale=$locale') as List? ??
              [])
          .whereType<Map<String, dynamic>>()
          .toList();
      if (mounted) {
        setState(() {
          _vendorStatus = status;
          _products = list;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = dt('حدث خطأ غير متوقع، حاول مجدداً'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _categories {
    final set = <String>{};
    for (final p in _products) {
      final c = p['category']?.toString().trim();
      if (c != null && c.isNotEmpty) set.add(c);
    }
    return set.toList();
  }

  String _productTitle(Map<String, dynamic> p) {
    final tr = (p['translations'] as List? ?? []);
    final locale = darbLocale.value.languageCode;
    for (final item in tr) {
      if (item is Map && item['locale'] == locale) {
        return item['name']?.toString() ?? dt('منتج');
      }
    }
    return tr.isNotEmpty
        ? tr.first['name']?.toString() ?? dt('منتج')
        : dt('منتج');
  }

  String _productDesc(Map<String, dynamic> p) {
    final tr = (p['translations'] as List? ?? []);
    final locale = darbLocale.value.languageCode;
    for (final item in tr) {
      if (item is Map && item['locale'] == locale) {
        return item['description']?.toString() ?? '';
      }
    }
    return tr.isNotEmpty ? tr.first['description']?.toString() ?? '' : '';
  }

  Future<void> _openProductSheet({Map<String, dynamic>? existing}) async {
    final nameCtrl = TextEditingController(
      text: existing != null ? _productTitle(existing) : '',
    );
    final categoryCtrl = TextEditingController(
      text: existing?['category']?.toString() ?? '',
    );
    final descCtrl = TextEditingController(
      text: existing != null ? _productDesc(existing) : '',
    );
    final priceCtrl =
        TextEditingController(text: existing?['basePrice']?.toString() ?? '');
    final stockCtrl =
        TextEditingController(text: existing?['stockQty']?.toString() ?? '');
    var isAvailable = existing?['isAvailable'] != false;
    var saving = false;
    String? err;

    await showDarbGlassModalSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              existing == null ? dt('منتج جديد') : dt('تعديل المنتج'),
              style: TextStyle(
                color: DarbColors.inkOf(ctx),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: dt('اسم المنتج')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: categoryCtrl,
              decoration: InputDecoration(labelText: dt('التصنيف (اختياري)')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: dt('السعر')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: stockCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: dt('المخزون (اختياري)')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: InputDecoration(labelText: dt('الوصف')),
            ),
            if (existing != null) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  dt('متاح للبيع'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                value: isAvailable,
                onChanged: (v) => setSheet(() => isAvailable = v),
              ),
            ],
            if (err != null) ...[
              const SizedBox(height: 6),
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
                      final name = nameCtrl.text.trim();
                      final category = categoryCtrl.text.trim();
                      final price = double.tryParse(priceCtrl.text.trim());
                      final stock = stockCtrl.text.trim().isEmpty
                          ? null
                          : int.tryParse(stockCtrl.text.trim());
                      if (name.length < 2 || price == null || price < 0) {
                        setSheet(() => err = dt('أدخل اسم المنتج وسعراً صحيحاً'));
                        return;
                      }
                      setSheet(() {
                        saving = true;
                        err = null;
                      });
                      try {
                        if (existing == null) {
                          await Api.instance.post('/vendor/products', {
                            'name': name,
                            'price': price,
                            'description': descCtrl.text.trim(),
                            'currency': 'SYP',
                            if (category.isNotEmpty) 'category': category,
                            if (stock != null) 'stockQty': stock,
                          });
                        } else {
                          await Api.instance
                              .patch('/vendor/products/${existing['id']}', {
                            'name': name,
                            'price': price,
                            'description': descCtrl.text.trim(),
                            'category': category,
                            if (stock != null) 'stockQty': stock,
                            'isAvailable': isAvailable,
                          });
                        }
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
              child: Text(
                saving
                    ? dt('جارٍ الحفظ')
                    : (existing == null ? dt('إضافة') : dt('حفظ التغييرات')),
              ),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    categoryCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    stockCtrl.dispose();
  }

  Future<void> _deleteProduct(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dt('حذف المنتج')),
        content: Text(
          dt('سيتم حذف المنتج أو إخفاؤه تلقائياً إذا ارتبط بطلبات سابقة.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(dt('إلغاء')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: DarbColors.dangerOf(ctx),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(dt('حذف المنتج')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Api.instance.delete('/vendor/products/$id');
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
    }
  }

  Future<void> _toggleAvailable(String id, bool nextVal) async {
    try {
      await Api.instance.patch('/vendor/products/$id', {'isAvailable': nextVal});
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const DarbStateView.loading();
    if (_error != null) return DarbStateView.error(message: _error, onRetry: _load);
    if (_vendorStatus != null && _vendorStatus != 'APPROVED') {
      return DarbStateView.empty(
        message: _vendorStatus == 'PENDING'
            ? dt('طلب متجرك قيد المراجعة. ستتمكن من إدارة المنتجات بعد اعتماد الإدارة.')
            : dt('حالة المتجر: $_vendorStatus'),
        icon: Icons.store_mall_directory_outlined,
        onRetry: _load,
      );
    }

    final categories = _categories;
    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = _products.where((p) {
      if (_selectedCategory.isNotEmpty &&
          p['category']?.toString() != _selectedCategory) {
        return false;
      }
      if (q.isEmpty) return true;
      return _productTitle(p).toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: dt('ابحث عن منتج...'),
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: () => _openProductSheet(),
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: Text(dt('إضافة منتج')),
                ),
              ],
            ),
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text(dt('الكل')),
                      selected: _selectedCategory.isEmpty,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = ''),
                    ),
                    for (final c in categories) ...[
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(c),
                        selected: _selectedCategory == c,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = c),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (filtered.isEmpty)
              DarbStateView.empty(
                message: dt('لم تضف أي منتجات بعد'),
                icon: Icons.inventory_2_outlined,
                onRetry: () => _openProductSheet(),
              )
            else
              for (final p in filtered)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildProductRow(p),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> p) {
    final id = p['id'].toString();
    final name = _productTitle(p);
    final category = p['category']?.toString();
    final price = num.tryParse(p['basePrice']?.toString() ?? '0') ?? 0;
    final currency = p['currency']?.toString() ?? 'SYP';
    final available = p['isAvailable'] != false;
    final stock = p['stockQty'];

    return DarbGlassSurface(
      padding: const EdgeInsets.all(14),
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
                      name,
                      style: TextStyle(
                        color: DarbColors.inkOf(context),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${formatDarbMoney(price, currency)}${category != null && category.isNotEmpty ? ' · $category' : ''}${stock != null ? ' · # $stock' : ''}',
                      style: TextStyle(
                        color: DarbColors.primaryOf(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: available,
                onChanged: (v) => _toggleAvailable(id, v),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _openProductSheet(existing: p),
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: Text(dt('تعديل المنتج')),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: DarbColors.dangerOf(context),
                ),
                onPressed: () => _deleteProduct(id),
                icon: const Icon(Icons.delete_outline_rounded, size: 17),
                label: Text(dt('حذف المنتج')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
