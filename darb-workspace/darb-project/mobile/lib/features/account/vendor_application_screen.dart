import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/local_cache.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_map_picker.dart';
import '../../core/widgets/darb_motion_components.dart';

class VendorApplicationScreen extends StatefulWidget {
  const VendorApplicationScreen({
    super.key,
    required this.user,
    required this.onRefreshUser,
    this.loadCitiesOverride,
    this.submitApplicationOverride,
    this.updateProfileOverride,
    this.enableDraftCache = true,
    this.enableInteractiveMap = true,
  });

  final Map<String, dynamic> user;
  final Future<void> Function() onRefreshUser;
  final Future<List<Map<String, dynamic>>> Function()? loadCitiesOverride;
  final Future<Map<String, dynamic>?> Function(Map<String, dynamic> payload)?
      submitApplicationOverride;
  final Future<void> Function(Map<String, dynamic> payload)?
      updateProfileOverride;
  final bool enableDraftCache;
  final bool enableInteractiveMap;

  @override
  State<VendorApplicationScreen> createState() =>
      _VendorApplicationScreenState();
}

class _VendorApplicationScreenState extends State<VendorApplicationScreen> {
  static const _draftKey = 'vendor_application_draft_v1';
  static const _totalSteps = 5;

  int _step = 0;
  bool _movingForward = true;

  late final TextEditingController _storeNameCtrl;
  late final TextEditingController _storeTypeCtrl;
  late final TextEditingController _ownerNameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _descriptionCtrl;

  String? _cityId;
  double? _lat;
  double? _lng;
  bool _confirmStoreTerms = false;

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
    _storeNameCtrl = TextEditingController();
    _storeTypeCtrl = TextEditingController();
    _ownerNameCtrl = TextEditingController(
      text: widget.user['name']?.toString().trim() ?? '',
    );
    _addressCtrl = TextEditingController();
    _descriptionCtrl = TextEditingController();
    _restoreDraft();
    _loadCities();
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _storeTypeCtrl.dispose();
    _ownerNameCtrl.dispose();
    _addressCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  String? get _vendorStatus =>
      widget.user['vendorApplication']?.toString().toUpperCase();
  String? get _driverStatus =>
      widget.user['driverApplication']?.toString().toUpperCase();

