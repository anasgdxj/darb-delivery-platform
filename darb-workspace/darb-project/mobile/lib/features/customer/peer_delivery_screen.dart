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
  DarbActionState _submitState = DarbActionState.idle;
  int _errorTrigger = 0;
  List<Map<String, dynamic>> _addresses = const [];
  String? _selectedAddressId;
  String? _error;

  static const _quickTypes = [
    ('مستندات', Icons.description_outlined),
    ('مفاتيح', Icons.vpn_key_outlined),
    ('طرد شخصي', Icons.inventory_2_outlined),
    ('أغراض منزلية', Icons.home_repair_service_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _itemDescriptionController =
        TextEditingController(text: widget.initialDescription ?? '');
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
          _selectedAddressId =
              (withLoc.isNotEmpty ? withLoc.first : list.first)['id']
                  ?.toString();
        }
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = dt('تعذر قراءة عناوين التوصيل'));
      }
    } finally {
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
      DarbHaptics.success();
      setState(() {
        _pickupLat = coords.latitude;
        _pickupLng = coords.longitude;
        _pickupMapRevision++;
      });
    } on DarbLocationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = dt('تعذر تحديد الموقع الحالي'));
    } finally {
      if (mounted) setState(() => _locatingPickup = false);
    }
  }

  void _nextStep() {
    setState(() {
      _error = null;
      _submitState = DarbActionState.idle;
    });
    if (_step == 0) {
      if (_pickupAddressController.text.trim().length < 5) {
        DarbHaptics.warning();
        setState(() {
          _error = dt('اكتب وصفاً واضحاً لمكان الاستلام');
          _submitState = DarbActionState.error;
          _errorTrigger++;
        });
        return;
      }
      if (_pickupLat == null || _pickupLng == null) {
        DarbHaptics.warning();
        setState(() {
          _error = dt('حدد موقع الاستلام أولاً');
          _submitState = DarbActionState.error;
          _errorTrigger++;
        });
        return;
      }
      if (_selectedAddressId == null) {
        DarbHaptics.warning();
        setState(() {
          _error = dt(
            'اختر عنوان تسليم محفوظاً مع موقع جغرافي أو أضف عنواناً جديداً',
          );
          _submitState = DarbActionState.error;
          _errorTrigger++;
        });
        return;
      }
      DarbHaptics.selection();
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      if (_itemTypeController.text.trim().isEmpty) {
        DarbHaptics.warning();
        setState(() {
          _error = dt('اكتب نوع الغرض الذي تريد إرساله');
          _submitState = DarbActionState.error;
          _errorTrigger++;
        });
        return;
      }
      if (_itemDescriptionController.text.trim().isEmpty) {
        DarbHaptics.warning();
        setState(() {
          _error = dt('أضف وصفاً مختصراً للغرض');
          _submitState = DarbActionState.error;
          _errorTrigger++;
        });
        return;
      }
      DarbHaptics.selection();
      setState(() => _step = 2);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _submitState = DarbActionState.loading;
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
      setState(() => _submitState = DarbActionState.success);
      widget.onCreated?.call();
      await Future<void>.delayed(DarbMotion.effectiveDuration(
        context,
        const Duration(milliseconds: 350),
      ));
      if (!mounted) return;
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
      if (mounted) {
        setState(() {
          _error = e.message;
          _submitState = DarbActionState.error;
          _errorTrigger++;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = dt('حدث خطأ غير متوقع، حاول مجدداً');
          _submitState = DarbActionState.error;
          _errorTrigger++;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          if (_submitState == DarbActionState.loading) {
            _submitState = DarbActionState.idle;
          }
        });
      }
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                DarbFadeSlide(
                  child: DarbCommandStage(
                    livePulse: true,
                    eyebrow: widget.cityName,
                    title: dt('توصيل مستقل'),
                    subtitle:
                        '${stepTitles[_step]} · ${dt('الخطوة ${_step + 1} من 3')}',
                    padding: const EdgeInsets.all(16),
                    bottom: Row(
                      children: List.generate(3, (i) {
                        final active = i <= _step;
                        final completed = i < _step;
                        return Expanded(
                          child: Padding(
                            padding:
                                EdgeInsetsDirectional.only(end: i < 2 ? 8 : 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: DarbMotion.effectiveDuration(
                                        context,
                                        DarbMotion.fast,
                                      ),
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: active
                                            ? DarbColors.lime
                                            : Colors.white
                                                .withValues(alpha: 0.10),
                                        border: Border.all(
                                          color: active
                                              ? DarbColors.lime
                                              : Colors.white
                                                  .withValues(alpha: 0.24),
                                        ),
                                      ),
                                      child: Center(
                                        child: completed
                                            ? const Icon(
                                                Icons.check_rounded,
                                                size: 13,
                                                color: DarbColors.darkCanvas,
                                              )
                                            : Text(
                                                '${i + 1}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w900,
                                                  color: active
                                                      ? DarbColors.darkCanvas
                                                      : Colors.white,
                                                  fontFeatures: const [
                                                    FontFeature
                                                        .tabularFigures(),
                                                  ],
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: AnimatedContainer(
                                        duration: DarbMotion.effectiveDuration(
                                          context,
                                          DarbMotion.fast,
                                        ),
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: active
                                              ? DarbColors.lime
                                              : Colors.white
                                                  .withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(
                                            DarbRadius.pill,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  stepTitles[i],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: active
                                        ? FontWeight.w900
                                        : FontWeight.w600,
                                    color: active
                                        ? Colors.white
                                        : DarbColors.mint
                                            .withValues(alpha: 0.72),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: DarbMotion.effectiveDuration(
                    context,
                    DarbMotion.standard,
                  ),
                  switchInCurve: DarbMotion.enter,
                  switchOutCurve: DarbMotion.exit,
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _step == 0
                        ? _buildLocationsStep()
                        : (_step == 1
                            ? _buildDetailsStep()
                            : _buildReviewStep()),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  DarbGlassSurface(
                    tintColor: DarbColors.dangerSoftOf(context),
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: DarbColors.dangerOf(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: DarbGlassSurface(
                borderRadius: DarbRadius.xl,
                blurSigma: 24,
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    if (_step > 0) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting
                              ? null
                              : () => setState(() {
                                    _step--;
                                    _error = null;
                                    _submitState = DarbActionState.idle;
                                  }),
                          child: Text(dt('السابق')),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: 2,
                      child: DarbActionButton(
                        label: _step < 2
                            ? dt('متابعة')
                            : dt('تأكيد وإرسال الطلب'),
                        loadingLabel: dt('جارٍ الحفظ'),
                        successLabel: dt('تم إرسال طلبك'),
                        state: _submitState,
                        errorTrigger: _errorTrigger,
                        icon: _step < 2
                            ? Icons.arrow_forward_rounded
                            : Icons.send_rounded,
                        onPressed: _submitting
                            ? null
                            : (_step < 2 ? _nextStep : _submit),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationsStep() {
    final primary = DarbColors.primaryOf(context);
    return DarbGlassSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            dt('من أين نستلم؟'),
            style: TextStyle(
              color: DarbColors.inkOf(context),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
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
          DarbPressScale(
            borderRadius: DarbRadius.md,
            onTap: _locatingPickup ? null : _capturePickupGps,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: _pickupLat != null
                    ? primary.withValues(alpha: 0.11)
                    : DarbColors.softSurfaceOf(context),
                borderRadius: BorderRadius.circular(DarbRadius.md),
                border: Border.all(
                  color: _pickupLat != null
                      ? primary.withValues(alpha: 0.45)
                      : DarbColors.borderOf(context),
                ),
              ),
              child: Row(
                children: [
                  if (_locatingPickup)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      _pickupLat != null
                          ? Icons.check_circle_rounded
                          : Icons.my_location_rounded,
                      size: 18,
                      color: _pickupLat != null
                          ? primary
                          : DarbColors.mutedOf(context),
                    ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _pickupLat != null
                          ? '${dt('تم تحديد موقع الاستلام')} (${_pickupLat!.toStringAsFixed(4)}, ${_pickupLng!.toStringAsFixed(4)})'
                          : dt('استخدام موقعي الحالي'),
                      style: TextStyle(
                        color: _pickupLat != null
                            ? primary
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
            key: ValueKey('pickup-map-$_pickupMapRevision'),
            selectedLatitude: _pickupLat,
            selectedLongitude: _pickupLng,
            cityName: widget.cityName,
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
                  style: TextStyle(
                    color: DarbColors.inkOf(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final created = await showAddressFormSheet(
                    context,
                    requireLocation: true,
                  );
                  if (created != null) {
                    setState(
                      () => _selectedAddressId = created['id']?.toString(),
                    );
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
            const DarbStateView.loading()
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
                    selected:
                        _addresses[i]['id']?.toString() == _selectedAddressId,
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
    final isDark = DarbColors.isDark(context);
    final primary = DarbColors.primaryOf(context);
    return DarbGlassSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            dt('ماذا تريد إرسال؟'),
            style: TextStyle(
              color: DarbColors.inkOf(context),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in _quickTypes)
                Builder(
                  builder: (ctx) {
                    final label = dt(item.$1);
                    final active = _itemTypeController.text.trim() == label;
                    return DarbPressScale(
                      borderRadius: DarbRadius.pill,
                      onTap: () {
                        DarbHaptics.selection();
                        setState(() => _itemTypeController.text = label);
                      },
                      child: AnimatedContainer(
                        duration: DarbMotion.effectiveDuration(
                          ctx,
                          DarbMotion.fast,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? (isDark ? DarbColors.lime : DarbColors.forest)
                              : DarbColors.softSurfaceOf(ctx),
                          borderRadius: BorderRadius.circular(DarbRadius.pill),
                          border: Border.all(
                            color: active
                                ? (isDark ? DarbColors.lime : DarbColors.forest)
                                : DarbColors.borderOf(ctx),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.$2,
                              size: 16,
                              color: active
                                  ? (isDark
                                      ? DarbColors.darkCanvas
                                      : Colors.white)
                                  : primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: TextStyle(
                                color: active
                                    ? (isDark
                                        ? DarbColors.darkCanvas
                                        : Colors.white)
                                    : DarbColors.inkOf(ctx),
                                fontSize: 12.5,
                                fontWeight:
                                    active ? FontWeight.w900 : FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),
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
    return DarbTicketPass(
      leadingIcon: Icons.route_rounded,
      title: dt('راجع طلبك'),
      subtitle: widget.cityName,
      status: 'PENDING',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DarbRouteConnector(
            pickupLabel: dt('موقع الاستلام'),
            pickupAddress: _pickupAddressController.text.trim(),
            dropoffLabel: dt('عنوان التسليم'),
            dropoffAddress:
                selectedAddr?['details']?.toString() ?? dt('لم يتم اختيار عنوان'),
            badgeText: _itemTypeController.text.trim(),
          ),
          const SizedBox(height: 14),
          _summaryRow(dt('نوع الغرض'), _itemTypeController.text.trim()),
          _summaryRow(dt('وصف الغرض'), _itemDescriptionController.text.trim()),
          if (_instructionsController.text.trim().isNotEmpty)
            _summaryRow(dt('تعليمات السائق'), _instructionsController.text.trim()),
        ],
      ),
      footer: Text(
        dt('بعد إرسال الطلب سيحدد السائقون أجورهم وفق مسافة التوصيل، وستختار العرض المناسب قبل تأكيد الطلب.'),
        style: TextStyle(
          color: DarbColors.mutedOf(context),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: DarbColors.mutedOf(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: DarbColors.inkOf(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}
