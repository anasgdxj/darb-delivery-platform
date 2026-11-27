import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_motion_components.dart';
import '../../core/widgets/darb_spatial_primitives.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key, this.onClaimedOrAccepted});
  final VoidCallback? onClaimedOrAccepted;

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  Map<String, dynamic>? _driver;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _available = const [];
  String _typeFilter = 'ALL';
  bool _loading = true;
  bool _togglingOnline = false;
  bool _sendingLocation = false;
  String? _error;
  String? _statsError;
  String? _availableError;
  final Set<String> _busyOrderIds = <String>{};

  List<Map<String, dynamic>> get _filteredAvailable {
    if (_typeFilter == 'ALL') return _available;
    return _available
        .where((o) => o['type']?.toString() == _typeFilter)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _statsError = null;
      _availableError = null;
    });
    try {
      final rawDriver = await Api.instance.get('/drivers/me');
      if (rawDriver is! Map<String, dynamic>) {
        throw const ApiException('تعذر تحميل بيانات السائق');
      }
      final driver = rawDriver;
      Map<String, dynamic>? stats;
      String? statsError;
      List<Map<String, dynamic>> available = const [];
      String? availableError;

      try {
        final rawStats = await Api.instance.get('/drivers/stats');
        if (rawStats is Map<String, dynamic>) stats = rawStats;
      } on ApiException catch (e) {
        statsError = e.message;
      } catch (_) {
        statsError =
            dt('تعذر تحميل بعض البيانات الثانوية. أعد المحاولة لتحديثها.');
      }

      if (driver['status'] == 'APPROVED' && driver['isOnline'] == true) {
        try {
          available =
              (await Api.instance.get('/orders/driver/available') as List? ??
                      [])
                  .whereType<Map<String, dynamic>>()
                  .toList();
        } on ApiException catch (e) {
          availableError = e.message;
        } catch (_) {
          availableError = dt('تعذر تحميل الطلبات المتاحة حالياً');
        }
      }

      if (!mounted) return;
      setState(() {
        _driver = driver;
        _stats = stats;
        _statsError = statsError;
        _available = available;
        _availableError = availableError;
      });
      DriverLocationReporter.start();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = dt('حدث خطأ غير متوقع، حاول مجدداً'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleOnline(bool val) async {
    setState(() => _togglingOnline = true);
    try {
      await Api.instance.patch('/drivers/online', {'isOnline': val});
      unawaited(DriverLocationReporter.refresh());
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
      if (mounted) setState(() => _togglingOnline = false);
    }
  }

  Future<void> _updateGpsNow() async {
    setState(() => _sendingLocation = true);
    try {
      final coords = await DarbLocationService.getCurrentPosition();
      await Api.instance.patch('/drivers/location', {
        'latitude': coords.latitude,
        'longitude': coords.longitude,
      });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dt('تم تحديد إحداثيات موقعك'))),
        );
      }
    } on DarbLocationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
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
      if (mounted) setState(() => _sendingLocation = false);
    }
  }

  Future<void> _pickVehicle() async {
    final current = _driver?['vehicleType']?.toString() ?? 'MOTORCYCLE';
    final selected = await showDarbGlassModalSheet<String>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            dt('تحديث المركبة'),
            style: TextStyle(
              color: DarbColors.inkOf(ctx),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in [
            ('BICYCLE', dt('دراجة هوائية'), Icons.pedal_bike_rounded),
            ('MOTORCYCLE', dt('دراجة نارية'), Icons.two_wheeler_rounded),
            ('CAR', dt('سيارة'), Icons.directions_car_rounded),
          ])
            ListTile(
              leading: Icon(entry.$3, color: DarbColors.primaryOf(ctx)),
              title: Text(
                entry.$2,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              trailing: current == entry.$1
                  ? Icon(
                      Icons.check_circle_rounded,
                      color: DarbColors.primaryOf(ctx),
                    )
                  : null,
              onTap: () => Navigator.pop(ctx, entry.$1),
            ),
        ],
      ),
    );
    if (selected == null || selected == current) return;
    try {
      await Api.instance.patch('/drivers/vehicle', {'vehicleType': selected});
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
    }
  }

  Future<void> _claimOrder(String id) async {
    if (!_busyOrderIds.add(id)) return;
    if (mounted) setState(() {});
    try {
      await Api.instance.post('/orders/$id/claim', {});
      if (mounted) DarbHaptics.success();
      await _load();
      widget.onClaimedOrAccepted?.call();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(dt('تم قبول الطلب'))));
      }
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
      _busyOrderIds.remove(id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _dismissOrder(String id) async {
    if (!_busyOrderIds.add(id)) return;
    if (mounted) setState(() {});
    try {
      await Api.instance.post('/orders/$id/dismiss', {});
      if (mounted) {
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dt('تم استبعاد الطلب'))),
        );
      }
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
      _busyOrderIds.remove(id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _withdrawOffer(String orderId) async {
    if (!_busyOrderIds.add(orderId)) return;
    if (mounted) setState(() {});
    try {
      await Api.instance.post('/orders/$orderId/offers/withdraw', {});
      if (mounted) {
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dt('تم سحب العرض'))),
        );
      }
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
      _busyOrderIds.remove(orderId);
      if (mounted) setState(() {});
    }
  }

  Future<void> _submitOffer(Map<String, dynamic> order) async {
    final controller = TextEditingController();
    final currency = order['currency']?.toString() ?? 'SYP';
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dt('تقديم أجرة التوصيل')),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(
            labelText: dt('أدخل المبلغ'),
            suffixText: currency,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(dt('إلغاء')),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              if (parsed != null && parsed > 0) Navigator.pop(ctx, parsed);
            },
            child: Text(dt('إرسال العرض')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null) return;
    final orderId = order['id'].toString();
    if (!_busyOrderIds.add(orderId)) return;
    if (mounted) setState(() {});
    try {
      await Api.instance.post('/orders/$orderId/offers', {'amount': amount});
      if (mounted) {
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(dt('تم إرسال عرضك للعميل'))));
      }
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
      _busyOrderIds.remove(orderId);
      if (mounted) setState(() {});
    }
  }

  String _vehicleLabel(String? code) => switch (code?.toUpperCase()) {
        'BICYCLE' => dt('دراجة هوائية'),
        'CAR' => dt('سيارة'),
        _ => dt('دراجة نارية'),
      };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const DarbStateView.loading();
    if (_error != null) return DarbStateView.error(message: _error, onRetry: _load);

    final driver = _driver ?? {};
    final driverStatus = driver['status']?.toString() ?? 'PENDING';
    final isApproved = driverStatus == 'APPROVED';
    final isPending = driverStatus == 'PENDING';
    final isOnline = driver['isOnline'] == true;
    final stats = _stats ?? {};
    final statsCurrency = stats['currency']?.toString() ?? 'SYP';

    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final hInset = maxW > 1080 ? (maxW - 1080) / 2 + 16 : 16.0;

          return ListView(
            padding: EdgeInsets.fromLTRB(hInset, 12, hInset, 104),
            children: [
              // 1. Courier Spatial Command Stage
              DarbCommandStage(
                livePulse: isApproved && isOnline,
                accentColor: isApproved
                    ? (isOnline ? DarbColors.lime : DarbColors.mint)
                    : DarbColors.warningOf(context),
                eyebrow: dt('حساب سائق'),
                title: isApproved
                    ? (isOnline
                        ? dt('متصل لاستلام الطلبات')
                        : dt('غير متصل'))
                    : (isPending
                        ? dt('حساب السائق بانتظار اعتماد الإدارة')
                        : dt('يتطلب طلب السائق مراجعة الإدارة')),
                subtitle: isApproved
                    ? dt('فعّل الحالة لتظهر لك الطلبات الجاهزة')
                    : (isPending ? dt('قيد مراجعة الإدارة') : driverStatus),
                trailing: Switch(
                  value: isOnline,
                  onChanged: (!isApproved || _togglingOnline)
                      ? null
                      : _toggleOnline,
                ),
                bottom: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.08),
                        ),
                        onPressed: _pickVehicle,
                        icon:
                            const Icon(Icons.two_wheeler_rounded, size: 18),
                        label: Text(
                          _vehicleLabel(driver['vehicleType']?.toString()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DarbColors.lime,
                          side: BorderSide(
                            color: DarbColors.lime.withValues(alpha: 0.42),
                          ),
                          backgroundColor:
                              DarbColors.lime.withValues(alpha: 0.12),
                        ),
                        onPressed: (!isApproved || _sendingLocation)
                            ? null
                            : _updateGpsNow,
                        icon: _sendingLocation
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: DarbColors.lime,
                                ),
                              )
                            : const Icon(Icons.my_location_rounded, size: 18),
                        label: Text(dt('موقع السائق')),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_statsError != null) ...[
                DarbFeedbackBanner(
                  kind: DarbFeedbackKind.warning,
                  message: _statsError!,
                  actionLabel: dt('إعادة المحاولة'),
                  onAction: _load,
                ),
                const SizedBox(height: 10),
              ],
              DarbTelemetryDeck(
                cells: [
                  DarbTelemetryCell(
                    label: dt('رحلات اليوم'),
                    value: '${stats['todayTrips'] ?? 0}',
                    icon: Icons.today_rounded,
                  ),
                  DarbTelemetryCell(
                    label: dt('أرباح اليوم'),
                    value: formatDarbMoney(
                      (stats['todayEarnings'] as num?) ?? 0,
                      statsCurrency,
                    ),
                    icon: Icons.trending_up_rounded,
                    accentColor: DarbColors.successOf(context),
                  ),
                  DarbTelemetryCell(
                    label: dt('الرحلات المكتملة'),
                    value: '${stats['completedTrips'] ?? 0}',
                    icon: Icons.task_alt_rounded,
                    accentColor: DarbColors.infoOf(context),
                  ),
                  DarbTelemetryCell(
                    label: dt('الأرباح المحققة'),
                    value: formatDarbMoney(
                      (stats['totalEarnings'] as num?) ?? 0,
                      statsCurrency,
                    ),
                    icon: Icons.account_balance_wallet_outlined,
                    accentColor: DarbColors.warningOf(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              DarbSectionHeader(
                title: dt('طلبات جاهزة للاستلام'),
                trailing: DarbContextMenuButton<String>(
                  tooltip: dt('خيارات'),
                  onSelected: (action) {
                    if (action == 'refresh') {
                      _load();
                    } else if (action == 'gps' &&
                        isApproved &&
                        !_sendingLocation) {
                      _updateGpsNow();
                    } else if (action == 'vehicle') {
                      _pickVehicle();
                    }
                  },
                  items: [
                    DarbContextMenuAction(
                      value: 'refresh',
                      label: dt('تحديث'),
                      icon: Icons.refresh_rounded,
                    ),
                    if (isApproved)
                      DarbContextMenuAction(
                        value: 'gps',
                        label: dt('موقع السائق'),
                        icon: Icons.my_location_rounded,
                      ),
                    DarbContextMenuAction(
                      value: 'vehicle',
                      label: dt('تحديث المركبة'),
                      icon: Icons.two_wheeler_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (!isApproved)
                DarbStateView.empty(
                  message: isPending
                      ? dt('حساب السائق بانتظار اعتماد الإدارة')
                      : dt('يتطلب طلب السائق مراجعة الإدارة'),
                  icon: Icons.hourglass_bottom_rounded,
                  onRetry: _load,
                )
              else if (!isOnline)
                DarbStateView.empty(
                  message: dt('فعّل الحالة لتظهر لك الطلبات الجاهزة'),
                  icon: Icons.power_settings_new_rounded,
                  onRetry: () => _toggleOnline(true),
                )
              else if (_availableError != null && _available.isEmpty)
                DarbStateView.error(
                  message: _availableError,
                  onRetry: _load,
                )
              else if (_available.isEmpty)
                DarbStateView.empty(
                  message: dt('لا توجد طلبات متاحة حالياً'),
                  icon: Icons.delivery_dining_outlined,
                  onRetry: _load,
                )
              else ...[
                DarbSegmentedDock<String>(
                  compact: true,
                  selectedValue: _typeFilter,
                  onSelected: (val) => setState(() => _typeFilter = val),
                  options: [
                    DarbDockOption(
                      value: 'ALL',
                      label: dt('الكل'),
                      count: _available.length,
                    ),
                    DarbDockOption(
                      value: 'VENDOR',
                      label: dt('طلب متجر'),
                      count: _available
                          .where((o) => o['type']?.toString() != 'PEER_DELIVERY')
                          .length,
                      icon: Icons.storefront_outlined,
                    ),
                    DarbDockOption(
                      value: 'PEER_DELIVERY',
                      label: dt('توصيل مستقل'),
                      count: _available
                          .where((o) => o['type']?.toString() == 'PEER_DELIVERY')
                          .length,
                      icon: Icons.local_shipping_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_filteredAvailable.isEmpty)
                  DarbStateView.empty(
                    message: dt('لا توجد طلبات مطابقة للتصفية الحالية'),
                    icon: Icons.filter_list_off_rounded,
                    onRetry: () => setState(() => _typeFilter = 'ALL'),
                  )
                else
                  DarbResponsiveTwoColumn(
                    children: [
                      for (var i = 0; i < _filteredAvailable.length; i++)
                        i < 6
                            ? DarbFadeSlide(
                                delay: DarbMotion.staggerDelay(i),
                                child: _buildAvailableCard(
                                  _filteredAvailable[i],
                                ),
                              )
                            : _buildAvailableCard(_filteredAvailable[i]),
                    ],
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvailableCard(Map<String, dynamic> order) {
    final id = order['id'].toString();
    final isPeer = order['type'] == 'PEER_DELIVERY';
    final isShopping = order['type'] == 'SHOPPING_DELIVERY';
    final dist = order['distanceKm'];
    final distLabel = dist is num ? '${dist.toStringAsFixed(1)} km' : null;
    final storeName = order['vendor']?['translations'] is List &&
            (order['vendor']['translations'] as List).isNotEmpty
        ? (order['vendor']['translations'] as List).first['name']?.toString()
        : null;
    final offers = (order['deliveryOffers'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .where((o) => o['status'] == 'PENDING')
        .toList();
    final activeOffer = offers.isNotEmpty ? offers.first : null;
    final offerCurrency = activeOffer?['currency']?.toString() ??
        order['currency']?.toString() ??
        'SYP';
    final offerAmount =
        num.tryParse(activeOffer?['amount']?.toString() ?? '0') ?? 0;

    final totalAmount = num.tryParse(order['total']?.toString() ?? '');
    final orderCurrency = order['currency']?.toString() ?? 'SYP';
    final isBusy = _busyOrderIds.contains(id);

    return DarbTicketPass(
      leadingIcon: (isPeer || isShopping) ? Icons.local_shipping_outlined : Icons.storefront_outlined,
      title: isShopping ? '${dt('شراء وتوصيل')}: ${order['shoppingItemName'] ?? dt('غرض')}' : (isPeer ? dt('طلب توصيل مستقل') : (storeName ?? dt('متجر'))),
      subtitle: (totalAmount != null && totalAmount > 0)
          ? formatDarbMoney(totalAmount, orderCurrency)
          : null,
      status: activeOffer != null ? 'PENDING' : 'READY',
      headerActions: [
        if (distLabel != null)
          Container(
            margin: const EdgeInsetsDirectional.only(end: 6),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: DarbColors.primaryOf(context).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(DarbRadius.pill),
            ),
            child: Text(
              distLabel,
              style: TextStyle(
                color: DarbColors.primaryOf(context),
                fontWeight: FontWeight.w900,
                fontSize: 11.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isShopping) ...[
            Text(order['shoppingDescription']?.toString() ?? '', style: TextStyle(color: DarbColors.inkOf(context), fontWeight: FontWeight.w700)),
            if ((order['shoppingStoreAddress'] ?? '').toString().isNotEmpty) Text(order['shoppingStoreAddress'].toString(), style: TextStyle(color: DarbColors.mutedOf(context), fontSize: 12)),
          ],
          DarbRouteConnector(
            pickupLabel: dt('الاستلام'),
            pickupAddress: isShopping ? ((order['shoppingStoreName'] ?? '').toString().isNotEmpty ? order['shoppingStoreName'].toString() : dt('متجر يحدده السائق')) : (isPeer
                ? (order['pickupAddress']?.toString() ?? dt('الاستلام'))
                : (storeName ?? dt('متجر'))),
            dropoffLabel: dt('التسليم'),
            dropoffAddress:
                order['address']?['details']?.toString() ?? dt('غير محدد'),
            badgeText: distLabel,
          ),
          if (order['notes'] != null &&
              order['notes'].toString().trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                order['notes'].toString(),
                style: TextStyle(
                  color: DarbColors.inkOf(context),
                  fontSize: 12.5,
                ),
              ),
            ),
          if (activeOffer != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: DarbFeedbackBanner(
                kind: DarbFeedbackKind.info,
                message:
                    '${dt('عرضك الحالي')}: ${formatDarbMoney(offerAmount, offerCurrency)}',
              ),
            ),
        ],
      ),
      footer: Row(
        children: [
          Expanded(
            child: activeOffer != null
                ? OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DarbColors.dangerOf(context),
                    ),
                    onPressed: isBusy ? null : () => _withdrawOffer(id),
                    child: isBusy
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(dt('سحب العرض')),
                  )
                : FilledButton(
                    onPressed: isBusy
                        ? null
                        : () =>
                            (isPeer || isShopping) ? _submitOffer(order) : _claimOrder(id),
                    child: isBusy
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            (isPeer || isShopping)
                                ? dt('تقديم أجرة التوصيل')
                                : dt('استلام الطلب'),
                          ),
                  ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: DarbColors.mutedOf(context),
            ),
            onPressed: isBusy ? null : () => _dismissOrder(id),
            child: Text(dt('استبعاد')),
          ),
        ],
      ),
    );
  }
}
