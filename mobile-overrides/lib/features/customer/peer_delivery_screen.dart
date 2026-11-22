import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_map_picker.dart';
import 'addresses_screen.dart';

class PeerDeliveryScreen extends StatefulWidget {
  const PeerDeliveryScreen({
    super.key,
    required this.cityId,
    required this.cityName,
    this.initialDescription,
    this.onCreated,
  });

  final String cityId;
  final String cityName;
  final String? initialDescription;
  final VoidCallback? onCreated;

  @override
  State<PeerDeliveryScreen> createState() => _PeerDeliveryScreenState();
}

class _PeerDeliveryScreenState extends State<PeerDeliveryScreen> {
  final _pickupAddressController = TextEditingController();
  final _itemTypeController = TextEditingController();
  late final TextEditingController _itemDescriptionController;
  final _instructionsController = TextEditingController();

  int _step = 0;
  double? _pickupLat;
  double? _pickupLng;
  int _pickupMapRevision = 0;
  bool _locatingPickup = false;
  bool _loadingAddresses = true;
  bool _submitting = false;
  List<Map<String, dynamic>> _addresses = const [];
  String? _selectedAddressId;
  String? _error;

  static const _quickTypes = ['مستندات', 'مفاتيح', 'طرد شخصي', 'أغراض منزلية'];

  @override
  void initState() {
    super.initState();
    _itemDescriptionController = TextEditingController(text: widget.initialDescription ?? '');
    _loadAddresses();
  }

