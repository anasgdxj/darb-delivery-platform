import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/local_cache.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_city_scene.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_motion_components.dart';
import '../../core/widgets/darb_spatial_primitives.dart';
import 'addresses_screen.dart';
import 'ai_order_assistant_screen.dart';
import 'driver_tracking_screen.dart';
import 'peer_delivery_screen.dart';
import 'shopping_request_screen.dart';
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
  static const _favoritesCacheKey = 'favorite_vendors_v1';

  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _cities = const [];
  List<Map<String, dynamic>> _vendors = const [];
  List<Map<String, dynamic>> _recentOrders = const [];
  List<Map<String, dynamic>> _addresses = const [];
  Set<String> _favoriteVendorIds = <String>{};
  String? _selectedCityId;
  String _selectedType = '';
  bool _openOnly = false;
  bool _favoritesOnly = false;
  bool _loading = true;
  bool _loadingVendors = false;
  bool _offline = false;
  String? _error;
  String? _vendorsError;

  @override
  void initState() {
    super.initState();
    darbLocale.addListener(_onLocaleChanged);
    unawaited(_loadFavorites());
    _bootstrap();
  }

  Future<void> _loadFavorites() async {
    try {
      final raw = await DarbLocalCache.instance.readJson(_favoritesCacheKey);
      if (raw is List && mounted) {
        setState(() {
          _favoriteVendorIds =
              raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite(String vendorId) async {
    DarbHaptics.selection();
    final updated = Set<String>.from(_favoriteVendorIds);
    if (!updated.remove(vendorId)) {
      updated.add(vendorId);
    }
    setState(() {
      _favoriteVendorIds = updated;
      if (_favoritesOnly && updated.isEmpty) {
        _favoritesOnly = false;
      }
    });
    unawaited(
      DarbLocalCache.instance.writeJson(_favoritesCacheKey, updated.toList()),
    );
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
    return label?.isNotEmpty == true
        ? label
        : (details.isNotEmpty ? details : null);
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
      _vendorsError = null;
    });
    try {
      final cityRes = await Api.instance.getWithCache('/cities', 'active_cities');
      final cities = (cityRes.data as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      final hasSelected = _selectedCityId != null &&
          cities.any((c) => c['id']?.toString() == _selectedCityId);
      final chosenId = hasSelected
          ? _selectedCityId
          : (cities.isNotEmpty ? cities.first['id']?.toString() : null);

      List<Map<String, dynamic>> vendors = const [];
      List<Map<String, dynamic>> orders = const [];
      List<Map<String, dynamic>> addresses = const [];
      String? vendorsError;
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
          }).catchError((Object err) {
            vendorsError = err is ApiException
                ? err.message
                : dt('حدث خطأ غير متوقع، حاول مجدداً');
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
        _vendorsError = vendorsError;
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
      _loadingVendors = true;
      _vendorsError = null;
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
        _vendorsError = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _vendorsError = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _vendorsError = dt('حدث خطأ غير متوقع، حاول مجدداً'));
      }
    } finally {
      if (mounted) setState(() => _loadingVendors = false);
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
    final list = _vendors.where((v) {
      final id = v['id']?.toString() ?? '';
      if (_favoritesOnly && !_favoriteVendorIds.contains(id)) return false;
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
    if (_favoriteVendorIds.isNotEmpty) {
      list.sort((a, b) {
        final aFav = _favoriteVendorIds.contains(a['id']?.toString() ?? '');
        final bFav = _favoriteVendorIds.contains(b['id']?.toString() ?? '');
        if (aFav == bFav) return 0;
        return aFav ? -1 : 1;
      });
    }
    return list;
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
      final res =
          await Api.instance.getWithCache('/addresses', 'customer_addresses');
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
    if (!_loading && _cities.isEmpty) {
      return RefreshIndicator(
        onRefresh: _bootstrap,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: DarbStateView.empty(
                message: dt('لا توجد بيانات متاحة حالياً'),
                icon: Icons.location_city_outlined,
                onRetry: _bootstrap,
              ),
            ),
          ),
        ),
      );
    }

    final types = _vendorTypes;
    final filtered = _filteredVendors;
    final featuredOrder = _featuredOrder;
    final rawName = widget.user?['name']?.toString().trim();
    final greetingName = (rawName != null && rawName.isNotEmpty)
        ? rawName.split(' ').first
        : null;
    final isDark = DarbColors.isDark(context);

    return RefreshIndicator(
      onRefresh: _bootstrap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final hInset = maxW > 1080 ? (maxW - 1080) / 2 + 16 : 16.0;

          return ListView(
            padding: EdgeInsets.fromLTRB(hInset, 10, hInset, 108),
            children: [
              if (_offline)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DarbFeedbackBanner(
                    kind: DarbFeedbackKind.warning,
                    message: dt('بيانات مخزنة محلياً لضعف الاتصال'),
                  ),
                ),

              // 1. Spatial Command Stage + Interactive City Orb Switcher
              DarbCommandStage(
                livePulse: true,
                eyebrow: dt('شبكة التوصيل المباشر'),
                title: greetingName != null
                    ? '${dt('أهلاً بك')}، $greetingName'
                    : dt('مرحباً بك في دازريفو'),
                subtitle: dt('جاهز لتوصيل طلبك أو غرضك بأسرع مسار'),
                trailing: DarbPressScale(
                  borderRadius: DarbRadius.pill,
                  onTap: _openAddresses,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(DarbRadius.pill),
                      border: Border.all(
                        color: DarbColors.lime.withValues(alpha: 0.36),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bookmarks_outlined,
                          size: 15,
                          color: DarbColors.lime,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dt('العناوين'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: _cities.isNotEmpty
                    ? DarbCityOrbStrip(
                        onDarkStage: true,
                        cities: [
                          for (final c in _cities)
                            DarbCityOrbOption(
                              id: c['id'].toString(),
                              name: _cityDisplayName(c),
                              code: c['code']?.toString() ?? '',
                            ),
                        ],
                        selectedCityId: _selectedCityId,
                        onSelect: _switchCity,
                      )
                    : null,
              ),

              // 2. Deterministic City Architectural Banner (no bitmap assets)
              if (_cities.isNotEmpty) ...[
                const SizedBox(height: 12),
                DarbCitySceneCard(
                  cityCode: _selectedCityCode,
                  cityName: _selectedCityName,
                  vendorCount: _vendors.length,
                  activeAddressLabel: _primaryAddressLabel,
                  onTapAddresses: _openAddresses,
                ),
              ],
              const SizedBox(height: 14),

              // 3. Asymmetric Bento Service Split (Peer Delivery + AI Order Assistant)
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
                          accentColor: DarbColors.violetOf(context),
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

              const SizedBox(height: 12),
              DarbFadeSlide(
                child: DarbBentoActionCard(
                  icon: Icons.shopping_cart_checkout_rounded,
                  accentColor: DarbColors.primaryOf(context),
                  badge: dt('خدمة جديدة'),
                  title: dt('اطلب أي شيء'),
                  subtitle: dt('نشتريه من أي متجر ونوصله إلى بابك بعد موافقتك على السعر'),
                  onTap: () {
                    if (_selectedCityId == null) return;
                    DarbHaptics.light();
                    Navigator.push(context, DarbPageRoute(builder: (_) => ShoppingRequestScreen(
                      cityId: _selectedCityId!, cityName: _selectedCityName, onCreated: widget.onOrderCreated,
                    )));
                  },
                ),
              ),
              // 4. Featured Order Dispatch Ticket
              if (featuredOrder != null) ...[
                const SizedBox(height: 20),
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

              // 5. Store Discovery Editorial Grid
              const SizedBox(height: 22),
              DarbSectionHeader(
                title: dt('المتاجر المتاحة'),
                subtitle: dt('تصفح المتاجر والمنتجات واطلب إلى بابك'),
                trailing: DarbPressScale(
                  borderRadius: DarbRadius.pill,
                  onTap: () {
                    DarbHaptics.selection();
                    setState(() => _openOnly = !_openOnly);
                  },
                  child: AnimatedContainer(
                    duration: DarbMotion.effectiveDuration(
                      context,
                      DarbMotion.interactive,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _openOnly
                          ? (isDark ? DarbColors.lime : DarbColors.forest)
                          : DarbColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(DarbRadius.pill),
                      border: Border.all(
                        color: _openOnly
                            ? Colors.transparent
                            : DarbColors.borderOf(context),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DarbPulseDot(
                          active: _openOnly,
                          size: 6,
                          color: _openOnly
                              ? (isDark
                                  ? DarbColors.forest
                                  : DarbColors.lime)
                              : DarbColors.mutedOf(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dt('المفتوحة فقط'),
                          style: TextStyle(
                            color: _openOnly
                                ? (isDark
                                    ? DarbColors.darkCanvas
                                    : Colors.white)
                                : DarbColors.inkOf(context),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DarbSearchBar(
                controller: _searchController,
                hintText: dt('ابحث عن متجر أو نشاط...'),
                onChanged: (_) => setState(() {}),
              ),
              if (_vendors.isNotEmpty &&
                  (_favoriteVendorIds.isNotEmpty || _favoritesOnly)) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    DarbPressScale(
                      borderRadius: DarbRadius.pill,
                      onTap: () {
                        DarbHaptics.selection();
                        setState(() => _favoritesOnly = !_favoritesOnly);
                      },
                      child: AnimatedContainer(
                        duration: DarbMotion.effectiveDuration(
                          context,
                          DarbMotion.interactive,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _favoritesOnly
                              ? (isDark ? DarbColors.lime : DarbColors.forest)
                              : DarbColors.surfaceOf(context),
                          borderRadius: BorderRadius.circular(DarbRadius.pill),
                          border: Border.all(
                            color: _favoritesOnly
                                ? Colors.transparent
                                : DarbColors.borderOf(context),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _favoritesOnly
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              size: 14,
                              color: _favoritesOnly
                                  ? (isDark
                                      ? DarbColors.darkCanvas
                                      : DarbColors.lime)
                                  : DarbColors.primaryOf(context),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${dt('المفضلة')} (${_vendors.where((v) => _favoriteVendorIds.contains(v['id']?.toString() ?? '')).length})',
                              style: TextStyle(
                                color: _favoritesOnly
                                    ? (isDark
                                        ? DarbColors.darkCanvas
                                        : Colors.white)
                                    : DarbColors.inkOf(context),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (types.isNotEmpty) ...[
                const SizedBox(height: 10),
                DarbSegmentedDock<String>(
                  compact: true,
                  selectedValue: _selectedType,
                  onSelected: (val) => setState(() => _selectedType = val),
                  options: [
                    DarbDockOption(
                      value: '',
                      label: dt('الكل'),
                      count: _vendors.length,
                    ),
                    for (final t in types)
                      DarbDockOption(
                        value: t,
                        label: t,
                        count: _vendors
                            .where((v) => v['type']?.toString() == t)
                            .length,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              if (_loading || _loadingVendors)
                const DarbStateView.loading()
              else if (_vendorsError != null)
                DarbStateView.error(
                  message: _vendorsError,
                  onRetry: _selectedCityId != null
                      ? () => _switchCity(_selectedCityId!)
                      : _bootstrap,
                )
              else if (filtered.isEmpty)
                DarbStateView.empty(
                  message: _vendors.isEmpty
                      ? dt('لا توجد متاجر متاحة في هذه المدينة')
                      : dt('لم نعثر على نتائج مطابقة'),
                  icon: _vendors.isEmpty
                      ? Icons.storefront_outlined
                      : Icons.search_off_rounded,
                  onRetry: _vendors.isEmpty
                      ? (_selectedCityId != null
                          ? () => _switchCity(_selectedCityId!)
                          : _bootstrap)
                      : () {
                          _searchController.clear();
                          setState(() {
                            _selectedType = '';
                            _openOnly = false;
                            _favoritesOnly = false;
                          });
                        },
                )
              else
                DarbResponsiveTwoColumn(
                  children: [
                    for (var i = 0; i < filtered.length; i++)
                      i < 6
                          ? DarbFadeSlide(
                              delay: DarbMotion.staggerDelay(i),
                              child: _buildVendorCard(filtered[i]),
                            )
                          : _buildVendorCard(filtered[i]),
                  ],
                ),
            ],
          );
        },
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

    return DarbTicketPass(
      onTap: widget.onOpenOrders,
      leadingIcon: isPeer
          ? Icons.local_shipping_outlined
          : Icons.shopping_bag_outlined,
      title: '${isPeer ? dt('توصيل مستقل') : dt('طلب')} · $number',
      subtitle: (order['address'] is Map)
          ? (order['address'] as Map)['details']?.toString()
          : null,
      status: status,
      body: DarbOrderTimeline(
        status: status,
        isPeer: isPeer,
      ),
      footer: Row(
        children: [
          Expanded(
            child: Text(
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
    );
  }

  Widget _buildVendorCard(Map<String, dynamic> v) {
    final vendorId = v['id']?.toString() ?? '';
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

    return DarbEditorialStoreCard(
      name: name,
      category: type,
      isOpen: isOpen,
      address: address,
      productsLabel: dt('$count منتج متاح'),
      ratingAvg: ratingAvg,
      reviewsCount: reviewsCount,
      isFavorite: vendorId.isNotEmpty && _favoriteVendorIds.contains(vendorId),
      onToggleFavorite:
          vendorId.isNotEmpty ? () => _toggleFavorite(vendorId) : null,
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
    );
  }
}
