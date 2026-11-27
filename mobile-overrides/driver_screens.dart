part of 'app_shell.dart';

class DriverLocationReporter {
  static Timer? _timer;
  static bool _sending = false;
  static bool _refreshing = false;
  static bool _refreshRequested = false;
  static bool _enabled = false;
  static bool _observerRegistered = false;
  static int _generation = 0;

  static final WidgetsBindingObserver _lifecycleObserver =
      _DriverLocationLifecycleObserver();

  static void start() {
    _enabled = true;
    if (!_observerRegistered) {
      WidgetsBinding.instance.addObserver(_lifecycleObserver);
      _observerRegistered = true;
    }
    if (_timer != null || _refreshing) return;
    unawaited(refresh());
  }

  static Future<void> refresh() async {
    if (!_enabled) return;
    if (_refreshing) {
      _refreshRequested = true;
      return;
    }
    _refreshing = true;
    final generation = ++_generation;
    _timer?.cancel();
    _timer = null;
    try {
      final driver =
          Map<String, dynamic>.from(await Api.instance.get('/drivers/me'));
      if (generation != _generation ||
          driver['status'] != 'APPROVED' ||
          driver['isOnline'] != true) {
        return;
      }
      await _sendLocation();
      if (generation != _generation) return;
      _timer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _sendLocation(),
      );
    } catch (_) {
      _timer?.cancel();
      _timer = null;
    } finally {
      _refreshing = false;
      if (_refreshRequested && _enabled) {
        _refreshRequested = false;
        unawaited(refresh());
      }
    }
  }

  static void pause() {
    _generation++;
    _refreshRequested = false;
    _timer?.cancel();
    _timer = null;
  }

  static void stop() {
    _enabled = false;
    pause();
    if (_observerRegistered) {
      WidgetsBinding.instance.removeObserver(_lifecycleObserver);
      _observerRegistered = false;
    }
  }

  static Future<void> _sendLocation() async {
    if (!_enabled || _sending) return;
    _sending = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!_enabled) return;
      await Api.instance.patch('/drivers/location', {
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    } catch (_) {
      // Location failures must not interrupt the driver's order workflow.
    } finally {
      _sending = false;
    }
  }
}

class _DriverLocationLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(DriverLocationReporter.refresh());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      DriverLocationReporter.pause();
    }
  }
}

class DriverAvailable extends StatefulWidget {
  const DriverAvailable({super.key});
  @override
  State<DriverAvailable> createState() => _DriverAvailableState();
}

class _DriverAvailableState extends State<DriverAvailable> {
  bool loading = true, working = false;
  Map<String, dynamic>? driver;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      driver =
          Map<String, dynamic>.from(await Api.instance.get('/drivers/me'));
      error = null;
      DriverLocationReporter.start();
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _toggle(bool value) async {
    setState(() => working = true);
    try {
      driver = Map<String, dynamic>.from(
        await Api.instance.patch('/drivers/online', {'isOnline': value}),
      );
      error = null;
      DriverLocationReporter.refresh();
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: DazrevoErrorState(
          message: error!,
          onRetry: _load,
          retryLabel: dt('إعادة المحاولة'),
        ),
      );
    }

