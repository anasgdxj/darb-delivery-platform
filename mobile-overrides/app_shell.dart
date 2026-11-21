import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import '../design_system.dart';
import '../main.dart';
import '../localizations.dart';
import '../notifications.dart';
import 'login_screen.dart';
import '../app_update.dart';

part 'admin_screens.dart';
part 'customer_screens.dart';
part 'peer_delivery_screen.dart';
part 'vendor_screens.dart';
part 'driver_screens.dart';
part 'account_screens.dart';
part 'account_pages.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;
  bool loading = true;
  String role = 'CUSTOMER';
  String? error;
  Map<String, dynamic>? me;

  @override
  void initState() {
    super.initState();
    _load();
    DarbNotifications.register();
  }

  Future<void> _load() async {
    if (mounted) setState(() => loading = true);
    try {
      final data = await Api.instance.get('/auth/me');
      me = Map<String, dynamic>.from(data);
      role = me?['role']?.toString() ?? 'CUSTOMER';
      if (role == 'DRIVER') {
        DriverLocationReporter.start();
      } else {
        DriverLocationReporter.stop();
      }
      final savedLocale = me?['locale']?.toString();
      if (savedLocale == 'ar' || savedLocale == 'en' || savedLocale == 'tr') {
        darbLocale.value = Locale(savedLocale!);
      }
      error = null;
    } catch (e) {
      if (Api.instance.sessionInvalidated) {
        await _logout();
        return;
      }
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _logout() async {
    DriverLocationReporter.stop();
    await DarbNotifications.unregister();
    await Api.instance.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  void dispose() {
    DriverLocationReporter.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 42, color: DarbColors.muted),
                SizedBox(height: 14),
                Text(dt('تعذر تحميل حسابك'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text(error!, textAlign: TextAlign.center, style: TextStyle(color: DarbColors.muted)),
                SizedBox(height: 18),
                FilledButton(onPressed: loading ? null : _load, child: Text(dt('إعادة المحاولة'))),
                SizedBox(height: 10),
                Text(dt('حسابك محفوظ. لن يتم تسجيل خروجك بسبب تعذر الاتصال.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: DarbColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isAdmin = role == 'ADMIN';
    final isCustomer = role == 'CUSTOMER';
    final isVendor = role == 'VENDOR';
    final titles = isAdmin
        ? [dt('طلبات المتاجر'), dt('طلبات السائقين'), dt('رسوم التوصيل'), dt('حسابي')]
        : isCustomer
            ? [dt('الرئيسية'), dt('طلباتي'), dt('حسابي')]
            : isVendor
                ? [dt('طلبات المتجر'), dt('المنتجات'), dt('حسابي')]
                : [dt('الطلبات المتاحة'), dt('توصيلاتي'), dt('حسابي')];
    final pages = isAdmin
        ? [AdminQueue(kind: 'vendors'), AdminQueue(kind: 'drivers'), AdminDeliveryZones(), AccountPage(me: me, onLogout: _logout)]
        : isCustomer
            ? [CustomerHome(), CustomerOrders(), AccountPage(me: me, onLogout: _logout)]
            : isVendor
                ? [VendorOrders(), VendorProducts(), AccountPage(me: me, onLogout: _logout)]
                : [DriverAvailable(), DriverOrders(), AccountPage(me: me, onLogout: _logout)];
    final icons = isAdmin
        ? [Icons.storefront_outlined, Icons.delivery_dining_rounded, Icons.payments_outlined, Icons.person_outline_rounded]
        : isCustomer
            ? [Icons.explore_outlined, Icons.receipt_long_outlined, Icons.person_outline_rounded]
            : isVendor
                ? [Icons.receipt_long_outlined, Icons.inventory_2_outlined, Icons.person_outline_rounded]
                : [Icons.radar_rounded, Icons.route_outlined, Icons.person_outline_rounded];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: DarbColors.forest,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 18,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [DarbColors.lime, DarbColors.mint],
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(dt('د'), style: TextStyle(color: DarbColors.forest, fontWeight: FontWeight.w900, fontSize: 23)),
            ),
            SizedBox(width: 11),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(dt('دَرْب'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, height: 1.1)),
                Text(titles[tab], style: TextStyle(color: Colors.white.withValues(alpha: .72), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: Theme.of(context).brightness == Brightness.dark
                ? dt('التبديل إلى الوضع النهاري')
                : dt('التبديل إلى الوضع الليلي'),
            onPressed: () {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              DarbTheme.setMode(isDark ? ThemeMode.light : ThemeMode.dark);
            },
            icon: AnimatedSwitcher(
              duration: DarbMotion.expressive,
              switchInCurve: DarbMotion.expressiveCurve,
              switchOutCurve: DarbMotion.exit,
              transitionBuilder: (child, animation) => RotationTransition(
                turns: Tween<double>(begin: .72, end: 1).animate(animation),
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                key: ValueKey(Theme.of(context).brightness),
                color: DarbColors.lime,
                size: 25,
              ),
            ),
          ),
          ValueListenableBuilder<DarbUpdateInfo?>(
            valueListenable: DarbUpdater.instance.availableUpdate,
            builder: (context, update, _) => IconButton(
              tooltip: dt('تحديث التطبيق'),
              onPressed: () async {
                if (update == null) {
                  await DarbUpdater.instance.checkForUpdate(force: true);
                }
                final latest = DarbUpdater.instance.availableUpdate.value;
                if (!mounted) return;
                if (latest != null) {
                  showDialog<void>(
                    context: context,
                    builder: (_) => DarbUpdateDialog(info: latest),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(
                      DarbUpdater.instance.checkFailed
                          ? dt('تعذر التحقق من التحديث')
                          : dt('تطبيقك محدّث إلى آخر إصدار'),
                    )),
                  );
                }
              },
              icon: Icon(
                update == null ? Icons.system_update_alt_rounded : Icons.system_update_rounded,
                color: update == null ? Colors.white : DarbColors.lime,
              ),
            ),
          ),
          IconButton(
            tooltip: dt('تحديث'),
            onPressed: () { setState(() => loading = true); _load(); },
            icon: Icon(Icons.refresh_rounded, color: Colors.white),
          ),
          SizedBox(width: 6),
        ],
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: Offset(0, .025), end: Offset.zero).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(tab), child: pages[tab]),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: DarbColors.surface,
        indicatorColor: DarbColors.mint.withValues(alpha: .62),
        elevation: 8,
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: [
          for (var i = 0; i < titles.length; i++)
            NavigationDestination(icon: Icon(icons[i]), selectedIcon: Icon(icons[i]), label: titles[i]),
        ],
      ),
    );
  }
}
