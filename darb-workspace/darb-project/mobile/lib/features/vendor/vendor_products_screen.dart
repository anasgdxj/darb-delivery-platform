import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_motion_components.dart';
import '../../core/widgets/darb_spatial_primitives.dart';

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
  final Set<String> _busyProductIds = <String>{};

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
      final rawMine = await Api.instance.get('/vendors/mine');
      if (rawMine is! Map<String, dynamic>) {
        if (mounted) {
          setState(() {
            _vendorStatus = 'MISSING';
            _products = const [];
          });
        }
        return;
      }
      final mine = rawMine;
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
                      final stockText = stockCtrl.text.trim();
                      final stock =
                          stockText.isEmpty ? null : int.tryParse(stockText);
                      if (name.length < 2 || price == null || price < 0) {
                        setSheet(
                            () => err = dt('أدخل اسم المنتج وسعراً صحيحاً'));
                        return;
                      }
                      if (stockText.isNotEmpty &&
                          (stock == null || stock < 0)) {
                        setSheet(() =>
                            err = dt('أدخل كمية مخزون صحيحة (0 أو أكثر)'));
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
    if (!_busyProductIds.add(id)) return;
    if (mounted) setState(() {});
    try {
      await Api.instance.delete('/vendor/products/$id');
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
      _busyProductIds.remove(id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _toggleAvailable(String id, bool nextVal) async {
    if (!_busyProductIds.add(id)) return;
    if (mounted) setState(() {});
    try {
      await Api.instance.patch('/vendor/products/$id', {'isAvailable': nextVal});
      if (mounted) DarbHaptics.selection();
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
      _busyProductIds.remove(id);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const DarbStateView.loading();
    if (_error != null) return DarbStateView.error(message: _error, onRetry: _load);
    if (_vendorStatus != null && _vendorStatus != 'APPROVED') {
      final msg = _vendorStatus == 'MISSING'
          ? dt('ملف المتجر غير مكتمل بعد. تواصل مع الإدارة أو أعد المحاولة.')
          : (_vendorStatus == 'PENDING'
              ? dt('طلب متجرك قيد المراجعة. ستتمكن من إدارة المنتجات بعد اعتماد الإدارة.')
              : dt('حالة المتجر: $_vendorStatus'));
      return RefreshIndicator(
        onRefresh: _load,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: DarbStateView.empty(
                message: msg,
                icon: Icons.store_mall_directory_outlined,
                onRetry: _load,
              ),
            ),
          ),
        ),
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
    final availableCount =
        _products.where((p) => p['isAvailable'] != false).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _load,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final hInset = maxW > 1080 ? (maxW - 1080) / 2 + 16 : 16.0;
            return ListView(
              padding: EdgeInsets.fromLTRB(hInset, 12, hInset, 110),
              children: [
                DarbCommandStage(
                  livePulse: availableCount > 0,
                  eyebrow: dt('متاح للبيع'),
                  title: dt('المنتجات'),
                  subtitle: dt('$availableCount منتج متاح'),
                  trailing: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: DarbColors.lime,
                      foregroundColor: DarbColors.darkCanvas,
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: () => _openProductSheet(),
                    icon: const Icon(Icons.add_rounded, size: 19),
                    label: Text(dt('إضافة منتج')),
                  ),
                ),
                const SizedBox(height: 12),
                DarbSearchBar(
                  controller: _searchCtrl,
                  hintText: dt('ابحث عن منتج...'),
                  onChanged: (_) => setState(() {}),
                ),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  DarbSegmentedDock<String>(
                    compact: true,
                    selectedValue: _selectedCategory,
                    onSelected: (val) =>
                        setState(() => _selectedCategory = val),
                    options: [
                      DarbDockOption(
                        value: '',
                        label: dt('الكل'),
                        count: _products.length,
                      ),
                      for (final c in categories)
                        DarbDockOption(
                          value: c,
                          label: c,
                          count: _products
                              .where((p) => p['category']?.toString() == c)
                              .length,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  DarbStateView.empty(
                    message: _products.isEmpty
                        ? dt('لم تضف أي منتجات بعد')
                        : dt('لم نعثر على نتائج مطابقة'),
                    icon: _products.isEmpty
                        ? Icons.inventory_2_outlined
                        : Icons.search_off_rounded,
                    onRetry: _products.isEmpty
                        ? () => _openProductSheet()
                        : () {
                            _searchCtrl.clear();
                            setState(() => _selectedCategory = '');
                          },
                  )
                else
                  DarbResponsiveTwoColumn(
                    children: [
                      for (var i = 0; i < filtered.length; i++)
                        i < 6
                            ? DarbFadeSlide(
                                delay: DarbMotion.staggerDelay(i),
                                child: _buildProductRow(filtered[i]),
                              )
                            : _buildProductRow(filtered[i]),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> p) {
    final id = p['id'].toString();
    final name = _productTitle(p);
    final desc = _productDesc(p);
    final category = p['category']?.toString();
    final price = num.tryParse(p['basePrice']?.toString() ?? '0') ?? 0;
    final currency = p['currency']?.toString() ?? 'SYP';
    final available = p['isAvailable'] != false;
    final stock = (p['stockQty'] as num?)?.toInt();
    final outOfStock = stock != null && stock <= 0;
    final isBusy = _busyProductIds.contains(id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DarbTelemetryProductCard(
          name: name,
          description: desc.trim().isNotEmpty ? desc : null,
          category: category,
          priceLabel: formatDarbMoney(price, currency),
          stockLabel: stock != null
              ? (outOfStock ? dt('نفد المخزون') : dt('المتبقي: $stock'))
              : null,
          stockRatio: stock != null ? (stock / 25).clamp(0.0, 1.0) : null,
          outOfStock: outOfStock || !available,
          highlighted: available,
          leadingIcon: Icons.inventory_2_outlined,
          actionDock: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Switch(
                value: available,
                onChanged: isBusy ? null : (v) => _toggleAvailable(id, v),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: dt('تعديل المنتج'),
                    onPressed:
                        isBusy ? null : () => _openProductSheet(existing: p),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: dt('حذف المنتج'),
                    onPressed: isBusy ? null : () => _deleteProduct(id),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: DarbColors.dangerOf(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
