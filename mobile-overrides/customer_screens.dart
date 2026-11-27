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
    search.addListener(() {
      if (mounted) setState(() {});
    });
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
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
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
      if (item is Map && item['locale'] == locale) {
        return item['name'].toString();
      }
    }
    for (final item in names) {
      if (item is Map && item['locale'] == 'ar') return item['name'].toString();
    }
    return names.isEmpty
        ? city['code'].toString()
        : names.first['name'].toString();
  }

  String _vendorName(dynamic vendor) {
    final translations = vendor['translations'] as List? ?? [];
    final locale = darbLocale.value.languageCode;
    for (final item in translations) {
      if (item is Map && item['locale'] == locale) {
        return item['name'].toString();
      }
    }
    for (final item in translations) {
      if (item is Map && item['locale'] == 'ar') {
        return item['name'].toString();
      }
    }
    return translations.isEmpty
        ? dt('متجر')
        : translations.first['name']?.toString() ?? dt('متجر');
  }

  void _openPeerDelivery() {
    if (cityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dt('لا توجد مدينة مفعّلة لخدمة التوصيل حالياً')),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PeerDeliveryScreen(cityId: cityId!),
      ),
    );
  }

  void _openAiOrderAssistant() {
    if (cityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dt('لا توجد مدينة مفعّلة لخدمة التوصيل حالياً')),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiOrderAssistantScreen(cityId: cityId!),
      ),
    );
  }

  void _openStores() {
    final target = storesKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
      alignment: .04,
    );
  }

  Widget _serviceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = highlight
        ? (isDark ? DarbColors.charcoalSoft : DarbColors.charcoal)
        : DarbColors.surface;
    final fg = highlight ? DarbColors.ivory : DarbColors.ink;
    final subFg = highlight
        ? DarbColors.ivory.withValues(alpha: .74)
        : DarbColors.muted;
    final borderColor = highlight
        ? DarbColors.champagne.withValues(alpha: .30)
        : DarbColors.line;

    return DarbPressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(DarbRadius.lg),
          border: Border.all(color: borderColor),
          boxShadow: DarbElevation.card,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: highlight
                    ? DarbColors.champagne.withValues(alpha: .16)
                    : DarbColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: highlight
                      ? DarbColors.champagne.withValues(alpha: .32)
                      : DarbColors.line,
                ),
              ),
              child: Icon(
                icon,
                color: highlight
                    ? DarbColors.champagne
                    : DarbColors.brandForeground,
                size: 22,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: fg,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: subFg,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: highlight ? DarbColors.champagne : DarbColors.muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _storeTile(dynamic vendor) {
    final name = _vendorName(vendor);
    final count = vendor['_count']?['products'] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DarbPressScale(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VendorCatalog(
              vendorId: vendor['id'].toString(),
              name: name,
              cityId: cityId ?? '',
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DarbColors.surface,
            borderRadius: BorderRadius.circular(DarbRadius.lg),
            border: Border.all(color: DarbColors.line),
            boxShadow: DarbElevation.card,
          ),
          child: Row(
            children: [
              const DazrevoIconWell(
                icon: Icons.storefront_rounded,
                size: 52,
                radius: 15,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: DarbColors.ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dt('$count منتج متاح'),
                      style: TextStyle(
                        color: DarbColors.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: DarbColors.accent,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final visibleVendors = vendors
        .where((v) => _vendorName(v).toLowerCase().contains(query))
        .toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: DarbColors.accent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: DarbColors.surface,
              borderRadius: BorderRadius.circular(DarbRadius.md),
              border: Border.all(color: DarbColors.line),
            ),
            child: Row(
              children: [
                DazrevoIconWell(
                  icon: Icons.location_on_rounded,
                  size: 36,
                  radius: 10,
                  iconColor: DarbColors.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dt('موقع التوصيل'),
                        style: TextStyle(color: DarbColors.muted, fontSize: 10.5),
                      ),
                      const SizedBox(height: 1),
                      if (cities.isNotEmpty)
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isDense: true,
                            value: cityId,
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: DarbColors.accent,
                            ),
                            dropdownColor: DarbColors.surface,
                            style: TextStyle(
                              color: DarbColors.ink,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                            items: [
                              for (final c in cities)
                                DropdownMenuItem(
                                  value: c['id'].toString(),
                                  child: Text(_cityName(c)),
                                ),
                            ],
                            onChanged: (value) async {
                              if (value == null || value == cityId) return;
                              setState(() => cityId = value);
                              await _load();
                            },
                          ),
                        )
                      else
                        Text(
                          dt('المدينة غير متاحة'),
                          style: TextStyle(
                            color: DarbColors.ink,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: dt('تحديث'),
                  onPressed: _load,
                  icon: Icon(Icons.refresh_rounded, color: DarbColors.muted, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DazrevoHeroSurface(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            borderRadius: DarbRadius.xl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: DarbColors.champagne.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: DarbColors.champagne.withValues(alpha: .32),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.route_rounded,
                        color: DarbColors.champagne,
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dt('خدمة التوصيل المستقل'),
                        style: TextStyle(
                          color: DarbColors.champagne,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  dt('من بابك إلى وجهتك،\nDAZREVO يتولى الطريق.'),
                  style: TextStyle(
                    color: DarbColors.ivory,
                    fontSize: 25,
                    height: 1.24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dt('أرسل غرضك بسهولة، واستقبل عروض السائقين واختر الأجرة المناسبة لك.'),
                  style: TextStyle(
                    color: DarbColors.ivory.withValues(alpha: .74),
                    fontSize: 12.5,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: cityId == null ? null : _openPeerDelivery,
                        style: FilledButton.styleFrom(
                          backgroundColor: DarbColors.champagne,
                          foregroundColor: DarbColors.obsidian,
                          minimumSize: const Size(0, 50),
                        ),
                        icon: const Icon(Icons.near_me_rounded, size: 18),
                        label: Text(
                          dt('ابدأ طلب توصيل'),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Tooltip(
                      message: dt('اطلب بمساعدة الذكاء الاصطناعي'),
                      child: IconButton(
                        onPressed: cityId == null ? null : _openAiOrderAssistant,
                        style: IconButton.styleFrom(
                          backgroundColor: DarbColors.ivory.withValues(alpha: .10),
                          foregroundColor: DarbColors.champagne,
                          fixedSize: const Size(50, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DarbRadius.md),
                            side: BorderSide(
                              color: DarbColors.champagne.withValues(alpha: .32),
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: DarbColors.champagne.withValues(alpha: .82),
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dt('قارن عروض السائقين قبل اختيار الأجرة'),
                      style: TextStyle(
                        color: DarbColors.ivory.withValues(alpha: .70),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          DazrevoSectionHeader(
            title: dt('كيف تريد استخدام DAZREVO؟'),
            subtitle: dt('اختر المسار الذي يناسب احتياجك'),
          ),
          const SizedBox(height: 12),
          DarbFadeSlide(
            delay: DarbMotion.staggerDelay(0),
            child: _serviceCard(
              icon: Icons.inventory_2_outlined,
              title: dt('إرسال غرض مستقل'),
              subtitle: dt('أرسل طرداً أو غرضاً من أي عنوان إلى آخر'),
              onTap: _openPeerDelivery,
              highlight: true,
            ),
          ),
          const SizedBox(height: 10),
          DarbFadeSlide(
            delay: DarbMotion.staggerDelay(1),
            child: _serviceCard(
              icon: Icons.auto_awesome_rounded,
              title: dt('اطلب بمساعدة الذكاء الاصطناعي'),
              subtitle: dt(
                'اكتب طلبك باللهجة التي تستخدمها ودع DAZREVO يحوله إلى مسودة للمراجعة',
              ),
              onTap: _openAiOrderAssistant,
            ),
          ),
          const SizedBox(height: 10),
          DarbFadeSlide(
            delay: DarbMotion.staggerDelay(2),
            child: _serviceCard(
              icon: Icons.storefront_outlined,
              title: dt('الطلب من المتاجر'),
              subtitle: dt('تصفح المتاجر والمنتجات واطلب إلى بابك'),
              onTap: _openStores,
            ),
          ),
          const SizedBox(height: 26),
          Container(key: storesKey),
          DazrevoSectionHeader(
            title: dt('متاجر مدينتك'),
            subtitle: dt('تصفح المتاجر المتاحة وابدأ طلبك'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: dt('ابحث عن متجر أو نشاط...'),
              prefixIcon: Icon(Icons.search_rounded, color: DarbColors.accent),
              suffixIcon: search.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: search.clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          if (loading)
            ...List.generate(
              3,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: DazrevoShimmerTile(height: 80),
              ),
            )
          else if (error != null)
            DazrevoErrorState(
              message: error!,
              onRetry: _load,
              retryLabel: dt('إعادة المحاولة'),
            )
          else if (visibleVendors.isEmpty)
            DazrevoEmptyState(
              icon: Icons.storefront_outlined,
              title: query.isEmpty
                  ? dt('لا توجد متاجر متاحة في هذه المدينة')
                  : dt('لم نعثر على نتائج مطابقة'),
              subtitle: dt(
                'يمكنك استخدام خدمة التوصيل المستقل حتى عندما لا تتوفر متاجر في مدينتك.',
              ),
              action: OutlinedButton.icon(
                onPressed: _openPeerDelivery,
                icon: const Icon(Icons.near_me_rounded, size: 17),
                label: Text(dt('إنشاء طلب توصيل مستقل')),
              ),
            )
          else
            ...List.generate(
              visibleVendors.length,
              (index) => DarbFadeSlide(
                delay: DarbMotion.staggerDelay(index.clamp(0, 5).toInt()),
                child: _storeTile(visibleVendors[index]),
              ),
            ),
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
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final value = _text.text.trim();
    if (value.length < 5 || value.length > 3000) {
      setState(() => _error = dt('اكتب طلباً بين 5 و3000 محرف'));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _draft = null;
    });
    try {
      final result = await Api.instance.post('/ai/order-assistant/drafts/text', {
        'cityId': widget.cityId,
        'text': value,
      });
      if (result is! Map) {
        throw const ApiException('استجابة المساعد غير صالحة');
      }
      if (mounted) setState(() => _draft = Map<String, dynamic>.from(result));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = dt(
            'تعذر تحليل الطلب حالياً. تحقق من اتصال الإنترنت ثم أعد المحاولة.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _intentLabel(String? intent) {
    switch (intent) {
      case 'STORE_ORDER':
        return dt('طلب من متجر');
      case 'PEER_DELIVERY':
        return dt('توصيل غرض مستقل');
      default:
        return dt('يحتاج إلى توضيح');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (_draft?['items'] as List?) ?? const [];
    final warnings = (_draft?['warnings'] as List?) ?? const [];
    final quickPrompts = [
      dt('بدي ٢ كيلو تفاح وعلبة حليب على عنوان البيت'),
      dt('إرسال ظرف مستندات من الساحة إلى المكتب'),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: DarbColors.canvas,
      appBar: AppBar(title: Text(dt('مساعد DAZREVO الذكي'))),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          DazrevoHeroSurface(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: DarbColors.champagne,
                  size: 28,
                ),
                const SizedBox(height: 12),
                Text(
                  dt('احكِ طلبك بطريقتك'),
                  style: TextStyle(
                    color: DarbColors.ivory,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  dt(
                    'اكتب باللهجة السورية أو العربية. سيستخرج المساعد نوع الطلب والمنتجات والعنوان، ثم يعرضها عليك للمراجعة.',
                  ),
                  style: TextStyle(
                    color: DarbColors.ivory.withValues(alpha: .76),
                    height: 1.55,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            dt('جرب مثالاً سريعاً'),
            style: TextStyle(
              color: DarbColors.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickPrompts
                .map(
                  (sample) => ActionChip(
                    label: Text(sample, style: const TextStyle(fontSize: 11.5)),
                    backgroundColor: DarbColors.surface,
                    side: BorderSide(color: DarbColors.line),
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                              _text.text = sample;
                              _error = null;
                            }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _text,
            minLines: 4,
            maxLines: 8,
            maxLength: 3000,
            decoration: InputDecoration(
              labelText: dt('اكتب طلبك هنا'),
              hintText: dt('مثال: بدي كيلو موز وحليب، والتوصيل على عنواني...'),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _loading ? null : _analyze,
              icon: _loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? DarbColors.obsidian : DarbColors.ivory,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                _loading ? dt('جارٍ تحليل طلبك...') : dt('حلّل الطلب'),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            DazrevoErrorState(
              message: _error!,
              onRetry: _analyze,
              retryLabel: dt('إعادة المحاولة'),
            ),
          ],
          if (_draft != null) ...[
            const SizedBox(height: 22),
            DazrevoSectionHeader(title: dt('مسودة طلبك')),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _intentLabel(_draft?['intent']?.toString()),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: DarbColors.ink,
                            ),
                          ),
                        ),
                        DazrevoStatusTag(
                          label: (_draft?['status'] ?? dt('غير محددة')).toString(),
                          color: DarbColors.accent,
                        ),
                      ],
                    ),
                    if ((_draft?['transcript'] ?? '').toString().isNotEmpty) ...[
                      const Divider(height: 22),
                      Text(
                        _draft!['transcript'].toString(),
                        style: TextStyle(color: DarbColors.ink, height: 1.5),
                      ),
                    ],
                    if (items.isNotEmpty) ...[
                      const Divider(height: 22),
                      Text(
                        dt('العناصر المستخرجة'),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: DarbColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final item in items)
                        if (item is Map)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const DazrevoIconWell(
                              icon: Icons.inventory_2_outlined,
                              size: 40,
                              radius: 11,
                            ),
                            title: Text(
                              item['rawName']?.toString() ?? dt('عنصر'),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: DarbColors.ink,
                              ),
                            ),
                            subtitle: Text(
                              '${dt('الكمية')}: ${item['quantity'] ?? 1} ${item['unit'] ?? ''}',
                              style: TextStyle(color: DarbColors.muted),
                            ),
                            trailing: item['productId'] == null
                                ? Icon(
                                    Icons.help_outline_rounded,
                                    color: DarbColors.warning,
                                  )
                                : Icon(
                                    Icons.check_circle_rounded,
                                    color: DarbColors.success,
                                  ),
                          ),
                    ],
                    if (warnings.isNotEmpty) ...[
                      const Divider(height: 22),
                      Text(
                        dt('يحتاج إلى مراجعتك'),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: DarbColors.warning,
                        ),
                      ),
                      for (final warning in warnings)
                        Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 17,
                                color: DarbColors.warning,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  warning.toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: DarbColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      dt(
                        'هذه مسودة فقط. لم يتم إنشاء طلب أو حجز منتجات أو تثبيت عنوان.',
                      ),
                      style: TextStyle(
                        color: DarbColors.muted,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
