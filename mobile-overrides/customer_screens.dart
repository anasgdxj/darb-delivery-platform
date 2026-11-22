part of 'app_shell.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});
  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  final search = TextEditingController();
  final storesKey = GlobalKey();
  bool loading = true;
  String? error;
  List<dynamic> cities = [], vendors = [];
  String? cityId;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    darbLocale.addListener(_onLocaleChanged);
    search.addListener(() { if (mounted) setState(() {}); });
    _load();
  }

  void _onLocaleChanged() => _load();

  @override
  void dispose() {
    darbLocale.removeListener(_onLocaleChanged);
    search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final loadedCities = await Api.instance.get('/cities') as List;
      if (generation != _loadGeneration) return;
      cities = loadedCities;
      if (cities.isNotEmpty) {
        cityId ??= cities.first['id'].toString();
        final locale = darbLocale.value.languageCode;
        final loadedVendors = await Api.instance.get(
          '/vendors?cityId=$cityId&locale=$locale',
        ) as List;
        if (generation != _loadGeneration) return;
        vendors = loadedVendors;
      } else {
        cityId = null;
        vendors = [];
      }
    } catch (e) {
      if (generation == _loadGeneration) error = e.toString();
    } finally {
      if (mounted && generation == _loadGeneration) {
        setState(() => loading = false);
      }
    }
  }

  String _cityName(dynamic city) {
    final names = city['names'] as List? ?? [];
    final locale = darbLocale.value.languageCode;
    for (final item in names) {
      if (item is Map && item['locale'] == locale) return item['name'].toString();
    }
    for (final item in names) {
      if (item is Map && item['locale'] == 'ar') return item['name'].toString();
    }
    return names.isEmpty ? city['code'].toString() : names.first['name'].toString();
  }

  String _vendorName(dynamic vendor) {
    final translations = vendor['translations'] as List? ?? [];
    final locale = darbLocale.value.languageCode;
    for (final item in translations) {
      if (item is Map && item['locale'] == locale) return item['name'].toString();
    }
    for (final item in translations) {
      if (item is Map && item['locale'] == 'ar') return item['name'].toString();
    }
    return translations.isEmpty ? dt('متجر') : translations.first['name']?.toString() ?? dt('متجر');
  }

  void _openPeerDelivery() {
    if (cityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dt('لا توجد مدينة مفعّلة لخدمة التوصيل حالياً'))),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PeerDeliveryScreen(cityId: cityId!),
    ));
  }

  void _openAiOrderAssistant() {
    if (cityId == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => AiOrderAssistantScreen(cityId: cityId!),
    ));
  }

  void _openStores() {
    final target = storesKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      alignment: .04,
    );
  }

  Widget _sectionTitle(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: ink)),
      SizedBox(height: 4),
      Text(subtitle, style: TextStyle(fontSize: 12, color: DarbColors.muted, height: 1.45)),
    ],
  );

  Widget _serviceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    final foreground = primary ? Colors.white : ink;
    return DarbGlassMaterial(
      color: primary ? DarbColors.forestSoft : DarbColors.surface,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: primary ? Colors.transparent : DarbColors.line),
          ),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: primary ? Colors.white.withValues(alpha: .12) : DarbColors.surfaceAlt,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: primary ? DarbColors.mint : DarbColors.brandForeground, size: 23),
            ),
            SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: foreground, fontSize: 14, fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text(subtitle, style: TextStyle(
                  color: primary ? Colors.white.withValues(alpha: .72) : DarbColors.muted,
                  fontSize: 11, height: 1.4,
                )),
              ],
            )),
            Icon(Icons.arrow_forward_ios_rounded, size: 15,
              color: primary ? Colors.white70 : DarbColors.muted),
          ]),
        ),
      ),
    );
  }

  Widget _storeTile(dynamic vendor) {
    final name = _vendorName(vendor);
    final count = vendor['_count']?['products'] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DarbGlassMaterial(
        color: DarbColors.surface,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => VendorCatalog(
              vendorId: vendor['id'].toString(),
              name: name,
              cityId: cityId ?? '',
            ),
          )),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: DarbColors.line),
            ),
            child: Row(children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  color: DarbColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.storefront_rounded, color: green, size: 25),
              ),
              SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w900)),
                  SizedBox(height: 5),
                  Text(dt('$count منتج متاح'),
                    style: TextStyle(color: DarbColors.muted, fontSize: 11)),
                ],
              )),
              Icon(Icons.chevron_left_rounded, color: green, size: 23),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final visibleVendors = vendors.where(
      (v) => _vendorName(v).toLowerCase().contains(query),
    ).toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: green,
      child: ListView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: DarbColors.surfaceAlt,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.location_on_rounded, color: green, size: 20),
            ),
            SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dt('موقع التوصيل'), style: TextStyle(color: DarbColors.muted, fontSize: 10)),
                SizedBox(height: 2),
                if (cities.isNotEmpty)
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isDense: true,
                      value: cityId,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: green),
                      style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w900),
                      items: [for (final c in cities)
                        DropdownMenuItem(value: c['id'].toString(), child: Text(_cityName(c)))],
                      onChanged: (value) async {
                        if (value == null || value == cityId) return;
                        setState(() => cityId = value);
                        await _load();
                      },
                    ),
                  )
                else
                  Text(dt('المدينة غير متاحة'), style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w800)),
              ],
            )),
            IconButton(
              tooltip: dt('تحديث'),
              onPressed: _load,
              icon: Icon(Icons.refresh_rounded, color: DarbColors.muted),
            ),
          ]),
          SizedBox(height: 17),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF285647), Color(0xFF102B26), Color(0xFF091D19)],
              ),
              borderRadius: BorderRadius.circular(27),
              boxShadow: [
                BoxShadow(color: Color(0x1D102B26), blurRadius: 22, offset: Offset(0, 10)),
              ],
            ),
            child: Stack(children: [
              Positioned(left: -48, top: -64, child: Container(
                width: 190, height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: .07), width: 27),
                ),
              )),
              Positioned(left: 28, bottom: -95, child: Container(
                width: 175, height: 175,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .035),
                ),
              )),
              Padding(
                padding: const EdgeInsets.fromLTRB(21, 22, 21, 21),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.route_rounded, color: DarbColors.mint, size: 14),
                      SizedBox(width: 6),
                      Text(dt('خدمة التوصيل المستقل'),
                        style: TextStyle(color: DarbColors.onForest, fontSize: 10, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                  SizedBox(height: 17),
                  Text(dt('من بابك إلى وجهتك،\\nدَرْب يتولى الطريق.'),
                    style: TextStyle(
                      color: DarbColors.onForest, fontSize: 27, height: 1.22,
                      fontWeight: FontWeight.w900, letterSpacing: -.35,
                    )),
                  SizedBox(height: 8),
                  Text(dt('أرسل غرضك بسهولة، واستقبل عروض السائقين واختر الأجرة المناسبة لك.'),
                    style: TextStyle(color: Color(0xFFD0DED7), fontSize: 12, height: 1.55)),
                  SizedBox(height: 19),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: cityId == null ? null : _openPeerDelivery,
                      style: FilledButton.styleFrom(
                        backgroundColor: DarbColors.mint,
                        foregroundColor: ink,
                        minimumSize: Size(0, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.near_me_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(dt('ابدأ طلب توصيل'), style: TextStyle(fontWeight: FontWeight.w900)),
                      ]),
                    ),
                  ),
                  SizedBox(height: 11),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.verified_user_outlined, color: Color(0xFFB9D4C5), size: 13),
                    SizedBox(width: 5),
                    Text(dt('قارن عروض السائقين قبل اختيار الأجرة'),
                      style: TextStyle(color: Color(0xFFB9D4C5), fontSize: 10, fontWeight: FontWeight.w600)),
                  ]),
                ]),
              ),
            ]),
          ),
          SizedBox(height: 22),
          _sectionTitle(dt('كيف تريد استخدام دَرْب؟'), dt('اختر المسار الذي يناسب احتياجك')),
          SizedBox(height: 12),
          DarbFadeSlide(
            delay: DarbMotion.staggerDelay(0),
            child: _serviceCard(
            icon: Icons.inventory_2_outlined,
            title: dt('إرسال غرض مستقل'),
            subtitle: dt('أرسل طرداً أو غرضاً من أي عنوان إلى آخر'),
            onTap: _openPeerDelivery,
            primary: true,
          )),
          SizedBox(height: 9),
          DarbFadeSlide(
            delay: DarbMotion.staggerDelay(1),
            child: _serviceCard(
            icon: Icons.auto_awesome_rounded,
            title: dt('اطلب بمساعدة الذكاء الاصطناعي'),
            subtitle: dt('اكتب طلبك باللهجة التي تستخدمها ودع دَرْب يحوله إلى مسودة للمراجعة'),
            onTap: _openAiOrderAssistant,
          )),
          SizedBox(height: 9),
          DarbFadeSlide(
            delay: DarbMotion.staggerDelay(2),
            child: _serviceCard(
            icon: Icons.storefront_outlined,
            title: dt('الطلب من المتاجر'),
            subtitle: dt('تصفح المتاجر والمنتجات واطلب إلى بابك'),
            onTap: _openStores,
          )),
          SizedBox(height: 25),
          Container(key: storesKey),
          _sectionTitle(dt('متاجر مدينتك'), dt('تصفح المتاجر المتاحة وابدأ طلبك')),
          SizedBox(height: 12),
          TextField(
            controller: search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: dt('ابحث عن متجر أو نشاط...'),
              prefixIcon: Icon(Icons.search_rounded, color: green),
              suffixIcon: search.text.isEmpty ? null : IconButton(
                onPressed: search.clear,
                icon: Icon(Icons.close_rounded),
              ),
              filled: true,
              fillColor: DarbColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: DarbColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: DarbColors.primary, width: 1.4),
              ),
            ),
          ),
          SizedBox(height: 13),
          if (loading)
            ...List.generate(3, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                height: 78,
                decoration: BoxDecoration(
                  color: DarbColors.surface,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: DarbColors.line),
                ),
                child: Center(child: LinearProgressIndicator(minHeight: 2)),
              ),
            ))
          else if (error != null)
            _ErrorPanel(message: error!, retry: _load)
          else if (visibleVendors.isEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              decoration: BoxDecoration(
                color: DarbColors.surface,
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: DarbColors.line),
              ),
              child: Column(children: [
                Container(
                  width: 55, height: 55,
                  decoration: BoxDecoration(
                    color: DarbColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(Icons.storefront_outlined, color: green, size: 27),
                ),
                SizedBox(height: 12),
                Text(
                  query.isEmpty ? dt('لا توجد متاجر متاحة في هذه المدينة') : dt('لم نعثر على نتائج مطابقة'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 14),
                ),
                SizedBox(height: 6),
                Text(dt('يمكنك استخدام خدمة التوصيل المستقل حتى عندما لا تتوفر متاجر في مدينتك.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: DarbColors.muted, fontSize: 11, height: 1.5),
                ),
                SizedBox(height: 13),
                OutlinedButton.icon(
                  onPressed: _openPeerDelivery,
                  icon: Icon(Icons.near_me_rounded, size: 17),
                  label: Text(dt('إنشاء طلب توصيل مستقل')),
                ),
              ]),
            )
          else
            ...List.generate(visibleVendors.length, (index) => DarbFadeSlide(
              delay: DarbMotion.staggerDelay(index.clamp(0, 5).toInt()),
              child: _storeTile(visibleVendors[index]),
            )),
        ],
      ),
    );
  }
}


