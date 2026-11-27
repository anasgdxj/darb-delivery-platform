import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/local_cache.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_motion_components.dart';
import '../../core/widgets/darb_spatial_primitives.dart';

class DriverApplicationScreen extends StatefulWidget {
  const DriverApplicationScreen({
    super.key,
    required this.user,
    required this.onRefreshUser,
    this.loadCitiesOverride,
    this.submitApplicationOverride,
    this.updateProfileOverride,
    this.enableDraftCache = true,
  });

  final Map<String, dynamic> user;
  final Future<void> Function() onRefreshUser;
  final Future<List<Map<String, dynamic>>> Function()? loadCitiesOverride;
  final Future<Map<String, dynamic>?> Function(Map<String, dynamic> payload)?
      submitApplicationOverride;
  final Future<void> Function(Map<String, dynamic> payload)?
      updateProfileOverride;
  final bool enableDraftCache;

  @override
  State<DriverApplicationScreen> createState() =>
      _DriverApplicationScreenState();
}

class _DriverApplicationScreenState extends State<DriverApplicationScreen> {
  static const _draftKey = 'driver_application_draft_v1';
  static const _totalSteps = 5;

  int _step = 0;
  bool _movingForward = true;
  late final TextEditingController _nameCtrl;
  String _vehicleType = 'MOTORCYCLE';
  String? _cityId;
  bool _confirmVehicleReady = false;
  bool _confirmLocationConsent = false;
  bool _confirmReviewTerms = false;

  List<Map<String, dynamic>> _cities = const [];
  bool _loadingCities = true;
  String? _citiesError;

