part of 'app_shell.dart';

class LanguageSelectionPage extends StatefulWidget {
  final String initialLocale;
  const LanguageSelectionPage({super.key, required this.initialLocale});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  late String selected = widget.initialLocale;
  bool saving = false;
  String? error;

  Future<void> _save() async {
    if (saving) return;
    setState(() { saving = true; error = null; });
    try {
      final updated = await Api.instance.patch('/auth/me', {'locale': selected});
      if (!mounted) return;
      darbLocale.value = Locale(selected);
      Navigator.of(context).pop(Map<String, dynamic>.from(updated));
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final options = [
      ('ar', l.t('languageArabic'), 'العربية', l.t('languageArabicNative'), 'AR'),
      ('en', l.t('languageEnglish'), 'English', l.t('languageEnglishNative'), 'EN'),
      ('tr', l.t('languageTurkish'), 'Türkçe', l.t('languageTurkishNative'), 'TR'),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.t('languageTitle'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [DarbColors.forest, DarbColors.forestSoft],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.translate_rounded, color: DarbColors.lime, size: 32),
                  const SizedBox(height: 16),
                  Text(l.t('languageTitle'), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 7),
                  Text(l.t('languageSubtitle'), style: TextStyle(color: Colors.white.withValues(alpha: .78), height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            for (final option in options) ...[
              _languageOption(
                code: option.$1,
                title: option.$2,
                nativeTitle: option.$3,
                subtitle: option.$4,
                tag: option.$5,
              ),
              const SizedBox(height: 12),
            ],
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: TextStyle(color: DarbColors.danger)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: saving ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
              child: saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(l.t('languageSave')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageOption({
    required String code,
    required String title,
    required String nativeTitle,
    required String subtitle,
    required String tag,
  }) {
    final active = selected == code;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: saving ? null : () => setState(() => selected = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active ? DarbColors.mint.withValues(alpha: .42) : DarbColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? DarbColors.brandForeground : DarbColors.line, width: active ? 1.6 : 1),
          boxShadow: active ? DarbElevation.card : const [],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: DarbColors.primary, borderRadius: BorderRadius.circular(15)),
              child: Text(tag, style: TextStyle(color: DarbColors.onPrimary, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: DarbColors.ink)),
                  const SizedBox(height: 3),
                  Text(nativeTitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DarbColors.brandForeground)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: DarbColors.muted)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? DarbColors.brandForeground : Colors.transparent,
                border: Border.all(color: active ? DarbColors.brandForeground : DarbColors.line, width: 1.5),
              ),
              child: active ? Icon(Icons.check_rounded, size: 16, color: DarbColors.onForest) : null,
            ),
          ],
        ),
      ),
    );
  }
}
