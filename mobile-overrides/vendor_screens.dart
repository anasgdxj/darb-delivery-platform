part of 'app_shell.dart';

String _localizedCatalogName(dynamic entity, String fallback) {
  final translations = entity['translations'] as List? ?? [];
  final locale = darbLocale.value.languageCode;
  for (final item in translations) {
    if (item is Map && item['locale'] == locale) {
      return item['name'].toString();
    }
  }
  for (final item in translations) {
    if (item is Map && item['locale'] == 'ar') return item['name'].toString();
  }
  return translations.isEmpty
      ? dt(fallback)
      : translations.first['name']?.toString() ?? dt(fallback);
}

class _VendorTile extends StatelessWidget {
  final Map<String, dynamic> vendor;
  final String cityId;
  const _VendorTile({required this.vendor, required this.cityId});

  @override
  Widget build(BuildContext context) {
    final name = _localizedCatalogName(vendor, 'متجر');
    return DarbFadeSlide(
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: const DazrevoIconWell(
            icon: Icons.storefront_rounded,
            size: 52,
            radius: 15,
          ),
          title: Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: DarbColors.ink,
            ),
          ),
          subtitle: Text(
            dt('${vendor['_count']?['products'] ?? 0} منتج متاح'),
            style: TextStyle(color: DarbColors.muted, fontSize: 12),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: DarbColors.accent,
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VendorCatalog(
                vendorId: vendor['id'].toString(),
                name: name,
                cityId: cityId,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VendorCatalog extends StatefulWidget {
  final String vendorId, name, cityId;
  const VendorCatalog({
    super.key,
    required this.vendorId,
    required this.name,
    required this.cityId,
  });
  @override
  State<VendorCatalog> createState() => _VendorCatalogState();
}

String _productName(dynamic p) => _localizedCatalogName(p, 'منتج');

class _VendorCatalogState extends State<VendorCatalog> {
  bool loading = true;
  String? error;
  int _loadGeneration = 0;
  List products = [];
  final Map<String, Map<String, dynamic>> cart = {};
  final TextEditingController search = TextEditingController();

  @override
  void initState() {
    super.initState();
    darbLocale.addListener(_onLocaleChanged);
    search.addListener(_refresh);
    _load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onLocaleChanged() => _load();

  @override
  void dispose() {
    darbLocale.removeListener(_onLocaleChanged);
    search.removeListener(_refresh);
    search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    if (mounted) setState(() => loading = true);
    try {
      final loaded = await Api.instance.get(
        '/vendors/${widget.vendorId}/products?locale=${darbLocale.value.languageCode}',
      ) as List;
      if (generation != _loadGeneration) return;
      products = loaded;
      error = null;
    } catch (e) {
      if (generation == _loadGeneration) error = e.toString();
    } finally {
      if (mounted && generation == _loadGeneration) {
        setState(() => loading = false);
      }
    }
  }

  void _add(dynamic p) {
    final id = p['id'].toString();
    setState(() {
      final old = cart[id];
      cart[id] = {
        'productId': id,
        'name': _productName(p),
        'price': p['basePrice'],
        'currency': p['currency'],
        'quantity': (old?['quantity'] ?? 0) + 1,
      };
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(dt('أضيف ${_productName(p)} إلى السلة')),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  void _changeQuantity(dynamic p, int delta) {
    final id = p['id'].toString();
    final current = cart[id]?['quantity'] as int? ?? 0;
    final next = current + delta;
    setState(() {
      if (next <= 0) {
        cart.remove(id);
      } else {
        cart[id] = {
          'productId': id,
          'name': _productName(p),
          'price': p['basePrice'],
          'currency': p['currency'],
          'quantity': next,
        };
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final quantity =
        cart.values.fold<int>(0, (total, item) => total + (item['quantity'] as int));
    final subtotal = cart.values.fold<double>(
      0,
      (sum, item) =>
          sum +
          ((double.tryParse(item['price'].toString()) ?? 0) *
              (item['quantity'] as int)),
    );
    final currency =
        cart.isEmpty ? '' : (cart.values.first['currency']?.toString() ?? '');
    final query = search.text.trim().toLowerCase();
    final visibleProducts = products
        .where((p) => _productName(p).toLowerCase().contains(query))
        .toList();

    return Scaffold(
      backgroundColor: DarbColors.canvas,
      appBar: AppBar(
        title: Text(widget.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 14),
            child: Center(
              child: DazrevoStatusTag(
                label: '$quantity',
                color: quantity > 0 ? DarbColors.accent : DarbColors.muted,
                icon: Icons.shopping_bag_outlined,
              ),
            ),
          ),
        ],
      ),
      body: loading
          ? ListView(
              padding: const EdgeInsets.all(18),
              children: List.generate(
                4,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: DazrevoShimmerTile(height: 92),
                ),
              ),
            )
          : error != null
              ? Padding(
                  padding: const EdgeInsets.all(18),
                  child: DazrevoErrorState(
                    message: error!,
                    onRetry: _load,
                    retryLabel: dt('إعادة المحاولة'),
                  ),
                )
              : products.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: DazrevoEmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: dt('لا توجد منتجات متاحة'),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                      children: [
                        DazrevoHeroSurface(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Icon(
                                Icons.storefront_rounded,
                                color: DarbColors.champagne,
                                size: 26,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  dt('منتجات المتجر'),
                                  style: TextStyle(
                                    color: DarbColors.ivory,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              DazrevoStatusTag(
                                label: '${products.length}',
                                color: DarbColors.champagne,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: search,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: dt('ابحث عن منتج...'),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: DarbColors.accent,
                            ),
                            suffixIcon: search.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: search.clear,
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 13),
                        if (visibleProducts.isEmpty)
                          DazrevoEmptyState(
                            icon: Icons.search_off_rounded,
                            title: query.isEmpty
                                ? dt('لا توجد منتجات متاحة')
                                : dt('لم نعثر على منتجات مطابقة'),
                          ),
                        for (var index = 0; index < visibleProducts.length; index++)
                          DarbFadeSlide(
                            delay: DarbMotion.staggerDelay(
                              index.clamp(0, 5).toInt(),
                            ),
                            child: Builder(
                              builder: (context) {
                                final product = visibleProducts[index];
                                final selected = cart[product['id'].toString()]
                                        ?['quantity'] as int? ??
                                    0;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(13),
                                    child: Row(
                                      children: [
                                        const DazrevoIconWell(
                                          icon: Icons.inventory_2_outlined,
                                          size: 54,
                                          radius: 15,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _productName(product),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14,
                                                  color: DarbColors.ink,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                '${product['basePrice']} ${product['currency']}',
                                                style: TextStyle(
                                                  color: DarbColors.accent,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 13.5,
                                                  fontFeatures: const [
                                                    FontFeature.tabularFigures(),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (selected == 0)
                                          IconButton.filledTonal(
                                            tooltip: dt('إضافة إلى السلة'),
                                            onPressed: () => _add(product),
                                            icon: const Icon(Icons.add_rounded),
                                            style: IconButton.styleFrom(
                                              backgroundColor: DarbColors.accent
                                                  .withValues(alpha: .16),
                                              foregroundColor:
                                                  DarbColors.brandForeground,
                                            ),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: DarbColors.surfaceAlt,
                                              borderRadius: BorderRadius.circular(
                                                DarbRadius.pill,
                                              ),
                                              border: Border.all(
                                                color: DarbColors.line,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  onPressed: () =>
                                                      _changeQuantity(product, -1),
                                                  icon: const Icon(
                                                    Icons.remove_rounded,
                                                  ),
                                                  iconSize: 17,
                                                  constraints:
                                                      const BoxConstraints.tightFor(
                                                    width: 30,
                                                    height: 30,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                  ),
                                                  child: Text(
                                                    '$selected',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w900,
                                                      color: DarbColors
                                                          .brandForeground,
                                                      fontFeatures: const [
                                                        FontFeature
                                                            .tabularFigures(),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () =>
                                                      _changeQuantity(product, 1),
                                                  icon: const Icon(Icons.add_rounded),
                                                  iconSize: 17,
                                                  constraints:
                                                      const BoxConstraints.tightFor(
                                                    width: 30,
                                                    height: 30,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
      bottomNavigationBar: quantity == 0
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(18, 8, 18, 14),
              child: FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutScreen(
                      vendorId: widget.vendorId,
                      cityId: widget.cityId,
                      items: cart.values.toList(),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${dt('متابعة إلى تأكيد الطلب • $quantity')} (${subtotal.toStringAsFixed(0)} $currency)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  final String vendorId, cityId;
  final List<Map<String, dynamic>> items;

  const CheckoutScreen({
    super.key,
    required this.vendorId,
    required this.cityId,
    required this.items,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool loading = true;
  bool sending = false;
  bool addingAddress = false;
  bool locating = false;
  String? error;
  String? addressId;
  List addresses = [];
  final notes = TextEditingController();
  final _addressFormKey = GlobalKey<FormState>();
  int _loadGeneration = 0;

  bool get _selectedAddressHasLocation => addresses.any(
        (address) =>
            address['id']?.toString() == addressId &&
            address['hasLocation'] == true,
      );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final result = await Api.instance.get('/addresses');
      if (result is! List) throw Exception(dt('تعذر قراءة عناوين التوصيل'));
      if (generation != _loadGeneration) return;
      addresses = result;
      if (!addresses.any((address) => address['id']?.toString() == addressId)) {
        addressId = addresses.isEmpty ? null : addresses.first['id'].toString();
      }
    } catch (e) {
      if (generation == _loadGeneration) error = e.toString();
    } finally {
      if (mounted && generation == _loadGeneration) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _newAddress() async {
    final label = TextEditingController();
    final details = TextEditingController();
    double? latitude;
    double? longitude;
    String? locationError;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, refreshDialog) => AlertDialog(
          title: Text(dt('إضافة عنوان توصيل')),
          content: SingleChildScrollView(
            child: Form(
              key: _addressFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: label,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: dt('اسم العنوان (اختياري)'),
                      prefixIcon: const Icon(Icons.bookmark_outline_rounded),
                    ),
                    validator: (value) => (value?.trim().length ?? 0) > 40
                        ? dt('اسم العنوان طويل جداً')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: details,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 500,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      labelText: dt('العنوان بالتفصيل'),
                      hintText: dt('الحي، الشارع، البناء، الطابق...'),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return dt('أدخل تفاصيل العنوان');
                      if (text.length > 500) {
                        return dt('تفاصيل العنوان طويلة جداً');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: locating
                          ? null
                          : () async {
                              refreshDialog(() {
                                locating = true;
                                locationError = null;
                              });
                              try {
                                if (!await Geolocator.isLocationServiceEnabled()) {
                                  throw Exception(
                                    dt('فعّل خدمة الموقع في هاتفك أولاً'),
                                  );
                                }
                                var permission =
                                    await Geolocator.checkPermission();
                                if (permission == LocationPermission.denied) {
                                  permission =
                                      await Geolocator.requestPermission();
                                }
                                if (permission == LocationPermission.denied ||
                                    permission ==
                                        LocationPermission.deniedForever) {
                                  throw Exception(
                                    dt('يلزم السماح للتطبيق بالوصول إلى موقعك'),
                                  );
                                }
                                final point = await Geolocator.getCurrentPosition(
                                  locationSettings: const LocationSettings(
                                    accuracy: LocationAccuracy.high,
                                    timeLimit: Duration(seconds: 20),
                                  ),
                                );
                                latitude = point.latitude;
                                longitude = point.longitude;
                                if (dialogContext.mounted) refreshDialog(() {});
                              } catch (e) {
                                locationError = e.toString();
                                if (dialogContext.mounted) refreshDialog(() {});
                              } finally {
                                if (dialogContext.mounted) {
                                  refreshDialog(() => locating = false);
                                }
                              }
                            },
                      icon: locating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              latitude == null
                                  ? Icons.my_location_rounded
                                  : Icons.check_circle_rounded,
                              color: latitude == null
                                  ? DarbColors.brandForeground
                                  : DarbColors.success,
                            ),
                      label: Text(
                        locating
                            ? dt('جارٍ تحديد الموقع...')
                            : latitude == null
                                ? dt('استخدام موقعي الحالي')
                                : dt('تم تحديد الموقع'),
                      ),
                    ),
                  ),
                  if (locationError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        locationError!,
                        style: TextStyle(color: DarbColors.danger, fontSize: 12),
                      ),
                    ),
                  if (latitude != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: DarbColors.success,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              dt(
                                'سيتم حفظ إحداثيات هذا العنوان لحساب مسافة التوصيل',
                              ),
                              style: TextStyle(
                                color: DarbColors.success,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  locating ? null : () => Navigator.pop(dialogContext, false),
              child: Text(dt('إلغاء')),
            ),
            FilledButton(
              onPressed: locating
                  ? null
                  : () {
                      if (_addressFormKey.currentState?.validate() ?? false) {
                        Navigator.pop(dialogContext, true);
                      }
                    },
              child: Text(dt('حفظ العنوان')),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      if (mounted) {
        setState(() {
          addingAddress = true;
          error = null;
        });
      }
      try {
        final created = await Api.instance.post('/addresses', {
          'label': label.text.trim(),
          'details': details.text.trim(),
          if (latitude != null && longitude != null) 'latitude': latitude,
          if (latitude != null && longitude != null) 'longitude': longitude,
        });
        if (created is! Map || created['id'] == null) {
          throw Exception(dt('لم يتم حفظ العنوان بشكل صحيح'));
        }
        if (mounted) {
          setState(() {
            addresses.insert(0, {
              ...Map<String, dynamic>.from(created),
              'hasLocation': latitude != null && longitude != null,
            });
            addressId = created['id'].toString();
            error = null;
          });
        }
      } catch (e) {
        if (mounted) setState(() => error = e.toString());
      } finally {
        if (mounted) setState(() => addingAddress = false);
      }
    }
    label.dispose();
    details.dispose();
  }

  String _orderError(Object exception) {
    final raw = exception.toString();
    if (raw.contains('حدد موقع عنوان التوصيل')) {
      return dt(
        'هذا الطلب يحتاج إلى إحداثيات عنوان التوصيل لحساب الأجرة. أضف عنواناً جديداً وحدد موقعك بدقة.',
      );
    }
    if (raw.contains('لم يتم إعداد رسوم التوصيل')) {
      return dt('التوصيل غير مفعّل لهذه المدينة حالياً. لم يتم إرسال الطلب.');
    }
    if (raw.contains('بعض المنتجات لم تعد متاحة') ||
        raw.contains('نفدت كمية أحد المنتجات')) {
      return dt(
        'تغيّرت توفر المنتجات أو الكمية. ارجع إلى المتجر وحدّث سلتك قبل المحاولة.',
      );
    }
    if (raw.contains('المتجر غير متاح')) {
      return dt('هذا المتجر غير متاح لاستقبال الطلبات حالياً.');
    }
    return raw;
  }

  Future<void> _submit() async {
    if (sending) return;
    if (widget.items.isEmpty ||
        widget.items.any((item) => (item['quantity'] as int? ?? 0) < 1)) {
      setState(() => error = dt('السلة فارغة أو تحتوي على كمية غير صالحة'));
      return;
    }
    if (addressId == null ||
        !addresses.any((address) => address['id']?.toString() == addressId)) {
      setState(
        () => error = dt('اختر عنوان توصيل صالحاً أو أضف عنواناً جديداً'),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      sending = true;
      error = null;
    });
    try {
      final result = await Api.instance.post('/orders', {
        'cityId': widget.cityId,
        'addressId': addressId,
        'vendorId': widget.vendorId,
        'items': widget.items
            .map((item) => {
                  'productId': item['productId'],
                  'quantity': item['quantity'],
                })
            .toList(),
        'notes': notes.text.trim(),
      });
      if (!mounted) return;
      if (result is! Map || result['id'] == null) {
        throw Exception(
          dt(
            'تم إرسال الطلب لكن تعذر قراءة تفاصيل التأكيد. تحقق من صفحة طلباتي قبل إعادة المحاولة.',
          ),
        );
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              OrderCreatedScreen(order: Map<String, dynamic>.from(result)),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => error = _orderError(e));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.items.fold<double>(
      0,
      (sum, item) =>
          sum +
          ((double.tryParse(item['price'].toString()) ?? 0) *
              (item['quantity'] as int)),
    );
    final currency =
        widget.items.isEmpty ? '' : widget.items.first['currency']?.toString() ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: DarbColors.canvas,
      appBar: AppBar(title: Text(dt('تأكيد الطلب'))),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null && addresses.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    DazrevoErrorState(
                      message: error!,
                      onRetry: _load,
                      retryLabel: dt('إعادة المحاولة'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: addingAddress ? null : _newAddress,
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: Text(dt('إضافة عنوان جديد')),
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                  children: [
                    DazrevoHeroSurface(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            color: DarbColors.champagne,
                            size: 27,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dt('مراجعة طلبك'),
                                  style: TextStyle(
                                    color: DarbColors.ivory,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dt('راجع المنتجات والعنوان قبل إرسال الطلب'),
                                  style: TextStyle(
                                    color: DarbColors.ivory.withValues(alpha: .76),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    DazrevoSectionHeader(title: dt('ملخص السلة')),
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          children: [
                            for (var index = 0;
                                index < widget.items.length;
                                index++) ...[
                              if (index > 0) const Divider(height: 18),
                              Row(
                                children: [
                                  const DazrevoIconWell(
                                    icon: Icons.inventory_2_outlined,
                                    size: 40,
                                    radius: 11,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.items[index]['name'].toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13.5,
                                            color: DarbColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${dt('الكمية')}: ${widget.items[index]['quantity']}',
                                          style: TextStyle(
                                            color: DarbColors.muted,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${widget.items[index]['price']} ${widget.items[index]['currency']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: DarbColors.accent,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const Divider(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    dt('المجموع الفرعي التقريبي'),
                                    style: TextStyle(
                                      color: DarbColors.muted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$subtotal $currency',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: DarbColors.brandForeground,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                dt(
                                  'السعر النهائي ورسوم التوصيل يؤكدهما الخادم عند إنشاء الطلب',
                                ),
                                style: TextStyle(
                                  color: DarbColors.muted,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    DazrevoSectionHeader(
                      title: dt('عنوان التوصيل'),
                      trailing: TextButton.icon(
                        onPressed:
                            addingAddress || sending ? null : _newAddress,
                        icon: const Icon(
                          Icons.add_location_alt_outlined,
                          size: 17,
                        ),
                        label: Text(dt('إضافة عنوان')),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (addresses.isEmpty)
                      DazrevoEmptyState(
                        icon: Icons.location_off_outlined,
                        title: dt('لا يوجد عنوان محفوظ. أضف عنواناً للمتابعة.'),
                      )
                    else
                      ...addresses.map((address) {
                        final id = address['id'].toString();
                        final selected = id == addressId;
                        final hasLoc = address['hasLocation'] == true;
                        final label =
                            address['label']?.toString().trim().isNotEmpty == true
                                ? address['label'].toString()
                                : dt('عنوان');
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(DarbRadius.md),
                            onTap: sending
                                ? null
                                : () => setState(() {
                                      addressId = id;
                                      error = null;
                                    }),
                            child: AnimatedContainer(
                              duration: DarbMotion.fast,
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: selected
                                    ? DarbColors.accent.withValues(alpha: .08)
                                    : DarbColors.surface,
                                borderRadius:
                                    BorderRadius.circular(DarbRadius.md),
                                border: Border.all(
                                  color: selected
                                      ? DarbColors.accent
                                      : DarbColors.line,
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selected
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                    color: selected
                                        ? DarbColors.accent
                                        : DarbColors.muted,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          label,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: DarbColors.ink,
                                          ),
                                        ),
                                        if ((address['details'] ?? '')
                                            .toString()
                                            .isNotEmpty)
                                          Text(
                                            address['details'].toString(),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: DarbColors.muted,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  DazrevoStatusTag(
                                    label: hasLoc
                                        ? dt('موقع محدد')
                                        : dt('الموقع غير محدد'),
                                    color: hasLoc
                                        ? DarbColors.success
                                        : DarbColors.warning,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    if (addressId != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _selectedAddressHasLocation
                                ? Icons.check_circle_rounded
                                : Icons.info_outline_rounded,
                            size: 16,
                            color: _selectedAddressHasLocation
                                ? DarbColors.success
                                : DarbColors.warning,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              _selectedAddressHasLocation
                                  ? dt('موقع العنوان محفوظ ويمكن حساب المسافة')
                                  : dt(
                                      'لا توجد إحداثيات لهذا العنوان. قد يطلب النظام تحديد الموقع لحساب رسوم التوصيل.',
                                    ),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: _selectedAddressHasLocation
                                    ? DarbColors.success
                                    : DarbColors.warning,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    TextField(
                      controller: notes,
                      maxLength: 500,
                      maxLines: 3,
                      enabled: !sending,
                      decoration: InputDecoration(
                        labelText: dt('ملاحظات للمتجر (اختياري)'),
                        hintText: dt('تعليمات تساعد المتجر في تجهيز طلبك'),
                        prefixIcon: const Icon(Icons.notes_rounded),
                        alignLabelWithHint: true,
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: DazrevoErrorState(
                          message: error!,
                          onRetry: _submit,
                          retryLabel: dt('إعادة المحاولة'),
                        ),
                      ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed:
                          sending || addressId == null || widget.items.isEmpty
                              ? null
                              : _submit,
                      child: sending
                          ? SizedBox(
                              width: 21,
                              height: 21,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark
                                    ? DarbColors.obsidian
                                    : DarbColors.ivory,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 19,
                                ),
                                const SizedBox(width: 8),
                                Text(dt('تأكيد الطلب • الدفع عند الاستلام')),
                              ],
                            ),
                    ),
                    const SizedBox(height: 9),
                    Center(
                      child: Text(
                        dt('لن يتم تحصيل أي مبلغ إلكترونياً في هذه الخطوة'),
                        style: TextStyle(color: DarbColors.muted, fontSize: 10.5),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class OrderCreatedScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  const OrderCreatedScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final orderNumber =
        order['orderNumber']?.toString() ?? order['id']?.toString() ?? '—';
    final currency = order['currency']?.toString() ?? '';
    final total = order['total']?.toString() ?? '—';
    final deliveryFee = order['deliveryFee']?.toString();

    return Scaffold(
      backgroundColor: DarbColors.canvas,
      appBar: AppBar(title: Text(dt('تم استلام طلبك'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const SizedBox(height: 18),
            Center(
              child: Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DarbColors.success.withValues(alpha: .12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DarbColors.success.withValues(alpha: .35),
                  ),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: DarbColors.success,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              dt('تم إرسال طلبك بنجاح'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                color: DarbColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dt('وصل طلبك إلى النظام، ويمكنك متابعة حالته من قسم طلباتي.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: DarbColors.muted, height: 1.5),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Text(
                      dt('رقم الطلب'),
                      style: TextStyle(color: DarbColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      orderNumber,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 19,
                        color: DarbColors.accent,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Divider(height: 28),
                    if (deliveryFee != null)
                      _confirmationValue(
                        context,
                        dt('رسوم التوصيل'),
                        '$deliveryFee $currency',
                      ),
                    _confirmationValue(
                      context,
                      dt('الإجمالي عند الاستلام'),
                      '$total $currency',
                    ),
                    _confirmationValue(
                      context,
                      dt('طريقة الدفع'),
                      dt('الدفع نقداً عند الاستلام'),
                    ),
                    _confirmationValue(
                      context,
                      dt('حالة الطلب'),
                      dt('بانتظار تأكيد المتجر'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              icon: const Icon(Icons.home_rounded),
              label: Text(dt('العودة إلى الرئيسية')),
            ),
            const SizedBox(height: 10),
            Text(
              dt('احتفظ برقم الطلب للرجوع إليه عند الحاجة.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: DarbColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _confirmationValue(BuildContext context, String label, String value) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: DarbColors.muted, fontSize: 12.5),
              ),
            ),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: DarbColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      );
}

class CustomerOrders extends StatelessWidget {
  const CustomerOrders({super.key});
  @override
  Widget build(BuildContext context) => _DataList(
        path: '/orders/mine',
        title: dt('طلباتك'),
        empty: dt('لا توجد طلبات حتى الآن'),
      );
}

class VendorOrders extends StatelessWidget {
  const VendorOrders({super.key});
  @override
  Widget build(BuildContext context) => _DataList(
        path: '/orders/vendor',
        title: dt('طلبات المتجر'),
        empty: dt('لا توجد طلبات واردة'),
      );
}

class VendorProducts extends StatefulWidget {
  const VendorProducts({super.key});
  @override
  State<VendorProducts> createState() => _VendorProductsState();
}

class _VendorProductsState extends State<VendorProducts> {
  bool loading = true, saving = false;
  String? error, vendorStatus;
  int _loadGeneration = 0;
  List products = [];

  @override
  void initState() {
    super.initState();
    darbLocale.addListener(_onLocaleChanged);
    _load();
  }

  void _onLocaleChanged() => _load();

  @override
  void dispose() {
    darbLocale.removeListener(_onLocaleChanged);
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    if (mounted) setState(() => loading = true);
    try {
      final mine = await Api.instance.get('/vendors/mine');
      if (generation != _loadGeneration) return;
      vendorStatus = mine['status']?.toString();
      if (vendorStatus != 'APPROVED') {
        products = [];
        error = null;
      } else {
        final id = mine['id'].toString();
        final loaded = await Api.instance.get(
          '/vendors/$id/products?locale=${darbLocale.value.languageCode}',
        ) as List;
        if (generation != _loadGeneration) return;
        products = loaded;
        error = null;
      }
    } catch (e) {
      if (generation == _loadGeneration) error = e.toString();
    } finally {
      if (mounted && generation == _loadGeneration) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _add() async {
    final name = TextEditingController(),
        price = TextEditingController(),
        description = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dt('منتج جديد')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: dt('اسم المنتج')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: dt('السعر')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: description,
                maxLines: 2,
                decoration: InputDecoration(labelText: dt('الوصف')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(dt('إلغاء')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(dt('إضافة')),
          ),
        ],
      ),
    );
    if (ok == true &&
        name.text.trim().isNotEmpty &&
        (double.tryParse(price.text) ?? 0) > 0) {
      setState(() => saving = true);
      try {
        await Api.instance.post('/vendor/products', {
          'name': name.text.trim(),
          'price': double.parse(price.text),
          'description': description.text.trim(),
          'currency': 'SYP',
        });
        await _load();
      } catch (e) {
        setState(() => error = e.toString());
      } finally {
        if (mounted) setState(() => saving = false);
      }
    }
    name.dispose();
    price.dispose();
    description.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: DarbColors.canvas,
        body: loading
            ? ListView(
                padding: const EdgeInsets.all(18),
                children: List.generate(
                  4,
                  (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: DazrevoShimmerTile(height: 78),
                  ),
                ),
              )
            : vendorStatus != null && vendorStatus != 'APPROVED'
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: DazrevoEmptyState(
                        icon: Icons.hourglass_top_rounded,
                        title: vendorStatus == 'PENDING'
                            ? dt(
                                'طلب متجرك قيد المراجعة. ستتمكن من إدارة المنتجات بعد اعتماد الإدارة.',
                              )
                            : dt('حالة المتجر: $vendorStatus'),
                      ),
                    ),
                  )
                : error != null
                    ? Padding(
                        padding: const EdgeInsets.all(18),
                        child: DazrevoErrorState(
                          message: error!,
                          onRetry: _load,
                          retryLabel: dt('إعادة المحاولة'),
                        ),
                      )
                    : products.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: DazrevoEmptyState(
                                icon: Icons.inventory_2_outlined,
                                title: dt('لم تضف أي منتجات بعد'),
                                action: FilledButton.icon(
                                  onPressed: saving ? null : _add,
                                  icon: const Icon(Icons.add_rounded),
                                  label: Text(dt('إضافة منتج')),
                                ),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: DarbColors.accent,
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                              children: [
                                DazrevoSectionHeader(
                                  title: dt('منتجات متجرك'),
                                  trailing: FilledButton.icon(
                                    onPressed: saving ? null : _add,
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(0, 42),
                                    ),
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: Text(dt('إضافة')),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                for (final p in products)
                                  Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      leading: const DazrevoIconWell(
                                        icon: Icons.inventory_2_outlined,
                                      ),
                                      title: Text(
                                        _productName(p),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: DarbColors.ink,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${p['basePrice']} ${p['currency']}',
                                        style: TextStyle(
                                          color: DarbColors.accent,
                                          fontWeight: FontWeight.w800,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
      );
}