    final approved = driver?['status'] == 'APPROVED';
    final online = driver?['isOnline'] == true && approved;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
          child: Container(
            decoration: BoxDecoration(
              color: DarbColors.surface,
              borderRadius: BorderRadius.circular(DarbRadius.lg),
              border: Border.all(
                color: online
                    ? DarbColors.success.withValues(alpha: .45)
                    : DarbColors.line,
              ),
              boxShadow: DarbElevation.card,
            ),
            child: SwitchListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              activeTrackColor: DarbColors.success.withValues(alpha: .35),
              thumbColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? DarbColors.success
                    : null,
              ),
              secondary: DazrevoIconWell(
                icon: online ? Icons.radar_rounded : Icons.pause_circle_outline,
                iconColor: online ? DarbColors.success : DarbColors.muted,
              ),
              value: online,
              onChanged: !approved || working ? null : _toggle,
              title: Text(
                dt('متصل لاستلام الطلبات'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: DarbColors.ink,
                ),
              ),
              subtitle: Text(
                approved
                    ? dt('فعّل الحالة لتظهر لك الطلبات الجاهزة')
                    : dt('حساب السائق بانتظار اعتماد الإدارة'),
                style: TextStyle(color: DarbColors.muted, fontSize: 12),
              ),
            ),
          ),
        ),
        if (online)
          Expanded(
            child: _DataList(
              path: '/orders/driver/available',
              title: dt('طلبات جاهزة للاستلام'),
              empty: dt('لا توجد طلبات متاحة حالياً'),
              showFilters: false,
            ),
          )
        else
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: DazrevoEmptyState(
                  icon: Icons.delivery_dining_rounded,
                  title: dt('اتصل لاستقبال الطلبات بعد اعتماد حسابك'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class DriverOrders extends StatelessWidget {
  const DriverOrders({super.key});
  @override
  Widget build(BuildContext context) => _DataList(
        path: '/orders/driver/mine',
        title: dt('توصيلاتي'),
        empty: dt('لا توجد توصيلات حالياً'),
      );
}

enum _OrderFilter { all, active, completed }

class _DataList extends StatefulWidget {
  final String path, title, empty;
  final bool showFilters;
  const _DataList({
    required this.path,
    required this.title,
    required this.empty,
    this.showFilters = true,
  });
  @override
  State<_DataList> createState() => _DataListState();
}

class _DataListState extends State<_DataList> {
  bool loading = true;
  String? error;
  String? _workingOrderId;
  _OrderFilter _filter = _OrderFilter.all;
  List rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      rows = await Api.instance.get(widget.path) as List;
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List get _filteredRows {
    if (!widget.showFilters || _filter == _OrderFilter.all) return rows;
    return rows.where((r) {
      final st = r['status']?.toString() ?? '';
      final done = st == 'DELIVERED' || st == 'CANCELLED';
      return _filter == _OrderFilter.completed ? done : !done;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filteredRows;
    return RefreshIndicator(
      onRefresh: _load,
      color: DarbColors.accent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          DazrevoHeroSurface(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: DarbColors.ivory,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        loading
                            ? dt('جارٍ تحديث البيانات')
                            : error != null
                                ? dt('تعذر تحديث القائمة')
                                : dt('اسحب للأسفل لتحديث الطلبات'),
                        style: TextStyle(
                          color: DarbColors.ivory.withValues(alpha: .72),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: DarbColors.champagne.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: DarbColors.champagne.withValues(alpha: .32),
                    ),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: DarbColors.champagne,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          if (widget.showFilters && !loading && error == null && rows.isNotEmpty) ...[
            const SizedBox(height: 14),
            DazrevoChoiceSegment<_OrderFilter>(
              options: [
                (_OrderFilter.all, dt('الكل'), null),
                (_OrderFilter.active, dt('النشطة'), null),
                (_OrderFilter.completed, dt('المكتملة'), null),
              ],
              selected: _filter,
              onChanged: (next) => setState(() => _filter = next),
            ),
          ],
          const SizedBox(height: 16),
          if (loading)
            ...List.generate(
              3,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: DazrevoShimmerTile(height: 112),
              ),
            ),
          if (error != null)
            DazrevoErrorState(
              message: error!,
              onRetry: _load,
              retryLabel: dt('إعادة المحاولة'),
            ),
          if (!loading && error == null && visible.isEmpty)
            DazrevoEmptyState(
              icon: Icons.receipt_long_outlined,
              title: widget.empty,
            ),
          if (!loading && error == null)
            for (var index = 0; index < visible.length; index++)
              DarbFadeSlide(
                delay: DarbMotion.staggerDelay(index.clamp(0, 5).toInt()),
                child: _orderCard(visible[index]),
              ),
        ],
      ),
    );
  }

  String _statusLabel(String status, {required bool peer}) {
    switch (status) {
      case 'PENDING':
        return peer ? dt('بانتظار عروض السائقين') : dt('بانتظار التأكيد');
      case 'ACCEPTED':
        return dt('تم قبول الطلب');
      case 'PREPARING':
        return dt('قيد التحضير');
      case 'READY':
        return dt('جاهز للاستلام');
      case 'ASSIGNED':
        return dt('تم تعيين سائق');
      case 'PICKED_UP':
        return dt('تم استلام الطلب');
      case 'DELIVERED':
        return dt('تم التسليم');
      case 'CANCELLED':
        return dt('ملغي');
      default:
        return status;
    }
  }

  Widget _orderCard(dynamic row) {
    final id = row['id']?.toString() ?? '';
    final status = row['status']?.toString() ?? '';
    final peer = row['type'] == 'PEER_DELIVERY';
    final pickup = row['pickupAddress']?.toString();
    final destination =
        (row['address'] is Map) ? row['address']['details']?.toString() : null;
    final actions = <Widget>[];
    if (widget.path == '/orders/vendor') {
      if (status == 'PENDING') actions.add(_action(id, dt('قبول'), 'ACCEPTED'));
      if (status == 'ACCEPTED') {
        actions.add(_action(id, dt('بدء التحضير'), 'PREPARING'));
      }
      if (status == 'PREPARING') {
        actions.add(_action(id, dt('جاهز للاستلام'), 'READY'));
      }
    }
    if (widget.path == '/orders/driver/available' && !peer) {
      actions.add(
        FilledButton.icon(
          onPressed: _workingOrderId == null ? () => _claim(id) : null,
          icon: _workingOrderId == id
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: Text(dt('استلام الطلب')),
        ),
      );
    }
    if (widget.path == '/orders/driver/available' && peer) {
      actions.add(_DriverOfferAction(orderId: id, onSent: _load));
    }
    if (widget.path == '/orders/mine' &&
        (status == 'ASSIGNED' || status == 'PICKED_UP')) {
      actions.add(
        OutlinedButton.icon(
          onPressed: () => _track(id),
          icon: const Icon(Icons.location_on_outlined, size: 18),
          label: Text(dt('موقع السائق')),
        ),
      );
    }
    if (widget.path == '/orders/driver/mine') {
      if (status == 'ASSIGNED') {
        actions.add(_action(id, dt('تم الاستلام'), 'PICKED_UP'));
      }
      if (status == 'PICKED_UP') {
        actions.add(_action(id, dt('تم التسليم'), 'DELIVERED'));
      }
    }
    final statusColor = switch (status) {
      'DELIVERED' => DarbColors.success,
      'CANCELLED' => DarbColors.danger,
      'PENDING' => DarbColors.warning,
      _ => DarbColors.info,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DazrevoIconWell(
                  icon: peer
                      ? Icons.local_shipping_rounded
                      : Icons.shopping_bag_outlined,
                  iconColor: DarbColors.accent,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        peer
                            ? dt('طلب توصيل مستقل')
                            : '${dt('طلب')} ${row['orderNumber'] ?? id}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                          color: DarbColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${dt('رقم الطلب')}: ${row['orderNumber'] ?? id}',
                        style: TextStyle(color: DarbColors.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                DazrevoStatusTag(
                  label: _statusLabel(status, peer: peer),
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: DarbColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DarbColors.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      peer && row['deliveryFee'] == 0
                          ? dt('بانتظار عروض السائقين')
                          : dt('قيمة الطلب'),
                      style: TextStyle(color: DarbColors.muted, fontSize: 11.5),
                    ),
                  ),
                  Text(
                    '${row['total'] ?? ''} ${row['currency'] ?? ''}',
                    style: TextStyle(
                      color: DarbColors.brandForeground,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            if (peer && row['distanceKm'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Icon(Icons.route_rounded, size: 16, color: DarbColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      dt(
                        'مسافة التوصيل: ${(row['distanceKm'] as num).toStringAsFixed(1)} كم',
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: DarbColors.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            if (peer && (pickup != null || destination != null)) ...[
              const SizedBox(height: 12),
              DazrevoRouteTimeline(
                pickupTitle: dt('الاستلام'),
                pickupAddress: pickup ?? '—',
                dropoffTitle: dt('التسليم'),
                dropoffAddress: destination ?? '—',
              ),
            ],
            if (peer && widget.path == '/orders/mine' && status == 'PENDING')
              _CustomerDeliveryOffers(orderId: id, onSelected: _load),
            if (actions.isNotEmpty) ...[
              const Divider(height: 20),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ],
        ),
      ),
    );
  }

  Widget _action(String id, String label, String status) => FilledButton.tonal(
        onPressed:
            _workingOrderId == null ? () => _changeStatus(id, status) : null,
        child: _workingOrderId == id
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      );

  Future<void> _track(String id) async {
    try {
      final location = await Api.instance.get('/orders/$id/driver-location');
      if (location is! Map || location['available'] != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(dt('لم يشارك السائق موقعه بعد'))),
          );
        }
        return;
      }
      final lat = location['latitude'];
      final lng = location['longitude'];
      final uri =
          Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception(dt('تعذر فتح الخرائط'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _changeStatus(String id, String status) async {
    if (_workingOrderId != null) return;
    setState(() => _workingOrderId = id);
    try {
      await Api.instance.patch('/orders/$id/status', {'status': status});
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _workingOrderId = null);
    }
  }

  Future<void> _claim(String id) async {
    if (_workingOrderId != null) return;
    setState(() => _workingOrderId = id);
    try {
      await Api.instance.post('/orders/$id/claim', {});
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _workingOrderId = null);
    }
  }
}

class _DriverOfferAction extends StatelessWidget {
  final String orderId;
  final Future<void> Function() onSent;
  const _DriverOfferAction({required this.orderId, required this.onSent});

  Future<void> _offer(BuildContext context) async {
    final price = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dt('تقديم أجرة التوصيل')),
        content: TextField(
          controller: price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: dt('الأجرة بالليرة السورية الجديدة'),
            hintText: dt('أدخل المبلغ'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(dt('إلغاء')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(dt('إرسال العرض')),
          ),
        ],
      ),
    );
    final amount = double.tryParse(price.text.trim());
    price.dispose();
    if (ok != true || amount == null || amount <= 0) return;
    try {
      await Api.instance.post('/orders/$orderId/offers', {'amount': amount});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dt('تم إرسال عرضك للعميل'))),
        );
        await onSent();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: () => _offer(context),
        icon: const Icon(Icons.local_offer_outlined, size: 18),
        label: Text(dt('تحديد الأجرة')),
      );
}

class _CustomerDeliveryOffers extends StatefulWidget {
  final String orderId;
  final Future<void> Function() onSelected;
  const _CustomerDeliveryOffers({
    required this.orderId,
    required this.onSelected,
  });
  @override
  State<_CustomerDeliveryOffers> createState() =>
      _CustomerDeliveryOffersState();
}

class _CustomerDeliveryOffersState extends State<_CustomerDeliveryOffers> {
  bool loading = true, selecting = false;
  String? error;
  List offers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      offers =
          await Api.instance.get('/orders/${widget.orderId}/offers') as List;
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _select(dynamic offer) async {
    setState(() => selecting = true);
    try {
      await Api.instance.post(
        '/orders/${widget.orderId}/offers/${offer['id']}/select',
        {},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dt('تم اختيار السائق وتأكيد الأجرة'))),
        );
        await widget.onSelected();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => selecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return TextButton(
        onPressed: () {
          setState(() => loading = true);
          _load();
        },
        child: Text(dt('تعذر تحميل العروض: $error')),
      );
    }
    if (offers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: DarbColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  dt('بانتظار عروض السائقين.'),
                  style: TextStyle(color: DarbColors.muted, fontSize: 12),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() => loading = true);
                  _load();
                },
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: Text(dt('تحديث')),
              ),
            ],
          ),
        ),
      );
    }

    double? minAmount;
    for (final offer in offers) {
      final val = (offer['amount'] as num?)?.toDouble() ??
          double.tryParse(offer['amount']?.toString() ?? '');
      if (val != null && (minAmount == null || val < minAmount)) {
        minAmount = val;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                dt('عروض السائقين'),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: DarbColors.ink,
                ),
              ),
            ),
            IconButton(
              onPressed: selecting
                  ? null
                  : () {
                      setState(() => loading = true);
                      _load();
                    },
              tooltip: dt('تحديث العروض'),
              icon: const Icon(Icons.refresh_rounded, size: 19),
            ),
          ],
        ),
        for (final offer in offers)
          Builder(
            builder: (context) {
              final amt = (offer['amount'] as num?)?.toDouble() ??
                  double.tryParse(offer['amount']?.toString() ?? '');
              final isBest =
                  minAmount != null && amt != null && amt == minAmount && offers.length > 1;
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isBest
                      ? DarbColors.accent.withValues(alpha: .08)
                      : DarbColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isBest ? DarbColors.accent : DarbColors.line,
                  ),
                ),
                child: Row(
                  children: [
                    const DazrevoIconWell(
                      icon: Icons.delivery_dining_rounded,
                      size: 42,
                      radius: 12,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  offer['driver']?['user']?['name']?.toString() ??
                                      dt('سائق'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: DarbColors.ink,
                                  ),
                                ),
                              ),
                              if (isBest) ...[
                                const SizedBox(width: 6),
                                DazrevoStatusTag(
                                  label: dt('أنسب عرض'),
                                  color: DarbColors.success,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            offer['driver']?['vehicleType']?.toString() ??
                                dt('سائق معتمد'),
                            style:
                                TextStyle(color: DarbColors.muted, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${offer['amount']} ${offer['currency']}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: DarbColors.brandForeground,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 4),
                        FilledButton(
                          onPressed: selecting ? null : () => _select(offer),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(74, 34),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: Text(
                            dt('اختيار'),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
