part of 'app_shell.dart';

class PeerDeliveryScreen extends StatefulWidget {
  final String cityId;
  const PeerDeliveryScreen({super.key, required this.cityId});

  @override
  State<PeerDeliveryScreen> createState() => _PeerDeliveryScreenState();
}

class _PeerDeliveryScreenState extends State<PeerDeliveryScreen> {
  final pickup = TextEditingController();
  final itemType = TextEditingController();
  final itemDescription = TextEditingController();
  final driverInstructions = TextEditingController();

  List<Map<String, dynamic>> addresses = [];
  String? addressId;
  String? error;
  int step = 0;
  bool loading = true;
  bool sending = false;
  bool locating = false;
  bool savingAddress = false;
  Position? pickupPosition;

  List<String> get _stepTitles =>
      [dt('المواقع'), dt('تفاصيل الغرض'), dt('مراجعة الطلب')];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    pickup.dispose();
    itemType.dispose();
    itemDescription.dispose();
    driverInstructions.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final result = await Api.instance.get('/addresses') as List;
      addresses = result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (addressId == null ||
          !addresses.any((a) => a['id'].toString() == addressId)) {
        final located =
            addresses.where((a) => a['hasLocation'] == true).toList();
        addressId = located.isNotEmpty
            ? located.first['id'].toString()
            : (addresses.isNotEmpty ? addresses.first['id'].toString() : null);
      }
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception(dt('فعّل خدمة الموقع على الهاتف'));
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(dt('يلزم السماح بالوصول إلى الموقع'));
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  Future<void> _locatePickup() async {
    setState(() {
      locating = true;
      error = null;
    });
    try {
      pickupPosition = await _currentPosition();
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> _addAddress() async {
    final label = TextEditingController();
    final details = TextEditingController();
    Position? position;
    String? dialogError;
    bool locatingAddress = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(dt('إضافة عنوان تسليم')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: label,
                  decoration: InputDecoration(labelText: dt('اسم العنوان')),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: details,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: dt('العنوان بالتفصيل'),
                    hintText: dt('الحي، الشارع، البناء، أقرب نقطة دالة'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: locatingAddress
                        ? null
                        : () async {
                            setDialogState(() {
                              locatingAddress = true;
                              dialogError = null;
                            });
                            try {
                              position = await _currentPosition();
                            } catch (e) {
                              dialogError = e.toString();
                            } finally {
                              setDialogState(() => locatingAddress = false);
                            }
                          },
                    icon: Icon(
                      position == null
                          ? Icons.my_location_rounded
                          : Icons.check_circle_rounded,
                      color: position == null
                          ? DarbColors.brandForeground
                          : DarbColors.success,
                    ),
                    label: Text(
                      locatingAddress
                          ? dt('جارٍ تحديد الموقع...')
                          : position == null
                              ? dt('تحديد موقع العنوان')
                              : dt('تم تحديد الموقع'),
                    ),
                  ),
                ),
                if (position != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      dt('تم حفظ الإحداثيات لهذا العنوان'),
                      style: TextStyle(color: DarbColors.success, fontSize: 12),
                    ),
                  ),
                if (dialogError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      dialogError!,
                      style: TextStyle(color: DarbColors.danger, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  dt('يجب تحديد الموقع وأنت موجود في مكان التسليم نفسه.'),
                  style: TextStyle(color: DarbColors.muted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dt('إلغاء')),
            ),
            FilledButton(
              onPressed:
                  position == null ? null : () => Navigator.pop(dialogContext, true),
              child: Text(dt('حفظ العنوان')),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      if (details.text.trim().length < 3 || position == null) {
        if (mounted) {
          setState(() => error = dt('أكمل العنوان وحدد موقعه الجغرافي'));
        }
      } else {
        setState(() {
          savingAddress = true;
          error = null;
        });
        try {
          final created = await Api.instance.post('/addresses', {
            'label': label.text.trim(),
            'details': details.text.trim(),
            'latitude': position!.latitude,
            'longitude': position!.longitude,
          });
          final address = Map<String, dynamic>.from(created as Map);
          address['hasLocation'] = true;
          if (mounted) {
            setState(() {
              addresses.insert(0, address);
              addressId = address['id'].toString();
            });
          }
        } catch (e) {
          if (mounted) setState(() => error = e.toString());
        } finally {
          if (mounted) setState(() => savingAddress = false);
        }
      }
    }
    label.dispose();
    details.dispose();
  }

  Map<String, dynamic>? get _selectedAddress {
    for (final address in addresses) {
      if (address['id'].toString() == addressId) return address;
    }
    return null;
  }

  String _addressLabel(Map<String, dynamic>? address) {
    if (address == null) return dt('لم يتم اختيار عنوان');
    final label = (address['label'] ?? dt('عنوان التسليم')).toString().trim();
    final details = (address['details'] ?? '').toString().trim();
    if (label.isEmpty) return details;
    return details.isEmpty ? label : '$label — $details';
  }

  bool _validateCurrentStep() {
    setState(() => error = null);
    if (step == 0) {
      if (pickup.text.trim().length < 5) {
        setState(() => error = dt('اكتب وصفاً واضحاً لمكان الاستلام'));
        return false;
      }
      if (pickupPosition == null) {
        setState(() => error = dt('حدد موقع الاستلام أولاً'));
        return false;
      }
      final destination = _selectedAddress;
      if (destination == null || destination['hasLocation'] != true) {
        setState(
          () => error = dt(
            'اختر عنوان تسليم محفوظاً مع موقع جغرافي أو أضف عنواناً جديداً',
          ),
        );
        return false;
      }
    } else if (step == 1) {
      if (itemType.text.trim().length < 2) {
        setState(() => error = dt('اكتب نوع الغرض الذي تريد إرساله'));
        return false;
      }
      if (itemDescription.text.trim().length < 3) {
        setState(() => error = dt('أضف وصفاً مختصراً للغرض'));
        return false;
      }
    }
    return true;
  }

  void _next() {
    if (!_validateCurrentStep()) return;
    setState(() => step += 1);
  }

  void _back() {
    if (sending) return;
    if (step == 0) {
      Navigator.pop(context);
    } else {
      setState(() {
        step--;
        error = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!_validateCurrentStep()) return;
    final destination = _selectedAddress;
    if (destination == null || pickupPosition == null) return;

    final noteParts = <String>[
      dt('نوع الغرض: ${itemType.text.trim()}'),
      dt('وصف الغرض: ${itemDescription.text.trim()}'),
      if (driverInstructions.text.trim().isNotEmpty)
        dt('تعليمات للسائق: ${driverInstructions.text.trim()}'),
    ];

    setState(() {
      sending = true;
      error = null;
    });
    try {
      final order = await Api.instance.post('/orders/peer-delivery', {
        'cityId': widget.cityId,
        'addressId': addressId,
        'pickupAddress': pickup.text.trim(),
        'pickupLatitude': pickupPosition!.latitude,
        'pickupLongitude': pickupPosition!.longitude,
        'notes': noteParts.join('\n'),
      });
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(Icons.check_circle_rounded, color: DarbColors.success, size: 44),
          title: Text(dt('تم إرسال طلبك')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dt('رقم الطلب: ${order['orderNumber'] ?? order['id']}'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: DarbColors.brandForeground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dt(
                  'سيظهر طلبك للسائقين المتاحين في مدينتك. سيقدم كل سائق أجرته، ويمكنك مقارنة العروض واختيار الأنسب قبل تأكيد التوصيل.',
                ),
                style: TextStyle(color: DarbColors.muted, fontSize: 12.5, height: 1.5),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(dt('حسناً')),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Widget _progressHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DarbColors.surface,
        borderRadius: BorderRadius.circular(DarbRadius.lg),
        border: Border.all(color: DarbColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                dt('الخطوة ${step + 1} من 3'),
                style: TextStyle(
                  color: DarbColors.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _stepTitles[step],
                style: TextStyle(
                  color: DarbColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: AnimatedContainer(
                  duration: DarbMotion.effectiveDuration(
                    context,
                    DarbMotion.standard,
                  ),
                  height: 5,
                  margin: EdgeInsetsDirectional.only(end: index == 2 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: index <= step ? DarbColors.accent : DarbColors.line,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressCard(Map<String, dynamic> address) {
    final id = address['id'].toString();
    final selected = id == addressId;
    final hasLoc = address['hasLocation'] == true;
    final title = (address['label'] ?? '').toString().trim().isNotEmpty
        ? address['label'].toString()
        : dt('عنوان التسليم');
    final details = (address['details'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(DarbRadius.md),
        onTap: () => setState(() {
          addressId = id;
          error = null;
        }),
        child: AnimatedContainer(
          duration: DarbMotion.fast,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected
                ? DarbColors.accent.withValues(alpha: .08)
                : DarbColors.surface,
            borderRadius: BorderRadius.circular(DarbRadius.md),
            border: Border.all(
              color: selected ? DarbColors.accent : DarbColors.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? DarbColors.accent : DarbColors.muted,
                size: 20,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: DarbColors.ink,
                      ),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        details,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: DarbColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              DazrevoStatusTag(
                label: hasLoc ? dt('موقع محدد') : dt('الموقع غير محدد'),
                color: hasLoc ? DarbColors.success : DarbColors.danger,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepOne() {
    final selected = _selectedAddress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dt('من أين نستلم؟'),
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: DarbColors.ink,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          dt('حدد مكان وجود الغرض حتى يصل السائق إليك.'),
          style: TextStyle(color: DarbColors.muted, fontSize: 12.5),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: pickup,
          maxLines: 2,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: dt('وصف مكان الاستلام'),
            hintText: dt('مثلاً: أمام صيدلية الشفاء، شارع ...'),
            prefixIcon: const Icon(Icons.inventory_2_outlined),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: locating ? null : _locatePickup,
            icon: locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    pickupPosition == null
                        ? Icons.my_location_rounded
                        : Icons.check_circle_rounded,
                    color: pickupPosition == null
                        ? DarbColors.brandForeground
                        : DarbColors.success,
                  ),
            label: Text(
              locating
                  ? dt('جارٍ تحديد الموقع...')
                  : pickupPosition == null
                      ? dt('استخدام موقعي الحالي')
                      : dt('تم تحديد موقع الاستلام'),
            ),
          ),
        ),
        if (pickupPosition != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              dt(
                'تم تحديد الموقع بدقة: ${pickupPosition!.latitude.toStringAsFixed(4)}, ${pickupPosition!.longitude.toStringAsFixed(4)}',
              ),
              style: TextStyle(color: DarbColors.success, fontSize: 11.5),
            ),
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                dt('إلى أين نوصّل؟'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: DarbColors.ink,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: savingAddress ? null : _addAddress,
              icon: const Icon(Icons.add_location_alt_outlined, size: 18),
              label: Text(dt('إضافة عنوان')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (addresses.isEmpty)
          DazrevoEmptyState(
            icon: Icons.location_off_outlined,
            title: dt('لا يوجد عنوان تسليم محفوظ. أضف عنواناً وحدد موقعه للمتابعة.'),
            action: OutlinedButton.icon(
              onPressed: savingAddress ? null : _addAddress,
              icon: const Icon(Icons.add_location_alt_outlined, size: 17),
              label: Text(dt('إضافة عنوان')),
            ),
          )
        else
          for (final address in addresses) _addressCard(address),
        if (selected != null && selected['hasLocation'] != true)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              dt('هذا العنوان لا يحتوي على موقع. أضف عنواناً جديداً وحدد موقعه.'),
              style: TextStyle(color: DarbColors.danger, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _stepTwo() {
    final presets = [
      dt('مستندات'),
      dt('طرد صغير'),
      dt('مشتريات'),
      dt('إلكترونيات'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dt('ماذا تريد إرسال؟'),
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: DarbColors.ink,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          dt('أخبر السائق بنوع الغرض وحجمه بشكل واضح.'),
          style: TextStyle(color: DarbColors.muted, fontSize: 12.5),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((preset) {
            final selected = itemType.text.trim() == preset;
            return ChoiceChip(
              label: Text(preset, style: const TextStyle(fontSize: 12)),
              selected: selected,
              selectedColor: DarbColors.accent.withValues(alpha: .20),
              side: BorderSide(
                color: selected ? DarbColors.accent : DarbColors.line,
              ),
              onSelected: (_) => setState(() => itemType.text = preset),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: itemType,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: dt('نوع الغرض'),
            hintText: dt('مثلاً: مستندات، حقيبة، قطعة غيار'),
            prefixIcon: const Icon(Icons.category_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: itemDescription,
          minLines: 3,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: dt('وصف الغرض'),
            hintText: dt('اذكر الحجم أو أي تفاصيل تساعد السائق'),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: driverInstructions,
          minLines: 2,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: dt('تعليمات إضافية للسائق (اختياري)'),
            hintText: dt('وقت مناسب، شخص للتواصل عند الوصول...'),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: DarbColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: DarbColors.muted, fontSize: 11.5),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: DarbColors.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepThree() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dt('راجع طلبك'),
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: DarbColors.ink,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          dt('تأكد من التفاصيل قبل إرسال الطلب للسائقين.'),
          style: TextStyle(color: DarbColors.muted, fontSize: 12.5),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DarbColors.surface,
            borderRadius: BorderRadius.circular(DarbRadius.lg),
            border: Border.all(color: DarbColors.line),
          ),
          child: Column(
            children: [
              DazrevoRouteTimeline(
                pickupTitle: dt('موقع الاستلام'),
                pickupAddress: pickup.text.trim(),
                dropoffTitle: dt('عنوان التسليم'),
                dropoffAddress: _addressLabel(_selectedAddress),
              ),
              const Divider(height: 24),
              _summaryRow(
                Icons.inventory_2_outlined,
                dt('نوع الغرض'),
                itemType.text.trim(),
              ),
              const Divider(height: 1),
              _summaryRow(
                Icons.description_outlined,
                dt('الوصف'),
                itemDescription.text.trim(),
              ),
              if (driverInstructions.text.trim().isNotEmpty) ...[
                const Divider(height: 1),
                _summaryRow(
                  Icons.notes_rounded,
                  dt('تعليمات السائق'),
                  driverInstructions.text.trim(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DarbColors.accent.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(DarbRadius.md),
            border: Border.all(
              color: DarbColors.accent.withValues(alpha: .28),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.payments_outlined, color: DarbColors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dt(
                    'بعد إرسال الطلب سيحدد السائقون أجورهم وفق مسافة التوصيل، وستختار العرض المناسب قبل تأكيد الطلب.',
                  ),
                  style: TextStyle(
                    color: DarbColors.ink,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: DarbColors.canvas,
      appBar: AppBar(
        title: Text(dt('توصيل مستقل')),
        leading: IconButton(
          tooltip: dt('رجوع'),
          onPressed: _back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                      children: [
                        _progressHeader(),
                        const SizedBox(height: 22),
                        AnimatedSwitcher(
                          duration: DarbMotion.effectiveDuration(
                            context,
                            DarbMotion.standard,
                          ),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: KeyedSubtree(
                            key: ValueKey(step),
                            child: step == 0
                                ? _stepOne()
                                : step == 1
                                    ? _stepTwo()
                                    : _stepThree(),
                          ),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: DarbColors.danger.withValues(alpha: .09),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: DarbColors.danger.withValues(alpha: .28),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: DarbColors.danger,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    error!,
                                    style: TextStyle(
                                      color: DarbColors.danger,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                    decoration: BoxDecoration(
                      color: DarbColors.surface,
                      border: Border(top: BorderSide(color: DarbColors.line)),
                    ),
                    child: Row(
                      children: [
                        if (step > 0) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: sending ? null : _back,
                              child: Text(dt('السابق')),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          flex: step == 0 ? 1 : 2,
                          child: FilledButton(
                            onPressed: sending || savingAddress
                                ? null
                                : (step == 2 ? _submit : _next),
                            child: sending
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: isDark
                                          ? DarbColors.obsidian
                                          : DarbColors.ivory,
                                    ),
                                  )
                                : Text(
                                    step == 2
                                        ? dt('تأكيد وإرسال الطلب')
                                        : dt('متابعة'),
                                  ),
                          ),
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
