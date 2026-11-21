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
  LatLng? pickupPoint;

  List<String> get _stepTitles => [dt('المواقع'), dt('تفاصيل الغرض'), dt('مراجعة الطلب')];

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
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final result = await Api.instance.get('/addresses') as List;
      addresses = result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (addressId == null || !addresses.any((a) => a['id'].toString() == addressId)) {
        final located = addresses.where((a) => a['hasLocation'] == true).toList();
        addressId = located.isNotEmpty ? located.first['id'].toString() : null;
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
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  Future<void> _locatePickup() async {
    setState(() { locating = true; error = null; });
    try {
      pickupPosition = await _currentPosition();
      pickupPoint = LatLng(pickupPosition!.latitude, pickupPosition!.longitude);
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> _addAddress() async {
    final label = TextEditingController();
    final details = TextEditingController();
    LatLng? position;
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
                SizedBox(height: 10),
                TextField(
                  controller: details,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: dt('العنوان بالتفصيل'),
                    hintText: dt('الحي، الشارع، البناء، أقرب نقطة دالة'),
                  ),
                ),
                SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: locatingAddress ? null : () async {
                      setDialogState(() { locatingAddress = true; dialogError = null; });
                      try {
                        final current = await _currentPosition();
                        position = LatLng(current.latitude, current.longitude);
                      } catch (e) {
                        dialogError = e.toString();
                      } finally {
                        setDialogState(() => locatingAddress = false);
                      }
                    },
                    icon: locatingAddress
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.my_location),
                    label: Text(locatingAddress ? dt('جارٍ تحديد الموقع...') : dt('استخدام موقعي')),
                  ),
                ),
                DarbMapPicker(
                  key: ValueKey('address-${position?.latitude}-${position?.longitude}'),
                  selectedPoint: position,
                  height: 230,
                  onPointSelected: (point) => setDialogState(() {
                    position = point;
                    dialogError = null;
                  }),
                ),
                if (position != null)
                  Text(
                    dt('الإحداثيات: ${position!.latitude.toStringAsFixed(5)}, ${position!.longitude.toStringAsFixed(5)}'),
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: DarbColors.muted, fontSize: 11),
                  ),
                if (position != null)
                  Text(dt('تم حفظ الإحداثيات لهذا العنوان'),
                    style: TextStyle(color: DarbColors.forest, fontSize: 12),
                  ),
                if (dialogError != null)
                  Text(dialogError!, style: TextStyle(color: DarbColors.danger)),
                SizedBox(height: 6),
                Text(dt('يجب تحديد الموقع وأنت موجود في مكان التسليم نفسه.'),
                  style: TextStyle(color: DarbColors.muted, fontSize: 12),
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
              onPressed: position == null ? null : () => Navigator.pop(dialogContext, true),
              child: Text(dt('حفظ العنوان')),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      if (details.text.trim().length < 3 || position == null) {
        if (mounted) setState(() => error = dt('أكمل العنوان وحدد موقعه الجغرافي'));
      } else {
        setState(() { savingAddress = true; error = null; });
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
    final label = (address['label'] ?? dt('عنوان التسليم')).toString();
    final details = (address['details'] ?? '').toString();
    return details.isEmpty ? label : '$label — $details';
  }

  bool _validateCurrentStep() {
    setState(() => error = null);
    if (step == 0) {
      if (pickup.text.trim().length < 5) {
        setState(() => error = dt('اكتب وصفاً واضحاً لمكان الاستلام'));
        return false;
      }
      if (pickupPoint == null) {
        setState(() => error = dt('حدد موقع الاستلام أولاً'));
        return false;
      }
      final destination = _selectedAddress;
      if (destination == null || destination['hasLocation'] != true) {
        setState(() => error = dt('اختر عنوان تسليم محفوظاً مع موقع جغرافي أو أضف عنواناً جديداً'));
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
      setState(() { step--; error = null; });
    }
  }

  Future<void> _submit() async {
    if (!_validateCurrentStep()) return;
    final destination = _selectedAddress;
    if (destination == null || pickupPoint == null) return;

    final noteParts = <String>[
      dt('نوع الغرض: ${itemType.text.trim()}'),
      dt('وصف الغرض: ${itemDescription.text.trim()}'),
      if (driverInstructions.text.trim().isNotEmpty)
        dt('تعليمات للسائق: ${driverInstructions.text.trim()}'),
    ];

    setState(() { sending = true; error = null; });
    try {
      final order = await Api.instance.post('/orders/peer-delivery', {
        'cityId': widget.cityId,
        'addressId': addressId,
        'pickupAddress': pickup.text.trim(),
        'pickupLatitude': pickupPoint!.latitude,
        'pickupLongitude': pickupPoint!.longitude,
        'notes': noteParts.join('\n'),
      });
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(Icons.check_circle, color: DarbColors.forest, size: 42),
          title: Text(dt('تم إرسال طلبك')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dt('رقم الطلب: ${order['orderNumber'] ?? order['id']}')),
              SizedBox(height: 8),
              Text(dt('سيظهر طلبك للسائقين المتاحين في مدينتك. سيقدم كل سائق أجرته، ويمكنك مقارنة العروض واختيار الأنسب قبل تأكيد التوصيل.')),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              dt('الخطوة ${step + 1} من 3'),
              style: TextStyle(color: DarbColors.muted, fontSize: 12, fontWeight: FontWeight.w700),
            ),
            Spacer(),
            Text(
              _stepTitles[step],
              style: TextStyle(color: DarbColors.forest, fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: List.generate(3, (index) => Expanded(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 260),
              height: 5,
              margin: EdgeInsetsDirectional.only(end: index == 2 ? 0 : 6),
              decoration: BoxDecoration(
                color: index <= step ? DarbColors.forest : DarbColors.line,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          )),
        ),
      ],
    );
  }

  Widget _stepOne() {
    final selected = _selectedAddress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(dt('من أين نستلم؟'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: DarbColors.ink)),
        SizedBox(height: 6),
        Text(dt('حدد مكان وجود الغرض حتى يصل السائق إليك.'), style: TextStyle(color: DarbColors.muted)),
        SizedBox(height: 18),
        TextField(
          controller: pickup,
          maxLines: 2,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: dt('وصف مكان الاستلام'),
            hintText: dt('مثلاً: أمام صيدلية الشفاء، شارع ...'),
            prefixIcon: Icon(Icons.inventory_2_outlined),
          ),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(dt('اختر نقطة الاستلام على الخريطة'), style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            TextButton.icon(
              onPressed: locating ? null : _locatePickup,
              icon: locating
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.my_location),
              label: Text(dt('موقعي')),
            ),
          ],
        ),
        DarbMapPicker(
          key: ValueKey('pickup-${pickupPoint?.latitude}-${pickupPoint?.longitude}'),
          selectedPoint: pickupPoint,
          onPointSelected: (point) => setState(() {
            pickupPoint = point;
            pickupPosition = null;
            error = null;
          }),
        ),
        if (pickupPoint != null)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              dt('إحداثيات الاستلام: ${pickupPoint!.latitude.toStringAsFixed(5)}, ${pickupPoint!.longitude.toStringAsFixed(5)}'),
              textDirection: TextDirection.ltr,
              style: TextStyle(color: DarbColors.muted, fontSize: 11),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(dt('المس الخريطة لتحديد مكان الاستلام بدقة.'), style: TextStyle(color: DarbColors.muted, fontSize: 12)),
          ),
        SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Text(dt('إلى أين نوصّل؟'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
            TextButton.icon(
              onPressed: savingAddress ? null : _addAddress,
              icon: Icon(Icons.add_location_alt_outlined),
              label: Text(dt('إضافة عنوان')),
            ),
          ],
        ),
        if (addresses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DarbColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: DarbColors.line),
            ),
            child: Text(dt('لا يوجد عنوان تسليم محفوظ. أضف عنواناً وحدد موقعه للمتابعة.'), style: TextStyle(color: DarbColors.muted)),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: addressId,
            isExpanded: true,
            decoration: InputDecoration(prefixIcon: Icon(Icons.location_on_outlined)),
            items: [
              for (final address in addresses)
                DropdownMenuItem(
                  value: address['id'].toString(),
                  child: Text(
                    _addressLabel(address),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) => setState(() => addressId = value),
          ),
        if (selected != null && selected['hasLocation'] != true)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(dt('هذا العنوان لا يحتوي على موقع. أضف عنواناً جديداً وحدد موقعه.'), style: TextStyle(color: DarbColors.danger, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _stepTwo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(dt('ماذا تريد إرسال؟'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: DarbColors.ink)),
        SizedBox(height: 6),
        Text(dt('أخبر السائق بنوع الغرض وحجمه بشكل واضح.'), style: TextStyle(color: DarbColors.muted)),
        SizedBox(height: 20),
        TextField(
          controller: itemType,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: dt('نوع الغرض'),
            hintText: dt('مثلاً: مستندات، حقيبة، قطعة غيار'),
            prefixIcon: Icon(Icons.category_outlined),
          ),
        ),
        SizedBox(height: 14),
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
        SizedBox(height: 14),
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
          Icon(icon, color: DarbColors.forest, size: 21),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: DarbColors.muted, fontSize: 12)),
                SizedBox(height: 3),
                Text(value, style: TextStyle(color: DarbColors.ink, fontSize: 14, fontWeight: FontWeight.w700)),
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
        Text(dt('راجع طلبك'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: DarbColors.ink)),
        SizedBox(height: 6),
        Text(dt('تأكد من التفاصيل قبل إرسال الطلب للسائقين.'), style: TextStyle(color: DarbColors.muted)),
        SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: DarbColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DarbColors.line),
          ),
          child: Column(
            children: [
              _summaryRow(Icons.trip_origin, dt('موقع الاستلام'), pickup.text.trim()),
              Divider(height: 1),
              _summaryRow(Icons.location_on_outlined, dt('عنوان التسليم'), _addressLabel(_selectedAddress)),
              Divider(height: 1),
              _summaryRow(Icons.inventory_2_outlined, dt('نوع الغرض'), itemType.text.trim()),
              Divider(height: 1),
              _summaryRow(Icons.description_outlined, dt('الوصف'), itemDescription.text.trim()),
              if (driverInstructions.text.trim().isNotEmpty) ...[
                Divider(height: 1),
                _summaryRow(Icons.notes_rounded, dt('تعليمات السائق'), driverInstructions.text.trim()),
              ],
            ],
          ),
        ),
        SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DarbColors.mint.withValues(alpha: .35),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.payments_outlined, color: DarbColors.forest),
              SizedBox(width: 10),
              Expanded(
                child: Text(dt('بعد إرسال الطلب سيحدد السائقون أجورهم وفق مسافة التوصيل، وستختار العرض المناسب قبل تأكيد الطلب.'),
                  style: TextStyle(color: DarbColors.forest, fontSize: 12, height: 1.5),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(dt('توصيل مستقل')),
        leading: IconButton(
          tooltip: dt('رجوع'),
          onPressed: _back,
          icon: Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                      children: [
                        _progressHeader(),
                        SizedBox(height: 28),
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: KeyedSubtree(
                            key: ValueKey(step),
                            child: step == 0 ? _stepOne() : step == 1 ? _stepTwo() : _stepThree(),
                          ),
                        ),
                        if (error != null) ...[
                          SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: DarbColors.danger.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.error_outline, color: DarbColors.danger, size: 20),
                                SizedBox(width: 8),
                                Expanded(child: Text(error!, style: TextStyle(color: DarbColors.danger, fontSize: 12))),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
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
                          SizedBox(width: 10),
                        ],
                        Expanded(
                          flex: step == 0 ? 1 : 2,
                          child: FilledButton(
                            onPressed: sending || savingAddress
                                ? null
                                : step == 2 ? _submit : _next,
                            child: sending
                                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(step == 2 ? dt('تأكيد وإرسال الطلب') : dt('متابعة')),
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


/// OpenStreetMap-based point selector. It selects coordinates only; it does not
/// claim to provide routing, navigation, or reverse geocoding.
class DarbMapPicker extends StatelessWidget {
  final LatLng? selectedPoint;
  final ValueChanged<LatLng> onPointSelected;
  final double height;

  const DarbMapPicker({
    super.key,
    required this.selectedPoint,
    required this.onPointSelected,
    this.height = 250,
  });

  static const LatLng _syriaCenter = LatLng(35.0, 38.5);

  @override
  Widget build(BuildContext context) {
    final center = selectedPoint ?? _syriaCenter;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: selectedPoint == null ? 6.0 : 15.0,
                minZoom: 4,
                maxZoom: 19,
                onTap: (tapPosition, point) => onPointSelected(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.darb.darb',
                  maxZoom: 19,
                ),
                if (selectedPoint != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: selectedPoint!,
                        width: 48,
                        height: 56,
                        child: Icon(
                          Icons.location_pin,
                          size: 48,
                          color: DarbColors.danger,
                          shadows: const [Shadow(color: Colors.white, blurRadius: 5)],
                        ),
                      ),
                    ],
                  ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ],
                  alignment: AttributionAlignment.bottomRight,
                ),
              ],
            ),
            Positioned(
              top: 10,
              left: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: DarbColors.surface.withValues(alpha: .94),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  child: Text(
                    dt('المس الخريطة لتحديد النقطة'),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DarbColors.ink),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
