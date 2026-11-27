import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/services/notifications_service.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_motion_components.dart';
import '../../core/widgets/darb_spatial_primitives.dart';

enum _NotifFilter { all, unread, orders }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.onOpenNotificationData,
  });

  final Future<void> Function(Map<String, dynamic> data)?
      onOpenNotificationData;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _items = const [];
  int _unreadCount = 0;
  bool _loading = true;
  bool _markingAll = false;
  bool _syncingDevice = false;
  _NotifFilter _filter = _NotifFilter.all;
  final Set<String> _markingIds = <String>{};
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
      final res = await Api.instance.get('/notifications');
      if (res is Map<String, dynamic>) {
        final raw = (res['items'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        if (!mounted) return;
        setState(() {
          _items = raw;
          _unreadCount = (res['unreadCount'] as num?)?.toInt() ?? 0;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = dt('حدث خطأ غير متوقع، حاول مجدداً'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _syncDevicePush() async {
    if (_syncingDevice) return;
    setState(() => _syncingDevice = true);
    try {
      await DarbNotifications.register(force: true);
      if (!mounted) return;
      final err = DarbNotifications.lastError;
      if (err != null && err.isNotEmpty) {
        DarbHaptics.warning();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      } else {
        DarbHaptics.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dt('تمت مزامنة الإشعارات بنجاح'))),
        );
      }
    } finally {
      if (mounted) setState(() => _syncingDevice = false);
    }
  }

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    try {
      await Api.instance.patch('/notifications/read-all', {});
      if (mounted) DarbHaptics.selection();
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
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _handleTileTap(Map<String, dynamic> item) async {
    await _markOneRead(item);
    if (!mounted) return;
    final rawData = item['data'];
    final payload = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};
    final type = item['type']?.toString();
    if (type != null && type.isNotEmpty && !payload.containsKey('type')) {
      payload['type'] = type;
    }
    final hasRouteTarget =
        (payload['orderId']?.toString().trim().isNotEmpty ?? false) ||
            payload['type']?.toString() == 'APP_UPDATE';
    if (hasRouteTarget && widget.onOpenNotificationData != null) {
      await widget.onOpenNotificationData!(payload);
    }
  }

  Future<void> _markOneRead(Map<String, dynamic> item) async {
    if (item['readAt'] != null) return;
    final id = item['id']?.toString();
    if (id == null || !_markingIds.add(id)) return;
    try {
      await Api.instance.patch('/notifications/$id/read', {});
      if (!mounted) return;
      DarbHaptics.selection();
      setState(() {
        _items = _items
            .map(
              (e) => e['id'] == id
                  ? {...e, 'readAt': DateTime.now().toIso8601String()}
                  : e,
            )
            .toList();
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dt('تعذر تحديث الإشعار'))),
        );
      }
    } finally {
      _markingIds.remove(id);
    }
  }

  bool _isOrderType(String? type) => switch (type?.toUpperCase()) {
        'ORDER_CREATED' ||
        'ORDER_ACCEPTED' ||
        'ORDER_PREPARING' ||
        'ORDER_READY' ||
        'ORDER_ASSIGNED' ||
        'ORDER_PICKED_UP' ||
        'ORDER_DELIVERED' ||
        'ORDER_CANCELLED' ||
        'ORDER_STATUS_UPDATED' ||
        'DELIVERY_OFFER_SELECTED' ||
        'PEER_DELIVERY_AVAILABLE' =>
          true,
        _ => false,
      };

  IconData _iconForType(String? type) => switch (type?.toUpperCase()) {
        'ORDER_CREATED' || 'ORDER_ACCEPTED' || 'ORDER_PREPARING' =>
          Icons.shopping_bag_outlined,
        'ORDER_READY' || 'ORDER_ASSIGNED' || 'DELIVERY_OFFER_SELECTED' =>
          Icons.local_shipping_outlined,
        'ORDER_PICKED_UP' || 'PEER_DELIVERY_AVAILABLE' => Icons.route_outlined,
        'ORDER_DELIVERED' => Icons.verified_rounded,
        'ORDER_CANCELLED' => Icons.cancel_outlined,
        'APP_UPDATE' => Icons.system_update_rounded,
        'DRIVER_APPROVED' || 'VENDOR_APPROVED' => Icons.verified_user_outlined,
        _ => Icons.notifications_active_outlined,
      };

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dtObj = DateTime.tryParse(iso)?.toLocal();
    if (dtObj == null) return '';
    final hh = dtObj.hour.toString().padLeft(2, '0');
    final mm = dtObj.minute.toString().padLeft(2, '0');
    return '${dtObj.year}-${dtObj.month.toString().padLeft(2, '0')}-${dtObj.day.toString().padLeft(2, '0')} · $hh:$mm';
  }

  Widget _buildSyncBanner(BuildContext context) {
    final isSynced =
        DarbNotifications.hasSyncedToken && DarbNotifications.lastError == null;
    final hasError = DarbNotifications.lastError != null &&
        DarbNotifications.lastError!.isNotEmpty;
    final accent = isSynced
        ? DarbColors.successOf(context)
        : (hasError
            ? DarbColors.warningOf(context)
            : DarbColors.primaryOf(context));

    return DarbGlassSurface(
      borderRadius: DarbRadius.lg,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      borderColor: accent.withValues(alpha: 0.34),
      child: Row(
        children: [
          DarbPulseDot(active: isSynced, color: accent, size: 8),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSynced
                      ? dt('جهازك متزامن مع الإشعارات الفورية')
                      : dt('بحاجة لمزامنة الإشعارات الفورية'),
                  style: TextStyle(
                    color: DarbColors.inkOf(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (hasError) ...[
                  const SizedBox(height: 2),
                  Text(
                    DarbNotifications.lastError!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: DarbColors.mutedOf(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _syncingDevice ? null : _syncDevicePush,
            icon: _syncingDevice
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded, size: 16),
            label: Text(dt('مزامنة الآن')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderItemsCount =
        _items.where((e) => _isOrderType(e['type']?.toString())).length;
    final filtered = switch (_filter) {
      _NotifFilter.unread => _items.where((e) => e['readAt'] == null).toList(),
      _NotifFilter.orders =>
        _items.where((e) => _isOrderType(e['type']?.toString())).toList(),
      _NotifFilter.all => _items,
    };

    return Scaffold(
      appBar: DarbGlassAppBar(
        title: dt('الإشعارات'),
        subtitle: _unreadCount > 0
            ? '${dt('إشعارات غير مقروءة')}: $_unreadCount'
            : null,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markingAll ? null : _markAllRead,
              child: Text(dt('تحديد الكل كمقروء')),
            ),
        ],
      ),
      body: DarbAmbientBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _loading
                ? const DarbStateView.loading()
                : _error != null
                    ? DarbStateView.error(message: _error, onRetry: _load)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _items.isEmpty
                            ? ListView(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 28),
                                children: [
                                  _buildSyncBanner(context),
                                  const SizedBox(height: 18),
                                  DarbStateView.empty(
                                    message: dt('لا توجد إشعارات حتى الآن'),
                                    icon: Icons.notifications_none_rounded,
                                    onRetry: _load,
                                  ),
                                ],
                              )
                            : ListView(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 28),
                                children: [
                                  DarbFadeSlide(
                                    child: DarbCommandStage(
                                      livePulse: _unreadCount > 0,
                                      eyebrow: dt(
                                        'تحديثات القبول والتحضير والتعيين والوصول',
                                      ),
                                      title: dt('الإشعارات'),
                                      subtitle: _unreadCount > 0
                                          ? '${dt('إشعارات غير مقروءة')}: $_unreadCount'
                                          : dt('تفضيلات الإشعارات'),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 11,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: DarbColors.lime
                                              .withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(
                                            DarbRadius.pill,
                                          ),
                                          border: Border.all(
                                            color: DarbColors.lime
                                                .withValues(alpha: 0.42),
                                          ),
                                        ),
                                        child: Text(
                                          '${_items.length}',
                                          style: const TextStyle(
                                            color: DarbColors.lime,
                                            fontWeight: FontWeight.w900,
                                            fontFeatures: [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildSyncBanner(context),
                                  const SizedBox(height: 12),
                                  DarbSegmentedDock<_NotifFilter>(
                                    selectedValue: _filter,
                                    onSelected: (v) =>
                                        setState(() => _filter = v),
                                    options: [
                                      DarbDockOption(
                                        value: _NotifFilter.all,
                                        label: dt('الكل'),
                                        count: _items.length,
                                        icon: Icons.inbox_rounded,
                                      ),
                                      DarbDockOption(
                                        value: _NotifFilter.unread,
                                        label: dt('إشعارات غير مقروءة'),
                                        count: _unreadCount,
                                        icon: Icons.mark_email_unread_outlined,
                                      ),
                                      DarbDockOption(
                                        value: _NotifFilter.orders,
                                        label: dt('الطلبات'),
                                        count: orderItemsCount,
                                        icon: Icons.local_shipping_outlined,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (filtered.isEmpty)
                                    DarbStateView.empty(
                                      message: dt('لا توجد إشعارات حتى الآن'),
                                      icon: Icons.notifications_none_rounded,
                                    )
                                  else
                                    for (var i = 0; i < filtered.length; i++) ...[
                                      if (i > 0) const SizedBox(height: 10),
                                      _buildNotifTile(
                                        context,
                                        filtered[i],
                                        index: i,
                                      ),
                                    ],
                                ],
                              ),
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotifTile(
    BuildContext context,
    Map<String, dynamic> item, {
    required int index,
  }) {
    final unread = item['readAt'] == null;
    final primary = DarbColors.primaryOf(context);
    final isDark = DarbColors.isDark(context);
    final rawData = item['data'];
    final hasOrder = rawData is Map &&
        (rawData['orderId']?.toString().trim().isNotEmpty ?? false);
    final isAppUpdate = item['type']?.toString() == 'APP_UPDATE' ||
        (rawData is Map && rawData['type']?.toString() == 'APP_UPDATE');
    final canOpenRoute =
        widget.onOpenNotificationData != null && (hasOrder || isAppUpdate);

    return DarbFadeSlide(
      delay: DarbMotion.staggerDelay(index),
      child: DarbInteractiveCard(
        onTap: () => unawaited(_handleTileTap(item)),
        padding: const EdgeInsets.all(14),
        borderColor: unread ? primary.withValues(alpha: 0.45) : null,
        tintColor: unread
            ? primary.withValues(alpha: isDark ? 0.08 : 0.04)
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: unread
                    ? primary.withValues(alpha: 0.16)
                    : DarbColors.softSurfaceOf(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _iconForType(item['type']?.toString()),
                color: unread ? primary : DarbColors.mutedOf(context),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['title']?.toString() ?? '',
                          style: TextStyle(
                            color: DarbColors.inkOf(context),
                            fontWeight:
                                unread ? FontWeight.w900 : FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                      if (unread)
                        DarbPulseDot(
                          color: primary,
                          size: 7.5,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['body']?.toString() ?? '',
                    style: TextStyle(
                      color: DarbColors.mutedOf(context),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatDate(item['createdAt']?.toString()),
                          style: TextStyle(
                            color: DarbColors.mutedOf(context),
                            fontSize: 11,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      if (canOpenRoute)
                        Text(
                          dt('فتح التفاصيل'),
                          style: TextStyle(
                            color: primary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
