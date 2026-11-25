import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/services/app_update_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/notifications_service.dart';
import '../../core/storage/local_cache.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_motion_components.dart';
import '../account/account_screen.dart';
import '../account/ai_role_assistant_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/admin_operations_screens.dart';
import '../auth/login_screen.dart';
import '../customer/customer_home_screen.dart';
import '../customer/customer_orders_screen.dart';
import '../customer/driver_tracking_screen.dart';
import '../driver/driver_dashboard_screen.dart';
import '../driver/driver_orders_screen.dart';
import '../notifications/notifications_screen.dart';
import '../vendor/vendor_orders_screen.dart';
import '../vendor/vendor_products_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.checkForUpdates = true});

  final bool checkForUpdates;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _profileCacheKey = 'auth_me_profile';

  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _offline = false;
  String? _error;
  int _tabIndex = 0;
  int _unreadNotifications = 0;

  StreamSubscription<RemoteMessage>? _fgSub;
  StreamSubscription<RemoteMessage>? _openSub;
  Timer? _bannerTimer;
  ({String title, String body, Map<String, dynamic> data})? _bannerNotification;
  Map<String, dynamic>? _pendingNotificationData;
  bool _handlingNotification = false;
  bool _redirectingToLogin = false;

  @override
  void initState() {
    super.initState();
    Api.instance.sessionExpiredNotifier.addListener(_onSessionExpired);
    _loadUser();
    _setupNotifications();
    if (!kDarbPlayStoreBuild && widget.checkForUpdates) {
      DarbUpdater.instance.checkForUpdate();
    }
  }

  @override
  void dispose() {
    Api.instance.sessionExpiredNotifier.removeListener(_onSessionExpired);
    _bannerTimer?.cancel();
    _fgSub?.cancel();
    _openSub?.cancel();
    super.dispose();
  }

  Future<void> _onSessionExpired() async {
    if (!mounted || _redirectingToLogin) return;
    await _redirectToLogin();
  }

  Future<void> _redirectToLogin() async {
    if (_redirectingToLogin) return;
    _redirectingToLogin = true;
    DriverLocationReporter.stop();
    await Api.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      DarbPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _setupNotifications() {
    _fgSub = DarbNotifications.listenForeground((title, body, data) {
      if (!mounted) return;
      _refreshUnreadCount();
      if (!DarbAppearanceController.instance.inAppBannersEnabled) return;
      final resolvedTitle =
          (title != null && title.trim().isNotEmpty) ? title.trim() : dt('إشعار جديد');
      final resolvedBody = body?.trim() ?? '';
      _bannerTimer?.cancel();
      setState(() {
        _bannerNotification = (
          title: resolvedTitle,
          body: resolvedBody,
          data: Map<String, dynamic>.from(data),
        );
      });
      _bannerTimer = Timer(const Duration(seconds: 6), () {
        if (mounted) _dismissBanner();
      });
    });

    _openSub = DarbNotifications.listenOpened((data) {
      if (mounted) {
        unawaited(_handleNotificationOpen(data));
      }
    });

    unawaited(
      DarbNotifications.initialMessageData().then((data) {
        if (data != null && mounted) {
          return _handleNotificationOpen(data);
        }
      }),
    );
  }

  void _dismissBanner() {
    _bannerTimer?.cancel();
    _bannerTimer = null;
    if (mounted && _bannerNotification != null) {
      setState(() => _bannerNotification = null);
    }
  }

  Future<void> _handleNotificationOpen(Map<String, dynamic> data) async {
    _dismissBanner();
    if (_user == null) {
      _pendingNotificationData = Map<String, dynamic>.from(data);
      return;
    }
    if (_handlingNotification) return;

    final orderId = data['orderId']?.toString().trim();
    unawaited(_refreshUnreadCount());

    if (data['type']?.toString() == 'APP_UPDATE') {
      if (!kDarbPlayStoreBuild) {
        await DarbUpdater.instance.checkForUpdate(force: true);
        final update = DarbUpdater.instance.availableUpdate.value;
        if (mounted && update != null) {
          await showDialog<void>(
            context: context,
            builder: (_) => DarbUpdateDialog(info: update),
          );
          return;
        }
      }
      await _openNotifications();
      return;
    }

    if (orderId == null || orderId.isEmpty) {
      await _openNotifications();
      return;
    }

    _handlingNotification = true;
    try {
      final role = _user?['role']?.toString().toUpperCase() ?? 'CUSTOMER';
      Map<String, dynamic>? matchedOrder;
      var targetTab = _tabIndex;

      if (role == 'CUSTOMER') {
        targetTab = 1;
        final list = (await Api.instance.get('/orders/mine') as List? ?? [])
            .whereType<Map<String, dynamic>>();
        for (final item in list) {
          if (item['id']?.toString() == orderId) {
            matchedOrder = item;
            break;
          }
        }
      } else if (role == 'VENDOR') {
        targetTab = 0;
        final list = (await Api.instance.get('/orders/vendor') as List? ?? [])
            .whereType<Map<String, dynamic>>();
        for (final item in list) {
          if (item['id']?.toString() == orderId) {
            matchedOrder = item;
            break;
          }
        }
      } else if (role == 'ADMIN') {
        targetTab = 1;
        final res = await Api.instance.get('/admin/orders?limit=50');
        final rawList =
            res is Map ? (res['items'] as List? ?? []) : (res as List? ?? []);
        for (final item in rawList.whereType<Map<String, dynamic>>()) {
          if (item['id']?.toString() == orderId) {
            matchedOrder = item;
            break;
          }
        }
      } else if (role == 'DRIVER') {
        try {
          final avail = (await Api.instance.get('/orders/driver/available')
                  as List? ??
              [])
              .whereType<Map<String, dynamic>>();
          for (final item in avail) {
            if (item['id']?.toString() == orderId) {
              matchedOrder = item;
              targetTab = 0;
              break;
            }
          }
        } catch (_) {}

        if (matchedOrder == null) {
          final mine = (await Api.instance.get('/orders/driver/mine') as List? ??
                  [])
              .whereType<Map<String, dynamic>>();
          for (final item in mine) {
            if (item['id']?.toString() == orderId) {
              matchedOrder = item;
              targetTab = 1;
              break;
            }
          }
        }
      }

      if (!mounted) return;
      if (targetTab != _tabIndex) {
        setState(() => _tabIndex = targetTab);
      }

      if (matchedOrder != null) {
        await _showOrderQuickSheet(matchedOrder, role);
      } else {
        await _openNotifications();
      }
    } catch (_) {
      if (mounted) {
        await _openNotifications();
      }
    } finally {
      _handlingNotification = false;
    }
  }

  Future<void> _showOrderQuickSheet(
    Map<String, dynamic> order,
    String role,
  ) async {
    final orderId = order['id']?.toString() ?? '';
    final status = order['status']?.toString() ?? 'PENDING';
    final total = num.tryParse(order['total']?.toString() ?? '0') ?? 0;
    final currency = order['currency']?.toString() ?? 'SYP';
    final addr = order['address'] is Map ? order['address'] as Map : null;
    final addrDetails = addr?['details']?.toString();
    final pickupAddress = order['pickupAddress']?.toString();
    final notes = order['notes']?.toString();
    final pickupLat = (order['pickupLatitude'] as num?)?.toDouble();
    final pickupLng = (order['pickupLongitude'] as num?)?.toDouble();
    final dropoffLat = (addr?['latitude'] as num?)?.toDouble();
    final dropoffLng = (addr?['longitude'] as num?)?.toDouble();
    final canTrack = role == 'CUSTOMER' &&
        (status == 'ASSIGNED' || status == 'PICKED_UP') &&
        orderId.isNotEmpty;

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
          if ((pickupAddress != null && pickupAddress.trim().isNotEmpty) ||
              (addrDetails != null && addrDetails.trim().isNotEmpty)) ...[
            DarbRouteConnector(
              pickupLabel: dt('الاستلام'),
              pickupAddress: (pickupAddress != null &&
                      pickupAddress.trim().isNotEmpty)
                  ? pickupAddress.trim()
                  : dt('المتجر'),
              dropoffLabel: dt('عنوان التوصيل'),
              dropoffAddress:
                  (addrDetails != null && addrDetails.trim().isNotEmpty)
                      ? addrDetails.trim()
                      : dt('غير محدد'),
            ),
            const SizedBox(height: 8),
          ],
          if (notes != null && notes.trim().isNotEmpty) ...[
            Text(
              notes.trim(),
              style: TextStyle(color: DarbColors.inkOf(ctx), fontSize: 13),
            ),
            const SizedBox(height: 6),
          ],
          if (total > 0) ...[
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dt('الإجمالي عند الاستلام'),
                  style: TextStyle(
                    color: DarbColors.inkOf(ctx),
                    fontWeight: FontWeight.w900,
                  ),
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
          ],
          const SizedBox(height: 16),
          if (canTrack) ...[
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  DarbPageRoute(
                    builder: (_) => DriverTrackingScreen(
                      orderId: orderId,
                      pickupLatitude: pickupLat,
                      pickupLongitude: pickupLng,
                      dropoffLatitude: dropoffLat,
                      dropoffLongitude: dropoffLng,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.map_outlined),
              label: Text(dt('تتبع المندوب')),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(dt('إغلاق')),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final res = await Api.instance.get('/notifications');
      if (res is Map<String, dynamic> && mounted) {
        setState(() {
          _unreadNotifications = (res['unreadCount'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUser() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await Api.instance.get('/auth/me');
      if (data is! Map<String, dynamic>) {
        throw const ApiException('بيانات الجلسة غير صالحة');
      }
      try {
        await DarbLocalCache.instance.writeJson(_profileCacheKey, data);
      } catch (_) {}
      final localeCode = data['locale']?.toString();
      if (localeCode != null && ['ar', 'en', 'tr'].contains(localeCode)) {
        darbLocale.value = Locale(localeCode);
      }
      // Push registration is best-effort: an unavailable Firebase plugin or
      // denied notification permission must never prevent account access.
      try {
        await DarbNotifications.register();
      } catch (_) {}
      if (data['role']?.toString().toUpperCase() == 'DRIVER') {
        DriverLocationReporter.start();
      } else {
        DriverLocationReporter.stop();
      }
      await _refreshUnreadCount();
      if (!mounted) return;
      setState(() {
        _user = data;
        _offline = false;
        _error = null;
      });
      final pending = _pendingNotificationData;
      if (pending != null) {
        _pendingNotificationData = null;
        unawaited(_handleNotificationOpen(pending));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401 ||
          e.statusCode == 403 ||
          Api.instance.sessionInvalidated) {
        await _redirectToLogin();
        return;
      }
      if (e.isNetworkError &&
          e.statusCode == null &&
          !Api.instance.sessionInvalidated) {
        dynamic cached;
        try {
          cached = await DarbLocalCache.instance.readJson(_profileCacheKey);
        } catch (_) {}
        if (cached is Map && mounted) {
          final profile = Map<String, dynamic>.from(cached);
          final localeCode = profile['locale']?.toString();
          if (localeCode != null && ['ar', 'en', 'tr'].contains(localeCode)) {
            darbLocale.value = Locale(localeCode);
          }
          if (profile['role']?.toString().toUpperCase() == 'DRIVER') {
            DriverLocationReporter.start();
          } else {
            DriverLocationReporter.stop();
          }
          setState(() {
            _user = profile;
            _offline = true;
            _error = null;
          });
          final pending = _pendingNotificationData;
          if (pending != null) {
            _pendingNotificationData = null;
            unawaited(_handleNotificationOpen(pending));
          }
          return;
        }
      }
      setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = dt('تعذر تحميل حسابك'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOutFromError() async {
    DriverLocationReporter.stop();
    await DarbNotifications.unregister();
    await Api.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      DarbPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _openNotifications() async {
    DarbHaptics.light();
    await Navigator.push(
      context,
      DarbPageRoute(builder: (_) => const NotificationsScreen()),
    );
    await _refreshUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _user == null) {
      return Scaffold(
        body: DarbAmbientBackground(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DarbBrandMark(size: 64),
                const SizedBox(height: 18),
                CircularProgressIndicator(color: DarbColors.primaryOf(context)),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null && _user == null) {
      return Scaffold(
        body: DarbAmbientBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: DarbGlassSurface(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 42,
                      color: DarbColors.dangerOf(context),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      dt('تعذر تحميل حسابك'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: DarbColors.inkOf(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: DarbColors.mutedOf(context)),
                    ),
                    const SizedBox(height: 18),
                    DarbActionButton(
                      label: dt('إعادة المحاولة'),
                      icon: Icons.refresh_rounded,
                      state: _loading
                          ? DarbActionState.loading
                          : DarbActionState.idle,
                      onPressed: _loadUser,
                    ),
                    const SizedBox(height: 10),
                    DarbActionButton(
                      label: dt('تسجيل الخروج'),
                      icon: Icons.logout_rounded,
                      variant: DarbActionVariant.outlined,
                      onPressed: _signOutFromError,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final user = _user ?? const <String, dynamic>{'role': 'CUSTOMER'};
    final role = user['role']?.toString().toUpperCase() ?? 'CUSTOMER';

    final destinations = switch (role) {
      'ADMIN' => [
          DarbNavDestination(
            label: dt('لوحة المؤشرات'),
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
          ),
          DarbNavDestination(
            label: dt('طلبات المتاجر'),
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long_rounded,
          ),
          DarbNavDestination(
            label: dt('المستخدمون والمدن'),
            icon: Icons.tune_outlined,
            selectedIcon: Icons.tune_rounded,
          ),
          DarbNavDestination(
            label: dt('حسابي'),
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
          ),
        ],
      'VENDOR' => [
          DarbNavDestination(
            label: dt('طلبات المتجر'),
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long_rounded,
          ),
          DarbNavDestination(
            label: dt('المنتجات'),
            icon: Icons.inventory_2_outlined,
            selectedIcon: Icons.inventory_2_rounded,
          ),
          DarbNavDestination(
            label: dt('حسابي'),
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
          ),
        ],
      'DRIVER' => [
          DarbNavDestination(
            label: dt('الطلبات المتاحة'),
            icon: Icons.local_shipping_outlined,
            selectedIcon: Icons.local_shipping_rounded,
          ),
          DarbNavDestination(
            label: dt('توصيلاتي'),
            icon: Icons.route_outlined,
            selectedIcon: Icons.route_rounded,
          ),
          DarbNavDestination(
            label: dt('حسابي'),
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
          ),
        ],
      _ => [
          DarbNavDestination(
            label: dt('الرئيسية'),
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore_rounded,
          ),
          DarbNavDestination(
            label: dt('طلباتي'),
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long_rounded,
          ),
          DarbNavDestination(
            label: dt('حسابي'),
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
          ),
        ],
    };

    final safeIndex = _tabIndex.clamp(0, destinations.length - 1);

    final pages = switch (role) {
      'ADMIN' => [
          const AdminDashboardScreen(),
          const AdminOrdersScreen(),
          const AdminOperationsScreen(),
          AccountScreen(user: user, onRefreshUser: _loadUser),
        ],
      'VENDOR' => [
          const VendorOrdersScreen(),
          const VendorProductsScreen(),
          AccountScreen(user: user, onRefreshUser: _loadUser),
        ],
      'DRIVER' => [
          DriverDashboardScreen(
            onClaimedOrAccepted: () {
              if (mounted) setState(() => _tabIndex = 1);
            },
          ),
          const DriverOrdersScreen(),
          AccountScreen(user: user, onRefreshUser: _loadUser),
        ],
      _ => [
          CustomerHomeScreen(
            user: user,
            onOrderCreated: () {
              if (mounted) setState(() => _tabIndex = 1);
            },
            onOpenOrders: () {
              if (mounted) setState(() => _tabIndex = 1);
            },
          ),
          const CustomerOrdersScreen(),
          AccountScreen(user: user, onRefreshUser: _loadUser),
        ],
    };

    final roleSubtitle = switch (role) {
      'ADMIN' => dt('إدارة دازريفو'),
      'VENDOR' => dt('حساب تاجر'),
      'DRIVER' => dt('حساب سائق'),
      _ => dt('حساب عميل'),
    };

    final banner = _bannerNotification;

    return Scaffold(
      extendBody: true,
      appBar: DarbGlassAppBar(
        leading: const Padding(
          padding: EdgeInsetsDirectional.only(start: 6),
          child: DarbBrandMark(size: 36),
        ),
        title: destinations[safeIndex].label,
        subtitle: roleSubtitle,
        actions: [
          if (!kDarbPlayStoreBuild)
            ValueListenableBuilder<DarbUpdateInfo?>(
              valueListenable: DarbUpdater.instance.availableUpdate,
              builder: (context, update, _) {
                if (update == null) return const SizedBox.shrink();
                return _ShellActionWell(
                  tooltip: dt('تحديث التطبيق'),
                  onTap: () {
                    DarbHaptics.light();
                    showDialog<void>(
                      context: context,
                      builder: (_) => DarbUpdateDialog(info: update),
                    );
                  },
                  child: Icon(
                    Icons.system_update_rounded,
                    size: 19,
                    color: DarbColors.primaryOf(context),
                  ),
                );
              },
            ),
          _ShellActionWell(
            tooltip: dt('الإشعارات'),
            onTap: _openNotifications,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 20,
                  color: DarbColors.inkOf(context),
                ),
                if (_unreadNotifications > 0)
                  PositionedDirectional(
                    top: -6,
                    end: -6,
                    child: DarbAnimatedBadge(
                      count: _unreadNotifications,
                      fontSize: 9.5,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _ShellActionWell(
            tooltip: dt('المساعد الذكي'),
            highlighted: true,
            violetAccent: true,
            onTap: () {
              DarbHaptics.light();
              Navigator.push(
                context,
                DarbPageRoute(builder: (_) => const AiRoleAssistantScreen()),
              );
            },
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 19,
              color: DarbColors.violetOf(context),
            ),
          ),
        ],
      ),
      body: DarbAmbientBackground(
        child: Stack(
          children: [
            Column(
              children: [
                if (_offline)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: DarbGlassSurface(
                      tintColor: DarbColors.warningSoftOf(context),
                      borderColor:
                          DarbColors.warningOf(context).withValues(alpha: 0.32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            size: 16,
                            color: DarbColors.warningOf(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dt('وضع عدم الاتصال — يتم عرض البيانات المحفوظة مؤقتاً'),
                              style: TextStyle(
                                color: DarbColors.warningOf(context),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 28),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _loadUser,
                            child: Text(dt('تحديث')),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: DarbTabViewStack(
                    index: safeIndex,
                    children: pages,
                  ),
                ),
              ],
            ),
            if (banner != null)
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: DarbPressScale(
                    onTap: () => _handleNotificationOpen(banner.data),
                    child: DarbGlassSurface(
                      borderRadius: DarbRadius.lg,
                      blurSigma: 22,
                      borderColor:
                          DarbColors.primaryOf(context).withValues(alpha: 0.35),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: DarbColors.primaryOf(context)
                                  .withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              Icons.notifications_active_rounded,
                              size: 19,
                              color: DarbColors.primaryOf(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  banner.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: DarbColors.inkOf(context),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (banner.body.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    banner.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: DarbColors.mutedOf(context),
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: dt('إغلاق'),
                            onPressed: _dismissBanner,
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: DarbColors.mutedOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: DarbGlassBottomNav(
        destinations: destinations,
        selectedIndex: safeIndex,
        onSelect: (index) {
          setState(() => _tabIndex = index);
          _refreshUnreadCount();
        },
      ),
    );
  }
}

class _ShellActionWell extends StatelessWidget {
  const _ShellActionWell({
    required this.tooltip,
    required this.onTap,
    required this.child,
    this.highlighted = false,
    this.violetAccent = false,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;
  final bool highlighted;
  final bool violetAccent;

  @override
  Widget build(BuildContext context) {
    final accent =
        violetAccent ? DarbColors.violetOf(context) : DarbColors.primaryOf(context);
    final isDark = DarbColors.isDark(context);

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: highlighted
                    ? accent.withValues(alpha: isDark ? 0.22 : 0.12)
                    : DarbColors.softSurfaceOf(context).withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: highlighted
                      ? accent.withValues(alpha: 0.34)
                      : DarbColors.borderOf(context),
                ),
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
