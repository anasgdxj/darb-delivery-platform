import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';

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
  bool _loading = true;
  bool _togglingOnline = false;
  bool _sendingLocation = false;
  String? _error;
  final Set<String> _busyOrderIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final driver =
          await Api.instance.get('/drivers/me') as Map<String, dynamic>;
      Map<String, dynamic>? stats;
      List<Map<String, dynamic>> available = const [];

      try {
        stats = await Api.instance.get('/drivers/stats') as Map<String, dynamic>;
      } catch (_) {}

      if (driver['status'] == 'APPROVED' && driver['isOnline'] == true) {
        try {
          available =
              (await Api.instance.get('/orders/driver/available') as List? ??
                      [])
                  .whereType<Map<String, dynamic>>()
                  .toList();
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _driver = driver;
        _stats = stats;
        _available = available;
      });
      DriverLocationReporter.start();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
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
    }
  }

  Future<void> _claimOrder(String id) async {
    if (!_busyOrderIds.add(id)) return;
    if (mounted) setState(() {});
    try {
      await Api.instance.post('/orders/$id/claim', {});
      if (mounted) HapticFeedback.selectionClick();
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
    } finally {
      _busyOrderIds.remove(id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _dismissOrder(String id) async {
    try {
      await Api.instance.post('/orders/$id/dismiss', {});
      if (mounted) {
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
    }
  }

  Future<void> _withdrawOffer(String orderId) async {
    try {
      await Api.instance.post('/orders/$orderId/offers/withdraw', {});
      if (mounted) {
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
    try {
      await Api.instance
          .post('/orders/${order['id']}/offers', {'amount': amount});
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(dt('تم إرسال عرضك للعميل'))));
      }
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
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
    final isApproved = driver['status'] == 'APPROVED';
    final isOnline = driver['isOnline'] == true;
    final stats = _stats ?? {};
    final statsCurrency = stats['currency']?.toString() ?? 'SYP';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 104),
        children: [
          DarbGlassSurface(
            padding: const EdgeInsets.all(18),
            tintColor: isOnline ? DarbColors.forest : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isApproved
                                ? (isOnline
                                    ? dt('متصل لاستلام الطلبات')
                                    : dt('غير متصل'))
                                : dt('حساب السائق بانتظار اعتماد الإدارة'),
                            style: TextStyle(
                              color: isOnline
                                  ? Colors.white
                                  : DarbColors.inkOf(context),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isApproved
                                ? dt('فعّل الحالة لتظهر لك الطلبات الجاهزة')
                                : dt('قيد مراجعة الإدارة'),
                            style: TextStyle(
                              color: isOnline
                                  ? DarbColors.mint
                                  : DarbColors.mutedOf(context),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isOnline,
                      onChanged:
                          (!isApproved || _togglingOnline) ? null : _toggleOnline,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isOnline
                              ? Colors.white
                              : DarbColors.inkOf(context),
                          side: BorderSide(
                            color: isOnline
                                ? Colors.white.withValues(alpha: 0.3)
                                : DarbColors.borderOf(context),
                          ),
                        ),
                        onPressed: _pickVehicle,
                        icon: const Icon(Icons.two_wheeler_rounded, size: 18),
                        label: Text(
                          _vehicleLabel(driver['vehicleType']?.toString()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isOnline
                              ? DarbColors.mint
                              : DarbColors.primaryOf(context),
                          side: BorderSide(
                            color: isOnline
                                ? DarbColors.mint.withValues(alpha: 0.4)
                                : DarbColors.borderOf(context),
                          ),
                        ),
                        onPressed:
                            (!isApproved || _sendingLocation) ? null : _updateGpsNow,
                        icon: _sendingLocation
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location_rounded, size: 18),
                        label: Text(dt('موقع السائق')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              DarbMetricCard(
                label: dt('رحلات اليوم'),
                value: '${stats['todayTrips'] ?? 0}',
                icon: Icons.today_rounded,
              ),
              DarbMetricCard(
                label: dt('أرباح اليوم'),
                value: formatDarbMoney(
                  (stats['todayEarnings'] as num?) ?? 0,
                  statsCurrency,
                ),
                icon: Icons.trending_up_rounded,
              ),
              DarbMetricCard(
                label: dt('الرحلات المكتملة'),
                value: '${stats['completedTrips'] ?? 0}',
                icon: Icons.task_alt_rounded,
              ),
              DarbMetricCard(
                label: dt('الأرباح المحققة'),
                value: formatDarbMoney(
                  (stats['totalEarnings'] as num?) ?? 0,
                  statsCurrency,
                ),
                icon: Icons.account_balance_wallet_outlined,
              ),
            ],
          ),
          const SizedBox(height: 18),
          DarbSectionHeader(
            title: dt('طلبات جاهزة للاستلام'),
            trailing: IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          const SizedBox(height: 10),
          if (!isApproved)
            DarbStateView.empty(
              message: dt('حساب السائق بانتظار اعتماد الإدارة'),
              icon: Icons.hourglass_bottom_rounded,
            )
          else if (!isOnline)
            DarbStateView.empty(
              message: dt('فعّل الحالة لتظهر لك الطلبات الجاهزة'),
              icon: Icons.power_settings_new_rounded,
            )
          else if (_available.isEmpty)
            DarbStateView.empty(
              message: dt('لا توجد طلبات متاحة حالياً'),
              icon: Icons.delivery_dining_outlined,
            )
          else
            for (final order in _available)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAvailableCard(order),
              ),
        ],
      ),
    );
  }

  Widget _buildAvailableCard(Map<String, dynamic> order) {
    final id = order['id'].toString();
    final isPeer = order['type'] == 'PEER_DELIVERY';
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
    final offerCurrency =
        activeOffer?['currency']?.toString() ?? order['currency']?.toString() ?? 'SYP';
    final offerAmount =
        num.tryParse(activeOffer?['amount']?.toString() ?? '0') ?? 0;

    return DarbGlassSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isPeer
                      ? dt('طلب توصيل مستقل')
                      : (storeName ?? dt('متجر')),
                  style: TextStyle(
                    color: DarbColors.inkOf(context),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (distLabel != null)
                Text(
                  distLabel,
                  style: TextStyle(
                    color: DarbColors.primaryOf(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (isPeer && order['pickupAddress'] != null)
            Text(
              '${dt('الاستلام')}: ${order['pickupAddress']}',
              style: TextStyle(
                color: DarbColors.mutedOf(context),
                fontSize: 13,
              ),
            ),
          if (order['address']?['details'] != null)
            Text(
              '${dt('التسليم')}: ${order['address']['details']}',
              style: TextStyle(
                color: DarbColors.mutedOf(context),
                fontSize: 13,
              ),
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
              child: DarbGlassSurface(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                borderRadius: DarbRadius.sm,
                child: Text(
                  '${dt('عرضك الحالي')}: ${formatDarbMoney(offerAmount, offerCurrency)}',
                  style: TextStyle(
                    color: DarbColors.primaryOf(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: activeOffer != null
                    ? OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DarbColors.dangerOf(context),
                        ),
                        onPressed: () => _withdrawOffer(id),
                        child: Text(dt('سحب العرض')),
                      )
                    : FilledButton(
                        onPressed: _busyOrderIds.contains(id)
                            ? null
                            : () => isPeer
                                ? _submitOffer(order)
                                : _claimOrder(id),
                        child: _busyOrderIds.contains(id)
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                isPeer
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
                onPressed: () => _dismissOrder(id),
                child: Text(dt('استبعاد')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