  @override
  void dispose() {
    _pickupAddressController.dispose();
    _itemTypeController.dispose();
    _itemDescriptionController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() => _loadingAddresses = true);
    try {
      final list = (await Api.instance.get('/addresses') as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      if (!mounted) return;
      setState(() {
        _addresses = list;
        if (_selectedAddressId == null && list.isNotEmpty) {
          final withLoc = list.where((a) => a['hasLocation'] == true).toList();
          _selectedAddressId = (withLoc.isNotEmpty ? withLoc.first : list.first)['id']?.toString();
        }
      });
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingAddresses = false);
    }
  }

  Future<void> _capturePickupGps() async {
    setState(() {
      _locatingPickup = true;
      _error = null;
    });
    try {
      final coords = await DarbLocationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _pickupLat = coords.latitude;
        _pickupLng = coords.longitude;
        _pickupMapRevision++;
      });
    } on DarbLocationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _locatingPickup = false);
    }
  }

  void _nextStep() {
    setState(() => _error = null);
    if (_step == 0) {
      if (_pickupAddressController.text.trim().length < 5) {
        setState(() => _error = dt('اكتب وصفاً واضحاً لمكان الاستلام'));
        return;
      }
      if (_pickupLat == null || _pickupLng == null) {
        setState(() => _error = dt('حدد موقع الاستلام أولاً'));
        return;
      }
      if (_selectedAddressId == null) {
        setState(() => _error = dt('اختر عنوان تسليم محفوظاً مع موقع جغرافي أو أضف عنواناً جديداً'));
        return;
      }
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      if (_itemTypeController.text.trim().isEmpty) {
        setState(() => _error = dt('اكتب نوع الغرض الذي تريد إرساله'));
        return;
      }
      if (_itemDescriptionController.text.trim().isEmpty) {
        setState(() => _error = dt('أضف وصفاً مختصراً للغرض'));
        return;
      }
      setState(() => _step = 2);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final notesParts = <String>[
      '${dt('نوع الغرض: ')}${_itemTypeController.text.trim()}',
      '${dt('وصف الغرض: ')}${_itemDescriptionController.text.trim()}',
      if (_instructionsController.text.trim().isNotEmpty)
        '${dt('تعليمات للسائق: ')}${_instructionsController.text.trim()}',
    ];
    try {
      await Api.instance.post('/orders/peer-delivery', {
        'cityId': widget.cityId,
        'addressId': _selectedAddressId,
        'pickupAddress': _pickupAddressController.text.trim(),
        'pickupLatitude': _pickupLat,
        'pickupLongitude': _pickupLng,
        'notes': notesParts.join('\n'),
      });
      if (!mounted) return;
      widget.onCreated?.call();
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(dt('تم إرسال طلبك')),
          content: Text(
            dt('سيظهر طلبك للسائقين المتاحين في مدينتك. سيقدم كل سائق أجرته، ويمكنك مقارنة العروض واختيار الأنسب قبل تأكيد التوصيل.'),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(dt('حسناً')),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepTitles = [dt('المواقع'), dt('تفاصيل الغرض'), dt('مراجعة الطلب')];
    return Scaffold(
      appBar: DarbGlassAppBar(
        title: dt('توصيل مستقل'),
        subtitle: '${widget.cityName} · ${dt('الخطوة ${_step + 1} من 3')}',
      ),
      body: DarbAmbientBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            DarbGlassSurface(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: List.generate(3, (i) {
                  final active = i <= _step;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(end: i < 2 ? 8 : 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedContainer(
                            duration: DarbMotion.fast,
                            height: 5,
                            decoration: BoxDecoration(
                              color: active
                                  ? DarbColors.primaryOf(context)
                                  : DarbColors.borderOf(context),
                              borderRadius: BorderRadius.circular(DarbRadius.pill),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            stepTitles[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                              color: active ? DarbColors.inkOf(context) : DarbColors.mutedOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 14),
            if (_step == 0) _buildLocationsStep(),
            if (_step == 1) _buildDetailsStep(),
            if (_step == 2) _buildReviewStep(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              DarbGlassSurface(
                tintColor: DarbColors.dangerSoft,
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: DarbColors.danger, fontWeight: FontWeight.w700),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (_step > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : () => setState(() => _step--),
                      child: Text(dt('السابق')),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _submitting ? null : (_step < 2 ? _nextStep : _submit),
                    child: Text(
                      _step < 2
                          ? dt('متابعة')
                          : (_submitting ? dt('جارٍ الحفظ') : dt('تأكيد وإرسال الطلب')),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationsStep() {
    return DarbGlassSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            dt('من أين نستلم؟'),
            style: TextStyle(color: DarbColors.inkOf(context), fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            dt('حدد مكان وجود الغرض حتى يصل السائق إليك.'),
            style: TextStyle(color: DarbColors.mutedOf(context), fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pickupAddressController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: dt('وصف مكان الاستلام'),
              hintText: dt('مثلاً: أمام صيدلية الشفاء، شارع ...'),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _locatingPickup ? null : _capturePickupGps,
            icon: _locatingPickup
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_pickupLat != null ? Icons.check_circle_rounded : Icons.my_location_rounded),
            label: Text(
              _pickupLat != null
                  ? '${dt('تم تحديد موقع الاستلام')} (${_pickupLat!.toStringAsFixed(4)}, ${_pickupLng!.toStringAsFixed(4)})'
                  : dt('استخدام موقعي الحالي'),
            ),
          ),
          const SizedBox(height: 12),
          DarbMapPicker(
            key: ValueKey('pickup-map-$_pickupMapRevision'),
            selectedLatitude: _pickupLat,
            selectedLongitude: _pickupLng,
            onPointSelected: (latitude, longitude) {
              setState(() {
                _pickupLat = latitude;
                _pickupLng = longitude;
                _error = null;
              });
            },
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  dt('إلى أين نوصّل؟'),
                  style: TextStyle(color: DarbColors.inkOf(context), fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final created = await showAddressFormSheet(context, requireLocation: true);
                  if (created != null) {
                    setState(() => _selectedAddressId = created['id']?.toString());
                    await _loadAddresses();
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(dt('إضافة عنوان')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loadingAddresses)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else if (_addresses.isEmpty)
            Text(
              dt('لا يوجد عنوان تسليم محفوظ. أضف عنواناً وحدد موقعه للمتابعة.'),
              style: TextStyle(color: DarbColors.mutedOf(context)),
            )
          else
            Column(
              children: [
                for (var i = 0; i < _addresses.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  DarbRadioOptionTile(
                    selected: _addresses[i]['id']?.toString() == _selectedAddressId,
                    title: _addresses[i]['label']?.toString().isNotEmpty == true
                        ? _addresses[i]['label'].toString()
                        : dt('عنوان التسليم'),
                    subtitle: _addresses[i]['details']?.toString() ?? '',
                    onTap: () => setState(
                      () => _selectedAddressId = _addresses[i]['id']?.toString(),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return DarbGlassSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            dt('ماذا تريد إرسال؟'),
            style: TextStyle(color: DarbColors.inkOf(context), fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chip in _quickTypes)
                ChoiceChip(
                  label: Text(chip),
                  selected: _itemTypeController.text.trim() == chip,
                  onSelected: (_) => setState(() => _itemTypeController.text = chip),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _itemTypeController,
            decoration: InputDecoration(
              labelText: dt('نوع الغرض'),
              hintText: dt('مثلاً: مستندات، حقيبة، قطعة غيار'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _itemDescriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: dt('وصف الغرض'),
              hintText: dt('اذكر الحجم أو أي تفاصيل تساعد السائق'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _instructionsController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: dt('تعليمات إضافية للسائق (اختياري)'),
              hintText: dt('وقت مناسب، شخص للتواصل عند الوصول...'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    final selectedAddr = _addresses.cast<Map<String, dynamic>?>().firstWhere(
          (a) => a?['id']?.toString() == _selectedAddressId,
          orElse: () => null,
        );
    return DarbGlassSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            dt('راجع طلبك'),
            style: TextStyle(color: DarbColors.inkOf(context), fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _summaryRow(dt('موقع الاستلام'), _pickupAddressController.text.trim()),
          _summaryRow(
            dt('عنوان التسليم'),
            selectedAddr?['details']?.toString() ?? dt('لم يتم اختيار عنوان'),
          ),
          _summaryRow(dt('نوع الغرض'), _itemTypeController.text.trim()),
          _summaryRow(dt('وصف الغرض'), _itemDescriptionController.text.trim()),
          if (_instructionsController.text.trim().isNotEmpty)
            _summaryRow(dt('تعليمات السائق'), _instructionsController.text.trim()),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DarbColors.softSurfaceOf(context),
              borderRadius: BorderRadius.circular(DarbRadius.sm),
            ),
            child: Text(
              dt('بعد إرسال الطلب سيحدد السائقون أجورهم وفق مسافة التوصيل، وستختار العرض المناسب قبل تأكيد الطلب.'),
              style: TextStyle(color: DarbColors.mutedOf(context), fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: DarbColors.mutedOf(context), fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: DarbColors.inkOf(context), fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