class AiOrderAssistantScreen extends StatefulWidget {
  final String cityId;
  const AiOrderAssistantScreen({super.key, required this.cityId});
  @override
  State<AiOrderAssistantScreen> createState() => _AiOrderAssistantScreenState();
}

class _AiOrderAssistantScreenState extends State<AiOrderAssistantScreen> {
  final _text = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _draft;

  @override
  void dispose() { _text.dispose(); super.dispose(); }

  Future<void> _analyze() async {
    final value = _text.text.trim();
    if (value.length < 5 || value.length > 3000) {
      setState(() => _error = dt('اكتب طلباً بين 5 و3000 محرف'));
      return;
    }
    setState(() { _loading = true; _error = null; _draft = null; });
    try {
      final result = await Api.instance.post('/ai/order-assistant/drafts/text', {
        'cityId': widget.cityId, 'text': value,
      });
      if (result is! Map) throw const ApiException('استجابة المساعد غير صالحة');
      if (mounted) setState(() => _draft = Map<String, dynamic>.from(result));
    } catch (_) {
      if (mounted) {
        setState(() => _error = dt('تعذر تحليل الطلب حالياً. تحقق من اتصال الإنترنت ثم أعد المحاولة.'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _intentLabel(String? intent) {
    switch (intent) {
      case 'STORE_ORDER': return dt('طلب من متجر');
      case 'PEER_DELIVERY': return dt('توصيل غرض مستقل');
      default: return dt('يحتاج إلى توضيح');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (_draft?['items'] as List?) ?? const [];
    final warnings = (_draft?['warnings'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(dt('مساعد دَرْب الذكي')),
        backgroundColor: DarbColors.primary, foregroundColor: DarbColors.onPrimary),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight, end: Alignment.bottomLeft,
                colors: [DarbColors.forestSoft, DarbColors.forest]),
              borderRadius: BorderRadius.circular(24)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.auto_awesome_rounded, color: DarbColors.mint, size: 28),
              const SizedBox(height: 12),
              Text(dt('احكِ طلبك بطريقتك'), style: const TextStyle(
                color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              Text(dt('اكتب باللهجة السورية أو العربية. سيستخرج المساعد نوع الطلب والمنتجات والعنوان، ثم يعرضها عليك للمراجعة.'),
                style: TextStyle(color: Colors.white.withValues(alpha: .78), height: 1.55, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 18),
          TextField(controller: _text, minLines: 5, maxLines: 8,
            maxLength: 3000, textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              labelText: dt('اكتب طلبك هنا'),
              hintText: dt('مثال: بدي كيلو موز وحليب، والتوصيل على عنواني...'),
              alignLabelWithHint: true, filled: true, fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)))),
          const SizedBox(height: 10),
          SizedBox(height: 52, child: FilledButton.icon(
            onPressed: _loading ? null : _analyze,
            icon: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.auto_awesome_rounded),
            label: Text(_loading ? dt('جارٍ تحليل طلبك...') : dt('حلّل الطلب')))),
          if (_error != null) ...[
            const SizedBox(height: 14),
            _ErrorPanel(message: _error!, retry: _analyze),
          ],
          if (_draft != null) ...[
            const SizedBox(height: 22),
            Text(dt('مسودة طلبك'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Card(child: Padding(padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_intentLabel(_draft?['intent']?.toString()),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 6),
                Text('الحالة: ${_draft?['status'] ?? 'غير محددة'}',
                  style: TextStyle(color: DarbColors.muted, fontSize: 12)),
                if ((_draft?['transcript'] ?? '').toString().isNotEmpty) ...[
                  const Divider(height: 22), Text(_draft!['transcript'].toString())],
                if (items.isNotEmpty) ...[
                  const Divider(height: 22),
                  Text(dt('العناصر المستخرجة'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  for (final item in items)
                    if (item is Map) ListTile(contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.inventory_2_outlined, color: DarbColors.brandForeground),
                      title: Text(item['rawName']?.toString() ?? dt('عنصر')),
                      subtitle: Text('الكمية: ${item['quantity'] ?? 1} ${item['unit'] ?? ''}'),
                      trailing: item['productId'] == null
                        ? Icon(Icons.help_outline_rounded, color: DarbColors.warning)
                        : Icon(Icons.check_circle_rounded, color: DarbColors.success)),
                ],
                if (warnings.isNotEmpty) ...[
                  const Divider(height: 22),
                  Text(dt('يحتاج إلى مراجعتك'), style: TextStyle(fontWeight: FontWeight.w800, color: DarbColors.warning)),
                  for (final warning in warnings)
                    Padding(padding: const EdgeInsets.only(top: 7),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.info_outline_rounded, size: 17, color: DarbColors.warning),
                        const SizedBox(width: 7), Expanded(child: Text(warning.toString(), style: const TextStyle(fontSize: 12)))])),
                ],
                const SizedBox(height: 12),
                Text(dt('هذه مسودة فقط. لم يتم إنشاء طلب أو حجز منتجات أو تثبيت عنوان.'),
                  style: TextStyle(color: DarbColors.muted, fontSize: 11, height: 1.5)),
              ]))),
          ],
        ],
      ),
    );
  }
}
