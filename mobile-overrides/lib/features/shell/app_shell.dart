import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/services/app_update_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/notifications_service.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
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
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  String? _error;
  int _tabIndex = 0;
  int _unreadNotifications = 0;
  StreamSubscription? _foregroundNotificationSubscription;
  StreamSubscription? _openedNotificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadUser();
    DarbUpdater.instance.checkForUpdate();
    _foregroundNotificationSubscription =
        DarbNotifications.listenForeground((title, body, data) {
      if (!mounted) return;
      unawaited(_refreshUnreadCount());
      final message = [title, body]
          .where((part) => part != null && part.trim().isNotEmpty)
          .join('\n');
      if (message.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: dt('عرض'),
            onPressed: () => unawaited(_openNotifications()),
          ),
        ),
      );
    });
    _openedNotificationSubscription = DarbNotifications.listenOpened((data) {
      if (mounted) unawaited(_handleNotificationOpen(data));
    });
    DarbNotifications.initialMessageData().then((data) {
      if (data != null && mounted) unawaited(_handleNotificationOpen(data));
    });
  }

  @override
  void dispose() {
    unawaited(_foregroundNotificationSubscription?.cancel() ?? Future<void>.value());
    unawaited(_openedNotificationSubscription?.cancel() ?? Future<void>.value());
    super.dispose();
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
      final localeCode = data['locale']?.toString();
      if (localeCode != null && ['ar', 'en', 'tr'].contains(localeCode)) {
        darbLocale.value = Locale(localeCode);
      }
      await DarbNotifications.register();
      if (data['role']?.toString().toUpperCase() == 'DRIVER') {
        DriverLocationReporter.start();
      } else {
        DriverLocationReporter.stop();
      }
      await _refreshUnreadCount();
      if (!mounted) return;
      setState(() {
        _user = data;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401 || Api.instance.sessionInvalidated) {
        await Api.instance.clear();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
        return;
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
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    await _refreshUnreadCount();
  }

  Future<void> _handleNotificationOpen(Map<String, dynamic> data) async {
    final orderId = (data['orderId'] ?? data['order_id'] ?? '').toString().trim();
    final role = _user?['role']?.toString().toUpperCase() ?? 'CUSTOMER';

    if (orderId.isNotEmpty && role == 'CUSTOMER') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverTrackingScreen(orderId: orderId),
        ),
      );
      await _refreshUnreadCount();
      return;
    }

    if (role == 'DRIVER' && mounted) {
      setState(() => _tabIndex = 1);
      return;
    }

    await _openNotifications();
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
                    FilledButton.icon(
                      onPressed: _loadUser,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(dt('إعادة المحاولة')),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _signOutFromError,
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(dt('تسجيل الخروج')),
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
            onOrderCreated: () {
              if (mounted) setState(() => _tabIndex = 1);
            },
          ),
          const CustomerOrdersScreen(),
          AccountScreen(user: user, onRefreshUser: _loadUser),
        ],
    };

    final roleSubtitle = switch (role) {
      'ADMIN' => dt('إدارة دَرْب'),
      'VENDOR' => dt('حساب تاجر'),
      'DRIVER' => dt('حساب سائق'),
      _ => dt('حساب عميل'),
    };

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
          ValueListenableBuilder<DarbUpdateInfo?>(
            valueListenable: DarbUpdater.instance.availableUpdate,
            builder: (context, update, _) {
              if (update == null) return const SizedBox.shrink();
              return IconButton(
                tooltip: dt('تحديث التطبيق'),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => DarbUpdateDialog(info: update),
                ),
                icon: Icon(
                  Icons.system_update_rounded,
                  color: DarbColors.primaryOf(context),
                ),
              );
            },
          ),
          IconButton(
            tooltip: dt('الإشعارات'),
            onPressed: _openNotifications,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: DarbColors.inkOf(context),
                ),
                if (_unreadNotifications > 0)
                  PositionedDirectional(
                    top: -3,
                    end: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: DarbColors.dangerOf(context),
                        borderRadius: BorderRadius.circular(DarbRadius.pill),
                      ),
                      child: Text(
                        _unreadNotifications > 99
                            ? '99+'
                            : '$_unreadNotifications',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: dt('المساعد الذكي'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiRoleAssistantScreen()),
            ),
            icon: Icon(
              Icons.auto_awesome_rounded,
              color: DarbColors.primaryOf(context),
            ),
          ),
        ],
      ),
      body: DarbAmbientBackground(
        child: IndexedStack(
          index: safeIndex,
          children: pages,
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