  String? _stepError;
  int _shakeTrigger = 0;
  DarbActionState _submitState = DarbActionState.idle;
  bool _submittedSuccess = false;
  String? _submittedMessage;
  bool _refreshingStatus = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.user['name']?.toString().trim() ?? '',
    );
    _restoreDraft();
    _loadCities();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String? get _driverStatus =>
      widget.user['driverApplication']?.toString().toUpperCase();
  String? get _vendorStatus =>
      widget.user['vendorApplication']?.toString().toUpperCase();

  Future<void> _restoreDraft() async {
    if (!widget.enableDraftCache) return;
    final raw = await DarbLocalCache.instance.readJson(_draftKey);
    if (!mounted || raw is! Map) return;
    setState(() {
      final savedName = raw['name']?.toString().trim() ?? '';
      if (savedName.isNotEmpty && _nameCtrl.text.trim().isEmpty) {
        _nameCtrl.text = savedName;
      }
      final savedVehicle = raw['vehicleType']?.toString();
      if (const ['BICYCLE', 'MOTORCYCLE', 'CAR'].contains(savedVehicle)) {
        _vehicleType = savedVehicle!;
      }
      final savedCity = raw['cityId']?.toString();
      if (savedCity != null && savedCity.isNotEmpty) {
        _cityId = savedCity;
      }
      _confirmVehicleReady = raw['confirmVehicleReady'] == true;
      _confirmLocationConsent = raw['confirmLocationConsent'] == true;
      _confirmReviewTerms = raw['confirmReviewTerms'] == true;
      final savedStep = raw['step'];
      if (savedStep is int && savedStep >= 0 && savedStep < _totalSteps) {
        _step = savedStep;
      }
    });
  }

  Future<void> _persistDraft() async {
    if (!widget.enableDraftCache) return;
    await DarbLocalCache.instance.writeJson(_draftKey, {
      'step': _step,
      'name': _nameCtrl.text.trim(),
      'vehicleType': _vehicleType,
      'cityId': _cityId,
      'confirmVehicleReady': _confirmVehicleReady,
      'confirmLocationConsent': _confirmLocationConsent,
      'confirmReviewTerms': _confirmReviewTerms,
    });
  }

  Future<void> _loadCities() async {
    setState(() {
      _loadingCities = true;
      _citiesError = null;
    });
    try {
      final list = widget.loadCitiesOverride != null
          ? await widget.loadCitiesOverride!()
          : (await Api.instance.get('/cities') as List? ?? [])
              .whereType<Map<String, dynamic>>()
              .toList();
      if (!mounted) return;
      setState(() {
        _cities = list;
        if (_cities.isNotEmpty &&
            (_cityId == null ||
                !_cities.any((c) => c['id']?.toString() == _cityId))) {
          _cityId = _cities.first['id']?.toString();
        }
        _loadingCities = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCities = false;
        _citiesError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingCities = false;
        _citiesError = dt('تعذر تحميل المدن المتاحة حالياً');
      });
    }
  }

  String _cityName(Map<String, dynamic> city) {
    final code = darbLocale.value.languageCode;
    final names = (city['names'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    for (final n in names) {
      if (n['locale'] == code) return n['name']?.toString() ?? '';
    }
    return names.isNotEmpty
        ? names.first['name']?.toString() ?? city['code']?.toString() ?? ''
        : city['code']?.toString() ?? '';
  }

  String _vehicleLabel(String type) => switch (type) {
        'BICYCLE' => dt('دراجة هوائية'),
        'CAR' => dt('سيارة'),
        _ => dt('دراجة نارية'),
      };

  String _stepTitle(int step) => switch (step) {
        0 => dt('المعلومات الشخصية'),
        1 => dt('وسيلة التوصيل'),
        2 => dt('المدينة ومنطقة العمل'),
        3 => dt('الاستعداد التشغيلي'),
        _ => dt('مراجعة الطلب والإرسال'),
      };

  bool _validateCurrentStep() {
    String? err;
    switch (_step) {
      case 0:
        final trimmed = _nameCtrl.text.trim();
        if (trimmed.length < 2) {
          err = dt('أدخل اسمك الكامل للمتابعة (حرفان على الأقل)');
        } else if (trimmed.length > 120) {
          err = dt('الاسم طويل جداً (الحد الأقصى 120 حرفاً)');
        }
      case 1:
        if (!const ['BICYCLE', 'MOTORCYCLE', 'CAR'].contains(_vehicleType)) {
          err = dt('اختر نوع المركبة للمتابعة');
        }
      case 2:
        if (_cityId == null || _cityId!.isEmpty) {
          err = dt('اختر مدينة العمل للمتابعة');
        }
      case 3:
        if (!_confirmVehicleReady ||
            !_confirmLocationConsent ||
            !_confirmReviewTerms) {
          err = dt('أكد بنود الجاهزية التشغيلية الثلاثة للمتابعة');
        }
    }
    if (err != null) {
      setState(() {
        _stepError = err;
        _shakeTrigger++;
      });
      DarbHaptics.error();
      return false;
    }
    return true;
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();
    if (!_validateCurrentStep()) return;
    if (_step < _totalSteps - 1) {
      DarbHaptics.selection();
      setState(() {
        _movingForward = true;
        _step++;
        _stepError = null;
      });
      _persistDraft();
    }
  }

  void _prevStep() {
    if (_step > 0) {
      DarbHaptics.selection();
      setState(() {
        _movingForward = false;
        _step--;
        _stepError = null;
      });
      _persistDraft();
    }
  }

  void _jumpToStep(int target) {
    if (target == _step || target < 0 || target >= _totalSteps) return;
    DarbHaptics.selection();
    setState(() {
      _movingForward = target > _step;
      _step = target;
      _stepError = null;
    });
    _persistDraft();
  }

  Future<void> _submitApplication() async {
    if (_cityId == null || _cityId!.isEmpty) {
      setState(() {
        _stepError = dt('اختر مدينة العمل للمتابعة');
        _submitState = DarbActionState.error;
        _shakeTrigger++;
      });
      return;
    }

    setState(() {
      _stepError = null;
      _submitState = DarbActionState.loading;
    });

    try {
      final trimmedName = _nameCtrl.text.trim();
      final existingName = widget.user['name']?.toString().trim() ?? '';
      if (trimmedName.length >= 2 && trimmedName != existingName) {
        if (widget.updateProfileOverride != null) {
          await widget.updateProfileOverride!({'name': trimmedName});
        } else {
          await Api.instance.patch('/auth/me', {'name': trimmedName});
        }
      }

      final payload = <String, dynamic>{
        'cityId': _cityId!,
        'vehicleType': _vehicleType,
      };
      final res = widget.submitApplicationOverride != null
          ? await widget.submitApplicationOverride!(payload)
          : await Api.instance.post('/drivers/apply', payload);

      if (!mounted) return;
      if (widget.enableDraftCache) {
        await DarbLocalCache.instance.writeJson(_draftKey, {
          'submitted': true,
          'cityId': _cityId,
          'vehicleType': _vehicleType,
        });
      }

      setState(() {
        _submitState = DarbActionState.success;
        _submittedSuccess = true;
        _submittedMessage = res is Map ? res['message']?.toString() : null;
      });
      DarbHaptics.success();
      await widget.onRefreshUser();
    } on ApiException catch (e) {
      if (!mounted) return;
      _persistDraft();
      setState(() {
        _submitState = DarbActionState.error;
        _stepError = e.message;
        _shakeTrigger++;
      });
    } catch (_) {
      if (!mounted) return;
      _persistDraft();
      setState(() {
        _submitState = DarbActionState.error;
        _stepError = dt('تعذر إرسال الطلب: تحقق من الإنترنت وحاول مجدداً');
        _shakeTrigger++;
      });
    }
  }

  Future<void> _refreshApplicationStatus() async {
    setState(() => _refreshingStatus = true);
    try {
      await widget.onRefreshUser();
    } finally {
      if (mounted) setState(() => _refreshingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _driverStatus;
    final vendorConflict = _vendorStatus;

    return Scaffold(
      appBar: DarbGlassAppBar(
        title: dt('طلب انضمام سائق'),
        subtitle: _submittedSuccess
            ? dt('تم استلام طلبك بنجاح')
            : (status != null
                ? dt('متابعة حالة طلب السائق')
                : '${dt('الخطوة')} ${_step + 1} / $_totalSteps'),
      ),
      body: DarbAmbientBackground(
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: _submittedSuccess
                  ? _buildSuccessView(context)
                  : (status != null || vendorConflict != null)
                      ? _buildStatusView(
                          context,
                          driverStatus: status,
                          vendorStatus: vendorConflict,
                        )
                      : _buildWizardView(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusView(
    BuildContext context, {
    String? driverStatus,
    String? vendorStatus,
  }) {
    final isConflict = driverStatus == null && vendorStatus != null;
    final activeStatus = driverStatus ?? vendorStatus ?? 'PENDING';

    final (IconData icon, Color tone, String title, String message) =
        isConflict
            ? (
                Icons.storefront_rounded,
                DarbColors.warningOf(context),
                dt('لديك طلب متجر مسجّل مسبقاً'),
                dt('الحساب الواحد في دازريفو يرتبط إما بملف متجر أو بملف سائق. يمكنك متابعة طلب متجرك من صفحة التقديم الخاصة بالمتجر.'),
              )
            : switch (activeStatus) {
                'APPROVED' => (
                    Icons.verified_rounded,
                    DarbColors.successOf(context),
                    dt('تم اعتماد حسابك كسائق'),
                    dt('طلبك معتمد في دازريفو. حدّث حالة الحساب إذا لم تظهر لوحة السائق تلقائياً.'),
                  ),
                'SUSPENDED' || 'REJECTED' => (
                    Icons.gpp_maybe_rounded,
                    DarbColors.dangerOf(context),
                    dt('يتطلب طلب السائق مراجعة الإدارة'),
                    dt('تم إيقاف أو رفض الطلب الحالي. تواصل مع فريق الدعم لمزيد من التفاصيل.'),
                  ),
                _ => (
                    Icons.hourglass_top_rounded,
                    DarbColors.warningOf(context),
                    dt('طلب السائق قيد المراجعة'),
                    dt('حساب السائق بانتظار اعتماد الإدارة. ستصلك رسالة إشعار فور تفعيل الحساب لتتمكن من استقبال الطلبات.'),
                  ),
              };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        DarbFadeSlide(
          child: DarbCommandStage(
            livePulse: activeStatus == 'PENDING',
            accentColor: tone,
            eyebrow: dt('انضم كسائق في دازريفو'),
            title: title,
            subtitle: message,
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: tone.withValues(alpha: 0.45)),
              ),
              child: Icon(icon, size: 26, color: tone),
            ),
            bottom: DarbStatusBadge(status: activeStatus),
          ),
        ),
        const SizedBox(height: 14),
        DarbFadeSlide(
          delay: DarbMotion.staggerDelay(1),
          child: DarbGlassSurface(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DarbActionButton(
                  label: dt('تحديث حالة الطلب'),
                  loadingLabel: dt('جارٍ التحديث...'),
                  icon: Icons.refresh_rounded,
                  state: _refreshingStatus
                      ? DarbActionState.loading
                      : DarbActionState.idle,
                  onPressed:
                      _refreshingStatus ? null : _refreshApplicationStatus,
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: Text(dt('العودة إلى حسابي')),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final ink = DarbColors.inkOf(context);
    final muted = DarbColors.mutedOf(context);
    final success = DarbColors.successOf(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        DarbFadeSlide(
          child: DarbGlassSurface(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: success.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: success.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      size: 38,
                      color: success,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  dt('تم استلام طلب انضمامك كسائق'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Center(child: const DarbStatusBadge(status: 'PENDING')),
                const SizedBox(height: 14),
                Text(
                  _submittedMessage?.isNotEmpty == true
                      ? _submittedMessage!
                      : dt('تم استلام طلبك وسيتم مراجعته قبل تفعيل الحساب'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: muted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                DarbActionButton(
                  label: dt('العودة إلى حسابي'),
                  icon: Icons.check_rounded,
                  onPressed: () => Navigator.maybePop(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWizardView(BuildContext context) {
    final muted = DarbColors.mutedOf(context);
    final reduced = DarbMotion.reduceMotion(context);
    final progress = (_step + 1) / _totalSteps;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: DarbCommandStage(
            livePulse: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            eyebrow: '${_step + 1} / $_totalSteps',
            title: _stepTitle(_step),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DarbColors.lime.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DarbColors.lime.withValues(alpha: 0.42),
                ),
              ),
              child: const Icon(
                Icons.two_wheeler_rounded,
                size: 20,
                color: DarbColors.lime,
              ),
            ),
            bottom: ClipRRect(
              borderRadius: BorderRadius.circular(DarbRadius.pill),
              child: Container(
                height: 6,
                color: Colors.white.withValues(alpha: 0.14),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AnimatedFractionallySizedBox(
                    duration: DarbMotion.effectiveDuration(
                      context,
                      DarbMotion.standard,
                    ),
                    curve: DarbMotion.enter,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [DarbColors.lime, DarbColors.darkViolet],
                        ),
                        borderRadius: BorderRadius.circular(DarbRadius.pill),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
            child: AnimatedSwitcher(
              duration: DarbMotion.effectiveDuration(
                context,
                DarbMotion.standard,
              ),
              switchInCurve: DarbMotion.enter,
              switchOutCurve: DarbMotion.exit,
              transitionBuilder: (child, anim) {
                if (reduced) return child;
                final beginX = _movingForward ? 0.05 : -0.05;
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(beginX, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: switch (_step) {
                  0 => _buildStepPersonal(context),
                  1 => _buildStepVehicle(context),
                  2 => _buildStepCity(context),
                  3 => _buildStepReadiness(context),
                  _ => _buildStepReview(context),
                },
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: DarbColors.surfaceOf(context).withValues(alpha: 0.94),
            border: Border(
              top: BorderSide(color: DarbColors.borderOf(context)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_stepError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DarbShakeBox(
                    trigger: _shakeTrigger,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: DarbColors.dangerSoftOf(context),
                        borderRadius: BorderRadius.circular(DarbRadius.sm),
                        border: Border.all(
                          color: DarbColors.dangerOf(context)
                              .withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 17,
                            color: DarbColors.dangerOf(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _stepError!,
                              style: TextStyle(
                                color: DarbColors.dangerOf(context),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  if (_step > 0) ...[
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: _submitState == DarbActionState.loading
                            ? null
                            : _prevStep,
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: Text(dt('السابق')),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 3,
                    child: _step < _totalSteps - 1
                        ? DarbActionButton(
                            label: dt('متابعة'),
                            icon: Icons.arrow_forward_rounded,
                            errorTrigger: _shakeTrigger,
                            onPressed: _nextStep,
                          )
                        : DarbActionButton(
                            label: dt('إرسال الطلب'),
                            loadingLabel: dt('جارٍ الإرسال...'),
                            successLabel: dt('تم الإرسال'),
                            icon: Icons.send_rounded,
                            state: _submitState,
                            errorTrigger: _shakeTrigger,
                            onPressed: _submitState == DarbActionState.loading
                                ? null
                                : _submitApplication,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                dt('يتم حفظ تقدمك تلقائياً على جهازك حتى في حال ضعف الاتصال.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepPersonal(BuildContext context) {
    final primary = DarbColors.primaryOf(context);
    final muted = DarbColors.mutedOf(context);
    final phone = widget.user['phone']?.toString();
    final email = widget.user['email']?.toString();

    return DarbGlassSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DarbSectionHeader(
            title: dt('بيانات مقدم الطلب'),
            subtitle: dt('تُستخدم هذه البيانات لتعريفك للعملاء والإدارة'),
          ),
          const SizedBox(height: 14),
          DarbShakeBox(
            trigger: _shakeTrigger,
            child: TextField(
              controller: _nameCtrl,
              maxLength: 120,
              onChanged: (_) {
                if (_stepError != null) setState(() => _stepError = null);
              },
              decoration: InputDecoration(
                labelText: dt('الاسم الكامل'),
                hintText: dt('الاسم الثلاثي كما سيظهر في الطلبات'),
                prefixIcon: Icon(Icons.person_outline_rounded, color: primary),
                counterStyle: TextStyle(color: muted, fontSize: 11),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DarbColors.softSurfaceOf(context),
              borderRadius: BorderRadius.circular(DarbRadius.md),
              border: Border.all(color: DarbColors.borderOf(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dt('وسيلة التواصل الموثّقة'),
                  style: TextStyle(
                    color: muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      (phone != null && phone.isNotEmpty)
                          ? phone
                          : (email ?? dt('حساب موثّق')),
                      style: TextStyle(
                        color: DarbColors.inkOf(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepVehicle(BuildContext context) {
    final options = [
      (
        'MOTORCYCLE',
        dt('دراجة نارية'),
        dt('الأسرع داخل المدن والأحياء المزدحمة والطلبات الخفيفة والمتوسطة'),
        Icons.two_wheeler_rounded,
      ),
      (
        'BICYCLE',
        dt('دراجة هوائية'),
        dt('مناسبة للمسافات القريبة داخل الأحياء دون تكاليف وقود'),
        Icons.pedal_bike_rounded,
      ),
      (
        'CAR',
        dt('سيارة'),
        dt('مناسبة للطلبات الكبيرة والطرود المتعددة والمسافات الأطول'),
        Icons.directions_car_rounded,
      ),
    ];

    return DarbGlassSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DarbSectionHeader(
            title: dt('اختر وسيلة التوصيل'),
            subtitle: dt('تظهر وسيلتك بوضوح في ملفك ويمكن تحديثها لاحقاً'),
          ),
          const SizedBox(height: 14),
          for (final v in options) ...[
            DarbRadioOptionTile(
              selected: _vehicleType == v.$1,
              title: v.$2,
              subtitle: v.$3,
              trailing: Icon(
                v.$4,
                size: 22,
                color: _vehicleType == v.$1
                    ? DarbColors.primaryOf(context)
                    : DarbColors.mutedOf(context),
              ),
              onTap: () {
                DarbHaptics.selection();
                setState(() {
                  _vehicleType = v.$1;
                  _stepError = null;
                });
                _persistDraft();
              },
            ),
            if (v.$1 != 'CAR') const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildStepCity(BuildContext context) {
    if (_loadingCities) {
      return const DarbStateView.loading();
    }
    if (_citiesError != null) {
      return DarbStateView.error(
        message: _citiesError!,
        onRetry: _loadCities,
      );
    }
    if (_cities.isEmpty) {
      return DarbStateView.empty(
        message: dt('لا توجد مدن متاحة للتقديم حالياً'),
        onRetry: _loadCities,
      );
    }

    return DarbGlassSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DarbSectionHeader(
            title: dt('اختر مدينة العمل'),
            subtitle: dt('ستستقبل طلبات التوصيل المتاحة في هذه المدينة'),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _cities.length; i++) ...[
            DarbRadioOptionTile(
              selected: _cityId == _cities[i]['id']?.toString(),
              title: _cityName(_cities[i]),
              subtitle: _cities[i]['code'] != null
                  ? '${dt('رمز المدينة: ')}${_cities[i]['code']}'
                  : null,
              onTap: () {
                DarbHaptics.selection();
                setState(() {
                  _cityId = _cities[i]['id']?.toString();
                  _stepError = null;
                });
                _persistDraft();
              },
            ),
            if (i < _cities.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildStepReadiness(BuildContext context) {
    return DarbGlassSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DarbSectionHeader(
            title: dt('الاستعداد التشغيلي'),
            subtitle: dt('أكد جاهزيتك قبل إرسال الطلب للإدارة'),
          ),
          const SizedBox(height: 12),
          _ChecklistTile(
            value: _confirmVehicleReady,
            title: dt('جاهزية المركبة للتوصيل'),
            subtitle: dt('مركبتي المختارة صالحة للعمل ومجهّزة لنقل الطلبات بأمان'),
            onChanged: (v) {
              DarbHaptics.selection();
              setState(() {
                _confirmVehicleReady = v;
                _stepError = null;
              });
              _persistDraft();
            },
          ),
          const SizedBox(height: 10),
          _ChecklistTile(
            value: _confirmLocationConsent,
            title: dt('مشاركة الموقع أثناء التوصيل'),
            subtitle: dt('أوافق على مشاركة موقعي المباشر أثناء تنفيذ الطلبات النشطة ليتمكن العميل من تتبع المسار'),
            onChanged: (v) {
              DarbHaptics.selection();
              setState(() {
                _confirmLocationConsent = v;
                _stepError = null;
              });
              _persistDraft();
            },
          ),
          const SizedBox(height: 10),
          _ChecklistTile(
            value: _confirmReviewTerms,
            title: dt('مراجعة الإدارة والتفعيل'),
            subtitle: dt('أفهم أن الطلب سيظل قيد المراجعة حتى تعتمده إدارة دازريفو قبل تفعيل استقبال الطلبات'),
            onChanged: (v) {
              DarbHaptics.selection();
              setState(() {
                _confirmReviewTerms = v;
                _stepError = null;
              });
              _persistDraft();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepReview(BuildContext context) {
    final selectedCity = _cities.cast<Map<String, dynamic>?>().firstWhere(
          (c) => c?['id']?.toString() == _cityId,
          orElse: () => null,
        );
    final cityLabel =
        selectedCity != null ? _cityName(selectedCity) : (_cityId ?? dt('غير محدد'));

    return DarbTicketPass(
      leadingIcon: Icons.two_wheeler_rounded,
      title: dt('مراجعة طلب السائق'),
      subtitle: dt('راجع تفاصيل طلبك قبل الإرسال النهائي'),
      status: 'PENDING',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReviewSummaryTile(
            label: dt('مقدم الطلب'),
            value: _nameCtrl.text.trim(),
            onEdit: () => _jumpToStep(0),
          ),
          const SizedBox(height: 10),
          _ReviewSummaryTile(
            label: dt('وسيلة التوصيل'),
            value: _vehicleLabel(_vehicleType),
            onEdit: () => _jumpToStep(1),
          ),
          const SizedBox(height: 10),
          _ReviewSummaryTile(
            label: dt('مدينة العمل'),
            value: cityLabel,
            onEdit: () => _jumpToStep(2),
          ),
          const SizedBox(height: 10),
          _ReviewSummaryTile(
            label: dt('الجاهزية التشغيلية'),
            value: dt('تم تأكيد جاهزية المركبة ومشاركة الموقع ومراجعة الإدارة'),
            onEdit: () => _jumpToStep(3),
          ),
        ],
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final primary = DarbColors.primaryOf(context);
    final isDark = DarbColors.isDark(context);
    return InkWell(
      borderRadius: BorderRadius.circular(DarbRadius.md),
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: DarbMotion.effectiveDuration(context, DarbMotion.fast),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DarbRadius.md),
          color: value
              ? (isDark
                  ? DarbColors.forestSoft.withValues(alpha: 0.72)
                  : DarbColors.mintTint.withValues(alpha: 0.72))
              : DarbColors.softSurfaceOf(context).withValues(alpha: 0.65),
          border: Border.all(
            color: value ? primary : DarbColors.borderOf(context),
            width: value ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: DarbColors.inkOf(context),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: DarbColors.mutedOf(context),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewSummaryTile extends StatelessWidget {
  const _ReviewSummaryTile({
    required this.label,
    required this.value,
    required this.onEdit,
  });

  final String label;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: DarbColors.softSurfaceOf(context).withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(DarbRadius.md),
        border: Border.all(color: DarbColors.borderOf(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: DarbColors.mutedOf(context),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: DarbColors.inkOf(context),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            child: Text(dt('تعديل')),
          ),
        ],
      ),
    );
  }
}
