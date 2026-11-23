import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _items = const [];
  int _unreadCount = 0;
  bool _loading = true;
  bool _markingAll = false;
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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    try {
      await Api.instance.patch('/notifications/read-all', {});
      if (mounted) HapticFeedback.selectionClick();
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _markOneRead(Map<String, dynamic> item) async {
    if (item['readAt'] != null) return;
    final id = item['id']?.toString();
    if (id == null || !_markingIds.add(id)) return;
    try {
      await Api.instance.patch('/notifications/$id/read', {});
      if (!mounted) return;
      HapticFeedback.selectionClick();
      setState(() {
        _items = _items
            .map((e) => e['id'] == id
                ? {...e, 'readAt': DateTime.now().toIso8601String()}
                : e)
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

  IconData _iconForType(String? type) => switch (type) {
        'ORDER_CREATED' => Icons.shopping_bag_outlined,
        'ORDER_ASSIGNED' || 'DELIVERY_OFFER_SELECTED' =>
          Icons.local_shipping_outlined,
        'PEER_DELIVERY_AVAILABLE' => Icons.route_outlined,
        'ORDER_CANCELLED' => Icons.cancel_outlined,
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

  @override
  Widget build(BuildContext context) {
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
        child: _loading
            ? const DarbStateView.loading()
            : _error != null
                ? DarbStateView.error(message: _error, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _items.isEmpty
                        ? ListView(
                            children: [
                              DarbStateView.empty(
                                message: dt('لا توجد إشعارات حتى الآن'),
                                icon: Icons.notifications_none_rounded,
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final unread = item['readAt'] == null;
                              final primary = DarbColors.primaryOf(context);

                              return DarbFadeSlide(
                                delay: DarbMotion.staggerDelay(index),
                                child: DarbPressScale(
                                  onTap: () => _markOneRead(item),
                                  child: DarbGlassSurface(
                                    padding: const EdgeInsets.all(14),
                                    borderColor: unread
                                        ? primary.withValues(alpha: 0.45)
                                        : null,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: unread
                                                ? primary.withValues(
                                                    alpha: 0.16)
                                                : DarbColors.softSurfaceOf(
                                                    context),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            _iconForType(
                                                item['type']?.toString()),
                                            color: unread
                                                ? primary
                                                : DarbColors.mutedOf(context),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item['title']
                                                              ?.toString() ??
                                                          '',
                                                      style: TextStyle(
                                                        color:
                                                            DarbColors.inkOf(
                                                                context),
                                                        fontWeight: unread
                                                            ? FontWeight.w900
                                                            : FontWeight.w700,
                                                        fontSize: 14.5,
                                                      ),
                                                    ),
                                                  ),
                                                  if (unread)
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: BoxDecoration(
                                                        color: primary,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                item['body']?.toString() ?? '',
                                                style: TextStyle(
                                                  color: DarbColors.mutedOf(
                                                      context),
                                                  fontSize: 13,
                                                  height: 1.4,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                _formatDate(item['createdAt']
                                                    ?.toString()),
                                                style: TextStyle(
                                                  color: DarbColors.mutedOf(
                                                      context),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
      ),
    );
  }
}
