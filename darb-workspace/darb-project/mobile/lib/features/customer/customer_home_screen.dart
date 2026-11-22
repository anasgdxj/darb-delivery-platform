import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import 'addresses_screen.dart';
import 'ai_order_assistant_screen.dart';
import 'peer_delivery_screen.dart';
import 'vendor_catalog_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key, this.onOrderCreated});
  final VoidCallback? onOrderCreated;

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _cities = const [];
  List<Map<String, dynamic>> _vendors = const [];
  String? _selectedCityId;
  String _selectedType = '';
  bool _openOnly = false;
  bool _loading = true;
  bool _offline = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    darbLocale.addListener(_onLocaleChanged);
    _bootstrap();
  }

  void _onLocaleChanged() {
    if (mounted) _bootstrap();
  }

  @override
  void dispose() {
    darbLocale.removeListener(_onLocaleChanged);
    _searchController.dispose();
    super.dispose();
  }

  String _cityDisplayName(Map<String, dynamic> city) {
    final code = darbLocale.value.languageCode;
    final names =
        (city['names'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    final exact = names.cast<Map<String, dynamic>?>().firstWhere(
          (n) => n?['locale'] == code,
          orElse: () => null,
        );
    return exact?['name']?.toString() ??
        (names.isNotEmpty
            ? names.first['name']?.toString() ?? ''
            : city['code']?.toString() ?? '');
  }

  String get _selectedCityName {
    final match = _cities.cast<Map<String, dynamic>?>().firstWhere(
          (c) => c?['id']?.toString() == _selectedCityId,
          orElse: () => null,
        );
    return match != null ? _cityDisplayName(match) : dt('المدينة');
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cityRes = await Api.instance.getWithCache('/cities', 'active_cities');
      final cities = (cityRes.data as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      final chosenId = _selectedCityId ??
          (cities.isNotEmpty ? cities.first['id']?.toString() : null);

      List<Map<String, dynamic>> vendors = const [];
      var usedCache = cityRes.fromCache;
      if (chosenId != null) {
        final vRes = await Api.instance.getWithCache(
          '/vendors?cityId=$chosenId&locale=${darbLocale.value.languageCode}',
          'city_vendors_$chosenId',
        );
        vendors = (vRes.data as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        usedCache = usedCache || vRes.fromCache;
      }

      if (!mounted) return;
      setState(() {
        _cities = cities;
        _selectedCityId = chosenId;
        _vendors = vendors;
        _offline = usedCache;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _switchCity(String cityId) async {
    setState(() {
      _selectedCityId = cityId;
      _loading = true;
      _error = null;
    });
    try {
      final res = await Api.instance.getWithCache(
        '/vendors?cityId=$cityId&locale=${darbLocale.value.languageCode}',
        'city_vendors_$cityId',
      );
      final vendors =
          (res.data as List? ?? []).whereType<Map<String, dynamic>>().toList();
      if (!mounted) return;
      setState(() {
        _vendors = vendors;
        _offline = res.fromCache;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _vendorTypes {
    final types = <String>{};
    for (final v in _vendors) {
      final t = v['type']?.toString().trim();
      if (t != null && t.isNotEmpty) types.add(t);
    }
    return types.toList();
  }

  List<Map<String, dynamic>> get _filteredVendors {
    final q = _searchController.text.trim().toLowerCase();
    return _vendors.where((v) {
      if (_openOnly && v['isOpen'] == false) return false;
      if (_selectedType.isNotEmpty && v['type']?.toString() != _selectedType) {
        return false;
      }
      if (q.isEmpty) return true;
      final tr = (v['translations'] as List? ?? []);
      final name =
          tr.isNotEmpty ? tr.first['name']?.toString().toLowerCase() ?? '' : '';
      final type = v['type']?.toString().toLowerCase() ?? '';
      return name.contains(q) || type.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _cities.isEmpty) return const DarbStateView.loading();
    if (_error != null && _cities.isEmpty) {
      return DarbStateView.error(message: _error, onRetry: _bootstrap);
    }

    final isDark = DarbColors.isDark(context);
    final types = _vendorTypes;
    final filtered = _filteredVendors;

    return RefreshIndicator(
      onRefresh: _bootstrap,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 104),
        children: [
          if (_offline)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DarbGlassSurface(
                tintColor: DarbColors.warningOf(context)
                    .withValues(alpha: isDark ? 0.18 : 0.12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  dt('بيانات مخزنة محلياً لضعف الاتصال'),
                  style: TextStyle(
                    color: DarbColors.warningOf(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (_cities.isNotEmpty)
            DarbGlassSurface(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          DarbColors.primaryOf(context).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.location_city_rounded,
                      size: 19,
                      color: DarbColors.primaryOf(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCityId,
                        isExpanded: true,
                        dropdownColor: DarbColors.surfaceElevatedOf(context),
                        style: TextStyle(
                          color: DarbColors.inkOf(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                        items: [
                          for (final c in _cities)
                            DropdownMenuItem(
                              value: c['id'].toString(),
                              child: Text(_cityDisplayName(c)),
                            ),
                        ],
                        onChanged: (val) {
                          if (val != null) _switchCity(val);
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: dt('عناوين التوصيل'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddressesScreen(),
                      ),
                    ),
                    icon: Icon(
                      Icons.bookmarks_outlined,
                      color: DarbColors.primaryOf(context),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          DarbFadeSlide(
            child: DarbGlassSurface(
              borderRadius: DarbRadius.xl,
              tintColor: DarbColors.forest,
              borderColor: DarbColors.mint.withValues(alpha: 0.25),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    dt('توصيل من الباب إلى الباب'),
                    style: const TextStyle(
                      color: DarbColors.mint,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dt('غرضك بأي مكان…\nودَرْب يوصّله.'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: DarbColors.lime,
                            foregroundColor: DarbColors.forest,
                          ),
                          onPressed: _selectedCityId == null
                              ? null
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PeerDeliveryScreen(
                                        cityId: _selectedCityId!,
                                        cityName: _selectedCityName,
                                        onCreated: widget.onOrderCreated,
                                      ),
                                    ),
                                  ),
                          icon: const Icon(
                            Icons.local_shipping_outlined,
                            size: 18,
                          ),
                          label: Text(dt('إرسال غرض مستقل')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor:
                              DarbColors.mint.withValues(alpha: 0.20),
                          foregroundColor: DarbColors.mint,
                          minimumSize: const Size(50, 50),
                        ),
                        tooltip: dt('مساعد الطلبات الذكي'),
                        onPressed: _selectedCityId == null
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AiOrderAssistantScreen(
                                      cityId: _selectedCityId!,
                                      cityName: _selectedCityName,
                                      onOrderCompleted: widget.onOrderCreated,
                                    ),
                                  ),
                                ),
                        icon: const Icon(Icons.auto_awesome_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          DarbSectionHeader(
            title: dt('المتاجر المتاحة'),
            subtitle: dt('تصفح المتاجر والمنتجات واطلب إلى بابك'),
            trailing: FilterChip(
              label: Text(dt('المفتوحة فقط')),
              selected: _openOnly,
              onSelected: (v) => setState(() => _openOnly = v),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: dt('ابحث عن متجر أو نشاط...'),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () =>
                          setState(() => _searchController.clear()),
                      icon: const Icon(Icons.close_rounded),
                    )
                  : null,
            ),
          ),
          if (types.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(dt('الكل')),
                    selected: _selectedType.isEmpty,
                    onSelected: (_) => setState(() => _selectedType = ''),
                  ),
                  for (final t in types) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(t),
                      selected: _selectedType == t,
                      onSelected: (_) => setState(() => _selectedType = t),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (_loading)
            const DarbStateView.loading()
          else if (filtered.isEmpty)
            DarbStateView.empty(
              message: _vendors.isEmpty
                  ? dt('لا توجد متاجر متاحة في هذه المدينة')
                  : dt('لم نعثر على نتائج مطابقة'),
              icon: Icons.storefront_outlined,
            )
          else
            for (var i = 0; i < filtered.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DarbFadeSlide(
                  delay: DarbMotion.staggerDelay(i),
                  child: _buildVendorCard(filtered[i]),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildVendorCard(Map<String, dynamic> v) {
    final tr = (v['translations'] as List? ?? []);
    final name = tr.isNotEmpty
        ? (tr.first['name']?.toString() ?? dt('متجر'))
        : dt('متجر');
    final type = v['type']?.toString() ?? dt('متجر');
    final address = v['location']?['address']?.toString();
    final isOpen = v['isOpen'] != false;
    final count = (v['_count']?['products'] as num?)?.toInt() ?? 0;
    final reviewsCount = (v['_count']?['reviews'] as num?)?.toInt() ?? 0;
    final ratingAvg = num.tryParse(v['ratingAvg']?.toString() ?? '')?.toDouble() ?? 0;

    return DarbPressScale(
      onTap: _selectedCityId == null
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VendorCatalogScreen(
                    vendor: v,
                    cityId: _selectedCityId!,
                    onOrderCompleted: widget.onOrderCreated,
                  ),
                ),
              ),
      child: DarbGlassSurface(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DarbColors.primaryOf(context).withValues(alpha: 0.16),
                    DarbColors.mint.withValues(alpha: 0.25),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.storefront_rounded,
                color: DarbColors.primaryOf(context),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: DarbColors.inkOf(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      DarbStatusBadge(status: isOpen ? 'OPEN' : 'CLOSED'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address != null && address.isNotEmpty
                        ? '$type · $address'
                        : type,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: DarbColors.mutedOf(context),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        dt('$count منتج متاح'),
                        style: TextStyle(
                          color: DarbColors.primaryOf(context),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (ratingAvg > 0 || reviewsCount > 0) ...[
                        const SizedBox(width: 10),
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: DarbColors.warningOf(context),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${ratingAvg.toStringAsFixed(1)} ($reviewsCount)',
                          style: TextStyle(
                            color: DarbColors.inkOf(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: DarbColors.mutedOf(context)),
          ],
        ),
      ),
    );
  }
}
