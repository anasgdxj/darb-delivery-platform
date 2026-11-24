import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_city_scene.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_motion_components.dart';
import 'addresses_screen.dart';
import 'ai_order_assistant_screen.dart';
import 'driver_tracking_screen.dart';
import 'peer_delivery_screen.dart';
import 'vendor_catalog_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({
    super.key,
    this.user,
    this.onOrderCreated,
    this.onOpenOrders,
  });

  final Map<String, dynamic>? user;
  final VoidCallback? onOrderCreated;
  final VoidCallback? onOpenOrders;

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _cities = const [];
  List<Map<String, dynamic>> _vendors = const [];
  List<Map<String, dynamic>> _recentOrders = const [];
  List<Map<String, dynamic>> _addresses = const [];
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

  Map<String, dynamic>? get _selectedCityMap =>
      _cities.cast<Map<String, dynamic>?>().firstWhere(
            (c) => c?['id']?.toString() == _selectedCityId,
            orElse: () => null,
          );

  String get _selectedCityName {
    final match = _selectedCityMap;
    return match != null ? _cityDisplayName(match) : dt('المدينة');
  }

  String get _selectedCityCode =>
      _selectedCityMap?['code']?.toString() ?? '';

  String? get _primaryAddressLabel {
    if (_addresses.isEmpty) return null;
    final withLoc = _addresses.where((a) => a['hasLocation'] == true).toList();
    final addr = withLoc.isNotEmpty ? withLoc.first : _addresses.first;
    final label = addr['label']?.toString().trim();
    final details = addr['details']?.toString().trim() ?? '';
    if (label != null && label.isNotEmpty && details.isNotEmpty) {
      return '$label · $details';
    }
    return label?.isNotEmpty == true ? label : (details.isNotEmpty ? details : null);
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
      List<Map<String, dynamic>> orders = const [];
      List<Map<String, dynamic>> addresses = const [];
      var usedCache = cityRes.fromCache;

      final secondaryFutures = <Future<void>>[
        Api.instance
            .getWithCache('/orders/mine', 'customer_orders')
            .then((res) {
          orders = (res.data as List? ?? [])
              .whereType<Map<String, dynamic>>()
              .toList();
          usedCache = usedCache || res.fromCache;
        }).catchError((_) {}),
        Api.instance
            .getWithCache('/addresses', 'customer_addresses')
            .then((res) {
          addresses = (res.data as List? ?? [])
              .whereType<Map<String, dynamic>>()
              .toList();
          usedCache = usedCache || res.fromCache;
        }).catchError((_) {}),
      ];

      if (chosenId != null) {
        secondaryFutures.add(
          Api.instance
              .getWithCache(
                '/vendors?cityId=$chosenId&locale=${darbLocale.value.languageCode}',
                'city_vendors_$chosenId',
              )
              .then((vRes) {
            vendors = (vRes.data as List? ?? [])
                .whereType<Map<String, dynamic>>()
                .toList();
            usedCache = usedCache || vRes.fromCache;
          }),
        );
      }

      await Future.wait(secondaryFutures);

      if (!mounted) return;
      setState(() {
        _cities = cities;
        _selectedCityId = chosenId;
        _vendors = vendors;
        _recentOrders = orders;
        _addresses = addresses;
        _offline = usedCache;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = dt('حدث خطأ غير متوقع، حاول مجدداً'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _switchCity(String cityId) async {
    DarbHaptics.selection();
    setState(() {
      _selectedCityId = cityId;
      _selectedType = '';
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
    } catch (_) {
      if (mounted) setState(() => _error = dt('حدث خطأ غير متوقع، حاول مجدداً'));
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

  Map<String, dynamic>? get _featuredOrder {
    if (_recentOrders.isEmpty) return null;
    for (final order in _recentOrders) {
      final s = order['status']?.toString().toUpperCase() ?? '';
      if (s != 'DELIVERED' && s != 'CANCELLED' && s != 'REJECTED') {
        return order;
      }
    }
    return _recentOrders.first;
  }

  Future<void> _openAddresses() async {
    await Navigator.push(
      context,
      DarbPageRoute(builder: (_) => const AddressesScreen()),
    );
    try {
      final res = await Api.instance.getWithCache('/addresses', 'customer_addresses');
      final list = (res.data as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      if (mounted) setState(() => _addresses = list);
    } catch (_) {}
  }

  Future<void> _openDriverTracking(Map<String, dynamic> order) async {
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

  @override
  Widget build(BuildContext context) {
    if (_loading && _cities.isEmpty) return const DarbStateView.loading();
    if (_error != null && _cities.isEmpty) {
      return DarbStateView.error(message: _error, onRetry: _bootstrap);
    }

    final types = _vendorTypes;
    final filtered = _filteredVendors;
    final featuredOrder = _featuredOrder;
    final rawName = widget.user?['name']?.toString().trim();
    final greetingName =
        (rawName != null && rawName.isNotEmpty) ? rawName.split(' ').first : null;

    return RefreshIndicator(
      onRefresh: _bootstrap,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 108),
        children: [
          if (_offline)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DarbGlassSurface(
                tintColor: DarbColors.warningSoftOf(context),
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

          // 1. Personalized Greeting Header + Saved Addresses Trigger
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greetingName != null
                            ? '${dt('أهلاً بك')}، $greetingName'
                            : dt('مرحباً بك في دَرْب'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: DarbColors.inkOf(context),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dt('جاهز لتوصيل طلبك أو غرضك بأسرع مسار'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: DarbColors.mutedOf(context),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DarbRadius.pill),
                    ),
                  ),
                  onPressed: _openAddresses,
                  icon: Icon(
                    Icons.bookmarks_outlined,
                    size: 16,
                    color: DarbColors.primaryOf(context),
                  ),
                  label: Text(
                    dt('العناوين'),
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),

          // 2. Active City Selector
          if (_cities.isNotEmpty) ...[
            DarbGlassSurface(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: DarbColors.primaryOf(context).withValues(alpha: 0.14),
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
                          if (val != null && val != _selectedCityId) {
                            _switchCity(val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Deterministic Animated City Scene Banner (Selected city ONLY)
            DarbCitySceneCard(
              cityCode: _selectedCityCode,
              cityName: _selectedCityName,
              vendorCount: _vendors.length,
              activeAddressLabel: _primaryAddressLabel,
              onTapAddresses: _openAddresses,
            ),
            const SizedBox(height: 14),
          ],

          // 4. Asymmetric Bento Service Split (Peer Delivery + AI Order Assistant)
          DarbFadeSlide(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 6,
                    child: DarbBentoActionCard(
                      isHeroDark: true,
                      icon: Icons.local_shipping_outlined,
                      badge: dt('سريع'),
                      title: dt('إرسال غرض مستقل'),
                      subtitle: dt('أرسل طرداً أو غرضاً من أي عنوان إلى آخر'),
                      onTap: () {
                        if (_selectedCityId == null) return;
                        DarbHaptics.light();
                        Navigator.push(
                          context,
                          DarbPageRoute(
                            builder: (_) => PeerDeliveryScreen(
                              cityId: _selectedCityId!,
                              cityName: _selectedCityName,
                              onCreated: widget.onOrderCreated,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: DarbBentoActionCard(
                      icon: Icons.auto_awesome_rounded,
                      accentColor: DarbColors.primaryOf(context),
                      badge: 'AI',
                      title: dt('المساعد الذكي'),
                      subtitle: dt('اكتب طلبك وسيتم تجهيزه تلقائياً'),
                      onTap: () {
                        if (_selectedCityId == null) return;
                        DarbHaptics.light();
                        Navigator.push(
                          context,
                          DarbPageRoute(
                            builder: (_) => AiOrderAssistantScreen(
                              cityId: _selectedCityId!,
                              cityName: _selectedCityName,
                              onOrderCompleted: widget.onOrderCreated,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Active / Recent Orders Strip (Real API data only)
          if (featuredOrder != null) ...[
            const SizedBox(height: 18),
            DarbSectionHeader(
              title: dt('طلبك الحالي'),
              trailing: TextButton(
                onPressed: widget.onOpenOrders,
                child: Text(dt('عرض الكل')),
              ),
            ),
            const SizedBox(height: 8),
            _buildFeaturedOrderCard(featuredOrder),
          ],

          // 6. Store Discovery
          const SizedBox(height: 20),
          DarbSectionHeader(
            title: dt('المتاجر المتاحة'),
            subtitle: dt('تصفح المتاجر والمنتجات واطلب إلى بابك'),
            trailing: FilterChip(
              label: Text(dt('المفتوحة فقط')),
              selected: _openOnly,
              onSelected: (v) {
                DarbHaptics.selection();
                setState(() => _openOnly = v);
              },
            ),
          ),
          const SizedBox(height: 10),
          DarbSearchBar(
            controller: _searchController,
            hintText: dt('ابحث عن متجر أو نشاط...'),
            onChanged: (_) => setState(() {}),
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
                    onSelected: (_) {
                      DarbHaptics.selection();
                      setState(() => _selectedType = '');
                    },
                  ),
                  for (final t in types) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(t),
                      selected: _selectedType == t,
                      onSelected: (_) {
                        DarbHaptics.selection();
                        setState(() => _selectedType = t);
                      },
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
                child: i < 6
                    ? DarbFadeSlide(
                        delay: DarbMotion.staggerDelay(i),
                        child: _buildVendorCard(filtered[i]),
                      )
                    : _buildVendorCard(filtered[i]),
              ),
        ],
      ),
    );
  }

  Widget _buildFeaturedOrderCard(Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? 'PENDING';
    final isPeer = order['type'] == 'PEER_DELIVERY';
    final number = order['orderNumber']?.toString() ?? '';
    final total = num.tryParse(order['total']?.toString() ?? '0') ?? 0;
    final currency = order['currency']?.toString() ?? 'SYP';
    final canTrack = status == 'ASSIGNED' || status == 'PICKED_UP';

    return DarbInteractiveCard(
      onTap: widget.onOpenOrders,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${isPeer ? dt('توصيل مستقل') : dt('طلب')} · $number',
                  style: TextStyle(
                    color: DarbColors.inkOf(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              DarbStatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 12),
          DarbOrderTimeline(
            status: status,
            isPeer: isPeer,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  total > 0
                      ? formatDarbMoney(total, currency)
                      : dt('بانتظار العروض'),
                  style: TextStyle(
                    color: DarbColors.primaryOf(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
              ),
              if (canTrack)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  onPressed: () => _openDriverTracking(order),
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: Text(dt('موقع السائق')),
                )
              else
                TextButton.icon(
                  onPressed: widget.onOpenOrders,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text(dt('التفاصيل')),
                ),
            ],
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
    final ratingAvg =
        num.tryParse(v['ratingAvg']?.toString() ?? '')?.toDouble() ?? 0;
    final isDark = DarbColors.isDark(context);

    return DarbInteractiveCard(
      onTap: _selectedCityId == null
          ? null
          : () => Navigator.push(
                context,
                DarbPageRoute(
                  builder: (_) => VendorCatalogScreen(
                    vendor: v,
                    cityId: _selectedCityId!,
                    onOrderCompleted: widget.onOrderCreated,
                  ),
                ),
              ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      DarbColors.primaryOf(context).withValues(alpha: 0.18),
                      DarbColors.mint.withValues(alpha: isDark ? 0.14 : 0.30),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: DarbColors.primaryOf(context).withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: DarbColors.primaryOf(context),
                  size: 27,
                ),
              ),
              if (isOpen)
                const PositionedDirectional(
                  top: -3,
                  end: -3,
                  child: DarbPulseDot(size: 7.5),
                ),
            ],
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: DarbColors.inkOf(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    DarbStatusBadge(status: isOpen ? 'OPEN' : 'CLOSED'),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: DarbColors.softSurfaceOf(context),
                        borderRadius: BorderRadius.circular(DarbRadius.pill),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          color: DarbColors.inkOf(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (address != null && address.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: DarbColors.mutedOf(context),
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 14,
                      color: DarbColors.primaryOf(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dt('$count منتج متاح'),
                      style: TextStyle(
                        color: DarbColors.primaryOf(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (ratingAvg > 0 || reviewsCount > 0) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: DarbColors.warningOf(context)
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(DarbRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: DarbColors.warningOf(context),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${ratingAvg.toStringAsFixed(1)} ($reviewsCount)',
                              style: TextStyle(
                                color: DarbColors.inkOf(context),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Icon(
              Icons.chevron_right_rounded,
              color: DarbColors.mutedOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
