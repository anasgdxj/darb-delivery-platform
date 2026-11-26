import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_motion_components.dart';
import '../../core/widgets/darb_spatial_primitives.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _stats = const {};
  List<Map<String, dynamic>> _pendingVendors = const [];
  List<Map<String, dynamic>> _pendingDrivers = const [];
  List<Map<String, dynamic>> _allVendors = const [];
  List<Map<String, dynamic>> _allDrivers = const [];
  int _directoryMode = 0; // 0: Pending queues, 1: All stores, 2: All drivers
  bool _loading = true;
  String? _error;
  String? _partialError;
  final Set<String> _busyIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _partialError = null;
    });
    try {
      final results = await Future.wait([
        Api.instance.get('/admin/vendors/pending'),
        Api.instance.get('/admin/drivers/pending'),
      ]);

      Map<String, dynamic> stats = const {};
      List<Map<String, dynamic>> allVendors = const [];
      List<Map<String, dynamic>> allDrivers = const [];
      var hasPartialFailure = false;

      try {
        final s = await Api.instance.get('/admin/stats');
        if (s is Map<String, dynamic>) stats = s;
      } catch (_) {
        hasPartialFailure = true;
      }

      try {
        final v = await Api.instance.get('/admin/vendors');
        if (v is List) {
          allVendors = v.whereType<Map<String, dynamic>>().toList();
        }
      } catch (_) {
        hasPartialFailure = true;
      }

      try {
        final d = await Api.instance.get('/admin/drivers');
        if (d is List) {
          allDrivers = d.whereType<Map<String, dynamic>>().toList();
        }
      } catch (_) {
        hasPartialFailure = true;
      }

      if (!mounted) return;
      setState(() {
        _pendingVendors = (results[0] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        _pendingDrivers = (results[1] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        _allVendors = allVendors;
        _allDrivers = allDrivers;
        _stats = stats;
        _partialError = hasPartialFailure
            ? dt('تعذر تحميل بعض البيانات الثانوية. أعد المحاولة لتحديثها.')
            : null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = dt('حدث خطأ غير متوقع، حاول مجدداً'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setVendorStatus(String id, String status) async {
    final key = 'v_$id';
    if (!_busyIds.add(key)) return;
    if (mounted) setState(() {});
    try {
      await Api.instance.patch('/admin/vendors/$id/status', {'status': status});
      if (mounted) DarbHaptics.success();
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
      _busyIds.remove(key);
      if (mounted) setState(() {});
    }
  }

  Future<void> _setDriverStatus(String id, String status) async {
    final key = 'd_$id';
    if (!_busyIds.add(key)) return;
    if (mounted) setState(() {});
    try {
      await Api.instance.patch('/admin/drivers/$id/status', {'status': status});
      if (mounted) DarbHaptics.success();
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
      _busyIds.remove(key);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const DarbStateView.loading();
    if (_error != null) return DarbStateView.error(message: _error, onRetry: _load);

    final totalOrders = _stats['ordersTotal'] ?? 0;
    final activeOrders = _stats['ordersActive'] ?? 0;
    final driversOnline = _stats['driversOnline'] ?? 0;
    final gmv =
        num.tryParse(_stats['deliveredGrossTotal']?.toString() ?? '0') ?? 0;
    final pendingTotal = _pendingVendors.length + _pendingDrivers.length;

    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final hInset = maxW > 1120 ? (maxW - 1120) / 2 + 16 : 16.0;

          return ListView(
            padding: EdgeInsets.fromLTRB(hInset, 12, hInset, 108),
            children: [
              DarbCommandStage(
                livePulse: (driversOnline is num && driversOnline > 0),
                eyebrow: dt('إدارة دازريفو'),
                title: dt('لوحة المؤشرات'),
                subtitle: '${dt('قيد الانتظار')}: $pendingTotal',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DarbContextMenuButton<String>(
                      tooltip: dt('خيارات'),
                      iconColor: DarbColors.lime,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      onSelected: (action) {
                        switch (action) {
                          case 'refresh':
                            _load();
                          case 'pending':
                            setState(() => _directoryMode = 0);
                          case 'vendors':
                            setState(() => _directoryMode = 1);
                          case 'drivers':
                            setState(() => _directoryMode = 2);
                        }
                      },
                      items: [
                        DarbContextMenuAction(
                          value: 'refresh',
                          label: dt('تحديث'),
                          icon: Icons.refresh_rounded,
                        ),
                        DarbContextMenuAction(
                          value: 'pending',
                          label: dt('قيد الانتظار'),
                          icon: Icons.pending_actions_rounded,
                        ),
                        DarbContextMenuAction(
                          value: 'vendors',
                          label: dt('سجل المتاجر'),
                          icon: Icons.storefront_rounded,
                        ),
                        DarbContextMenuAction(
                          value: 'drivers',
                          label: dt('سجل السائقين'),
                          icon: Icons.delivery_dining_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                    ),
                  ],
                ),
              ),
              if (_partialError != null) ...[
                const SizedBox(height: 10),
                DarbFeedbackBanner(
                  kind: DarbFeedbackKind.warning,
                  message: _partialError!,
                  actionLabel: dt('إعادة المحاولة'),
                  onAction: _load,
                ),
              ],
              const SizedBox(height: 12),
              DarbTelemetryDeck(
                cells: [
                  DarbTelemetryCell(
                    label: dt('إجمالي الطلبات'),
                    value: '$totalOrders',
                    icon: Icons.receipt_long_rounded,
                    accentColor: DarbColors.primaryOf(context),
                  ),
                  DarbTelemetryCell(
                    label: dt('قيد التنفيذ'),
                    value: '$activeOrders',
                    icon: Icons.local_shipping_outlined,
                    accentColor: DarbColors.infoOf(context),
                  ),
                  DarbTelemetryCell(
                    label: dt('سائقون متصلون'),
                    value: '$driversOnline',
                    icon: Icons.sensors_rounded,
                    accentColor: DarbColors.successOf(context),
                  ),
                  DarbTelemetryCell(
                    label: dt('إجمالي المبيعات'),
                    value: formatDarbMoney(gmv),
                    icon: Icons.account_balance_wallet_outlined,
                    accentColor: DarbColors.warningOf(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DarbSegmentedDock<int>(
                selectedValue: _directoryMode,
                onSelected: (val) => setState(() => _directoryMode = val),
                options: [
                  DarbDockOption(
                    value: 0,
                    label: dt('قيد الانتظار'),
                    count: pendingTotal,
                    icon: Icons.pending_actions_rounded,
                  ),
                  DarbDockOption(
                    value: 1,
                    label: dt('سجل المتاجر'),
                    count: _allVendors.length,
                    icon: Icons.storefront_outlined,
                  ),
                  DarbDockOption(
                    value: 2,
                    label: dt('سجل السائقين'),
                    count: _allDrivers.length,
                    icon: Icons.delivery_dining_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_directoryMode == 0) ...[
                DarbSectionHeader(
                  title: '${dt('طلبات المتاجر')} (${_pendingVendors.length})',
                ),
                const SizedBox(height: 10),
                if (_pendingVendors.isEmpty)
                  DarbGlassSurface(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      dt('لا توجد طلبات معلّقة حالياً'),
                      style: TextStyle(color: DarbColors.mutedOf(context)),
                    ),
                  )
                else
                  DarbResponsiveTwoColumn(
                    spacing: 10,
                    children: [
                      for (final v in _pendingVendors) _buildVendorCard(v),
                    ],
                  ),
                const SizedBox(height: 18),
                DarbSectionHeader(
                  title: '${dt('طلبات السائقين')} (${_pendingDrivers.length})',
                ),
                const SizedBox(height: 10),
                if (_pendingDrivers.isEmpty)
                  DarbGlassSurface(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      dt('لا توجد طلبات معلّقة حالياً'),
                      style: TextStyle(color: DarbColors.mutedOf(context)),
                    ),
                  )
                else
                  DarbResponsiveTwoColumn(
                    spacing: 10,
                    children: [
                      for (final d in _pendingDrivers) _buildDriverCard(d),
                    ],
                  ),
              ] else if (_directoryMode == 1) ...[
                if (_allVendors.isEmpty)
                  DarbStateView.empty(
                    message: dt('لا توجد بيانات متاحة حالياً'),
                    icon: Icons.storefront_outlined,
                    onRetry: _load,
                  )
                else
                  DarbResponsiveTwoColumn(
                    spacing: 10,
                    children: [
                      for (final v in _allVendors) _buildVendorCard(v),
                    ],
                  ),
              ] else ...[
                if (_allDrivers.isEmpty)
                  DarbStateView.empty(
                    message: dt('لا توجد بيانات متاحة حالياً'),
                    icon: Icons.delivery_dining_outlined,
                    onRetry: _load,
                  )
                else
                  DarbResponsiveTwoColumn(
                    spacing: 10,
                    children: [
                      for (final d in _allDrivers) _buildDriverCard(d),
                    ],
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildVendorCard(Map<String, dynamic> v) {
    final tr = (v['translations'] as List? ?? []);
    final name = tr.isNotEmpty
        ? tr.first['name']?.toString() ?? dt('متجر')
        : dt('متجر');
    final status = v['status']?.toString() ?? 'PENDING';
    final id = v['id'].toString();
    final isBusy = _busyIds.contains('v_$id');
    final accent = status == 'APPROVED'
        ? DarbColors.successOf(context)
        : (status == 'PENDING'
            ? DarbColors.warningOf(context)
            : DarbColors.primaryOf(context));

    return DarbTicketPass(
      leadingIcon: Icons.storefront_rounded,
      accentColor: accent,
      title: '$name · ${v['type'] ?? ''}',
      subtitle:
          '${v['user']?['name'] ?? ''} · ${v['user']?['phone'] ?? v['user']?['email'] ?? ''}',
      status: status,
      body: const SizedBox.shrink(),
      footer: Row(
        children: [
          if (status != 'APPROVED')
            Expanded(
              child: FilledButton(
                onPressed:
                    isBusy ? null : () => _setVendorStatus(id, 'APPROVED'),
                child: isBusy
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(dt('اعتماد')),
              ),
            ),
          if (status != 'APPROVED' && status != 'SUSPENDED')
            const SizedBox(width: 8),
          if (status != 'SUSPENDED')
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: DarbColors.dangerOf(context),
              ),
              onPressed: isBusy
                  ? null
                  : () => _setVendorStatus(
                        id,
                        status == 'PENDING' ? 'REJECTED' : 'SUSPENDED',
                      ),
              child: Text(status == 'PENDING' ? dt('رفض') : dt('تعليق')),
            ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> d) {
    final status = d['status']?.toString() ?? 'PENDING';
    final id = d['id'].toString();
    final isBusy = _busyIds.contains('d_$id');
    final vehicle = d['vehicleType']?.toString() ?? 'MOTORCYCLE';
    final vehicleIcon = switch (vehicle) {
      'CAR' => Icons.directions_car_rounded,
      'BICYCLE' => Icons.pedal_bike_rounded,
      _ => Icons.two_wheeler_rounded,
    };
    final accent = status == 'APPROVED'
        ? DarbColors.successOf(context)
        : (status == 'PENDING'
            ? DarbColors.warningOf(context)
            : DarbColors.infoOf(context));

    return DarbTicketPass(
      leadingIcon: vehicleIcon,
      accentColor: accent,
      title: d['user']?['name']?.toString() ?? dt('سائق جديد'),
      subtitle:
          '$vehicle · ${d['city']?['code'] ?? ''} · ${d['user']?['phone'] ?? d['user']?['email'] ?? ''}',
      status: status,
      body: const SizedBox.shrink(),
      footer: Row(
        children: [
          if (status != 'APPROVED')
            Expanded(
              child: FilledButton(
                onPressed:
                    isBusy ? null : () => _setDriverStatus(id, 'APPROVED'),
                child: isBusy
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(dt('اعتماد')),
              ),
            ),
          if (status != 'APPROVED' && status != 'SUSPENDED')
            const SizedBox(width: 8),
          if (status != 'SUSPENDED')
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: DarbColors.dangerOf(context),
              ),
              onPressed: isBusy
                  ? null
                  : () => _setDriverStatus(id, 'SUSPENDED'),
              child: Text(dt('تعليق')),
            ),
        ],
      ),
    );
  }
}
