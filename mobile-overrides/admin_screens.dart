part of 'app_shell.dart';

class AdminQueue extends StatefulWidget {
  final String kind;
  const AdminQueue({super.key, required this.kind});
  @override
  State<AdminQueue> createState() => _AdminQueueState();
}

class _AdminQueueState extends State<AdminQueue> {
  bool loading = true, working = false;
  String? error;
  List rows = [];

  String get endpoint => widget.kind == 'vendors'
      ? '/admin/vendors/pending'
      : '/admin/drivers/pending';

  String get heading => widget.kind == 'vendors'
      ? dt('طلبات انضمام المتاجر')
      : dt('طلبات انضمام السائقين');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      rows = await Api.instance.get(endpoint) as List;
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _setStatus(String id, String status) async {
    setState(() => working = true);
    try {
      await Api.instance
          .patch('/admin/${widget.kind}/$id/status', {'status': status});
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: _load,
        color: DarbColors.accent,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          children: [
            DazrevoSectionHeader(
              title: heading,
              trailing: rows.isEmpty
                  ? null
                  : DazrevoStatusTag(
                      label: '${rows.length}',
                      color: DarbColors.accent,
                    ),
            ),
            const SizedBox(height: 14),
            if (loading)
              ...List.generate(
                3,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: DazrevoShimmerTile(height: 120),
                ),
              ),
            if (error != null)
              DazrevoErrorState(
                message: error!,
                onRetry: _load,
                retryLabel: dt('إعادة المحاولة'),
              ),
            if (!loading && error == null && rows.isEmpty)
              DazrevoEmptyState(
                icon: widget.kind == 'vendors'
                    ? Icons.storefront_outlined
                    : Icons.delivery_dining_rounded,
                title: dt('لا توجد طلبات معلّقة حالياً'),
              ),
            for (var index = 0; index < rows.length; index++)
              DarbFadeSlide(
                delay: DarbMotion.staggerDelay(index.clamp(0, 5).toInt()),
                child: _requestCard(rows[index]),
              ),
          ],
        ),
      );

  Widget _requestCard(dynamic row) {
    final user = row['user'] as Map? ?? {};
    final translations = row['translations'] as List? ?? [];
    final title = widget.kind == 'vendors'
        ? (translations.isEmpty
            ? dt('متجر جديد')
            : translations.first['name']?.toString() ?? dt('متجر جديد'))
        : user['name']?.toString() ?? dt('سائق جديد');
    final cityData = row['city'];
    final city = widget.kind == 'drivers' && cityData is Map
        ? cityData['code']?.toString() ?? ''
        : '';
    final detail = widget.kind == 'vendors'
        ? row['type']?.toString() ?? ''
        : row['vehicleType']?.toString() ?? '';
    final id = row['id'].toString();
    final metaParts = <String>[
      if (detail.isNotEmpty) detail,
      if (city.isNotEmpty) city,
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DazrevoIconWell(
                  icon: widget.kind == 'vendors'
                      ? Icons.storefront_rounded
                      : Icons.delivery_dining_rounded,
                  iconColor: DarbColors.accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: DarbColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user['phone']?.toString() ?? '',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(color: DarbColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                DazrevoStatusTag(
                  label: dt('قيد المراجعة'),
                  color: DarbColors.warning,
                ),
              ],
            ),
            if (metaParts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: DarbColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: DarbColors.line),
                ),
                child: Text(
                  metaParts.join(' • '),
                  style: TextStyle(
                    color: DarbColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: working ? null : () => _setStatus(id, 'APPROVED'),
                    child: Text(dt('اعتماد الطلب')),
                  ),
                ),
                const SizedBox(width: 9),
                OutlinedButton(
                  onPressed: working
                      ? null
                      : () => _setStatus(
                            id,
                            widget.kind == 'vendors' ? 'REJECTED' : 'SUSPENDED',
                          ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DarbColors.danger,
                    side: BorderSide(color: DarbColors.danger),
                  ),
                  child: Text(
                    widget.kind == 'vendors' ? dt('رفض') : dt('تعليق'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdminDeliveryZones extends StatefulWidget {
  const AdminDeliveryZones({super.key});
  @override
  State<AdminDeliveryZones> createState() => _AdminDeliveryZonesState();
}

class _AdminDeliveryZonesState extends State<AdminDeliveryZones> {
  bool loading = true, working = false;
  String? error;
  List zones = [], cities = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final values = await Future.wait([
        Api.instance.get('/admin/delivery-zones'),
        Api.instance.get('/cities'),
      ]);
      zones = values[0] as List;
      cities = values[1] as List;
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _cityName(Map city) {
    final names = city['names'] as List? ?? [];
    final locale = darbLocale.value.languageCode;
    for (final item in names) {
      if (item is Map && item['locale'] == locale) {
        return item['name'].toString();
      }
    }
    for (final item in names) {
      if (item is Map && item['locale'] == 'ar') return item['name'].toString();
    }
    return names.isNotEmpty
        ? names.first['name'].toString()
        : city['code'].toString();
  }

  Future<void> _edit([Map? zone]) async {
    final selectableCities = zone == null
        ? cities.where((c) => !zones.any((z) => z['cityId'] == c['id'])).toList()
        : cities;
    if (selectableCities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dt('لا توجد مدن أخرى تحتاج إلى إعداد رسوم'))),
      );
      return;
    }
    final name = TextEditingController(text: zone?['name']?.toString() ?? '');
    final base =
        TextEditingController(text: zone?['feeBase']?.toString() ?? '');
    final perKm =
        TextEditingController(text: zone?['feePerKm']?.toString() ?? '');
    String cityId =
        zone?['cityId']?.toString() ?? selectableCities.first['id'].toString();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(
            zone == null
                ? dt('إضافة منطقة توصيل')
                : dt('تعديل رسوم التوصيل'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (zone == null) ...[
                  DropdownButtonFormField<String>(
                    value: cityId,
                    decoration: InputDecoration(labelText: dt('المدينة')),
                    items: [
                      for (final c in selectableCities)
                        DropdownMenuItem(
                          value: c['id'].toString(),
                          child: Text(_cityName(c as Map)),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialog(() => cityId = v);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                TextField(
                  controller: name,
                  decoration: InputDecoration(labelText: dt('وصف إعداد الرسوم')),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: base,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: dt('الرسم الأساسي (ل.س)'),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: perKm,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: dt('الرسم لكل كيلومتر (ل.س)'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(dt('إلغاء')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(dt('حفظ')),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      final feeBase = double.tryParse(base.text),
          feePerKm = double.tryParse(perKm.text);
      if (name.text.trim().isEmpty ||
          feeBase == null ||
          feePerKm == null ||
          feeBase < 0 ||
          feePerKm < 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(dt('أدخل اسمًا ورسومًا رقمية غير سالبة'))),
          );
        }
      } else {
        setState(() => working = true);
        try {
          final body = {
            'name': name.text.trim(),
            'feeBase': feeBase,
            'feePerKm': feePerKm,
            if (zone == null) 'cityId': cityId,
          };
          if (zone == null) {
            await Api.instance.post('/admin/delivery-zones', body);
          } else {
            await Api.instance
                .patch('/admin/delivery-zones/${zone['id']}', body);
          }
          await _load();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(e.toString())));
          }
        } finally {
          if (mounted) setState(() => working = false);
        }
      }
    }
    name.dispose();
    base.dispose();
    perKm.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: DarbColors.canvas,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: working ? null : () => _edit(),
          icon: const Icon(Icons.add_rounded),
          label: Text(dt('إضافة رسوم لمدينة')),
        ),
        body: loading
            ? ListView(
                padding: const EdgeInsets.all(18),
                children: List.generate(
                  3,
                  (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: DazrevoShimmerTile(height: 86),
                  ),
                ),
              )
            : error != null
                ? Padding(
                    padding: const EdgeInsets.all(18),
                    child: DazrevoErrorState(
                      message: dt('تعذر تحميل المناطق: $error'),
                      onRetry: _load,
                      retryLabel: dt('إعادة المحاولة'),
                    ),
                  )
                : zones.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: DazrevoEmptyState(
                            icon: Icons.payments_outlined,
                            title: dt('لم تُضف رسوم توصيل بعد'),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: DarbColors.accent,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 86),
                          children: [
                            DazrevoSectionHeader(
                              title: dt('إعداد رسوم التوصيل'),
                              subtitle: dt(
                                'يُضبط رسم واحد لكل مدينة. احتساب رسم الكيلومتر يتطلب تحديد موقع المتجر وموقع عنوان العميل.',
                              ),
                            ),
                            const SizedBox(height: 16),
                            for (final zone in zones)
                              Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  leading: DazrevoIconWell(
                                    icon: Icons.payments_outlined,
                                    iconColor: DarbColors.accent,
                                  ),
                                  title: Text(
                                    zone['name']?.toString() ?? dt('منطقة'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: DarbColors.ink,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      dt(
                                        'رسوم المنطقة: ${zone['feeBase']} ل.س • لكل كم: ${zone['feePerKm']} ل.س',
                                      ),
                                      style: TextStyle(
                                        color: DarbColors.muted,
                                        fontSize: 12,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                                  trailing: IconButton(
                                    onPressed: working
                                        ? null
                                        : () => _edit(zone as Map),
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      color: DarbColors.accent,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
      );
}
