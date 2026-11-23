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
  List<Map<String, dynamic>> _allVendors = const [];
  List<Map<String, dynamic>> _allDrivers = const [];
  int _directoryMode = 0; // 0: Pending queues, 1: All stores, 2: All drivers
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

      Map<String, dynamic> stats = const {};
      List<Map<String, dynamic>> allVendors = const [];
      List<Map<String, dynamic>> allDrivers = const [];

      try {
        final s = await Api.instance.get('/admin/stats');
        if (s is Map<String, dynamic>) stats = s;
      } catch (_) {}

      try {
        final v = await Api.instance.get('/admin/vendors');
        if (v is List) {
          allVendors = v.whereType<Map<String, dynamic>>().toList();
        }
      } catch (_) {}

      try {
        final d = await Api.instance.get('/admin/drivers');
        if (d is List) {
          allDrivers = d.whereType<Map<String, dynamic>>().toList();
        }
      } catch (_) {}

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
    try {
      await Api.instance.patch('/admin/vendors/$id/status', {'status': status});
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

  Future<void> _setDriverStatus(String id, String status) async {
    try {
      await Api.instance.patch('/admin/drivers/$id/status', {'status': status});
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const DarbStateView.loading();
    if (_error != null) return DarbStateView.error(message: _error, onRetry: _load);

    final totalOrders = _stats['ordersTotal'] ?? 0;
    final activeOrders = _stats['ordersActive'] ?? 0;
    final driversOnline = _stats['driversOnline'] ?? 0;
    final gmv = num.tryParse(_stats['deliveredGrossTotal']?.toString() ?? '0') ?? 0;

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
                label: dt('قيد التنفيذ'),
                value: '$activeOrders',
                icon: Icons.local_shipping_outlined,
              ),
              DarbMetricCard(
                label: dt('سائقون متصلون'),
                value: '$driversOnline',
                icon: Icons.sensors_rounded,
              ),
              DarbMetricCard(
                label: dt('إجمالي المبيعات'),
                value: formatDarbMoney(gmv),
                icon: Icons.account_balance_wallet_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(
                    '${dt('قيد الانتظار')} (${_pendingVendors.length + _pendingDrivers.length})',
                  ),
                  selected: _directoryMode == 0,
                  onSelected: (_) => setState(() => _directoryMode = 0),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('${dt('سجل المتاجر')} (${_allVendors.length})'),
                  selected: _directoryMode == 1,
                  onSelected: (_) => setState(() => _directoryMode = 1),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('${dt('سجل السائقين')} (${_allDrivers.length})'),
                  selected: _directoryMode == 2,
                  onSelected: (_) => setState(() => _directoryMode = 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
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
              for (final v in _pendingVendors)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildVendorCard(v),
                ),
            const SizedBox(height: 16),
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
              for (final d in _pendingDrivers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildDriverCard(d),
                ),
          ] else if (_directoryMode == 1) ...[
            if (_allVendors.isEmpty)
              DarbStateView.empty(
                message: dt('لا توجد متاجر متاحة في هذه المدينة'),
                icon: Icons.storefront_outlined,
              )
            else
              for (final v in _allVendors)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildVendorCard(v),
                ),
          ] else ...[
            if (_allDrivers.isEmpty)
              DarbStateView.empty(
                message: dt('لا توجد بيانات متاحة حالياً'),
                icon: Icons.delivery_dining_outlined,
              )
            else
              for (final d in _allDrivers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildDriverCard(d),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildVendorCard(Map<String, dynamic> v) {
    final tr = (v['translations'] as List? ?? []);
    final name = tr.isNotEmpty
        ? tr.first['name']?.toString() ?? dt('متجر')
        : dt('متجر');
    final status = v['status']?.toString() ?? 'PENDING';
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
              DarbStatusBadge(status: status),
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
              if (status != 'APPROVED')
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        _setVendorStatus(v['id'].toString(), 'APPROVED'),
                    child: Text(dt('اعتماد')),
                  ),
                ),
              if (status != 'APPROVED' && status != 'SUSPENDED')
                const SizedBox(width: 8),
              if (status != 'SUSPENDED')
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DarbColors.dangerOf(context),
                  ),
                  onPressed: () => _setVendorStatus(
                    v['id'].toString(),
                    status == 'PENDING' ? 'REJECTED' : 'SUSPENDED',
                  ),
                  child: Text(status == 'PENDING' ? dt('رفض') : dt('تعليق')),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> d) {
    final status = d['status']?.toString() ?? 'PENDING';
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
              DarbStatusBadge(status: status),
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
              if (status != 'APPROVED')
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        _setDriverStatus(d['id'].toString(), 'APPROVED'),
                    child: Text(dt('اعتماد')),
                  ),
                ),
              if (status != 'APPROVED' && status != 'SUSPENDED')
                const SizedBox(width: 8),
              if (status != 'SUSPENDED')
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
