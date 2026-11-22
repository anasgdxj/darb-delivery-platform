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
        return dt('إدارة دَرْب');
      case 'DRIVER':
        return dt('حساب سائق');
      case 'VENDOR':
        return dt('حساب تاجر');
      default:
        return dt('حساب عميل');
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const DarbSettingsPage()),
    );
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
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: locale,
                decoration: InputDecoration(
                  labelText: dt('لغة التطبيق'),
                  prefixIcon: Icon(Icons.language_rounded),
                ),
                items: [
                  DropdownMenuItem(value: 'ar', child: Text(dt('العربية'))),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
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
        if (mounted) _showMessage(dt('تعذر حفظ التغييرات: $error'), isError: true);
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
            title: Text(vendor ? dt('طلب انضمام متجر') : dt('طلب انضمام سائق')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (vendor) ...[
                    TextField(
                      controller: storeName,
                      decoration: InputDecoration(
                        labelText: dt('اسم المتجر'),
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: activity,
                      decoration: InputDecoration(
                        labelText: dt('نوع النشاط'),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                    ),
                  ] else
                    TextField(
                      controller: activity,
                      decoration: InputDecoration(
                        labelText: dt('نوع المركبة (اختياري)'),
                        prefixIcon: Icon(Icons.two_wheeler_outlined),
                      ),
                    ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: cityId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: dt('المدينة'),
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    items: [
                      for (final city in cities)
                        DropdownMenuItem<String>(
                          value: city['id'].toString(),
                          child: Text(
                            (city['names'] as List? ?? []).isEmpty
                                ? city['code'].toString()
                                : (city['names'] as List).first['name'].toString(),
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
                    SizedBox(height: 10),
                    TextField(
                      controller: address,
                      decoration: InputDecoration(
                        labelText: dt('عنوان المتجر (اختياري)'),
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                    ),
                    SizedBox(height: 8),
                    OutlinedButton.icon(
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
          _showMessage(dt('تم إرسال الطلب. ستراجع الإدارة بياناتك قبل تفعيل الصلاحيات.'));
        } catch (error) {
          if (mounted) _showMessage(dt('تعذر إرسال الطلب: $error'), isError: true);
        }
      }

      storeName.dispose();
      activity.dispose();
      address.dispose();
    } catch (error) {
      if (mounted) _showMessage(dt('تعذر تحميل المدن: $error'), isError: true);
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
          backgroundColor: isError ? DarbColors.danger : DarbColors.forest,
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

  Widget _sectionTitle(String title, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: DarbColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  Widget _profileHero() {
    final initial = _name.isNotEmpty ? _name.characters.first : dt('د');
    return ClipRRect(
      borderRadius: BorderRadius.circular(DarbRadius.hero),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 25, 22, 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [DarbColors.forestSoft, DarbColors.forest],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .35),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 29,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: DarbColors.mint,
                        borderRadius: BorderRadius.circular(DarbRadius.pill),
                      ),
                      child: Text(
                        _roleLabel,
                        style: TextStyle(
                          color: DarbColors.brandForeground,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 22),
                Text(
                  _name.isEmpty ? dt('مرحباً بك في دَرْب') : _name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  _phone.isNotEmpty ? _phone : (_email.isNotEmpty ? _email  : dt('أكمل بيانات حسابك')),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .72),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: DarbColors.mint,
                      size: 16,
                    ),
                    SizedBox(width: 7),
                    Text(dt('حسابك ضمن شبكة دَرْب'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .86),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: -36,
            top: -55,
            child: IgnorePointer(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .06),
                    width: 22,
                  ),
                ),
              ),
            ),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: DarbColors.mint.withValues(alpha: .38),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: DarbColors.brandForeground, size: 20),
          ),
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
        if (!last) Divider(height: 1, indent: 72, endIndent: 16),
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
      padding: const EdgeInsets.all(17),
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: DarbColors.mint.withValues(alpha: .4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: DarbColors.brandForeground, size: 25),
              ),
              SizedBox(width: 12),
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
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: DarbColors.muted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          if (submitted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(14),
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
                  SizedBox(width: 8),
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
                        SizedBox(height: 4),
                        Text(
                          status == 'PENDING'
                              ? dt('استلمنا طلبك. ستراجع الإدارة بياناتك قبل تفعيل الصلاحيات.')
                              : status == 'APPROVED'
                                  ? dt('تم اعتماد طلبك. حدّث بيانات الحساب لتظهر صلاحياتك الجديدة.')
                                  : dt('يمكنك التواصل مع الدعم لمعرفة تفاصيل القرار.'),
                          style: TextStyle(
                            color: DarbColors.muted,
                            fontSize: 11,
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
                icon: Icon(Icons.arrow_forward_rounded, size: 18),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: DarbColors.mint.withValues(alpha: .38),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: DarbColors.brandForeground, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: DarbColors.ink,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: DarbColors.muted, fontSize: 11),
      ),
      trailing: trailing ?? Icon(
        Icons.chevron_left_rounded,
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
          tween: Tween(begin: .94, end: 1),
          duration: DarbMotion.expressive,
          curve: DarbMotion.enter,
          builder: (context, value, child) => Opacity(
            opacity: value.clamp(0, 1).toDouble(),
            child: Transform.scale(scale: value, child: child),
          ),
          child: _profileHero(),
        ),
        SizedBox(height: 28),
        _sectionTitle(
          dt('بيانات الحساب'),
          action: TextButton.icon(
            onPressed: saving ? null : _edit,
            icon: saving
                ? SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.edit_rounded, size: 16),
            label: Text(saving ? dt('جارٍ الحفظ') : dt('تعديل')),
          ),
        ),
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
          SizedBox(height: 30),
          _sectionTitle(dt('وسّع دورك مع دَرْب')),
          Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text(dt('انضم إلى شبكة التوصيل أو افتح متجرك على دَرْب. ستراجع الإدارة طلبك قبل تفعيل الصلاحيات.'),
              style: TextStyle(
                color: DarbColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
          _applicationCard(
            title: dt('كن سائقاً في دَرْب'),
            description: dt('استقبل طلبات التوصيل وقدّم عروض الأجرة للعملاء'),
            icon: Icons.delivery_dining_rounded,
            status: profile?['driverApplication'],
            onApply: () => _apply(false),
          ),
          SizedBox(height: 12),
          _applicationCard(
            title: dt('انضم بمتجرك'),
            description: dt('اعرض منتجات متجرك واستقبل طلبات العملاء'),
            icon: Icons.storefront_rounded,
            status: profile?['vendorApplication'],
            onApply: () => _apply(true),
          ),
        ],
        SizedBox(height: 30),
        _sectionTitle(dt('التفضيلات والدعم')),
        Container(
          decoration: BoxDecoration(
            color: DarbColors.surface,
            borderRadius: BorderRadius.circular(DarbRadius.lg),
            border: Border.all(color: DarbColors.line),
          ),
          child: Column(
            children: [
              _settingsTile(
                icon: Icons.settings_rounded,
                title: dt('إعدادات دَرْب'),
                subtitle: dt('المظهر والتحديث واللغة'),
                onTap: _openSettings,
              ),
              Divider(height: 1, indent: 72, endIndent: 16),
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
              Divider(height: 1, indent: 72, endIndent: 16),
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
        SizedBox(height: 22),
        OutlinedButton.icon(
          onPressed: _confirmLogout,
          icon: Icon(Icons.logout_rounded),
          label: Text(dt('تسجيل الخروج')),
          style: OutlinedButton.styleFrom(
            foregroundColor: DarbColors.danger,
            minimumSize: const Size.fromHeight(52),
            side: BorderSide(
              color: DarbColors.danger.withValues(alpha: .35),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DarbRadius.md),
            ),
          ),
        ),
        SizedBox(height: 18),
        Center(
          child: Text(dt('دَرْب • طريقك الأسهل'),
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

class _EmptyPanel extends StatelessWidget {
  final String text;

  const _EmptyPanel({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DarbColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: DarbColors.muted),
        ),
      );
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final Future<void> Function() retry;

  const _ErrorPanel({
    required this.message,
    required this.retry,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: DarbColors.danger.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(message, style: TextStyle(color: DarbColors.danger)),
            TextButton(
              onPressed: retry,
              child: Text(dt('إعادة المحاولة')),
            ),
          ],
        ),
      );
}
