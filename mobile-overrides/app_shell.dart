import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
      return Scaffold(
        backgroundColor: DarbColors.canvas,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DazrevoLogoMark(size: 62),
              const SizedBox(height: 18),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: DarbColors.accent,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (error != null) {
      return Scaffold(
        backgroundColor: DarbColors.canvas,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DazrevoIconWell(
                    icon: Icons.cloud_off_rounded,
                    size: 64,
                    radius: 20,
                    iconColor: DarbColors.accent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    dt('تعذر تحميل حسابك'),
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: DarbColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: DarbColors.muted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: loading ? null : _load,
                      child: Text(dt('إعادة المحاولة')),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    dt('حسابك محفوظ. لن يتم تسجيل خروجك بسبب تعذر الاتصال.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: DarbColors.muted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final isAdmin = role == 'ADMIN';
    final isCustomer = role == 'CUSTOMER';
    final isVendor = role == 'VENDOR';
    final titles = isAdmin
        ? [
            dt('طلبات المتاجر'),
            dt('طلبات السائقين'),
            dt('رسوم التوصيل'),
            dt('حسابي'),
          ]
        : isCustomer
            ? [dt('الرئيسية'), dt('طلباتي'), dt('حسابي')]
            : isVendor
                ? [dt('طلبات المتجر'), dt('المنتجات'), dt('حسابي')]
                : [dt('الطلبات المتاحة'), dt('توصيلاتي'), dt('حسابي')];
    final pages = isAdmin
        ? [
            const AdminQueue(kind: 'vendors'),
            const AdminQueue(kind: 'drivers'),
            const AdminDeliveryZones(),
            AccountPage(me: me, onLogout: _logout),
          ]
        : isCustomer
            ? [
                const CustomerHome(),
                const CustomerOrders(),
                AccountPage(me: me, onLogout: _logout),
              ]
            : isVendor
                ? [
                    const VendorOrders(),
                    const VendorProducts(),
                    AccountPage(me: me, onLogout: _logout),
                  ]
                : [
                    const DriverAvailable(),
                    const DriverOrders(),
                    AccountPage(me: me, onLogout: _logout),
                  ];
    final icons = isAdmin
        ? [
            Icons.storefront_rounded,
            Icons.delivery_dining_rounded,
            Icons.payments_rounded,
            Icons.person_rounded,
          ]
        : isCustomer
            ? [
                Icons.explore_rounded,
                Icons.receipt_long_rounded,
                Icons.person_rounded,
              ]
            : isVendor
                ? [
                    Icons.receipt_long_rounded,
                    Icons.inventory_2_rounded,
                    Icons.person_rounded,
                  ]
                : [
                    Icons.radar_rounded,
                    Icons.route_rounded,
                    Icons.person_rounded,
                  ];

    final isWide = MediaQuery.sizeOf(context).width >= 840;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mainBody = AnimatedSwitcher(
      duration: DarbMotion.effectiveDuration(context, DarbMotion.standard),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, .02),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(tab), child: pages[tab]),
    );

    return Scaffold(
      backgroundColor: DarbColors.canvas,
      appBar: AppBar(
        backgroundColor: DarbColors.canvas,
        foregroundColor: DarbColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 18,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: DarbColors.line),
        ),
        title: Row(
          children: [
            const DazrevoLogoMark(size: 38),
            const SizedBox(width: 11),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DazrevoWordmark(
                  color: DarbColors.ink,
                  fontSize: 16,
                  letterSpacing: 1.8,
                ),
                Text(
                  titles[tab],
                  style: TextStyle(
                    color: DarbColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDark
                ? dt('التبديل إلى الوضع النهاري')
                : dt('التبديل إلى الوضع الليلي'),
            onPressed: () => DarbTheme.setMode(
              isDark ? ThemeMode.light : ThemeMode.dark,
            ),
            icon: AnimatedSwitcher(
              duration: DarbMotion.expressive,
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                key: ValueKey(isDark),
                color: DarbColors.accent,
                size: 22,
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
                    SnackBar(
                      content: Text(
                        DarbUpdater.instance.checkFailed
                            ? dt('تعذر التحقق من التحديث')
                            : dt('تطبيقك محدّث إلى آخر إصدار'),
                      ),
                    ),
                  );
                }
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    update == null
                        ? Icons.system_update_alt_rounded
                        : Icons.system_update_rounded,
                    color: update == null
                        ? DarbColors.muted
                        : DarbColors.accent,
                    size: 21,
                  ),
                  if (update != null)
                    PositionedDirectional(
                      top: -2,
                      end: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: DarbColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: dt('تحديث'),
            onPressed: () {
              setState(() => loading = true);
              _load();
            },
            icon: Icon(Icons.refresh_rounded, color: DarbColors.ink, size: 21),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: tab,
                  onDestinationSelected: (value) => setState(() => tab = value),
                  backgroundColor: DarbColors.surface,
                  labelType: NavigationRailLabelType.all,
                  indicatorColor: DarbColors.accent.withValues(alpha: .16),
                  selectedIconTheme: IconThemeData(color: DarbColors.accent),
                  selectedLabelTextStyle: TextStyle(
                    color: DarbColors.brandForeground,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    color: DarbColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  destinations: [
                    for (var i = 0; i < titles.length; i++)
                      NavigationRailDestination(
                        icon: Icon(icons[i]),
                        label: Text(titles[i]),
                      ),
                  ],
                ),
                VerticalDivider(width: 1, color: DarbColors.line),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: mainBody,
                    ),
                  ),
                ),
              ],
            )
          : mainBody,
      bottomNavigationBar: isWide
          ? null
          : DazrevoFloatingDock(
              labels: titles,
              icons: icons,
              selectedIndex: tab,
              onSelected: (value) => setState(() => tab = value),
            ),
    );
  }
}