  Future<void> _restoreDraft() async {
    if (!widget.enableDraftCache) return;
    final raw = await DarbLocalCache.instance.readJson(_draftKey);
    if (!mounted || raw is! Map) return;
    setState(() {
      final storeName = raw['name']?.toString() ?? '';
      if (storeName.isNotEmpty) _storeNameCtrl.text = storeName;
      final storeType = raw['type']?.toString() ?? '';
      if (storeType.isNotEmpty) _storeTypeCtrl.text = storeType;
      final ownerName = raw['ownerName']?.toString().trim() ?? '';
      if (ownerName.isNotEmpty && _ownerNameCtrl.text.trim().isEmpty) {
        _ownerNameCtrl.text = ownerName;
      }
      final address = raw['address']?.toString() ?? '';
      if (address.isNotEmpty) _addressCtrl.text = address;
      final desc = raw['description']?.toString() ?? '';
      if (desc.isNotEmpty) _descriptionCtrl.text = desc;
      final savedCity = raw['cityId']?.toString();
      if (savedCity != null && savedCity.isNotEmpty) {
        _cityId = savedCity;
      }
      final rawLat = raw['latitude'];
      final rawLng = raw['longitude'];
      if (rawLat is num && rawLng is num) {
        _lat = rawLat.toDouble();
        _lng = rawLng.toDouble();
      }
      _confirmStoreTerms = raw['confirmStoreTerms'] == true;
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
      'name': _storeNameCtrl.text.trim(),
      'type': _storeTypeCtrl.text.trim(),
      'ownerName': _ownerNameCtrl.text.trim(),
      'cityId': _cityId,
      'address': _addressCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      'latitude': _lat,
      'longitude': _lng,
      'confirmStoreTerms': _confirmStoreTerms,
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

  String _stepTitle(int step) => switch (step) {
        0 => dt('هوية المتجر ونوع النشاط'),
        1 => dt('مسؤول المتجر والتواصل'),
        2 => dt('المدينة والعنوان والموقع'),
        3 => dt('وصف المتجر والجاهزية'),
        _ => dt('مراجعة الطلب والإرسال'),
      };

  bool _validateCurrentStep() {
    String? err;
    switch (_step) {
      case 0:
        final storeName = _storeNameCtrl.text.trim();
        final storeType = _storeTypeCtrl.text.trim();
        if (storeName.length < 2) {
          err = dt('أدخل اسم المتجر (حرفان على الأقل)');
        } else if (storeName.length > 60) {
          err = dt('اسم المتجر يجب ألا يتجاوز 60 حرفاً');
        } else if (storeType.length < 2) {
          err = dt('أدخل نوع النشاط التجاري للمتجر');
        } else if (storeType.length > 40) {
          err = dt('نوع النشاط يجب ألا يتجاوز 40 حرفاً');
        }
      case 1:
        final owner = _ownerNameCtrl.text.trim();
        if (owner.length < 2) {
          err = dt('أدخل اسم مسؤول المتجر للمتابعة');
        } else if (owner.length > 120) {
          err = dt('الاسم طويل جداً (الحد الأقصى 120 حرفاً)');
        }
      case 2:
        if (_cityId == null || _cityId!.isEmpty) {
          err = dt('اختر المدينة التي يعمل بها المتجر');
        } else if (_addressCtrl.text.trim().length > 300) {
          err = dt('العنوان طويل جداً (الحد الأقصى 300 حرف)');
        }
      case 3:
        if (_descriptionCtrl.text.trim().length > 500) {
          err = dt('وصف المتجر يجب ألا يتجاوز 500 حرف');
        } else if (!_confirmStoreTerms) {
          err = dt('أكد جاهزية المتجر وشروط الانضمام للمتابعة');
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
        _stepError = dt('اختر المدينة التي يعمل بها المتجر');
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
      final ownerName = _ownerNameCtrl.text.trim();
      final existingName = widget.user['name']?.toString().trim() ?? '';
      if (ownerName.length >= 2 && ownerName != existingName) {
        if (widget.updateProfileOverride != null) {
          await widget.updateProfileOverride!({'name': ownerName});
        } else {
          await Api.instance.patch('/auth/me', {'name': ownerName});
        }
      }

      final desc = _descriptionCtrl.text.trim();
      final addr = _addressCtrl.text.trim();
      final payload = <String, dynamic>{
        'name': _storeNameCtrl.text.trim(),
        'type': _storeTypeCtrl.text.trim(),
        'cityId': _cityId!,
        if (desc.isNotEmpty) 'description': desc,
        if (addr.isNotEmpty) 'address': addr,
        if (_lat != null && _lng != null) ...{
          'latitude': _lat!,
          'longitude': _lng!,
        },
      };

      final res = widget.submitApplicationOverride != null
          ? await widget.submitApplicationOverride!(payload)
          : await Api.instance.post('/vendors/apply', payload);

      if (!mounted) return;
      if (widget.enableDraftCache) {
        await DarbLocalCache.instance.writeJson(_draftKey, {
          'submitted': true,
          'name': _storeNameCtrl.text.trim(),
          'type': _storeTypeCtrl.text.trim(),
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
    final status = _vendorStatus;
    final driverConflict = _driverStatus;

    return Scaffold(
      appBar: DarbGlassAppBar(
        title: dt('طلب انضمام متجر'),
        subtitle: _submittedSuccess
            ? dt('تم استلام طلب المتجر بنجاح')
            : (status != null
                ? dt('متابعة حالة طلب المتجر')
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
                  : (status != null || driverConflict != null)
                      ? _buildStatusView(
                          context,
                          vendorStatus: status,
                          driverStatus: driverConflict,
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
    String? vendorStatus,
    String? driverStatus,
  }) {
    final isConflict = vendorStatus == null && driverStatus != null;
    final activeStatus = vendorStatus ?? driverStatus ?? 'PENDING';
    final ink = DarbColors.inkOf(context);
    final muted = DarbColors.mutedOf(context);

    final (IconData icon, Color tone, String title, String message) =
        isConflict
            ? (
                Icons.delivery_dining_rounded,
                DarbColors.warningOf(context),
                dt('لديك طلب سائق مسجّل مسبقاً'),
                dt('الحساب الواحد في دَرْب يرتبط إما بملف سائق أو بملف متجر. يمكنك متابعة طلب السائق من صفحة التقديم الخاصة بالسائقين.'),
              )
            : switch (activeStatus) {
                'APPROVED' => (
                    Icons.verified_rounded,
                    DarbColors.successOf(context),
                    dt('تم اعتماد متجرك في دَرْب'),
                    dt('طلب المتجر معتمد. حدّث حالة الحساب إذا لم تظهر لوحة التاجر تلقائياً.'),
                  ),
                'REJECTED' || 'SUSPENDED' => (
                    Icons.store_mall_directory_outlined,
                    DarbColors.dangerOf(context),
                    dt('طلب المتجر غير مفعل حالياً'),
                    dt('تم رفض أو تعليق طلب المتجر الحالي. تواصل مع إدارة دَرْب لمراجعة السبب.'),
                  ),
                _ => (
                    Icons.hourglass_top_rounded,
                    DarbColors.warningOf(context),
                    dt('طلب متجرك قيد المراجعة'),
                    dt('طلب متجرك قيد المراجعة. ستتمكن من إدارة المنتجات بعد اعتماد الإدارة.'),
                  ),
              };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        DarbFadeSlide(
          child: DarbGlassSurface(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: tone.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, size: 28, color: tone),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DarbStatusBadge(status: activeStatus),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(
                    color: muted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
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
                      Icons.storefront_rounded,
                      size: 36,
                      color: success,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  dt('تم استلام طلب انضمام متجرك'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Center(child: DarbStatusBadge(status: 'PENDING')),
                const SizedBox(height: 14),
                Text(
                  _submittedMessage?.isNotEmpty == true
                      ? _submittedMessage!
                      : dt('تم استلام طلبك وسيتم مراجعته قبل تفعيل المتجر'),
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
    final primary = DarbColors.primaryOf(context);
    final ink = DarbColors.inkOf(context);
    final muted = DarbColors.mutedOf(context);
    final reduced = DarbMotion.reduceMotion(context);
    final progress = (_step + 1) / _totalSteps;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: DarbGlassSurface(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            borderRadius: DarbRadius.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(DarbRadius.pill),
                      ),
                      child: Text(
                        '${_step + 1} / $_totalSteps',
                        style: TextStyle(
                          color: primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _stepTitle(_step),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(DarbRadius.pill),
                  child: Container(
                    height: 6,
                    color: DarbColors.softSurfaceOf(context),
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
                            gradient: LinearGradient(
                              colors: [primary, DarbColors.lime],
                            ),
                            borderRadius:
                                BorderRadius.circular(DarbRadius.pill),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
                  0 => _buildStepStoreIdentity(context),
                  1 => _buildStepOwner(context),
                  2 => _buildStepLocation(context),
                  3 => _buildStepDescription(context),
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

  Widget _buildStepStoreIdentity(BuildContext context) {
    final primary = DarbColors.primaryOf(context);
    final muted = DarbColors.mutedOf(context);
    final suggestions = [
      dt('مطعم'),
      dt('سوبرماركت'),
      dt('صيدلية'),
      dt('حلويات'),
      dt('خضار وفواكه'),
      dt('متجر عام'),
    ];

    return DarbGlassSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DarbSectionHeader(
            title: dt('بيانات المتجر الأساسية'),
            subtitle: dt('اختر اسماً واضحاً ونوع النشاط الذي يظهر للعملاء'),
          ),
          const SizedBox(height: 14),
          DarbShakeBox(
            trigger: _shakeTrigger,
            child: Column(
              children: [
                TextField(
                  controller: _storeNameCtrl,
                  maxLength: 60,
                  onChanged: (_) {
                    if (_stepError != null) setState(() => _stepError = null);
                  },
                  decoration: InputDecoration(
                    labelText: dt('اسم المتجر'),
                    hintText: dt('مثلاً: مخبز الياسمين، صيدلية النور...'),
                    prefixIcon:
                        Icon(Icons.storefront_outlined, color: primary),
                    counterStyle: TextStyle(color: muted, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _storeTypeCtrl,
                  maxLength: 40,
                  onChanged: (_) {
                    if (_stepError != null) setState(() => _stepError = null);
                  },
                  decoration: InputDecoration(
                    labelText: dt('نوع النشاط'),
                    hintText: dt('مثلاً: مطعم، سوبرماركت، صيدلية...'),
                    prefixIcon:
                        Icon(Icons.category_outlined, color: primary),
                    counterStyle: TextStyle(color: muted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dt('تصنيفات سريعة'),
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in suggestions)
                ChoiceChip(
                  label: Text(tag),
                  selected: _storeTypeCtrl.text.trim() == tag,
                  onSelected: (_) {
                    DarbHaptics.selection();
                    setState(() {
                      _storeTypeCtrl.text = tag;
                      _stepError = null;
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepOwner(BuildContext context) {
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
            title: dt('مسؤول المتجر والتواصل'),
            subtitle: dt('بيانات الشخص المسؤول عن إدارة الطلبات'),
          ),
          const SizedBox(height: 14),
          DarbShakeBox(
            trigger: _shakeTrigger,
            child: TextField(
              controller: _ownerNameCtrl,
              maxLength: 120,
              onChanged: (_) {
                if (_stepError != null) setState(() => _stepError = null);
              },
              decoration: InputDecoration(
                labelText: dt('اسم مسؤول المتجر'),
                hintText: dt('الاسم الكامل لصاحب المتجر أو المدير'),
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
                  dt('وسيلة التواصل الموثّقة للحساب'),
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

  Widget _buildStepLocation(BuildContext context) {
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

    final selectedCity = _cities.cast<Map<String, dynamic>?>().firstWhere(
          (c) => c?['id']?.toString() == _cityId,
          orElse: () => null,
        );

    return DarbGlassSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DarbSectionHeader(
            title: dt('موقع المتجر وعنوانه'),
            subtitle: dt('يساعد تحديد الموقع الدقيق في احتساب أجرة التوصيل بدقة'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _cityId,
            decoration: InputDecoration(labelText: dt('المدينة')),
            items: [
              for (final c in _cities)
                DropdownMenuItem(
                  value: c['id']?.toString(),
                  child: Text(_cityName(c)),
                ),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _cityId = v;
                _stepError = null;
              });
              _persistDraft();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressCtrl,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: dt('عنوان المتجر (اختياري)'),
              hintText: dt('الحي، الشارع، أقرب نقطة علامة...'),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.enableInteractiveMap)
            DarbMapPicker(
              selectedLatitude: _lat,
              selectedLongitude: _lng,
              cityName: selectedCity != null ? _cityName(selectedCity) : null,
              onPointSelected: (pickedLat, pickedLng) {
                setState(() {
                  _lat = pickedLat;
                  _lng = pickedLng;
                  _stepError = null;
                });
                _persistDraft();
              },
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DarbColors.softSurfaceOf(context),
                borderRadius: BorderRadius.circular(DarbRadius.md),
                border: Border.all(color: DarbColors.borderOf(context)),
              ),
              child: Text(
                (_lat != null && _lng != null)
                    ? '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                    : dt('تحديد الموقع عبر الخريطة اختياري'),
                style: TextStyle(
                  color: DarbColors.mutedOf(context),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepDescription(BuildContext context) {
    final isDark = DarbColors.isDark(context);
    final primary = DarbColors.primaryOf(context);

    return DarbGlassSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DarbSectionHeader(
            title: dt('وصف المتجر وجاهزية التشغيل'),
            subtitle: dt('نبذة مختصرة تعرّف العملاء بمنتجاتك وخدماتك'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _descriptionCtrl,
            maxLength: 500,
            minLines: 3,
            maxLines: 5,
            onChanged: (_) {
              if (_stepError != null) setState(() => _stepError = null);
            },
            decoration: InputDecoration(
              labelText: dt('وصف المتجر (اختياري)'),
              hintText: dt('أبرز الأصناف المتوفرة، ساعات العمل، أو أي ملاحظة للعملاء...'),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(DarbRadius.md),
            onTap: () {
              DarbHaptics.selection();
              setState(() {
                _confirmStoreTerms = !_confirmStoreTerms;
                _stepError = null;
              });
              _persistDraft();
            },
            child: AnimatedContainer(
              duration: DarbMotion.effectiveDuration(context, DarbMotion.fast),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DarbRadius.md),
                color: _confirmStoreTerms
                    ? (isDark
                        ? DarbColors.forestSoft.withValues(alpha: 0.72)
                        : DarbColors.mintTint.withValues(alpha: 0.72))
                    : DarbColors.softSurfaceOf(context).withValues(alpha: 0.65),
                border: Border.all(
                  color: _confirmStoreTerms
                      ? primary
                      : DarbColors.borderOf(context),
                  width: _confirmStoreTerms ? 1.4 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _confirmStoreTerms,
                    onChanged: (v) {
                      DarbHaptics.selection();
                      setState(() {
                        _confirmStoreTerms = v ?? false;
                        _stepError = null;
                      });
                      _persistDraft();
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dt('الالتزام بجودة الطلبات والمراجعة'),
                            style: TextStyle(
                              color: DarbColors.inkOf(context),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            dt('أؤكد جاهزية المتجر لاستقبال وتحضير طلبات العملاء، وأفهم أن الطلب يخضع لمراجعة إدارة دَرْب قبل التفعيل.'),
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

    return DarbGlassSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DarbSectionHeader(
            title: dt('مراجعة طلب انضمام المتجر'),
            subtitle: dt('تحقق من صحة البيانات قبل الإرسال النهائي'),
          ),
          const SizedBox(height: 14),
          _VendorReviewTile(
            label: dt('اسم المتجر ونوع النشاط'),
            value:
                '${_storeNameCtrl.text.trim()} · ${_storeTypeCtrl.text.trim()}',
            onEdit: () => _jumpToStep(0),
          ),
          const SizedBox(height: 10),
          _VendorReviewTile(
            label: dt('مسؤول المتجر'),
            value: _ownerNameCtrl.text.trim(),
            onEdit: () => _jumpToStep(1),
          ),
          const SizedBox(height: 10),
          _VendorReviewTile(
            label: dt('المدينة والعنوان'),
            value: [
              cityLabel,
              if (_addressCtrl.text.trim().isNotEmpty)
                _addressCtrl.text.trim(),
              if (_lat != null && _lng != null)
                '${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
            ].join(' · '),
            onEdit: () => _jumpToStep(2),
          ),
          const SizedBox(height: 10),
          _VendorReviewTile(
            label: dt('وصف المتجر'),
            value: _descriptionCtrl.text.trim().isNotEmpty
                ? _descriptionCtrl.text.trim()
                : dt('بدون وصف إضافي'),
            onEdit: () => _jumpToStep(3),
          ),
        ],
      ),
    );
  }
}

class _VendorReviewTile extends StatelessWidget {
  const _VendorReviewTile({
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
