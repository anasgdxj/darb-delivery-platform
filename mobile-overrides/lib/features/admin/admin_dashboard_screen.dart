import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _stats = const {};
  List<Map<String, dynamic>> _pendingVendors = const [];
  List<Map<String, dynamic>> _pendingDrivers = const [];
  int _ordersTotal = 0;
  int _zonesCount = 0;
  int _citiesCount = 0;
  bool _loading = true;
  String? _error;

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
      final results = await Future.wait([
        Api.instance.get('/admin/vendors/pending'),
        Api.instance.get('/admin/drivers/pending'),
      ]);

      int ordersTotal = _ordersTotal;
      int zonesCount = _zonesCount;
      int citiesCount = _citiesCount;
      Map<String, dynamic> stats = const {};

      try {
        final ordersRes = await Api.instance.get('/admin/orders?limit=1');
        if (ordersRes is Map) {
          ordersTotal = (ordersRes['total'] as num?)?.toInt() ??
              ((ordersRes['items'] as List?)?.length ?? 0);
        } else if (ordersRes is List) {
          ordersTotal = ordersRes.length;
        }
      } catch (_) {}

      try {
        final zones = await Api.instance.get('/admin/delivery-zones');
        if (zones is List) zonesCount = zones.length;
      } catch (_) {}

      try {
        final cities = await Api.instance.get('/cities');
        if (cities is List) citiesCount = cities.length;
      } catch (_) {}

      try {
        final s = await Api.instance.get('/admin/stats');
        if (s is Map<String, dynamic>) stats = s;
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _pendingVendors =
            (results[0] as List? ?? []).whereType<Map<String, dynamic>>().toList();
        _pendingDrivers =
            (results[1] as List? ?? []).whereType<Map<String, dynamic>>().toList();
        _ordersTotal = ordersTotal;
        _zonesCount = zonesCount;
        _citiesCount = citiesCount;
        _stats = stats;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setVendorStatus(String id, String status) async {
    try {
      await Api.instance.patch('/admin/vendors/$id/status', {'status': status});
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _setDriverStatus(String id, String status) async {
    try {
      await Api.instance.patch('/admin/drivers/$id/status', {'status': status});
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const DarbStateView.loading();
    if (_error != null) return DarbStateView.error(message: _error, onRetry: _load);

    final totalOrders = _stats['ordersTotal'] ?? _ordersTotal;
    final pendingTotal = _pendingVendors.length + _pendingDrivers.length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 108),
        children: [
          DarbSectionHeader(
            title: dt('لوحة المؤشرات'),
            trailing: IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              DarbMetricCard(
                label: dt('إجمالي الطلبات'),
                value: '$totalOrders',
                icon: Icons.receipt_long_rounded,
              ),
              DarbMetricCard(
                label: dt('قيد الانتظار'),
                value: '$pendingTotal',
                icon: Icons.pending_actions_rounded,
              ),
              DarbMetricCard(
                label: dt('رسوم التوصيل'),
                value: '$_zonesCount',
                icon: Icons.payments_outlined,
              ),
              DarbMetricCard(
                label: dt('المدن المدعومة'),
                value: '$_citiesCount',
                icon: Icons.location_city_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          DarbSectionHeader(
            title: '${dt('طلبات انضمام المتاجر')} (${_pendingVendors.length})',
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
            for (final v in _pendingVendors)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildPendingVendorCard(v),
              ),
          const SizedBox(height: 18),
          DarbSectionHeader(
            title: '${dt('طلبات انضمام السائقين')} (${_pendingDrivers.length})',
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
            for (final d in _pendingDrivers)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildPendingDriverCard(d),
              ),
        ],
      ),
    );
  }

  Widget _buildPendingVendorCard(Map<String, dynamic> v) {
    final tr = (v['translations'] as List? ?? []);
    final name = tr.isNotEmpty
        ? tr.first['name']?.toString() ?? dt('متجر جديد')
        : dt('متجر جديد');
    return DarbGlassSurface(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$name · ${v['type'] ?? ''}',
                  style: TextStyle(
                    color: DarbColors.inkOf(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const DarbStatusBadge(status: 'PENDING'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${v['user']?['name'] ?? ''} · ${v['user']?['phone'] ?? v['user']?['email'] ?? ''}',
            style: TextStyle(color: DarbColors.mutedOf(context), fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      _setVendorStatus(v['id'].toString(), 'APPROVED'),
                  child: Text(dt('اعتماد')),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: DarbColors.dangerOf(context),
                ),
                onPressed: () =>
                    _setVendorStatus(v['id'].toString(), 'REJECTED'),
                child: Text(dt('رفض')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingDriverCard(Map<String, dynamic> d) {
    return DarbGlassSurface(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  d['user']?['name']?.toString() ?? dt('سائق جديد'),
                  style: TextStyle(
                    color: DarbColors.inkOf(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const DarbStatusBadge(status: 'PENDING'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${d['vehicleType'] ?? 'MOTORCYCLE'} · ${d['city']?['code'] ?? ''} · ${d['user']?['phone'] ?? d['user']?['email'] ?? ''}',
            style: TextStyle(color: DarbColors.mutedOf(context), fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      _setDriverStatus(d['id'].toString(), 'APPROVED'),
                  child: Text(dt('اعتماد')),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: DarbColors.dangerOf(context),
                ),
                onPressed: () =>
                    _setDriverStatus(d['id'].toString(), 'SUSPENDED'),
                child: Text(dt('تعليق')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
