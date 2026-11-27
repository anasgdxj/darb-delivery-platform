part of 'app_shell.dart';

class AccountPage extends StatefulWidget {
  final Map<String, dynamic>? me;
  final VoidCallback onLogout;

  const AccountPage({
    super.key,
    required this.me,
    required this.onLogout,
  });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late Map<String, dynamic>? profile = widget.me;
  bool saving = false;
  bool applying = false;

  String get _name => profile?['name']?.toString().trim() ?? '';
  String get _email => profile?['email']?.toString().trim() ?? '';
  String get _phone => profile?['phone']?.toString().trim() ?? '';
  String get _role => profile?['role']?.toString() ?? 'CUSTOMER';

  String get _roleLabel {
    switch (_role) {
      case 'ADMIN':
        return dt('إدارة DAZREVO');
      case 'DRIVER':
        return dt('حساب سائق');
      case 'VENDOR':
        return dt('حساب تاجر');
      default:
        return dt('حساب عميل');
    }
  }

  Future<void> _openLanguageSettings() async {
    final updated = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => LanguageSelectionPage(
          initialLocale: darbLocale.value.languageCode,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => profile = Map<String, dynamic>.from(updated));
    }
  }

  Future<void> _edit() async {
    final name = TextEditingController(text: _name);
    var locale = profile?['locale']?.toString() ?? 'ar';

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(dt('تعديل الملف الشخصي')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                maxLength: 120,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: dt('الاسم'),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: locale,
                decoration: InputDecoration(
                  labelText: dt('لغة التطبيق'),
                  prefixIcon: const Icon(Icons.language_rounded),
                ),
                items: [
                  DropdownMenuItem(value: 'ar', child: Text(dt('العربية'))),
                  const DropdownMenuItem(value: 'en', child: Text('English')),
                  const DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => locale = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dt('إلغاء')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(dt('حفظ التغييرات')),
            ),
          ],
        ),
      ),
    );

    if (ok == true && mounted) {
      setState(() => saving = true);
      try {
        final updated = await Api.instance.patch('/auth/me', {
          'name': name.text.trim(),
          'locale': locale,
        });
        if (!mounted) return;
        setState(() => profile = Map<String, dynamic>.from(updated));
        darbLocale.value = Locale(locale);
        _showMessage(dt('تم تحديث بيانات حسابك'));
      } catch (error) {
        if (mounted) {
          _showMessage(dt('تعذر حفظ التغييرات: $error'), isError: true);
        }
      } finally {
        if (mounted) setState(() => saving = false);
      }
    }
    name.dispose();
  }

  Future<void> _apply(bool vendor) async {
    if (applying) return;
    setState(() => applying = true);

    try {
      final response = await Api.instance.get('/cities');
      if (response is! List) {
        throw FormatException(dt('تعذر قراءة قائمة المدن'));
      }
      final cities = response;
      if (!mounted) return;
      if (cities.isEmpty) {
        _showMessage(dt('لا توجد مدن مفعّلة حالياً'), isError: true);
        return;
      }

      var cityId = cities.first['id'].toString();
      final storeName = TextEditingController();
      final activity = TextEditingController();
      final address = TextEditingController();
      double? latitude;
      double? longitude;
      var locationSelected = false;

      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title:
                Text(vendor ? dt('طلب انضمام متجر') : dt('طلب انضمام سائق')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (vendor) ...[
                    TextField(
                      controller: storeName,
                      decoration: InputDecoration(
                        labelText: dt('اسم المتجر'),
                        prefixIcon: const Icon(Icons.storefront_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: activity,
                      decoration: InputDecoration(
                        labelText: dt('نوع النشاط'),
                        prefixIcon: const Icon(Icons.category_outlined),
                      ),
                    ),
                  ] else
                    TextField(
                      controller: activity,
                      decoration: InputDecoration(
                        labelText: dt('نوع المركبة (اختياري)'),
                        prefixIcon: const Icon(Icons.two_wheeler_outlined),
                      ),
                    ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: cityId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: dt('المدينة'),
                      prefixIcon: const Icon(Icons.location_city_outlined),
                    ),
                    items: [
                      for (final city in cities)
                        DropdownMenuItem<String>(
                          value: city['id'].toString(),
                          child: Text(
                            (city['names'] as List? ?? []).isEmpty
                                ? city['code'].toString()
                                : (city['names'] as List)
                                    .first['name']
                                    .toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => cityId = value);
                      }
                    },
                  ),
                  if (vendor) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: address,
                      decoration: InputDecoration(
                        labelText: dt('عنوان المتجر (اختياري)'),
                        prefixIcon: const Icon(Icons.place_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            if (!await Geolocator.isLocationServiceEnabled()) {
                              throw Exception(dt('فعّل خدمة الموقع أولاً'));
                            }
                            var permission = await Geolocator.checkPermission();
                            if (permission == LocationPermission.denied) {
                              permission = await Geolocator.requestPermission();
                            }
                            if (permission == LocationPermission.denied ||
                                permission == LocationPermission.deniedForever) {
                              throw Exception(dt('لم يتم منح إذن الموقع'));
                            }
                            final point = await Geolocator.getCurrentPosition();
                            latitude = point.latitude;
                            longitude = point.longitude;
                            setDialogState(() => locationSelected = true);
                          } catch (error) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            }
                          }
                        },
                        icon: Icon(
                          locationSelected
                              ? Icons.check_circle_rounded
                              : Icons.my_location_rounded,
                        ),
                        label: Text(
                          locationSelected
                              ? dt('تم تحديد موقع المتجر')
                              : dt('تحديد موقع المتجر'),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(dt('إلغاء')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(dt('إرسال الطلب')),
              ),
            ],
          ),
        ),
      );

      if (accepted == true && mounted) {
        try {
          await Api.instance.post(
            vendor ? '/vendors/apply' : '/drivers/apply',
            vendor
                ? {
                    'name': storeName.text.trim(),
                    'type': activity.text.trim(),
                    'cityId': cityId,
                    'address': address.text.trim(),
                    if (latitude != null && longitude != null) ...{
                      'latitude': latitude,
                      'longitude': longitude,
                    },
                  }
                : {
                    'cityId': cityId,
                    'vehicleType': activity.text.trim(),
                  },
          );
          final fresh = await Api.instance.get('/auth/me');
          if (!mounted) return;
          setState(() => profile = Map<String, dynamic>.from(fresh));
          _showMessage(
            dt('تم إرسال الطلب. ستراجع الإدارة بياناتك قبل تفعيل الصلاحيات.'),
          );
        } catch (error) {
          if (mounted) {
            _showMessage(dt('تعذر إرسال الطلب: $error'), isError: true);
          }
        }
      }

      storeName.dispose();
      activity.dispose();
      address.dispose();
    } catch (error) {
      if (mounted) {
        _showMessage(dt('تعذر تحميل المدن: $error'), isError: true);
      }
    } finally {
      if (mounted) setState(() => applying = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.logout_rounded, color: DarbColors.danger),
        title: Text(dt('تسجيل الخروج؟')),
        content: Text(dt('ستحتاج إلى تسجيل الدخول مجدداً للوصول إلى حسابك.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dt('إلغاء')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: DarbColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dt('تسجيل الخروج')),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onLogout();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? DarbColors.danger : null,
          content: Text(message),
        ),
      );
  }

  String _statusLabel(dynamic value) {
    switch (value?.toString()) {
      case 'PENDING':
        return dt('قيد مراجعة الإدارة');
      case 'APPROVED':
        return dt('تمت الموافقة');
      case 'REJECTED':
        return dt('لم تتم الموافقة');
      case 'SUSPENDED':
        return dt('معلّق من الإدارة');
      default:
        return dt('لم يُرسل طلب بعد');
    }
  }

  Color _statusColor(dynamic value) {
    switch (value?.toString()) {
      case 'APPROVED':
        return DarbColors.success;
      case 'REJECTED':
      case 'SUSPENDED':
        return DarbColors.danger;
      case 'PENDING':
        return DarbColors.warning;
      default:
        return DarbColors.muted;
    }
  }

  Widget _profileHero() {
    final initial = _name.isNotEmpty ? _name.characters.first : 'D';
    return DazrevoHeroSurface(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      borderRadius: DarbRadius.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DarbColors.champagne.withValues(alpha: .16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DarbColors.champagne.withValues(alpha: .42),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  initial,
                  style: TextStyle(
                    color: DarbColors.champagne,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              DazrevoStatusTag(
                label: _roleLabel,
                color: DarbColors.champagne,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _name.isEmpty ? dt('مرحباً بك في DAZREVO') : _name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: DarbColors.ivory,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _phone.isNotEmpty
                ? _phone
                : (_email.isNotEmpty ? _email : dt('أكمل بيانات حسابك')),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: DarbColors.ivory.withValues(alpha: .72),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: DarbColors.champagne,
                size: 16,
              ),
              const SizedBox(width: 7),
              Text(
                dt('حسابك ضمن شبكة DAZREVO'),
                style: TextStyle(
                  color: DarbColors.ivory.withValues(alpha: .86),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    bool last = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          leading: DazrevoIconWell(icon: icon, size: 40, radius: 12),
          title: Text(
            label,
            style: TextStyle(
              color: DarbColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            value,
            style: TextStyle(
              color: DarbColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (!last) const Divider(height: 1, indent: 70, endIndent: 16),
      ],
    );
  }

  Widget _applicationCard({
    required String title,
    required String description,
    required IconData icon,
    required dynamic status,
    required VoidCallback onApply,
  }) {
    final submitted = status != null;
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DarbColors.surface,
        borderRadius: BorderRadius.circular(DarbRadius.lg),
        border: Border.all(color: DarbColors.line),
        boxShadow: DarbElevation.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DazrevoIconWell(
                icon: icon,
                size: 48,
                radius: 14,
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
                        color: DarbColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: DarbColors.muted,
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (submitted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: .28)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    status == 'APPROVED'
                        ? Icons.check_circle_outline_rounded
                        : status == 'PENDING'
                            ? Icons.hourglass_top_rounded
                            : Icons.info_outline_rounded,
                    color: color,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _statusLabel(status),
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status == 'PENDING'
                              ? dt(
                                  'استلمنا طلبك. ستراجع الإدارة بياناتك قبل تفعيل الصلاحيات.',
                                )
                              : status == 'APPROVED'
                                  ? dt(
                                      'تم اعتماد طلبك. حدّث بيانات الحساب لتظهر صلاحياتك الجديدة.',
                                    )
                                  : dt(
                                      'يمكنك التواصل مع الدعم لمعرفة تفاصيل القرار.',
                                    ),
                          style: TextStyle(
                            color: DarbColors.muted,
                            fontSize: 11.5,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: applying ? null : onApply,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(dt('ابدأ طلب الانضمام')),
              ),
            ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      leading: DazrevoIconWell(icon: icon, size: 40, radius: 12),
      title: Text(
        title,
        style: TextStyle(
          color: DarbColors.ink,
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: DarbColors.muted, fontSize: 11.5),
      ),
      trailing: trailing ??
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: DarbColors.muted,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 34),
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: .96, end: 1),
          duration: DarbMotion.effectiveDuration(context, DarbMotion.expressive),
          curve: DarbMotion.enter,
          builder: (context, value, child) => Opacity(
            opacity: value.clamp(0, 1).toDouble(),
            child: Transform.scale(scale: value, child: child),
          ),
          child: _profileHero(),
        ),
        const SizedBox(height: 26),
        DazrevoSectionHeader(
          title: dt('بيانات الحساب'),
          trailing: TextButton.icon(
            onPressed: saving ? null : _edit,
            icon: saving
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.edit_rounded, size: 16),
            label: Text(saving ? dt('جارٍ الحفظ') : dt('تعديل')),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: DarbColors.surface,
            borderRadius: BorderRadius.circular(DarbRadius.lg),
            border: Border.all(color: DarbColors.line),
            boxShadow: DarbElevation.card,
          ),
          child: Column(
            children: [
              _infoRow(
                icon: Icons.person_outline_rounded,
                label: dt('الاسم'),
                value: _name.isEmpty ? dt('غير محدد') : _name,
              ),
              _infoRow(
                icon: Icons.alternate_email_rounded,
                label: dt('البريد الإلكتروني'),
                value: _email.isEmpty ? dt('غير مرتبط') : _email,
                last: _phone.isEmpty,
              ),
              if (_phone.isNotEmpty)
                _infoRow(
                  icon: Icons.phone_iphone_rounded,
                  label: dt('رقم الهاتف'),
                  value: _phone,
                  last: true,
                ),
            ],
          ),
        ),
        if (_role == 'CUSTOMER') ...[
          const SizedBox(height: 28),
          DazrevoSectionHeader(
            title: dt('وسّع دورك مع DAZREVO'),
            subtitle: dt(
              'انضم إلى شبكة التوصيل أو افتح متجرك على DAZREVO. ستراجع الإدارة طلبك قبل تفعيل الصلاحيات.',
            ),
          ),
          const SizedBox(height: 12),
          _applicationCard(
            title: dt('كن سائقاً في DAZREVO'),
            description: dt('استقبل طلبات التوصيل وقدّم عروض الأجرة للعملاء'),
            icon: Icons.delivery_dining_rounded,
            status: profile?['driverApplication'],
            onApply: () => _apply(false),
          ),
          const SizedBox(height: 12),
          _applicationCard(
            title: dt('انضم بمتجرك'),
            description: dt('اعرض منتجات متجرك واستقبل طلبات العملاء'),
            icon: Icons.storefront_rounded,
            status: profile?['vendorApplication'],
            onApply: () => _apply(true),
          ),
        ],
        const SizedBox(height: 28),
        DazrevoSectionHeader(title: dt('التفضيلات والدعم')),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DarbColors.surface,
            borderRadius: BorderRadius.circular(DarbRadius.lg),
            border: Border.all(color: DarbColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dt('مظهر التطبيق'),
                style: TextStyle(
                  color: DarbColors.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: DarbTheme.mode,
                builder: (context, mode, _) => DazrevoChoiceSegment<ThemeMode>(
                  options: [
                    (
                      ThemeMode.system,
                      dt('حسب الجهاز'),
                      Icons.brightness_auto_rounded,
                    ),
                    (ThemeMode.light, dt('نهاري'), Icons.light_mode_rounded),
                    (ThemeMode.dark, dt('ليلي'), Icons.dark_mode_rounded),
                  ],
                  selected: mode,
                  onChanged: (next) => DarbTheme.setMode(next),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: DarbColors.surface,
            borderRadius: BorderRadius.circular(DarbRadius.lg),
            border: Border.all(color: DarbColors.line),
          ),
          child: Column(
            children: [
              _settingsTile(
                icon: Icons.language_rounded,
                title: dt('لغة التطبيق'),
                subtitle: switch (profile?['locale']?.toString() ?? 'ar') {
                  'en' => 'English',
                  'tr' => 'Türkçe',
                  _ => dt('العربية'),
                },
                onTap: saving ? null : _openLanguageSettings,
              ),
              const Divider(height: 1, indent: 70, endIndent: 16),
              _settingsTile(
                icon: Icons.support_agent_rounded,
                title: dt('المساعدة والدعم'),
                subtitle: dt('تواصل معنا عند الحاجة'),
                onTap: null,
                trailing: Icon(
                  Icons.info_outline_rounded,
                  color: DarbColors.muted,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        OutlinedButton.icon(
          onPressed: _confirmLogout,
          icon: const Icon(Icons.logout_rounded),
          label: Text(dt('تسجيل الخروج')),
          style: OutlinedButton.styleFrom(
            foregroundColor: DarbColors.danger,
            minimumSize: const Size.fromHeight(52),
            side: BorderSide(
              color: DarbColors.danger.withValues(alpha: .38),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DarbRadius.md),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            dt('DAZREVO • هندسة التوصيل الفاخر'),
            style: TextStyle(
              color: DarbColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
