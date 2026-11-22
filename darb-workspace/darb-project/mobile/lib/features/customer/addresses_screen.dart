import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';

Future<Map<String, dynamic>?> showAddressFormSheet(
  BuildContext context, {
  Map<String, dynamic>? existing,
  bool requireLocation = false,
}) {
  return showDarbGlassModalSheet<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _AddressFormSheet(
      existing: existing,
      requireLocation: requireLocation,
    ),
  );
}

class _AddressFormSheet extends StatefulWidget {
  const _AddressFormSheet({this.existing, this.requireLocation = false});

  final Map<String, dynamic>? existing;
  final bool requireLocation;

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  late final TextEditingController _label;
  late final TextEditingController _details;
  double? _lat;
  double? _lng;
  bool _locating = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.existing?['label']?.toString() ?? '');
    _details = TextEditingController(text: widget.existing?['details']?.toString() ?? '');
  }

  @override
  void dispose() {
    _label.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final coords = await DarbLocationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _lat = coords.latitude;
        _lng = coords.longitude;
      });
    } on DarbLocationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = dt('تعذر تحديد الموقع الحالي'));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    final label = _label.text.trim();
    final details = _details.text.trim();
    if (label.length > 40) {
      setState(() => _error = dt('اسم العنوان طويل جداً'));
      return;
    }
    if (details.length < 4) {
      setState(() => _error = dt('أدخل تفاصيل العنوان'));
      return;
    }
    if (details.length > 500) {
      setState(() => _error = dt('تفاصيل العنوان طويلة جداً'));
      return;
    }
    final alreadyHasLocation = widget.existing?['hasLocation'] == true;
    if (widget.requireLocation && (_lat == null || _lng == null) && !alreadyHasLocation) {
      setState(() => _error = dt('أكمل العنوان وحدد موقعه الجغرافي'));
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final body = <String, dynamic>{
        if (label.isNotEmpty) 'label': label,
        'details': details,
        if (_lat != null && _lng != null) ...{'latitude': _lat, 'longitude': _lng},
      };
      final id = widget.existing?['id']?.toString();
      final saved = id != null
          ? await Api.instance.patch('/addresses/$id', body)
          : await Api.instance.post('/addresses', body);
      if (!mounted) return;
      Navigator.pop(context, saved as Map<String, dynamic>?);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final hasSavedCoords = (_lat != null && _lng != null) || widget.existing?['hasLocation'] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isEdit ? dt('تعديل العنوان') : dt('إضافة عنوان توصيل'),
          style: TextStyle(
            color: DarbColors.inkOf(context),
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _label,
          decoration: InputDecoration(
            labelText: dt('اسم العنوان (اختياري)'),
            hintText: dt('المنزل، العمل...'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _details,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: dt('العنوان بالتفصيل'),
            hintText: dt('الحي، الشارع، البناء، الطابق...'),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _locating ? null : _captureLocation,
          icon: _locating
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(
                  hasSavedCoords ? Icons.my_location_rounded : Icons.location_searching_rounded,
                  color: hasSavedCoords ? DarbColors.primaryOf(context) : null,
                ),
          label: Text(
            _locating
                ? dt('جارٍ تحديد الموقع...')
                : (_lat != null
                    ? '${dt('تم تحديد الموقع')} (${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)})'
                    : (hasSavedCoords ? dt('تم حفظ الإحداثيات لهذا العنوان') : dt('استخدام موقعي الحالي'))),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: TextStyle(color: DarbColors.dangerOf(context), fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? dt('جارٍ الحفظ') : dt('حفظ العنوان')),
        ),
      ],
    );
  }
}

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<Map<String, dynamic>> _addresses = const [];
  bool _loading = true;
  bool _offline = false;
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
      final res = await Api.instance.getWithCache('/addresses', 'customer_addresses');
      final list = (res.data as List? ?? []).whereType<Map<String, dynamic>>().toList();
      if (!mounted) return;
      setState(() {
        _addresses = list;
        _offline = res.fromCache;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteAddress(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dt('حذف العنوان')),
        content: Text(dt('هل تريد حذف هذا العنوان المحفوظ؟')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(dt('إلغاء'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: DarbColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(dt('حذف العنوان')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Api.instance.delete('/addresses/$id');
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DarbGlassAppBar(
        title: dt('عناوين التوصيل'),
        actions: [
          IconButton(
            onPressed: () async {
              final created = await showAddressFormSheet(context);
              if (created != null) _load();
            },
            icon: const Icon(Icons.add_location_alt_outlined),
          ),
        ],
      ),
      body: DarbAmbientBackground(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const DarbStateView.loading()
              : _error != null
                  ? DarbStateView.error(message: _error, onRetry: _load)
                  : _addresses.isEmpty
                      ? ListView(
                          children: [
                            DarbStateView.empty(
                              message: dt('لا يوجد عنوان محفوظ'),
                              icon: Icons.location_off_outlined,
                              onRetry: () async {
                                final created = await showAddressFormSheet(context);
                                if (created != null) _load();
                              },
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                          itemCount: _addresses.length + (_offline ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (_offline && index == 0) {
                              return DarbGlassSurface(
                                tintColor: DarbColors.warningSoft,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Text(
                                  dt('بيانات مخزنة محلياً لضعف الاتصال'),
                                  style: const TextStyle(
                                    color: DarbColors.warning,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            }
                            final addr = _addresses[_offline ? index - 1 : index];
                            final hasLocation = addr['hasLocation'] == true;
                            return DarbGlassSurface(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: DarbColors.primaryOf(context).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Icon(
                                      hasLocation ? Icons.location_on_rounded : Icons.location_searching_rounded,
                                      color: DarbColors.primaryOf(context),
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
                                                addr['label']?.toString().isNotEmpty == true
                                                    ? addr['label'].toString()
                                                    : dt('عنوان'),
                                                style: TextStyle(
                                                  color: DarbColors.inkOf(context),
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            DarbStatusBadge(status: hasLocation ? 'OPEN' : 'PENDING'),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          addr['details']?.toString() ?? '',
                                          style: TextStyle(color: DarbColors.mutedOf(context), height: 1.4),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            TextButton.icon(
                                              onPressed: () async {
                                                final updated = await showAddressFormSheet(context, existing: addr);
                                                if (updated != null) _load();
                                              },
                                              icon: const Icon(Icons.edit_outlined, size: 17),
                                              label: Text(dt('تعديل')),
                                            ),
                                            TextButton.icon(
                                              style: TextButton.styleFrom(
                                                foregroundColor: DarbColors.dangerOf(context),
                                              ),
                                              onPressed: () => _deleteAddress(addr['id'].toString()),
                                              icon: const Icon(Icons.delete_outline_rounded, size: 17),
                                              label: Text(dt('حذف العنوان')),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: DarbColors.primaryOf(context),
        foregroundColor: Colors.white,
        onPressed: () async {
          final created = await showAddressFormSheet(context);
          if (created != null) _load();
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(dt('إضافة عنوان')),
      ),
    );
  }
}
