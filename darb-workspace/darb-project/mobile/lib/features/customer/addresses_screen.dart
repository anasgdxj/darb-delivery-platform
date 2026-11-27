import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_map_picker.dart';
import '../../core/widgets/darb_motion_components.dart';
import '../../core/widgets/darb_spatial_primitives.dart';

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
  int _mapRevision = 0;
  bool _locating = false;
  bool _saving = false;
  DarbActionState _saveState = DarbActionState.idle;
  int _errorTrigger = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(
      text: widget.existing?['label']?.toString() ?? '',
    );
    _details = TextEditingController(
      text: widget.existing?['details']?.toString() ?? '',
    );
    _lat = (widget.existing?['latitude'] as num?)?.toDouble();
    _lng = (widget.existing?['longitude'] as num?)?.toDouble();
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
      DarbHaptics.success();
      setState(() {
        _lat = coords.latitude;
        _lng = coords.longitude;
        _mapRevision++;
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
      setState(() {
        _error = dt('اسم العنوان طويل جداً');
        _saveState = DarbActionState.error;
        _errorTrigger++;
      });
      return;
    }
    if (details.length < 4) {
      setState(() {
        _error = dt('أدخل تفاصيل العنوان');
        _saveState = DarbActionState.error;
        _errorTrigger++;
      });
      return;
    }
    if (details.length > 500) {
      setState(() {
        _error = dt('تفاصيل العنوان طويلة جداً');
        _saveState = DarbActionState.error;
        _errorTrigger++;
      });
      return;
    }
    final alreadyHasLocation = widget.existing?['hasLocation'] == true;
    if (widget.requireLocation &&
        (_lat == null || _lng == null) &&
        !alreadyHasLocation) {
      setState(() {
        _error = dt('أكمل العنوان وحدد موقعه الجغرافي');
        _saveState = DarbActionState.error;
        _errorTrigger++;
      });
      return;
    }

    setState(() {
      _saving = true;
      _saveState = DarbActionState.loading;
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
      setState(() => _saveState = DarbActionState.success);
      Navigator.pop(context, saved as Map<String, dynamic>?);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _saveState = DarbActionState.error;
          _errorTrigger++;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = dt('حدث خطأ غير متوقع، حاول مجدداً');
          _saveState = DarbActionState.error;
          _errorTrigger++;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          if (_saveState == DarbActionState.loading) {
            _saveState = DarbActionState.idle;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final hasSavedCoords =
        (_lat != null && _lng != null) || widget.existing?['hasLocation'] == true;
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
        DarbPressScale(
          borderRadius: DarbRadius.md,
          onTap: _locating ? null : _captureLocation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: hasSavedCoords
                  ? DarbColors.primaryOf(context).withValues(alpha: 0.11)
                  : DarbColors.softSurfaceOf(context),
              borderRadius: BorderRadius.circular(DarbRadius.md),
              border: Border.all(
                color: hasSavedCoords
                    ? DarbColors.primaryOf(context).withValues(alpha: 0.45)
                    : DarbColors.borderOf(context),
              ),
            ),
            child: Row(
              children: [
                if (_locating)
                  const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    hasSavedCoords
                        ? Icons.my_location_rounded
                        : Icons.location_searching_rounded,
                    size: 18,
                    color: hasSavedCoords
                        ? DarbColors.primaryOf(context)
                        : DarbColors.mutedOf(context),
                  ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    _locating
                        ? dt('جارٍ تحديد الموقع...')
                        : (_lat != null
                            ? '${dt('تم تحديد الموقع')} (${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)})'
                            : (hasSavedCoords
                                ? dt('تم حفظ الإحداثيات لهذا العنوان')
                                : dt('استخدام موقعي الحالي'))),
                    style: TextStyle(
                      color: hasSavedCoords
                          ? DarbColors.primaryOf(context)
                          : DarbColors.inkOf(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        DarbMapPicker(
          key: ValueKey('address-map-$_mapRevision'),
          selectedLatitude: _lat,
          selectedLongitude: _lng,
          onPointSelected: (latitude, longitude) {
            setState(() {
              _lat = latitude;
              _lng = longitude;
              _error = null;
            });
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: TextStyle(
              color: DarbColors.dangerOf(context),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 16),
        DarbActionButton(
          label: dt('حفظ العنوان'),
          loadingLabel: dt('جارٍ الحفظ'),
          state: _saveState,
          errorTrigger: _errorTrigger,
          icon: Icons.check_rounded,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}

enum _AddressFilter { all, verified, unpinned }

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
  _AddressFilter _filter = _AddressFilter.all;
  final Set<String> _busyAddressIds = <String>{};

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
      final res = await Api.instance.getWithCache(
        '/addresses',
        'customer_addresses',
      );
      final list = (res.data as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      if (!mounted) return;
      setState(() {
        _addresses = list;
        _offline = res.fromCache;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = dt('حدث خطأ غير متوقع، حاول مجدداً'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreateSheet() async {
    final created = await showAddressFormSheet(context);
    if (created != null) _load();
  }

  Future<void> _deleteAddress(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dt('حذف العنوان')),
        content: Text(dt('هل تريد حذف هذا العنوان المحفوظ؟')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(dt('إلغاء')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: DarbColors.dangerOf(ctx),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(dt('حذف العنوان')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!_busyAddressIds.add(id)) return;
    if (mounted) setState(() {});
    try {
      await Api.instance.delete('/addresses/$id');
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
      _busyAddressIds.remove(id);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final gpsCount = _addresses.where((a) => a['hasLocation'] == true).length;
    final unpinnedCount = _addresses.length - gpsCount;
    final filtered = switch (_filter) {
      _AddressFilter.verified =>
        _addresses.where((a) => a['hasLocation'] == true).toList(),
      _AddressFilter.unpinned =>
        _addresses.where((a) => a['hasLocation'] != true).toList(),
      _AddressFilter.all => _addresses,
    };

    return Scaffold(
      appBar: DarbGlassAppBar(
        title: dt('عناوين التوصيل'),
        actions: [
          IconButton(
            tooltip: dt('إضافة عنوان'),
            onPressed: _openCreateSheet,
            icon: const Icon(Icons.add_location_alt_outlined),
          ),
        ],
      ),
      body: DarbAmbientBackground(
        child: RefreshIndicator(
          onRefresh: _load,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: _loading
                  ? const DarbStateView.loading()
                  : _error != null
                      ? DarbStateView.error(message: _error, onRetry: _load)
                      : _addresses.isEmpty
                          ? LayoutBuilder(
                              builder: (context, constraints) =>
                                  SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: DarbStateView.empty(
                                    message: dt('لا يوجد عنوان محفوظ'),
                                    icon: Icons.location_off_outlined,
                                    onRetry: _openCreateSheet,
                                  ),
                                ),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                14,
                                16,
                                28,
                              ),
                              children: [
                                DarbFadeSlide(
                                  child: DarbCommandStage(
                                    livePulse: gpsCount > 0,
                                    eyebrow: dt('إدارة عناوينك المحفوظة وتحديدها على الخريطة'),
                                    title: dt('عناوين التوصيل'),
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
                                        '${_addresses.length}',
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
                                if (_offline) ...[
                                  DarbGlassSurface(
                                    tintColor:
                                        DarbColors.warningSoftOf(context),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      dt('بيانات مخزنة محلياً لضعف الاتصال'),
                                      style: TextStyle(
                                        color: DarbColors.warningOf(context),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                DarbSegmentedDock<_AddressFilter>(
                                  selectedValue: _filter,
                                  onSelected: (v) =>
                                      setState(() => _filter = v),
                                  options: [
                                    DarbDockOption(
                                      value: _AddressFilter.all,
                                      label: dt('الكل'),
                                      count: _addresses.length,
                                      icon: Icons.layers_outlined,
                                    ),
                                    DarbDockOption(
                                      value: _AddressFilter.verified,
                                      label: dt('تم تحديد الموقع'),
                                      count: gpsCount,
                                      icon: Icons.location_on_outlined,
                                    ),
                                    if (unpinnedCount > 0)
                                      DarbDockOption(
                                        value: _AddressFilter.unpinned,
                                        label: dt('تحتاج لتحديد موقع'),
                                        count: unpinnedCount,
                                        icon: Icons.location_searching_rounded,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                if (filtered.isEmpty)
                                  DarbStateView.empty(
                                    message: dt('لا يوجد عنوان محفوظ'),
                                    icon: Icons.location_off_outlined,
                                  )
                                else
                                  for (var i = 0; i < filtered.length; i++) ...[
                                    if (i > 0) const SizedBox(height: 12),
                                    _buildAddressPass(
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: DarbGlassSurface(
                borderRadius: DarbRadius.xl,
                blurSigma: 22,
                padding: const EdgeInsets.all(10),
                child: DarbActionButton(
                  label: dt('إضافة عنوان'),
                  icon: Icons.add_location_alt_rounded,
                  onPressed: _openCreateSheet,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressPass(
    BuildContext context,
    Map<String, dynamic> addr, {
    required int index,
  }) {
    final id = addr['id'].toString();
    final hasLocation = addr['hasLocation'] == true;
    final isBusy = _busyAddressIds.contains(id);
    final lat = (addr['latitude'] as num?)?.toDouble();
    final lng = (addr['longitude'] as num?)?.toDouble();
    final title = addr['label']?.toString().isNotEmpty == true
        ? addr['label'].toString()
        : dt('عنوان');
    final coordsText = (lat != null && lng != null)
        ? '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'
        : (hasLocation ? dt('تم حفظ الإحداثيات لهذا العنوان') : null);

    return DarbFadeSlide(
      delay: DarbMotion.staggerDelay(index),
      child: DarbTicketPass(
        leadingIcon:
            hasLocation ? Icons.location_on_rounded : Icons.location_searching_rounded,
        title: title,
        subtitle: coordsText,
        status: hasLocation ? 'OPEN' : 'PENDING',
        body: Text(
          addr['details']?.toString() ?? '',
          style: TextStyle(
            color: DarbColors.inkOf(context),
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),
        footer: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            TextButton.icon(
              onPressed: isBusy
                  ? null
                  : () async {
                      final updated =
                          await showAddressFormSheet(context, existing: addr);
                      if (updated != null) _load();
                    },
              icon: const Icon(Icons.edit_outlined, size: 17),
              label: Text(dt('تعديل')),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: DarbColors.dangerOf(context),
              ),
              onPressed: isBusy ? null : () => _deleteAddress(id),
              icon: const Icon(Icons.delete_outline_rounded, size: 17),
              label: Text(dt('حذف العنوان')),
            ),
          ],
        ),
      ),
    );
  }
}
