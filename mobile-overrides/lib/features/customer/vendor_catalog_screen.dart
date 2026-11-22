import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import 'checkout_screen.dart';

class VendorCatalogScreen extends StatefulWidget {
  const VendorCatalogScreen({
    super.key,
    required this.vendor,
    required this.cityId,
    this.initialCart = const {},
    this.onOrderCompleted,
  });

  final Map<String, dynamic> vendor;
  final String cityId;
  final Map<String, int> initialCart;
  final VoidCallback? onOrderCompleted;

  @override
  State<VendorCatalogScreen> createState() => _VendorCatalogScreenState();
}

class _VendorCatalogScreenState extends State<VendorCatalogScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _products = const [];
  final Map<String, int> _cart = {};
  String _selectedCategory = '';
  bool _loading = true;
  String? _error;

  String get _vendorId => widget.vendor['id'].toString();
  String get _vendorName {
    final tr = widget.vendor['translations'] as List? ?? [];
    return tr.isNotEmpty ? (tr.first['name']?.toString() ?? dt('متجر')) : dt('متجر');
  }

  bool get _vendorOpen => widget.vendor['isOpen'] != false;

  @override
  void initState() {
    super.initState();
    _cart.addAll(widget.initialCart);
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final locale = darbLocale.value.languageCode;
      final res = await Api.instance.getWithCache(
        '/vendors/$_vendorId/products?locale=$locale',
        'vendor_products_$_vendorId',
      );
      final list = (res.data as List? ?? []).whereType<Map<String, dynamic>>().toList();
      if (!mounted) return;
      setState(() => _products = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _categories {
    final set = <String>{};
    for (final p in _products) {
      final cat = p['category']?.toString().trim();
      if (cat != null && cat.isNotEmpty) set.add(cat);
    }
    return set.toList();
  }

  List<Map<String, dynamic>> get _filteredProducts {
    final q = _searchController.text.trim().toLowerCase();
    return _products.where((p) {
      if (_selectedCategory.isNotEmpty && p['category']?.toString() != _selectedCategory) {
        return false;
      }
      if (q.isEmpty) return true;
      final tr = (p['translations'] as List? ?? []);
      final name = tr.isNotEmpty ? tr.first['name']?.toString().toLowerCase() ?? '' : '';
      final desc = tr.isNotEmpty ? tr.first['description']?.toString().toLowerCase() ?? '' : '';
      return name.contains(q) || desc.contains(q);
    }).toList();
  }

  double get _cartSubtotal {
    var total = 0.0;
    for (final entry in _cart.entries) {
      final prod = _products.cast<Map<String, dynamic>?>().firstWhere(
            (p) => p?['id']?.toString() == entry.key,
            orElse: () => null,
          );
      if (prod != null) {
        final price = double.tryParse(prod['basePrice']?.toString() ?? '0') ?? 0;
        total += price * entry.value;
      }
    }
    return total;
  }

  int get _cartCount => _cart.values.fold(0, (a, b) => a + b);

  void _increment(Map<String, dynamic> product) {
    final id = product['id'].toString();
    final stock = (product['stockQty'] as num?)?.toInt();
    final current = _cart[id] ?? 0;
    if (stock != null && current >= stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dt('تم بلوغ الكمية المتوفرة من هذا المنتج'))),
      );
      return;
    }
    setState(() => _cart[id] = current + 1);
  }

  void _decrement(String id) {
    final current = _cart[id] ?? 0;
    if (current <= 1) {
      setState(() => _cart.remove(id));
    } else {
      setState(() => _cart[id] = current - 1);
    }
  }

  Future<void> _openCheckout() async {
    if (!_vendorOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dt('هذا المتجر غير متاح لاستقبال الطلبات حالياً.'))),
      );
      return;
    }
    final items = _cart.entries.map((entry) {
      final prod = _products.firstWhere((p) => p['id'].toString() == entry.key, orElse: () => {});
      final tr = (prod['translations'] as List? ?? []);
      return CartCheckoutItem(
        productId: entry.key,
        name: tr.isNotEmpty ? (tr.first['name']?.toString() ?? dt('منتج')) : dt('منتج'),
        unitPrice: double.tryParse(prod['basePrice']?.toString() ?? '0') ?? 0,
        currency: prod['currency']?.toString() ?? 'SYP',
        quantity: entry.value,
      );
    }).toList();

    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          cityId: widget.cityId,
          vendorId: _vendorId,
          vendorName: _vendorName,
          items: items,
        ),
      ),
    );
    if (submitted == true && mounted) {
      setState(() => _cart.clear());
      widget.onOrderCompleted?.call();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    final filtered = _filteredProducts;
    return Scaffold(
      appBar: DarbGlassAppBar(
        title: _vendorName,
        subtitle: widget.vendor['type']?.toString() ?? dt('متجر'),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: DarbStatusBadge(status: _vendorOpen ? 'OPEN' : 'CLOSED'),
          ),
        ],
      ),
      body: DarbAmbientBackground(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _loadProducts,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 12, 16, _cartCount > 0 ? 115 : 28),
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: dt('ابحث عن منتج...'),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () => setState(() => _searchController.clear()),
                              icon: const Icon(Icons.close_rounded),
                            )
                          : null,
                    ),
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
                            onSelected: (_) => setState(() => _selectedCategory = ''),
                          ),
                          for (final cat in categories) ...[
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text(cat),
                              selected: _selectedCategory == cat,
                              onSelected: (_) => setState(() => _selectedCategory = cat),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (_loading)
                    const DarbStateView.loading()
                  else if (_error != null)
                    DarbStateView.error(message: _error, onRetry: _loadProducts)
                  else if (filtered.isEmpty)
                    DarbStateView.empty(
                      message: dt('لا توجد منتجات متاحة'),
                      icon: Icons.inventory_2_outlined,
                    )
                  else
                    for (final prod in filtered)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildProductCard(prod),
                      ),
                ],
              ),
            ),
            if (_cartCount > 0)
              Positioned(
                left: 14,
                right: 14,
                bottom: 14 + MediaQuery.paddingOf(context).bottom,
                child: DarbGlassSurface(
                  borderRadius: DarbRadius.xl,
                  tintColor: DarbColors.forest.withValues(alpha: 0.92),
                  borderColor: DarbColors.mint.withValues(alpha: 0.35),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: DarbColors.mint,
                          borderRadius: BorderRadius.circular(DarbRadius.pill),
                        ),
                        child: Text(
                          '$_cartCount',
                          style: const TextStyle(
                            color: DarbColors.forest,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dt('السلة ($_cartCount)'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              formatDarbMoney(_cartSubtotal),
                              style: const TextStyle(color: DarbColors.mint, fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: DarbColors.primary,
                          minimumSize: const Size(0, 42),
                        ),
                        onPressed: _openCheckout,
                        child: Text(dt('تأكيد الطلب')),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> prod) {
    final id = prod['id'].toString();
    final tr = (prod['translations'] as List? ?? []);
    final name = tr.isNotEmpty ? (tr.first['name']?.toString() ?? dt('منتج')) : dt('منتج');
    final desc = tr.isNotEmpty ? tr.first['description']?.toString() : null;
    final price = double.tryParse(prod['basePrice']?.toString() ?? '0') ?? 0;
    final currency = prod['currency']?.toString() ?? 'SYP';
    final qty = _cart[id] ?? 0;

    return DarbGlassSurface(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: DarbColors.softSurfaceOf(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.shopping_bag_outlined, color: DarbColors.primaryOf(context), size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(color: DarbColors.inkOf(context), fontSize: 15.5, fontWeight: FontWeight.w800),
                ),
                if (desc != null && desc.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: DarbColors.mutedOf(context), fontSize: 12.5),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  formatDarbMoney(price, currency),
                  style: TextStyle(
                    color: DarbColors.primaryOf(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (qty == 0)
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                minimumSize: const Size(44, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                backgroundColor: DarbColors.mintTint,
                foregroundColor: DarbColors.forest,
              ),
              onPressed: _vendorOpen ? () => _increment(prod) : null,
              child: const Icon(Icons.add_rounded, size: 20),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: DarbColors.softSurfaceOf(context),
                borderRadius: BorderRadius.circular(DarbRadius.pill),
                border: Border.all(color: DarbColors.borderOf(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _decrement(id),
                    icon: const Icon(Icons.remove_rounded, size: 18),
                  ),
                  Text(
                    '$qty',
                    style: TextStyle(color: DarbColors.inkOf(context), fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _increment(prod),
                    icon: Icon(Icons.add_rounded, size: 18, color: DarbColors.primaryOf(context)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
