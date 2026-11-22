part of 'app_shell.dart';

class DarbSettingsPage extends StatefulWidget {
  const DarbSettingsPage({super.key});

  @override
  State<DarbSettingsPage> createState() => _DarbSettingsPageState();
}

class _DarbSettingsPageState extends State<DarbSettingsPage> {
  PackageInfo? _packageInfo;
  bool _loadingVersion = true;
  bool _checkingUpdate = false;
  String? _versionError;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _packageInfo = info;
        _loadingVersion = false;
        _versionError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingVersion = false;
        _versionError = dt('تعذر قراءة إصدار التطبيق');
      });
    }
  }

  Future<void> _checkForUpdate() async {
    if (_checkingUpdate) return;
    setState(() => _checkingUpdate = true);
    await DarbUpdater.instance.checkForUpdate(force: true);
    if (!mounted) return;
    setState(() => _checkingUpdate = false);

    final update = DarbUpdater.instance.availableUpdate.value;
    if (update != null) {
      await showDialog<void>(
        context: context,
        builder: (_) => DarbUpdateDialog(info: update),
      );
      return;
    }

    final message = DarbUpdater.instance.checkFailed
        ? dt('تعذر التحقق من التحديث')
        : dt('تطبيقك محدّث إلى آخر إصدار');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openLanguageSettings() async {
    await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => LanguageSelectionPage(
          initialLocale: darbLocale.value.languageCode,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 12),
          child: Row(
            children: [
              Icon(icon, color: DarbColors.brandForeground, size: 19),
              const SizedBox(width: 9),
              Text(
                title,
                style: TextStyle(
                  color: DarbColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        DarbGlassSurface(
          padding: EdgeInsets.zero,
          radius: DarbRadius.lg,
          child: child,
        ),
      ],
    );
  }

  Widget _settingDescription(String value) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 14),
        child: Text(
          value,
          style: TextStyle(color: DarbColors.muted, fontSize: 11, height: 1.45),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(dt('إعدادات دَرْب')),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [DarbColors.forest, DarbColors.forestSoft],
                ),
                borderRadius: BorderRadius.circular(DarbRadius.xl),
                boxShadow: DarbElevation.floating,
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: DarbColors.mint.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: DarbColors.mint.withValues(alpha: .35)),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Color(0xFFB9E4D2)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'دَرْب',
                          style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dt('المظهر والتحديث واللغة'),
                          style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            _section(
              icon: Icons.palette_outlined,
              title: dt('التخصيص'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 17, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dt('نمط الواجهة'), style: TextStyle(color: DarbColors.ink, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text(
                                DarbAppearance.glass.value
                                    ? dt('شفافية ناعمة وطبقات زجاجية')
                                    : dt('ألوان صلبة وواضحة'),
                                style: TextStyle(color: DarbColors.muted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: DarbAppearance.glass,
                          builder: (context, glass, _) => SegmentedButton<bool>(
                            showSelectedIcon: false,
                            style: const ButtonStyle(visualDensity: VisualDensity.compact),
                            segments: [
                              ButtonSegment<bool>(
                                value: true,
                                label: Text(dt('زجاجي')),
                                icon: const Icon(Icons.blur_on_rounded, size: 16),
                              ),
                              ButtonSegment<bool>(
                                value: false,
                                label: Text(dt('عادي')),
                                icon: const Icon(Icons.crop_square_rounded, size: 16),
                              ),
                            ],
                            selected: {glass},
                            onSelectionChanged: (values) => DarbAppearance.setGlass(values.first),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _settingDescription(dt('يتم حفظ اختيارات المظهر على هذا الجهاز')),
                  Divider(height: 1, color: DarbColors.line),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Text(dt('مظهر النظام'), style: TextStyle(color: DarbColors.ink, fontWeight: FontWeight.w800)),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
                    child: ValueListenableBuilder<ThemeMode>(
                      valueListenable: DarbTheme.mode,
                      builder: (context, mode, _) => SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(value: ThemeMode.system, label: Text(dt('تلقائي')), icon: const Icon(Icons.settings_suggest_outlined, size: 16)),
                            ButtonSegment(value: ThemeMode.light, label: Text(dt('فاتح')), icon: const Icon(Icons.light_mode_outlined, size: 16)),
                            ButtonSegment(value: ThemeMode.dark, label: Text(dt('داكن')), icon: const Icon(Icons.dark_mode_outlined, size: 16)),
                          ],
                          selected: {mode},
                          onSelectionChanged: (values) => DarbTheme.setMode(values.first),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _section(
              icon: Icons.system_update_alt_rounded,
              title: dt('التحديثات'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: DarbColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.phone_android_rounded, color: DarbColors.brandForeground),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dt('إصدار التطبيق'), style: TextStyle(color: DarbColors.ink, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 3),
                              Text(
                                _loadingVersion
                                    ? dt('جارٍ قراءة الإصدار')
                                    : _versionError ?? (_packageInfo == null
                                        ? '—'
                                        : '${_packageInfo!.version} (${_packageInfo!.buildNumber})'),
                                style: TextStyle(color: DarbColors.muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (_loadingVersion)
                          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ValueListenableBuilder<DarbUpdateInfo?>(
                      valueListenable: DarbUpdater.instance.availableUpdate,
                      builder: (context, update, _) {
                        if (update == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(Icons.new_releases_rounded, color: DarbColors.success, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${dt('توجد نسخة أحدث متاحة')}: ${update.versionName}',
                                  style: TextStyle(color: DarbColors.success, fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _checkingUpdate ? null : _checkForUpdate,
                        icon: _checkingUpdate
                            ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(_checkingUpdate ? dt('جارٍ التحقق من التحديثات') : dt('التحقق من وجود تحديث')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            _section(
              icon: Icons.language_rounded,
              title: dt('اللغة والمنطقة'),
              child: ListTile(
                leading: Icon(Icons.translate_rounded, color: DarbColors.brandForeground),
                title: Text(dt('لغة التطبيق'), style: TextStyle(color: DarbColors.ink, fontWeight: FontWeight.w800)),
                subtitle: Text(
                  switch (darbLocale.value.languageCode) {
                    'en' => 'English',
                    'tr' => 'Türkçe',
                    _ => 'العربية',
                  },
                  style: TextStyle(color: DarbColors.muted, fontSize: 12),
                ),
                trailing: Icon(Icons.chevron_right_rounded, color: DarbColors.muted),
                onTap: _openLanguageSettings,
              ),
            ),
            const SizedBox(height: 22),
            _section(
              icon: Icons.info_outline_rounded,
              title: dt('حول دَرْب'),
              child: ListTile(
                leading: Icon(Icons.route_rounded, color: DarbColors.brandForeground),
                title: Text('دَرْب', style: TextStyle(color: DarbColors.ink, fontWeight: FontWeight.w900)),
                subtitle: Text(
                  dt('منصة توصيل تربط العملاء بالمندوبين والمتاجر'),
                  style: TextStyle(color: DarbColors.muted, fontSize: 11),
                ),
                trailing: Text(
                  _packageInfo == null ? '—' : 'v${_packageInfo!.version}',
                  style: TextStyle(color: DarbColors.muted, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
